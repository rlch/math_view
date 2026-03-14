import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_view/src/render/editable_math_line.dart';
import 'package:math_view/src/render/math_block_widget.dart';
import 'package:math_view/src/rust/api/editor_api.dart';
import 'package:math_view/src/rust/api/editor_layout.dart';

/// Wrap a widget in a MaterialApp for testing.
Widget testApp(Widget child) {
  return MaterialApp(
    home: Scaffold(body: Center(child: child)),
  );
}

const _fontSize = 20.0;
const _color = Color(0xFF000000);
const _cursorColor = Color(0xFF0066FF);

void main() {
  late String editorId;

  setUp(() {
    editorId = createEditorFromLatex(latex: r'\frac{x+1}{2}');
    // Cursor starts at the end — move to the very start
    dispatchEditor(
      id: editorId,
      intent: const EditorIntent.moveToStart(),
      displayMode: false,
    );
  });

  tearDown(() => closeEditor(id: editorId));

  // -------------------------------------------------------------------------
  // Helper: get snapshot, print layout tree for debugging, pump widget
  // -------------------------------------------------------------------------

  EditorSnapshot snap(String id) =>
      getEditorSnapshot(id: id, displayMode: false);

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

  /// Recursively describe the cursor state for debugging.
  String describeCursor(BlockLayout block, {int indent = 0}) {
    final pad = '  ' * indent;
    final buf = StringBuffer();
    buf.writeln('${pad}Block(id=${block.blockId}, cursor=${block.cursorIndex}, '
        'caretPositions=${block.caretPositions}, '
        'baselineShift=${block.baselineShift.toStringAsFixed(4)}, '
        'fontScale=${block.fontScale.toStringAsFixed(4)}, '
        'leftX=${block.leftX.toStringAsFixed(4)})');
    for (final child in block.children) {
      switch (child) {
        case NodeLayout_Leaf():
          buf.writeln('$pad  Leaf(id=${child.nodeId}, leftX=${child.leftX.toStringAsFixed(4)})');
        case NodeLayout_Command():
          buf.writeln('$pad  Command(id=${child.nodeId}, kind=${child.kind}, leftX=${child.leftX.toStringAsFixed(4)})');
          for (final cb in child.childBlocks) {
            buf.write(describeCursor(cb, indent: indent + 2));
          }
      }
    }
    return buf.toString();
  }

  // -------------------------------------------------------------------------
  // Walk through \frac{x+1}{2} from left to right
  //
  // Expected cursor positions:
  //   0. ^\frac{x+1}{2}       — root block, cursor=0
  //   1. \frac{^x+1}{2}       — numerator, cursor=0
  //   2. \frac{x^+1}{2}       — numerator, cursor=1
  //   3. \frac{x+^1}{2}       — numerator, cursor=2
  //   4. \frac{x+1^}{2}       — numerator, cursor=3
  //   5. \frac{x+1}{^2}       — denominator, cursor=0
  //   6. \frac{x+1}{2^}       — denominator, cursor=1
  //   7. \frac{x+1}{2}^       — root block, cursor=1
  // -------------------------------------------------------------------------

  group(r'\frac{x+1}{2} cursor walk-through (real Rust data)', () {
    test('step 0: cursor at start — before frac in root', () {
      final s = snap(editorId);
      final layout = s.editorLayout;

      // Print full tree for inspection
      // ignore: avoid_print
      print(describeCursor(layout.root));

      final cursorBlock = findCursorBlock(layout.root)!;
      expect(cursorBlock.blockId, layout.root.blockId,
          reason: 'Cursor should be in root block');
      expect(cursorBlock.cursorIndex, 0,
          reason: 'Cursor should be at gap 0 (before frac)');

      // Root should have fontScale ≈ 1.0
      expect(cursorBlock.fontScale, closeTo(1.0, 0.01),
          reason: 'Root block fontScale should be 1.0');
      // Root baselineShift ≈ 0
      expect(cursorBlock.baselineShift, closeTo(0.0, 0.01),
          reason: 'Root block baselineShift should be 0');
    });

    test('steps 1–7: MoveRight walk and verify each position', () {
      // Step 0 already verified above. Now walk right 7 times.
      final positions = <Map<String, dynamic>>[];

      // Record step 0
      var s = snap(editorId);
      var cb = findCursorBlock(s.editorLayout.root)!;
      positions.add({
        'step': 0,
        'blockId': cb.blockId,
        'cursorIndex': cb.cursorIndex,
        'baselineShift': cb.baselineShift,
        'fontScale': cb.fontScale,
        'caretPositions': cb.caretPositions.toList(),
        'leftX': cb.leftX,
      });

      // Steps 1–7: dispatch MoveRight
      for (int step = 1; step <= 7; step++) {
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
          'baselineShift': cb.baselineShift,
          'fontScale': cb.fontScale,
          'caretPositions': cb.caretPositions.toList(),
          'leftX': cb.leftX,
        });
      }

      // Print all positions for manual inspection
      for (final p in positions) {
        // ignore: avoid_print
        print('Step ${p['step']}: block=${p['blockId']} cursor=${p['cursorIndex']} '
            'fontScale=${(p['fontScale'] as double).toStringAsFixed(4)} '
            'baselineShift=${(p['baselineShift'] as double).toStringAsFixed(4)} '
            'leftX=${(p['leftX'] as double).toStringAsFixed(4)} '
            'caretPositions=${p['caretPositions']}');
      }

      // --- Verify navigation order ---
      // Step 0: root block, cursor=0
      expect(positions[0]['cursorIndex'], 0);

      // Steps 1–4: numerator block (same blockId), cursor 0→3
      final numBlockId = positions[1]['blockId'];
      for (int i = 1; i <= 4; i++) {
        expect(positions[i]['blockId'], numBlockId,
            reason: 'Steps 1-4 should be in numerator block');
        expect(positions[i]['cursorIndex'], i - 1,
            reason: 'Step $i: cursor should be at gap ${i - 1} in numerator');
      }

      // Steps 5–6: denominator block (different blockId), cursor 0→1
      final denomBlockId = positions[5]['blockId'];
      expect(denomBlockId, isNot(numBlockId),
          reason: 'Denominator must be a different block from numerator');
      expect(positions[5]['cursorIndex'], 0);
      expect(positions[6]['cursorIndex'], 1);

      // Step 7: back to root block, cursor=1
      expect(positions[7]['blockId'], positions[0]['blockId'],
          reason: 'Step 7 should return to root block');
      expect(positions[7]['cursorIndex'], 1);

      // --- Verify fontScale ---
      // Root (steps 0, 7): fontScale ≈ 1.0
      expect(positions[0]['fontScale'] as double, closeTo(1.0, 0.01));
      expect(positions[7]['fontScale'] as double, closeTo(1.0, 0.01));

      // Numerator and denominator: fontScale < 1.0 (fraction text is smaller)
      final numScale = positions[1]['fontScale'] as double;
      final denomScale = positions[5]['fontScale'] as double;
      expect(numScale, lessThan(1.0),
          reason: 'Numerator fontScale should be < 1.0 (fraction sizing)');
      expect(denomScale, lessThan(1.0),
          reason: 'Denominator fontScale should be < 1.0');
      expect(numScale, closeTo(denomScale, 0.01),
          reason: 'Numerator and denominator should have same fontScale');

      // --- Verify baselineShift ---
      // Root: baselineShift ≈ 0
      expect(positions[0]['baselineShift'] as double, closeTo(0.0, 0.01));

      // Numerator: baselineShift > 0 (above expression baseline)
      final numShift = positions[1]['baselineShift'] as double;
      expect(numShift, greaterThan(0),
          reason: 'Numerator baselineShift should be positive (above baseline)');

      // Denominator: baselineShift < 0 (below expression baseline)
      final denomShift = positions[5]['baselineShift'] as double;
      expect(denomShift, lessThan(0),
          reason: 'Denominator baselineShift should be negative (below baseline)');

      // --- Verify caret positions are monotonically increasing within each block ---
      for (int i = 0; i < positions.length; i++) {
        final carets = positions[i]['caretPositions'] as List<double>;
        for (int j = 1; j < carets.length; j++) {
          expect(carets[j], greaterThan(carets[j - 1]),
              reason: 'Step $i: caret positions should be strictly increasing, '
                  'but caret[$j]=${carets[j]} <= caret[${j - 1}]=${carets[j - 1]}');
        }
      }

      // --- Verify cursor X makes sense ---
      // At each step, the caret position at cursorIndex should be a real em value
      for (int i = 0; i < positions.length; i++) {
        final carets = positions[i]['caretPositions'] as List<double>;
        final idx = positions[i]['cursorIndex'] as int;
        final leftX = positions[i]['leftX'] as double;
        final cursorXPx = (carets[idx] - leftX) * _fontSize;
        // Allow small negative from command padding (CMD_CARET_PAD = 0.12em)
        expect(cursorXPx, greaterThanOrEqualTo(-3.0),
            reason: 'Step $i: cursor X in pixels should be >= -3.0, '
                'got $cursorXPx (caret=${carets[idx]}, leftX=$leftX)');
      }
    });

    testWidgets('render walk-through: cursor rect at each position',
        (tester) async {
      // Walk through all 8 positions, render each, verify cursor rect
      final cursorRects = <Map<String, dynamic>>[];

      for (int step = 0; step <= 7; step++) {
        if (step > 0) {
          dispatchEditor(
            id: editorId,
            intent: const EditorIntent.moveRight(),
            displayMode: false,
          );
        }

        final s = snap(editorId);
        final layout = s.editorLayout;

        await tester.pumpWidget(testApp(
          MathBlockWidget(
            block: layout.root,
            untaggedGlyphs: layout.untagged,
            isEditable: true,
            fontSize: _fontSize,
            color: _color,
            cursorColor: _cursorColor,
            cursorOpacity: 1.0,
          ),
        ));

        // Find the RenderEditableMathLine that has a cursor
        final all = tester.renderObjectList<RenderEditableMathLine>(
          find.byType(EditableMathLine),
        );

        RenderEditableMathLine? cursorRender;
        for (final r in all) {
          if (r.cursorRect != null) {
            cursorRender = r;
            break;
          }
        }

        expect(cursorRender, isNotNull,
            reason: 'Step $step: should have a block with active cursor');

        final rect = cursorRender!.cursorRect!;
        final globalPos = cursorRender.localToGlobal(Offset.zero);

        cursorRects.add({
          'step': step,
          'blockId': cursorRender.blockId,
          'localRect': rect,
          'globalX': globalPos.dx + rect.left,
          'globalY': globalPos.dy + rect.center.dy,
          'height': rect.height,
        });

        // ignore: avoid_print
        print('Step $step: block=${cursorRender.blockId} '
            'localX=${rect.left.toStringAsFixed(2)} '
            'globalX=${(globalPos.dx + rect.left).toStringAsFixed(2)} '
            'globalY=${(globalPos.dy + rect.center.dy).toStringAsFixed(2)} '
            'height=${rect.height.toStringAsFixed(2)}');
      }

      // --- Verify cursor heights ---
      final rootHeight = cursorRects[0]['height'] as double;
      final numHeight = cursorRects[1]['height'] as double;
      final denomHeight = cursorRects[5]['height'] as double;

      expect(rootHeight, greaterThan(numHeight),
          reason: 'Root cursor (fontScale=1.0) must be taller than '
              'numerator cursor (fontScale<1.0). '
              'Root=$rootHeight, Num=$numHeight');

      expect(numHeight, closeTo(denomHeight, 0.01),
          reason: 'Numerator and denominator cursors should have same height. '
              'Num=$numHeight, Denom=$denomHeight');

      // --- Verify global Y: numerator above denominator ---
      final numGlobalY = cursorRects[1]['globalY'] as double;
      final denomGlobalY = cursorRects[5]['globalY'] as double;
      expect(numGlobalY, lessThan(denomGlobalY),
          reason: 'Numerator cursor must be above (smaller Y) denominator. '
              'Num=$numGlobalY, Denom=$denomGlobalY');

      // --- Verify global X is monotonically increasing within numerator ---
      for (int i = 2; i <= 4; i++) {
        final prev = cursorRects[i - 1]['globalX'] as double;
        final curr = cursorRects[i]['globalX'] as double;
        expect(curr, greaterThan(prev),
            reason: 'Numerator global X should increase. '
                'Step ${i - 1}=$prev, Step $i=$curr');
      }

      // --- Verify step 7 X is at the right edge ---
      final step0X = cursorRects[0]['globalX'] as double;
      final step7X = cursorRects[7]['globalX'] as double;
      expect(step7X, greaterThan(step0X),
          reason: 'Cursor after frac should be to the right of before frac');
    });
  });
}
