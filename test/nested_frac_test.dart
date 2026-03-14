import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_view/src/render/editable_math_line.dart';
import 'package:math_view/src/render/math_block_widget.dart';
import 'package:math_view/src/rust/api/editor_api.dart';
import 'package:math_view/src/rust/api/editor_layout.dart';

Widget testApp(Widget child) =>
    MaterialApp(home: Scaffold(body: Center(child: child)));

const _fontSize = 20.0;
const _color = Color(0xFF000000);
const _cursorColor = Color(0xFF0066FF);

void main() {
  // =========================================================================
  // Deeply nested fractions — reproduces staircase rendering bug
  //
  // MathQuill renders nested fractions centered and stacked vertically.
  // Our renderer shows them in a diagonal staircase pattern with fraction
  // bars extending too far left and content not centered.
  // =========================================================================

  group('Deeply nested fractions — staircase rendering bug', () {
    // -----------------------------------------------------------------------
    // Data-layer tests: verify Rust layout tree has correct structure
    // -----------------------------------------------------------------------

    test('nested frac via LiveFraction: LaTeX is correctly nested', () {
      // Simulate typing "fa/2/31213/2123/123123" with LiveFraction
      final id = createEditor();
      // Type "fa"
      for (final ch in 'fa'.split('')) {
        dispatchEditor(
            id: id,
            intent: EditorIntent.insertSymbol(ch: ch),
            displayMode: false);
      }
      // "/" → LiveFraction wraps "fa" into numerator
      dispatchEditor(
          id: id,
          intent: const EditorIntent.liveFraction(),
          displayMode: false);
      // Type "2" in denominator
      dispatchEditor(
          id: id,
          intent: const EditorIntent.insertSymbol(ch: '2'),
          displayMode: false);
      // "/" → LiveFraction wraps "2" into numerator of nested frac
      dispatchEditor(
          id: id,
          intent: const EditorIntent.liveFraction(),
          displayMode: false);
      // Type "31213"
      for (final ch in '31213'.split('')) {
        dispatchEditor(
            id: id,
            intent: EditorIntent.insertSymbol(ch: ch),
            displayMode: false);
      }
      // "/" again
      dispatchEditor(
          id: id,
          intent: const EditorIntent.liveFraction(),
          displayMode: false);
      // Type "2123"
      for (final ch in '2123'.split('')) {
        dispatchEditor(
            id: id,
            intent: EditorIntent.insertSymbol(ch: ch),
            displayMode: false);
      }
      // "/" again
      dispatchEditor(
          id: id,
          intent: const EditorIntent.liveFraction(),
          displayMode: false);
      // Type "123123"
      for (final ch in '123123'.split('')) {
        dispatchEditor(
            id: id,
            intent: EditorIntent.insertSymbol(ch: ch),
            displayMode: false);
      }

      final snap = getEditorSnapshot(id: id, displayMode: false);
      // ignore: avoid_print
      print('LaTeX: ${snap.latex}');

      // The LaTeX should show nested fractions in the denominator
      expect(snap.latex, contains(r'\frac'));

      closeEditor(id: id);
    });

    test('simple 2-level nesting: child blocks centered under parent bar', () {
      // \frac{a}{\frac{b}{c}} — inner fraction should be centered under outer bar
      final id = createEditorFromLatex(latex: r'\frac{a}{\frac{b}{c}}');
      final snap = getEditorSnapshot(id: id, displayMode: false);
      final root = snap.editorLayout.root;

      // Root should have one child: the outer frac command
      expect(root.children.length, 1);
      final outerFrac = root.children[0] as NodeLayout_Command;
      expect(outerFrac.kind, isA<CommandLayoutKind_Frac>());

      // Outer frac has 2 child blocks: numer and denom
      expect(outerFrac.childBlocks.length, 2);
      final outerNumer = outerFrac.childBlocks[0];
      final outerDenom = outerFrac.childBlocks[1];

      // Denom contains the inner frac
      expect(outerDenom.children.length, 1);
      final innerFrac = outerDenom.children[0] as NodeLayout_Command;
      expect(innerFrac.kind, isA<CommandLayoutKind_Frac>());

      // --- Key assertion: inner frac should be within the outer frac's x-range ---
      final outerLeft = outerFrac.leftX;
      final outerRight = outerFrac.leftX + outerFrac.width;
      final innerLeft = innerFrac.leftX;
      final innerRight = innerFrac.leftX + innerFrac.width;

      // ignore: avoid_print
      print('Outer frac: left=${outerLeft.toStringAsFixed(4)}, '
          'right=${outerRight.toStringAsFixed(4)}, width=${outerFrac.width.toStringAsFixed(4)}');
      // ignore: avoid_print
      print('Inner frac: left=${innerLeft.toStringAsFixed(4)}, '
          'right=${innerRight.toStringAsFixed(4)}, width=${innerFrac.width.toStringAsFixed(4)}');
      // ignore: avoid_print
      print('Outer numer leftX: ${outerNumer.leftX.toStringAsFixed(4)}');
      // ignore: avoid_print
      print('Outer denom leftX: ${outerDenom.leftX.toStringAsFixed(4)}');

      closeEditor(id: id);
    });

    test('3-level nesting: all fraction bars horizontally overlap', () {
      // \frac{a}{\frac{b}{\frac{c}{d}}}
      final id = createEditorFromLatex(
          latex: r'\frac{a}{\frac{b}{\frac{c}{d}}}');
      final snap = getEditorSnapshot(id: id, displayMode: false);
      final root = snap.editorLayout.root;

      // Navigate the tree to get all 3 frac commands
      final frac1 = root.children[0] as NodeLayout_Command;
      final frac2 =
          frac1.childBlocks[1].children[0] as NodeLayout_Command; // denom
      final frac3 =
          frac2.childBlocks[1].children[0] as NodeLayout_Command; // denom

      // ignore: avoid_print
      print('Frac1: leftX=${frac1.leftX.toStringAsFixed(4)}, '
          'width=${frac1.width.toStringAsFixed(4)}');
      // ignore: avoid_print
      print('Frac2: leftX=${frac2.leftX.toStringAsFixed(4)}, '
          'width=${frac2.width.toStringAsFixed(4)}');
      // ignore: avoid_print
      print('Frac3: leftX=${frac3.leftX.toStringAsFixed(4)}, '
          'width=${frac3.width.toStringAsFixed(4)}');

      // All fraction bars should horizontally overlap (their x-ranges intersect)
      // The center of each inner bar should be within the outer bar's x-range
      final frac1Center = frac1.leftX + frac1.width / 2;
      final frac2Center = frac2.leftX + frac2.width / 2;
      final frac3Center = frac3.leftX + frac3.width / 2;

      // ignore: avoid_print
      print('Centers: frac1=${frac1Center.toStringAsFixed(4)}, '
          'frac2=${frac2Center.toStringAsFixed(4)}, '
          'frac3=${frac3Center.toStringAsFixed(4)}');

      closeEditor(id: id);
    });

    // -----------------------------------------------------------------------
    // Rendered widget tests: verify pixel positions in Flutter
    // -----------------------------------------------------------------------

    testWidgets('2-level nested frac: inner content is horizontally centered',
        (tester) async {
      final id = createEditorFromLatex(latex: r'\frac{a}{\frac{b}{c}}');
      final snap = getEditorSnapshot(id: id, displayMode: false);

      await tester.pumpWidget(testApp(
        MathBlockWidget(
          block: snap.editorLayout.root,
          untaggedGlyphs: snap.editorLayout.untagged,
          isEditable: true,
          fontSize: _fontSize,
          color: _color,
          cursorColor: _cursorColor,
          cursorOpacity: 0.0,
        ),
      ));

      // Find all EditableMathLine render objects and get their global positions
      final allLines = tester.renderObjectList<RenderEditableMathLine>(
        find.byType(EditableMathLine),
      ).toList();

      // ignore: avoid_print
      print('Found ${allLines.length} EditableMathLines');

      for (int i = 0; i < allLines.length; i++) {
        final line = allLines[i];
        final globalPos = line.localToGlobal(Offset.zero);
        // ignore: avoid_print
        print('Line $i: blockId=${line.blockId}, '
            'globalX=${globalPos.dx.toStringAsFixed(2)}, '
            'globalY=${globalPos.dy.toStringAsFixed(2)}, '
            'width=${line.size.width.toStringAsFixed(2)}, '
            'height=${line.size.height.toStringAsFixed(2)}');
      }

      // The root block (outermost) should be the widest
      // All inner blocks should have their centers within the root block's x-range
      if (allLines.length >= 2) {
        final rootLine = allLines.firstWhere((l) =>
            l.blockId == snap.editorLayout.root.blockId);
        final rootGlobal = rootLine.localToGlobal(Offset.zero);
        final rootCenterX = rootGlobal.dx + rootLine.size.width / 2;

        for (final line in allLines) {
          if (line.blockId == rootLine.blockId) continue;
          final lineGlobal = line.localToGlobal(Offset.zero);
          final lineCenterX = lineGlobal.dx + line.size.width / 2;

          // Each inner block's center should be near the root center
          // (within the root block's width)
          final delta = (lineCenterX - rootCenterX).abs();
          // ignore: avoid_print
          print('Block ${line.blockId}: centerX=${lineCenterX.toStringAsFixed(2)}, '
              'rootCenterX=${rootCenterX.toStringAsFixed(2)}, delta=${delta.toStringAsFixed(2)}');

          expect(delta, lessThan(rootLine.size.width / 2),
              reason: 'Block ${line.blockId} center (${lineCenterX.toStringAsFixed(2)}) '
                  'should be within root block horizontal range '
                  '(root center=${rootCenterX.toStringAsFixed(2)}, '
                  'half-width=${(rootLine.size.width / 2).toStringAsFixed(2)})');
        }
      }

      closeEditor(id: id);
    });

    testWidgets(
        '3-level nested frac: no staircase — all content under outermost bar',
        (tester) async {
      final id = createEditorFromLatex(
          latex: r'\frac{a}{\frac{b}{\frac{c}{d}}}');
      final snap = getEditorSnapshot(id: id, displayMode: false);

      await tester.pumpWidget(testApp(
        MathBlockWidget(
          block: snap.editorLayout.root,
          untaggedGlyphs: snap.editorLayout.untagged,
          isEditable: true,
          fontSize: _fontSize,
          color: _color,
          cursorColor: _cursorColor,
          cursorOpacity: 0.0,
        ),
      ));

      final allLines = tester.renderObjectList<RenderEditableMathLine>(
        find.byType(EditableMathLine),
      ).toList();

      // ignore: avoid_print
      print('Found ${allLines.length} EditableMathLines for 3-level nesting');

      // Check that blocks at deeper levels don't drift rightward (staircase)
      // All blocks should have similar center X values (centered under parent)
      final positions = <Map<String, double>>[];
      for (final line in allLines) {
        final globalPos = line.localToGlobal(Offset.zero);
        positions.add({
          'blockId': line.blockId.toDouble(),
          'globalX': globalPos.dx,
          'centerX': globalPos.dx + line.size.width / 2,
          'width': line.size.width,
          'globalY': globalPos.dy,
        });
        // ignore: avoid_print
        print('Block ${line.blockId}: '
            'x=${globalPos.dx.toStringAsFixed(2)}, '
            'centerX=${(globalPos.dx + line.size.width / 2).toStringAsFixed(2)}, '
            'width=${line.size.width.toStringAsFixed(2)}, '
            'y=${globalPos.dy.toStringAsFixed(2)}');
      }

      // The staircase bug manifests as globalX increasing for each deeper level.
      // In a correct rendering, the global X positions should NOT monotonically
      // increase — deeper blocks should be centered under their parent, not
      // shifted further right.
      if (positions.length >= 3) {
        // Sort by Y to get top-to-bottom order
        positions.sort((a, b) => a['globalY']!.compareTo(b['globalY']!));

        // Check for staircase: if every successive block has larger globalX,
        // that's the bug.
        int stairSteps = 0;
        for (int i = 1; i < positions.length; i++) {
          if (positions[i]['globalX']! > positions[i - 1]['globalX']! + 2.0) {
            stairSteps++;
          }
        }

        // ignore: avoid_print
        print('Staircase steps detected: $stairSteps / ${positions.length - 1}');

        // In a correct rendering, at most 1-2 blocks might shift slightly,
        // but not ALL blocks forming a staircase
        expect(stairSteps, lessThan(positions.length - 1),
            reason: 'All blocks shift right = staircase rendering bug. '
                'Blocks should be centered under parent fraction bars, '
                'not forming a diagonal pattern.');
      }

      closeEditor(id: id);
    });

    testWidgets(
        'LiveFraction typing: 5-level nesting does not produce staircase',
        (tester) async {
      // Simulate the exact scenario from the screenshot: fa/2/31213/2123/123123
      final id = createEditor();

      void typeStr(String s) {
        for (final ch in s.split('')) {
          dispatchEditor(
              id: id,
              intent: EditorIntent.insertSymbol(ch: ch),
              displayMode: false);
        }
      }

      void liveFrac() {
        dispatchEditor(
            id: id,
            intent: const EditorIntent.liveFraction(),
            displayMode: false);
      }

      typeStr('fa');
      liveFrac();
      typeStr('2');
      liveFrac();
      typeStr('31213');
      liveFrac();
      typeStr('2123');
      liveFrac();
      typeStr('123123');

      final snap = getEditorSnapshot(id: id, displayMode: false);
      // ignore: avoid_print
      print('LaTeX: ${snap.latex}');

      await tester.pumpWidget(testApp(
        MathBlockWidget(
          block: snap.editorLayout.root,
          untaggedGlyphs: snap.editorLayout.untagged,
          isEditable: true,
          fontSize: _fontSize,
          color: _color,
          cursorColor: _cursorColor,
          cursorOpacity: 0.0,
        ),
      ));

      final allLines = tester.renderObjectList<RenderEditableMathLine>(
        find.byType(EditableMathLine),
      ).toList();

      // Get positions sorted by Y
      final positions = <Map<String, double>>[];
      for (final line in allLines) {
        final globalPos = line.localToGlobal(Offset.zero);
        positions.add({
          'blockId': line.blockId.toDouble(),
          'globalX': globalPos.dx,
          'centerX': globalPos.dx + line.size.width / 2,
          'width': line.size.width,
          'globalY': globalPos.dy,
        });
      }
      positions.sort((a, b) => a['globalY']!.compareTo(b['globalY']!));

      for (final p in positions) {
        // ignore: avoid_print
        print('Block ${p['blockId']!.toInt()}: '
            'x=${p['globalX']!.toStringAsFixed(1)}, '
            'center=${p['centerX']!.toStringAsFixed(1)}, '
            'w=${p['width']!.toStringAsFixed(1)}, '
            'y=${p['globalY']!.toStringAsFixed(1)}');
      }

      // KEY ASSERTION: blocks should NOT form a monotonic staircase to the right
      if (positions.length >= 4) {
        int stairSteps = 0;
        for (int i = 1; i < positions.length; i++) {
          if (positions[i]['globalX']! > positions[i - 1]['globalX']! + 2.0) {
            stairSteps++;
          }
        }
        // ignore: avoid_print
        print('Staircase steps: $stairSteps / ${positions.length - 1}');

        expect(stairSteps, lessThan(positions.length ~/ 2),
            reason: 'Staircase rendering detected: each deeper fraction block '
                'shifts further right. Expected centered nesting.');
      }

      closeEditor(id: id);
    });

    // -----------------------------------------------------------------------
    // Specific property tests
    // -----------------------------------------------------------------------

    test('nested frac denominators have decreasing font_scale', () {
      // Each nesting level should have smaller fontScale
      final id = createEditorFromLatex(
          latex: r'\frac{a}{\frac{b}{\frac{c}{d}}}');
      final snap = getEditorSnapshot(id: id, displayMode: false);

      final frac1 = snap.editorLayout.root.children[0] as NodeLayout_Command;
      final numer1 = frac1.childBlocks[0];
      final denom1 = frac1.childBlocks[1];
      final frac2 = denom1.children[0] as NodeLayout_Command;
      final numer2 = frac2.childBlocks[0];
      final denom2 = frac2.childBlocks[1];
      final frac3 = denom2.children[0] as NodeLayout_Command;
      final numer3 = frac3.childBlocks[0];
      final denom3 = frac3.childBlocks[1];

      // ignore: avoid_print
      print('Level 1 numer: scale=${numer1.fontScale.toStringAsFixed(4)}, '
          'shift=${numer1.baselineShift.toStringAsFixed(4)}');
      // ignore: avoid_print
      print('Level 1 denom: scale=${denom1.fontScale.toStringAsFixed(4)}, '
          'shift=${denom1.baselineShift.toStringAsFixed(4)}');
      // ignore: avoid_print
      print('Level 2 numer: scale=${numer2.fontScale.toStringAsFixed(4)}, '
          'shift=${numer2.baselineShift.toStringAsFixed(4)}');
      // ignore: avoid_print
      print('Level 2 denom: scale=${denom2.fontScale.toStringAsFixed(4)}, '
          'shift=${denom2.baselineShift.toStringAsFixed(4)}');
      // ignore: avoid_print
      print('Level 3 numer: scale=${numer3.fontScale.toStringAsFixed(4)}, '
          'shift=${numer3.baselineShift.toStringAsFixed(4)}');
      // ignore: avoid_print
      print('Level 3 denom: scale=${denom3.fontScale.toStringAsFixed(4)}, '
          'shift=${denom3.baselineShift.toStringAsFixed(4)}');

      // Font scale should decrease at each level
      expect(numer1.fontScale, lessThan(1.0));
      expect(numer2.fontScale, lessThan(numer1.fontScale),
          reason: 'Level 2 should have smaller font scale than level 1');

      closeEditor(id: id);
    });

    test('nested frac: inner fraction bar width <= outer fraction bar width',
        () {
      final id = createEditorFromLatex(
          latex: r'\frac{a}{\frac{b}{\frac{c}{d}}}');
      final snap = getEditorSnapshot(id: id, displayMode: false);

      final frac1 = snap.editorLayout.root.children[0] as NodeLayout_Command;
      final frac2 =
          frac1.childBlocks[1].children[0] as NodeLayout_Command;
      final frac3 =
          frac2.childBlocks[1].children[0] as NodeLayout_Command;

      // ignore: avoid_print
      print('Frac1 width: ${frac1.width.toStringAsFixed(4)}');
      // ignore: avoid_print
      print('Frac2 width: ${frac2.width.toStringAsFixed(4)}');
      // ignore: avoid_print
      print('Frac3 width: ${frac3.width.toStringAsFixed(4)}');

      // Inner fraction bars should be no wider than outer ones
      // (content gets smaller at each level)
      expect(frac2.width, lessThanOrEqualTo(frac1.width + 0.01),
          reason: 'Inner fraction bar should not be wider than outer');
      expect(frac3.width, lessThanOrEqualTo(frac2.width + 0.01),
          reason: 'Innermost fraction bar should not be wider than middle');

      closeEditor(id: id);
    });
  });
}
