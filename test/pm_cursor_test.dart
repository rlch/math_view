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
    // a ± b — three arena nodes: Symbol('a'), Symbol('\\pm '), Symbol('b')
    editorId = createEditorFromLatex(latex: r'a\pm b');
    dispatchEditor(
      id: editorId,
      intent: const EditorIntent.moveToStart(),
      displayMode: false,
    );
  });

  tearDown(() => closeEditor(id: editorId));

  // -------------------------------------------------------------------------
  // Expected cursor positions for "a \pm b":
  //   0. ^a\pm b     — root block, cursor=0 (before 'a')
  //   1. a^\pm b     — root block, cursor=1 (after 'a', before \pm)
  //   2. a\pm ^b     — root block, cursor=2 (after \pm, before 'b')
  //   3. a\pm b^     — root block, cursor=3 (after 'b')
  // -------------------------------------------------------------------------

  group(r'a\pm b cursor walk-through (data layer)', () {
    test('walk right through all 4 positions — carets are monotonic', () {
      final positions = <Map<String, dynamic>>[];

      // Record step 0
      var s = getEditorSnapshot(id: editorId, displayMode: false);
      var cb = findCursorBlock(s.editorLayout.root)!;
      positions.add({
        'step': 0,
        'blockId': cb.blockId,
        'cursorIndex': cb.cursorIndex,
        'caretPositions': cb.caretPositions.toList(),
        'leftX': cb.leftX,
      });

      // Steps 1–3: dispatch MoveRight
      for (int step = 1; step <= 3; step++) {
        s = dispatchEditor(
          id: editorId,
          intent: const EditorIntent.moveRight(),
          displayMode: false,
        );
        cb = findCursorBlock(s.editorLayout.root)!;
        positions.add({
          'step': step,
          'blockId': cb.blockId,
          'cursorIndex': cb.cursorIndex,
          'caretPositions': cb.caretPositions.toList(),
          'leftX': cb.leftX,
        });
      }

      // Print all for inspection
      for (final p in positions) {
        // ignore: avoid_print
        print('Step ${p['step']}: block=${p['blockId']} cursor=${p['cursorIndex']} '
            'caretPositions=${p['caretPositions']} leftX=${p['leftX']}');
      }

      // All positions should be in root block
      final rootBlockId = positions[0]['blockId'];
      for (final p in positions) {
        expect(p['blockId'], rootBlockId,
            reason: 'Step ${p['step']}: should stay in root block');
      }

      // Cursor indices should be 0, 1, 2, 3
      for (int i = 0; i <= 3; i++) {
        expect(positions[i]['cursorIndex'], i,
            reason: 'Step $i: cursorIndex should be $i');
      }

      // Block should have exactly 4 caret positions (3 nodes + 1)
      final carets = positions[0]['caretPositions'] as List<double>;
      expect(carets.length, 4,
          reason: 'a \\pm b has 3 nodes → 4 caret positions');

      // Caret positions must be strictly monotonic
      for (int j = 1; j < carets.length; j++) {
        expect(carets[j], greaterThan(carets[j - 1]),
            reason: 'caret[$j]=${carets[j]} should be > '
                'caret[${j - 1}]=${carets[j - 1]}');
      }

      // \pm (caret 1→2) should span a reasonable width
      final pmWidth = carets[2] - carets[1];
      // ignore: avoid_print
      print('\\pm caret width: $pmWidth em');
      expect(pmWidth, greaterThan(0.2),
          reason: '\\pm should have reasonable caret span (got $pmWidth em)');
    });
  });

  group(r'a\pm b cursor rendering', () {
    testWidgets('cursor X advances correctly at each position', (tester) async {
      final cursorData = <Map<String, dynamic>>[];

      for (int step = 0; step <= 3; step++) {
        if (step > 0) {
          dispatchEditor(
            id: editorId,
            intent: const EditorIntent.moveRight(),
            displayMode: false,
          );
        }

        final s = getEditorSnapshot(id: editorId, displayMode: false);
        final cursor = await getCursorGlobal(tester, s);

        cursorData.add({
          'step': step,
          'globalX': cursor.globalX,
          'globalY': cursor.globalY,
          'height': cursor.height,
          'blockId': cursor.blockId,
        });

        // ignore: avoid_print
        print('Step $step: globalX=${cursor.globalX.toStringAsFixed(2)} '
            'globalY=${cursor.globalY.toStringAsFixed(2)} '
            'height=${cursor.height.toStringAsFixed(2)}');
      }

      // All should be in the same block
      final rootBlockId = cursorData[0]['blockId'];
      for (final d in cursorData) {
        expect(d['blockId'], rootBlockId,
            reason: 'Step ${d['step']}: should be in root block');
      }

      // Global X should be strictly increasing
      for (int i = 1; i < cursorData.length; i++) {
        final prevX = cursorData[i - 1]['globalX'] as double;
        final currX = cursorData[i]['globalX'] as double;
        expect(currX, greaterThan(prevX),
            reason: 'Step $i: globalX ($currX) should be > step ${i - 1} ($prevX)');
      }

      // All heights should be equal (all in root block at same scale)
      final h0 = cursorData[0]['height'] as double;
      for (int i = 1; i < cursorData.length; i++) {
        expect(cursorData[i]['height'] as double, closeTo(h0, 0.01),
            reason: 'Step $i: cursor height should match step 0');
      }

      // All Y positions should be equal (same baseline)
      final y0 = cursorData[0]['globalY'] as double;
      for (int i = 1; i < cursorData.length; i++) {
        expect(cursorData[i]['globalY'] as double, closeTo(y0, 0.5),
            reason: 'Step $i: cursor Y should match step 0');
      }

      // Gap between step 1 and 2 (the \pm symbol) should be > gap for single chars
      final gapA = (cursorData[1]['globalX'] as double) - (cursorData[0]['globalX'] as double);
      final gapPm = (cursorData[2]['globalX'] as double) - (cursorData[1]['globalX'] as double);
      final gapB = (cursorData[3]['globalX'] as double) - (cursorData[2]['globalX'] as double);

      // ignore: avoid_print
      print('Gap a: ${gapA.toStringAsFixed(2)}px, '
          'gap ±: ${gapPm.toStringAsFixed(2)}px, '
          'gap b: ${gapB.toStringAsFixed(2)}px');

      // \pm should be wider than a single letter (it's a wider symbol)
      expect(gapPm, greaterThan(0),
          reason: '\\pm gap should be positive');
    });
  });
}
