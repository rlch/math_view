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

/// Get ALL cursor info from rendered tree.
Future<({double globalX, double globalY, double height, int blockId, Rect localRect})>
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
        localRect: rect,
      );
    }
  }

  throw StateError('No cursor found in rendered tree');
}

void main() {
  group('Cursor sync after edits in complex expressions', () {
    late String editorId;

    setUp(() {
      editorId = createEditor();
    });

    tearDown(() => closeEditor(id: editorId));

    EditorSnapshot dispatch(EditorIntent intent) =>
        dispatchEditor(id: editorId, intent: intent, displayMode: false);

    EditorSnapshot type_(String ch) =>
        dispatch(EditorIntent.insertSymbol(ch: ch));

    test('type in denominator after complex numerator — cursor carets valid', () {
      // Build: \frac{-b}{2a}
      dispatch(const EditorIntent.insertFrac());
      // Cursor is in numerator
      type_('-');
      type_('b');
      // Move to denominator
      dispatch(const EditorIntent.moveRight()); // exit numerator → denominator
      type_('2');
      type_('a');

      final s = getEditorSnapshot(id: editorId, displayMode: false);
      final cb = findCursorBlock(s.editorLayout.root)!;

      // ignore: avoid_print
      print('Denom after "2a": block=${cb.blockId} cursor=${cb.cursorIndex} '
          'carets=${cb.caretPositions.toList()} leftX=${cb.leftX} '
          'latex=${s.latex}');

      // Cursor should be at index 2 (after '2' and 'a')
      expect(cb.cursorIndex, 2);

      // Caret positions must be monotonic and non-zero
      final carets = cb.caretPositions.toList();
      expect(carets.length, 3, reason: '2 nodes → 3 caret positions');
      for (int j = 1; j < carets.length; j++) {
        expect(carets[j], greaterThan(carets[j - 1]),
            reason: 'carets[$j]=${carets[j]} should be > carets[${j - 1}]=${carets[j - 1]}');
      }

      // Now type another char and verify cursor advances
      final s2 = type_('+');
      final cb2 = findCursorBlock(s2.editorLayout.root)!;
      expect(cb2.cursorIndex, 3);

      // ignore: avoid_print
      print('Denom after "+": block=${cb2.blockId} cursor=${cb2.cursorIndex} '
          'carets=${cb2.caretPositions.toList()} latex=${s2.latex}');

      final carets2 = cb2.caretPositions.toList();
      for (int j = 1; j < carets2.length; j++) {
        expect(carets2[j], greaterThan(carets2[j - 1]),
            reason: 'After +: carets[$j]=${carets2[j]} should be > carets[${j - 1}]=${carets2[j - 1]}');
      }
    });

    testWidgets('rendered cursor position updates correctly after each edit', (tester) async {
      // Build \frac{ab}{} then type in denominator
      dispatch(const EditorIntent.insertFrac());
      type_('a');
      type_('b');
      dispatch(const EditorIntent.moveRight()); // → denominator

      // Type 'x', 'y', 'z' in denominator, track rendered cursor X
      final cursorXs = <double>[];
      for (final ch in ['x', 'y', 'z']) {
        final s = type_(ch);
        final cursor = await getCursorGlobal(tester, s);
        cursorXs.add(cursor.globalX);

        final cb = findCursorBlock(s.editorLayout.root)!;
        // ignore: avoid_print
        print('After "$ch" in denom: globalX=${cursor.globalX.toStringAsFixed(2)} '
            'block=${cursor.blockId} height=${cursor.height.toStringAsFixed(2)} '
            'cursorIdx=${cb.cursorIndex} carets=${cb.caretPositions.toList()} '
            'latex=${s.latex}');
      }

      // Cursor X should strictly increase
      for (int i = 1; i < cursorXs.length; i++) {
        expect(cursorXs[i], greaterThan(cursorXs[i - 1]),
            reason: 'Cursor X should advance: step $i (${cursorXs[i]}) > step ${i - 1} (${cursorXs[i - 1]})');
      }
    });

    test('SetLatex then navigate — cursor in correct block', () {
      // Load quadratic formula
      dispatch(EditorIntent.setLatex(latex: r'x=\frac{-b\pm\sqrt{b^2-4ac}}{2a}'));
      dispatch(const EditorIntent.moveToStart());

      // Walk to denominator: start → x → = → frac → num → ... → denom
      // Let's just move to end of root, then move left into denominator
      dispatch(const EditorIntent.moveToEnd());
      dispatch(const EditorIntent.moveLeft()); // before last node (if any) or into frac

      final s1 = getEditorSnapshot(id: editorId, displayMode: false);
      final cb1 = findCursorBlock(s1.editorLayout.root)!;

      // ignore: avoid_print
      print('After MoveToEnd+MoveLeft: block=${cb1.blockId} cursor=${cb1.cursorIndex} '
          'carets=${cb1.caretPositions.toList()} latex=${s1.latex}');

      // Carets should be valid
      final carets = cb1.caretPositions.toList();
      for (int j = 1; j < carets.length; j++) {
        expect(carets[j], greaterThan(carets[j - 1]),
            reason: 'carets[$j]=${carets[j]} should be > carets[${j - 1}]=${carets[j - 1]}');
      }
    });

    test('type after \\pm in complex expression — cursor correct', () {
      // Build: -b\pm c
      type_('-');
      type_('b');
      dispatch(EditorIntent.setLatex(latex: r'-b\pm'));
      // Cursor at end, type 'c'
      final s = type_('c');
      final cb = findCursorBlock(s.editorLayout.root)!;

      // ignore: avoid_print
      print('After typing c after \\pm: block=${cb.blockId} cursor=${cb.cursorIndex} '
          'carets=${cb.caretPositions.toList()} latex=${s.latex}');

      final carets = cb.caretPositions.toList();
      // Should have 4 positions: before -, before b, before \pm, before c, after c
      // Actually after SetLatex then type: -b\pm c → nodes: -, b, \pm, c → 5 caret positions
      for (int j = 1; j < carets.length; j++) {
        expect(carets[j], greaterThan(carets[j - 1]),
            reason: 'carets[$j]=${carets[j]} should be > carets[${j - 1}]=${carets[j - 1]}');
      }
    });

    testWidgets('cursor rendered at correct position in denominator of loaded expression', (tester) async {
      // Load \frac{a}{b}, navigate to denominator, type char, verify position
      dispatch(EditorIntent.setLatex(latex: r'\frac{abc}{xy}'));
      dispatch(const EditorIntent.moveToEnd());
      // moveLeft from end enters denominator at end
      dispatch(const EditorIntent.moveLeft());

      var s = getEditorSnapshot(id: editorId, displayMode: false);
      var cb = findCursorBlock(s.editorLayout.root)!;

      // ignore: avoid_print
      print('In denom of \\frac{abc}{xy}: block=${cb.blockId} cursor=${cb.cursorIndex} '
          'carets=${cb.caretPositions.toList()}');

      // Type 'z'
      s = type_('z');
      cb = findCursorBlock(s.editorLayout.root)!;

      // ignore: avoid_print
      print('After z in denom: block=${cb.blockId} cursor=${cb.cursorIndex} '
          'carets=${cb.caretPositions.toList()} latex=${s.latex}');

      // Carets should be valid
      final carets = cb.caretPositions.toList();
      for (int j = 1; j < carets.length; j++) {
        expect(carets[j], greaterThan(carets[j - 1]),
            reason: 'carets[$j] should be > carets[${j - 1}]');
      }

      // Render and check cursor
      final cursor = await getCursorGlobal(tester, s);
      // ignore: avoid_print
      print('Rendered cursor: globalX=${cursor.globalX.toStringAsFixed(2)} '
          'globalY=${cursor.globalY.toStringAsFixed(2)} block=${cursor.blockId}');

      // cursor.blockId should match the denominator block
      expect(cursor.blockId, cb.blockId,
          reason: 'Rendered cursor should be in denominator block');

      // Cursor X should be positive (not at origin)
      expect(cursor.globalX, greaterThan(300),
          reason: 'Cursor should not be at left edge of screen');
    });
  });
}
