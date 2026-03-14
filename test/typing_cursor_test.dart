import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_view/src/render/editable_math_line.dart';
import 'package:math_view/src/render/math_block_widget.dart';
import 'package:math_view/src/rust/api/editor_api.dart';
import 'package:math_view/src/rust/api/editor_layout.dart';

Widget testApp(Widget child) {
  return MaterialApp(
    home: Scaffold(body: Center(child: child)),
  );
}

const _fontSize = 20.0;
const _color = Color(0xFF000000);
const _cursorColor = Color(0xFF0066FF);

/// Find the BlockLayout with a non-null cursorIndex in the tree.
BlockLayout? findCursorBlock(BlockLayout block) {
  if (block.cursorIndex != null) return block;
  for (final child in block.children) {
    if (child is NodeLayout_Command) {
      for (final cb in child.childBlocks) {
        final found = findCursorBlock(cb);
        if (found != null) return found;
      }
    }
  }
  return null;
}

/// Get the cursor's global X position from a rendered widget tree.
Future<({double globalX, double globalY, double height, int blockId})>
    getCursorGlobal(WidgetTester tester, EditorSnapshot s) async {
  await tester.pumpWidget(testApp(
    MathBlockWidget(
      block: s.editorLayout.root,
      untaggedGlyphs: s.editorLayout.untagged,
      isEditable: true,
      fontSize: _fontSize,
      color: _color,
      cursorColor: _cursorColor,
      cursorOpacity: 1.0,
    ),
  ));

  final all = tester.renderObjectList<RenderEditableMathLine>(
    find.byType(EditableMathLine),
  );

  for (final r in all) {
    final rect = r.cursorRect;
    if (rect != null) {
      final globalPos = r.localToGlobal(Offset.zero);
      return (
        globalX: globalPos.dx + rect.left,
        globalY: globalPos.dy + rect.center.dy,
        height: rect.height,
        blockId: r.blockId,
      );
    }
  }

  throw StateError('No cursor found in rendered tree');
}

void main() {
  late String editorId;

  setUp(() {
    editorId = createEditor();
  });

  tearDown(() => closeEditor(id: editorId));

  EditorSnapshot dispatch(EditorIntent intent) =>
      dispatchEditor(id: editorId, intent: intent, displayMode: false);

  EditorSnapshot type_(String ch) =>
      dispatch(EditorIntent.insertSymbol(ch: ch));

  group('Typing in root block', () {
    test('typing "abc" — cursor advances right after each character', () {
      final positions = <double>[];

      for (final ch in ['a', 'b', 'c']) {
        final s = type_(ch);
        final cb = findCursorBlock(s.editorLayout.root)!;
        final carets = cb.caretPositions;
        final idx = cb.cursorIndex!;
        final cursorEm = carets[idx];
        positions.add(cursorEm);

        // ignore: avoid_print
        print('After "$ch": cursor=$idx caretEm=$cursorEm '
            'carets=${carets.toList()} latex=${s.latex}');
      }

      // Each cursor position should be strictly greater than the previous
      for (int i = 1; i < positions.length; i++) {
        expect(positions[i], greaterThan(positions[i - 1]),
            reason: 'Cursor should move right after typing character $i');
      }
    });

    test('typing "abc" — caret positions are always monotonic', () {
      for (final ch in ['a', 'b', 'c']) {
        final s = type_(ch);
        final cb = findCursorBlock(s.editorLayout.root)!;
        final carets = cb.caretPositions;
        for (int j = 1; j < carets.length; j++) {
          expect(carets[j], greaterThan(carets[j - 1]),
              reason: 'After "$ch": carets[$j]=${carets[j]} should be > '
                  'carets[${j - 1}]=${carets[j - 1]}');
        }
      }
    });
  });

  group('Typing in fraction numerator', () {
    test('type into numerator — cursor stays in numerator, advances right',
        () {
      // Create fraction, cursor lands in numerator
      dispatch(const EditorIntent.insertFrac());
      final afterFrac = dispatchEditor(
          id: editorId,
          intent: const EditorIntent.moveToStart(),
          displayMode: false);
      // Move right to enter numerator
      dispatch(const EditorIntent.moveRight());

      final numBlockId =
          findCursorBlock(dispatchEditor(
                  id: editorId,
                  intent: const EditorIntent.moveRight(),
                  displayMode: false)
              .editorLayout
              .root);
      // Reset — create fresh
      closeEditor(id: editorId);
      editorId = createEditor();
      dispatch(const EditorIntent.insertFrac());

      // Cursor should now be in the numerator (first child block of frac)
      var s = dispatchEditor(
          id: editorId,
          intent: const EditorIntent.moveToStart(),
          displayMode: false);
      s = dispatch(const EditorIntent.moveRight()); // enter numerator

      var cb = findCursorBlock(s.editorLayout.root)!;
      final numBlock = cb.blockId;
      expect(cb.cursorIndex, 0,
          reason: 'Should be at start of numerator');

      // ignore: avoid_print
      print('Numerator block=$numBlock');

      // Type "xy" into numerator
      final positions = <double>[];
      for (final ch in ['x', 'y']) {
        s = type_(ch);
        cb = findCursorBlock(s.editorLayout.root)!;
        expect(cb.blockId, numBlock,
            reason: 'After typing "$ch", cursor should still be in numerator');

        final carets = cb.caretPositions;
        final idx = cb.cursorIndex!;
        positions.add(carets[idx]);

        // ignore: avoid_print
        print('After "$ch" in numerator: cursor=$idx caretEm=${carets[idx]} '
            'carets=${carets.toList()} latex=${s.latex}');

        // Caret positions should be monotonic
        for (int j = 1; j < carets.length; j++) {
          expect(carets[j], greaterThan(carets[j - 1]),
              reason: 'After "$ch" in numerator: carets not monotonic');
        }
      }

      // Cursor should advance
      expect(positions[1], greaterThan(positions[0]),
          reason: 'Cursor should move right after typing in numerator');

      // baselineShift should be positive (numerator is above)
      expect(cb.baselineShift, greaterThan(0),
          reason: 'Numerator baselineShift should be positive');
      // fontScale should be < 1.0
      expect(cb.fontScale, lessThan(1.0),
          reason: 'Numerator fontScale should be < 1.0');
    });
  });

  group('Typing in fraction denominator', () {
    test('type into denominator — cursor stays in denominator, advances right',
        () {
      // Create fraction, navigate to denominator
      dispatch(const EditorIntent.insertFrac());
      dispatch(const EditorIntent.moveToStart());
      dispatch(const EditorIntent.moveRight()); // enter numerator
      // Exit numerator to denominator
      var s = dispatch(const EditorIntent.moveRight()); // exit empty numerator → denominator

      var cb = findCursorBlock(s.editorLayout.root)!;
      final denomBlock = cb.blockId;
      expect(cb.cursorIndex, 0,
          reason: 'Should be at start of denominator');

      // ignore: avoid_print
      print('Denominator block=$denomBlock');

      // Type "23" into denominator
      final positions = <double>[];
      for (final ch in ['2', '3']) {
        s = type_(ch);
        cb = findCursorBlock(s.editorLayout.root)!;
        expect(cb.blockId, denomBlock,
            reason: 'After typing "$ch", cursor should still be in denominator');

        final carets = cb.caretPositions;
        final idx = cb.cursorIndex!;
        positions.add(carets[idx]);

        // ignore: avoid_print
        print('After "$ch" in denominator: cursor=$idx caretEm=${carets[idx]} '
            'carets=${carets.toList()} latex=${s.latex}');

        for (int j = 1; j < carets.length; j++) {
          expect(carets[j], greaterThan(carets[j - 1]),
              reason: 'After "$ch" in denominator: carets not monotonic');
        }
      }

      expect(positions[1], greaterThan(positions[0]),
          reason: 'Cursor should move right after typing in denominator');

      expect(cb.baselineShift, lessThan(0),
          reason: 'Denominator baselineShift should be negative');
      expect(cb.fontScale, lessThan(1.0),
          reason: 'Denominator fontScale should be < 1.0');
    });
  });

  group('Typing in nested fraction', () {
    test(r'type into \frac{\frac{_}{_}}{_} — double nesting', () {
      // Build \frac{}{}: outer fraction
      dispatch(const EditorIntent.insertFrac());
      dispatch(const EditorIntent.moveToStart());
      dispatch(const EditorIntent.moveRight()); // enter outer numerator

      // Insert inner fraction in the outer numerator
      dispatch(const EditorIntent.insertFrac());
      // Cursor should now be in inner numerator

      var s = dispatchEditor(
          id: editorId,
          intent: const EditorIntent.moveToStart(),
          displayMode: false);
      // Navigate: start → outer frac → outer num → inner frac → inner num
      s = dispatch(const EditorIntent.moveRight()); // enter outer numerator
      s = dispatch(const EditorIntent.moveRight()); // enter inner numerator

      var cb = findCursorBlock(s.editorLayout.root)!;
      final innerNumBlock = cb.blockId;

      // ignore: avoid_print
      print('Inner numerator block=$innerNumBlock');

      // Type "a" into inner numerator
      s = type_('a');
      cb = findCursorBlock(s.editorLayout.root)!;
      expect(cb.blockId, innerNumBlock,
          reason: 'Cursor should be in inner numerator after typing');

      // ignore: avoid_print
      print('After "a" in inner num: cursor=${cb.cursorIndex} '
          'baselineShift=${cb.baselineShift.toStringAsFixed(4)} '
          'fontScale=${cb.fontScale.toStringAsFixed(4)} '
          'carets=${cb.caretPositions.toList()} '
          'latex=${s.latex}');

      // Inner numerator should have even smaller fontScale (nested fraction)
      expect(cb.fontScale, lessThan(0.7),
          reason: 'Doubly-nested fraction should have fontScale < 0.7');

      // Carets should be monotonic
      final carets = cb.caretPositions;
      for (int j = 1; j < carets.length; j++) {
        expect(carets[j], greaterThan(carets[j - 1]),
            reason: 'Inner numerator carets should be monotonic');
      }
    });
  });

  group('Typing renders correctly', () {
    testWidgets('cursor global position after typing in numerator vs denominator',
        (tester) async {
      // Build \frac{}{}, type "a" in numerator, "b" in denominator
      dispatch(const EditorIntent.insertFrac());
      dispatch(const EditorIntent.moveToStart());
      dispatch(const EditorIntent.moveRight()); // enter numerator
      var s = type_('a'); // type 'a' in numerator

      final numCursor = await getCursorGlobal(tester, s);
      // ignore: avoid_print
      print('After "a" in numerator: $numCursor');

      // Move to denominator and type 'b'
      dispatch(const EditorIntent.moveRight()); // exit numerator → denominator
      s = type_('b');

      final denomCursor = await getCursorGlobal(tester, s);
      // ignore: avoid_print
      print('After "b" in denominator: $denomCursor');

      // Numerator cursor should be above denominator
      expect(numCursor.globalY, lessThan(denomCursor.globalY),
          reason: 'Numerator cursor Y (${numCursor.globalY}) should be above '
              'denominator cursor Y (${denomCursor.globalY})');

      // Both should have same height (same fontScale)
      expect(numCursor.height, closeTo(denomCursor.height, 0.01),
          reason: 'Numerator and denominator cursor heights should match');

      // Both should be smaller than root height
      dispatch(const EditorIntent.moveRight()); // exit denominator → root
      s = type_('c'); // type in root

      final rootCursor = await getCursorGlobal(tester, s);
      // ignore: avoid_print
      print('After "c" in root: $rootCursor');

      expect(rootCursor.height, greaterThan(numCursor.height),
          reason: 'Root cursor should be taller than fraction cursor');
    });

    testWidgets('cursor X advances after each typed character (rendered)',
        (tester) async {
      // Type "xyz" in root and verify rendered cursor moves right
      final globalXs = <double>[];
      for (final ch in ['x', 'y', 'z']) {
        final s = type_(ch);
        final cursor = await getCursorGlobal(tester, s);
        globalXs.add(cursor.globalX);
        // ignore: avoid_print
        print('After "$ch": globalX=${cursor.globalX.toStringAsFixed(2)}');
      }

      for (int i = 1; i < globalXs.length; i++) {
        expect(globalXs[i], greaterThan(globalXs[i - 1]),
            reason: 'Rendered cursor X should advance after each character');
      }
    });
  });
}
