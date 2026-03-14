import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_view/math_view.dart';
import 'package:math_view/src/render/editable_math_line.dart';
import 'package:math_view/src/render/math_block_widget.dart';
import 'package:math_view/src/rust/api/editor_layout.dart';
import 'package:math_view/src/rust/api/math_api.dart';

Widget testApp(Widget child) =>
    MaterialApp(home: Scaffold(body: Center(child: child)));

const _fontSize = 20.0;
const _color = Color(0xFF000000);
const _cursorColor = Color(0xFF0066FF);

/// Info about a rendered block with cursor.
class CursorInfo {
  final int blockId;
  final Rect cursorRect;
  final Offset globalPos;
  final double globalCursorX;
  final double globalCursorY;
  final double cursorHeight;

  CursorInfo({
    required this.blockId,
    required this.cursorRect,
    required this.globalPos,
  })  : globalCursorX = globalPos.dx + cursorRect.left,
        globalCursorY = globalPos.dy + cursorRect.center.dy,
        cursorHeight = cursorRect.height;
}

/// Info about all rendered EditableMathLine blocks.
class BlockInfo {
  final int blockId;
  final Offset globalPos;
  final Size size;
  final bool isEmpty;

  BlockInfo({
    required this.blockId,
    required this.globalPos,
    required this.size,
    required this.isEmpty,
  });
}

void main() {
  group('Fraction fill states — cursor + box positioning', () {
    /// Build widget from snapshot, pump, return all block infos and cursor info.
    Future<({CursorInfo? cursor, List<BlockInfo> blocks, EditorSnapshot snap})>
        pumpFrac(WidgetTester tester, String editorId) async {
      final s = getEditorSnapshot(id: editorId, displayMode: false);
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

      // Find all EditableMathLine render objects
      final allLines = tester.renderObjectList<RenderEditableMathLine>(
        find.byType(EditableMathLine),
      );

      CursorInfo? cursorInfo;
      final blockInfos = <BlockInfo>[];

      for (final r in allLines) {
        final gpos = r.localToGlobal(Offset.zero);
        blockInfos.add(BlockInfo(
          blockId: r.blockId,
          globalPos: gpos,
          size: r.size,
          isEmpty: r.cursorRect == null && r.size.width < _fontSize * 0.5,
        ));

        if (r.cursorRect != null) {
          cursorInfo = CursorInfo(
            blockId: r.blockId,
            cursorRect: r.cursorRect!,
            globalPos: gpos,
          );
        }
      }

      return (cursor: cursorInfo, blocks: blockInfos, snap: s);
    }

    /// Find the BlockLayout for a given block index within the frac command.
    BlockLayout fracBlock(EditorSnapshot s, int index) {
      final cmd = s.editorLayout.root.children[0] as NodeLayout_Command;
      return cmd.childBlocks[index];
    }

    // -------------------------------------------------------------------
    // Case 1: \frac{}{} — both empty
    // -------------------------------------------------------------------
    testWidgets('both empty: cursor in numer, boxes positioned correctly',
        (tester) async {
      final id = createEditor();
      dispatchEditor(
          id: id,
          intent: const EditorIntent.insertFrac(),
          displayMode: false);
      // Cursor should be in numerator (first empty block)

      final r = await pumpFrac(tester, id);
      final snap = r.snap;

      // Layout assertions
      final numer = fracBlock(snap, 0);
      final denom = fracBlock(snap, 1);

      expect(numer.isEmpty, isTrue);
      expect(denom.isEmpty, isTrue);
      expect(numer.baselineShift, greaterThan(0),
          reason: 'empty numer should have positive shift');
      expect(denom.baselineShift, lessThan(0),
          reason: 'empty denom should have negative shift');
      expect(numer.fontScale, closeTo(0.7, 0.05),
          reason: 'empty numer should have fraction font scale');
      expect(denom.fontScale, closeTo(0.7, 0.05),
          reason: 'empty denom should have fraction font scale');

      // Cursor should exist
      expect(r.cursor, isNotNull, reason: 'should have active cursor');

      // Rendered blocks: find numer and denom
      // The root block + 2 child blocks = at least 3 EditableMathLines
      expect(r.blocks.length, greaterThanOrEqualTo(3));

      // Find the two fraction child blocks by their blockIds
      final numerBlock =
          r.blocks.where((b) => b.blockId == numer.blockId).firstOrNull;
      final denomBlock =
          r.blocks.where((b) => b.blockId == denom.blockId).firstOrNull;
      expect(numerBlock, isNotNull, reason: 'numer block should be rendered');
      expect(denomBlock, isNotNull, reason: 'denom block should be rendered');

      // Numer should be above denom (smaller globalY)
      expect(numerBlock!.globalPos.dy, lessThan(denomBlock!.globalPos.dy),
          reason: 'numerator should be above denominator');

      // Both should have non-zero size (placeholder)
      expect(numerBlock.size.height, greaterThan(0),
          reason: 'empty numer should have placeholder height');
      expect(denomBlock.size.height, greaterThan(0),
          reason: 'empty denom should have placeholder height');

      closeEditor(id: id);
    });

    // -------------------------------------------------------------------
    // Case 2: \frac{x}{} — numerator filled, denominator empty
    // -------------------------------------------------------------------
    testWidgets('numer filled, denom empty: empty box below with correct shift',
        (tester) async {
      final id = createEditorFromLatex(latex: r'\frac{x}{}');
      // Move cursor into the empty denominator
      dispatchEditor(
          id: id,
          intent: const EditorIntent.moveToStart(),
          displayMode: false);
      dispatchEditor(
          id: id,
          intent: const EditorIntent.moveRight(),
          displayMode: false); // into numer
      dispatchEditor(
          id: id,
          intent: const EditorIntent.moveRight(),
          displayMode: false); // past x
      dispatchEditor(
          id: id,
          intent: const EditorIntent.moveRight(),
          displayMode: false); // into denom

      final r = await pumpFrac(tester, id);
      final snap = r.snap;
      final numer = fracBlock(snap, 0);
      final denom = fracBlock(snap, 1);

      // Layout
      expect(numer.isEmpty, isFalse);
      expect(denom.isEmpty, isTrue);
      expect(numer.baselineShift, greaterThan(0));
      expect(denom.baselineShift, lessThan(0),
          reason:
              'empty denom shift=${denom.baselineShift} should be < 0');
      expect(denom.fontScale, closeTo(0.7, 0.05),
          reason:
              'empty denom scale=${denom.fontScale} should be ~0.7');

      // Cursor should be in denom
      expect(r.cursor, isNotNull);
      expect(r.cursor!.blockId, denom.blockId,
          reason: 'cursor should be in denominator');

      // Rendered positioning
      final numerBlock =
          r.blocks.where((b) => b.blockId == numer.blockId).firstOrNull;
      final denomBlock =
          r.blocks.where((b) => b.blockId == denom.blockId).firstOrNull;
      expect(numerBlock, isNotNull);
      expect(denomBlock, isNotNull);

      // Numer above denom
      expect(numerBlock!.globalPos.dy, lessThan(denomBlock!.globalPos.dy),
          reason: 'numer should be above denom');

      // Cursor height should be fraction-sized (scale ~0.7), not full-size
      expect(r.cursor!.cursorHeight, lessThan(_fontSize),
          reason:
              'cursor in empty denom should be fraction-sized, not full-sized. '
              'Got ${r.cursor!.cursorHeight}');

      // Cursor Y should be in the denominator area (below numer)
      expect(r.cursor!.globalCursorY, greaterThan(numerBlock.globalPos.dy),
          reason: 'cursor should be below numerator');

      // Print for manual inspection
      // ignore: avoid_print
      print('NUM_FILLED: cursor blockId=${r.cursor!.blockId} '
          'globalX=${r.cursor!.globalCursorX.toStringAsFixed(2)} '
          'globalY=${r.cursor!.globalCursorY.toStringAsFixed(2)} '
          'height=${r.cursor!.cursorHeight.toStringAsFixed(2)}');
      // ignore: avoid_print
      print('  numer: y=${numerBlock.globalPos.dy.toStringAsFixed(2)} '
          'h=${numerBlock.size.height.toStringAsFixed(2)}');
      // ignore: avoid_print
      print('  denom: y=${denomBlock.globalPos.dy.toStringAsFixed(2)} '
          'h=${denomBlock.size.height.toStringAsFixed(2)}');

      closeEditor(id: id);
    });

    // -------------------------------------------------------------------
    // Case 3: \frac{}{x} — numerator empty, denominator filled
    // -------------------------------------------------------------------
    testWidgets('numer empty, denom filled: empty box above with correct shift',
        (tester) async {
      final id = createEditorFromLatex(latex: r'\frac{}{x}');
      // Move cursor into the empty numerator
      dispatchEditor(
          id: id,
          intent: const EditorIntent.moveToStart(),
          displayMode: false);
      dispatchEditor(
          id: id,
          intent: const EditorIntent.moveRight(),
          displayMode: false); // into numer (empty)

      final r = await pumpFrac(tester, id);
      final snap = r.snap;
      final numer = fracBlock(snap, 0);
      final denom = fracBlock(snap, 1);

      // Layout
      expect(numer.isEmpty, isTrue);
      expect(denom.isEmpty, isFalse);
      expect(numer.baselineShift, greaterThan(0),
          reason:
              'empty numer shift=${numer.baselineShift} should be > 0');
      expect(numer.fontScale, closeTo(0.7, 0.05),
          reason:
              'empty numer scale=${numer.fontScale} should be ~0.7');
      expect(denom.baselineShift, lessThan(0));

      // Cursor should be in numer
      expect(r.cursor, isNotNull);
      expect(r.cursor!.blockId, numer.blockId,
          reason: 'cursor should be in numerator');

      // Cursor height should be fraction-sized
      expect(r.cursor!.cursorHeight, lessThan(_fontSize),
          reason:
              'cursor in empty numer should be fraction-sized. '
              'Got ${r.cursor!.cursorHeight}');

      // Rendered positioning
      final numerBlock =
          r.blocks.where((b) => b.blockId == numer.blockId).firstOrNull;
      final denomBlock =
          r.blocks.where((b) => b.blockId == denom.blockId).firstOrNull;
      expect(numerBlock, isNotNull);
      expect(denomBlock, isNotNull);

      // Numer above denom
      expect(numerBlock!.globalPos.dy, lessThan(denomBlock!.globalPos.dy),
          reason: 'numer should be above denom');

      // Cursor Y should be in the numerator area (above denom)
      expect(r.cursor!.globalCursorY, lessThan(denomBlock.globalPos.dy),
          reason: 'cursor should be above denominator');

      // Print for manual inspection
      // ignore: avoid_print
      print('DENOM_FILLED: cursor blockId=${r.cursor!.blockId} '
          'globalX=${r.cursor!.globalCursorX.toStringAsFixed(2)} '
          'globalY=${r.cursor!.globalCursorY.toStringAsFixed(2)} '
          'height=${r.cursor!.cursorHeight.toStringAsFixed(2)}');

      closeEditor(id: id);
    });

    // -------------------------------------------------------------------
    // Case 4: \frac{x}{y} — both filled (baseline, should work)
    // -------------------------------------------------------------------
    testWidgets('both filled: cursor in numer, correct positioning',
        (tester) async {
      final id = createEditorFromLatex(latex: r'\frac{x}{y}');
      // Move cursor into numerator
      dispatchEditor(
          id: id,
          intent: const EditorIntent.moveToStart(),
          displayMode: false);
      dispatchEditor(
          id: id,
          intent: const EditorIntent.moveRight(),
          displayMode: false); // into numer

      final r = await pumpFrac(tester, id);
      final snap = r.snap;
      final numer = fracBlock(snap, 0);
      final denom = fracBlock(snap, 1);

      // Layout
      expect(numer.isEmpty, isFalse);
      expect(denom.isEmpty, isFalse);
      expect(numer.baselineShift, greaterThan(0));
      expect(denom.baselineShift, lessThan(0));
      expect(numer.fontScale, closeTo(0.7, 0.05));
      expect(denom.fontScale, closeTo(0.7, 0.05));

      // Cursor in numer
      expect(r.cursor, isNotNull);
      expect(r.cursor!.blockId, numer.blockId);

      // Cursor height should be fraction-sized
      expect(r.cursor!.cursorHeight, lessThan(_fontSize));

      // Rendered positioning
      final numerBlock =
          r.blocks.where((b) => b.blockId == numer.blockId).firstOrNull;
      final denomBlock =
          r.blocks.where((b) => b.blockId == denom.blockId).firstOrNull;
      expect(numerBlock, isNotNull);
      expect(denomBlock, isNotNull);
      expect(numerBlock!.globalPos.dy, lessThan(denomBlock!.globalPos.dy));

      // Print for manual inspection
      // ignore: avoid_print
      print('BOTH_FILLED: cursor blockId=${r.cursor!.blockId} '
          'globalX=${r.cursor!.globalCursorX.toStringAsFixed(2)} '
          'globalY=${r.cursor!.globalCursorY.toStringAsFixed(2)} '
          'height=${r.cursor!.cursorHeight.toStringAsFixed(2)}');

      closeEditor(id: id);
    });

    // -------------------------------------------------------------------
    // Cross-case: cursor height consistency
    // -------------------------------------------------------------------
    testWidgets('cursor height is consistent across all fill states',
        (tester) async {
      final heights = <String, double>{};

      // Both filled — cursor in numer
      var id = createEditorFromLatex(latex: r'\frac{x}{y}');
      dispatchEditor(
          id: id,
          intent: const EditorIntent.moveToStart(),
          displayMode: false);
      dispatchEditor(
          id: id,
          intent: const EditorIntent.moveRight(),
          displayMode: false);
      var r = await pumpFrac(tester, id);
      heights['both_filled_numer'] = r.cursor!.cursorHeight;
      closeEditor(id: id);

      // Num only — cursor in empty denom
      id = createEditorFromLatex(latex: r'\frac{x}{}');
      dispatchEditor(
          id: id,
          intent: const EditorIntent.moveToStart(),
          displayMode: false);
      dispatchEditor(
          id: id,
          intent: const EditorIntent.moveRight(),
          displayMode: false);
      dispatchEditor(
          id: id,
          intent: const EditorIntent.moveRight(),
          displayMode: false);
      dispatchEditor(
          id: id,
          intent: const EditorIntent.moveRight(),
          displayMode: false);
      r = await pumpFrac(tester, id);
      heights['num_only_denom'] = r.cursor!.cursorHeight;
      closeEditor(id: id);

      // Denom only — cursor in empty numer
      id = createEditorFromLatex(latex: r'\frac{}{x}');
      dispatchEditor(
          id: id,
          intent: const EditorIntent.moveToStart(),
          displayMode: false);
      dispatchEditor(
          id: id,
          intent: const EditorIntent.moveRight(),
          displayMode: false);
      r = await pumpFrac(tester, id);
      heights['denom_only_numer'] = r.cursor!.cursorHeight;
      closeEditor(id: id);

      // Both empty — cursor in numer
      id = createEditor();
      dispatchEditor(
          id: id,
          intent: const EditorIntent.insertFrac(),
          displayMode: false);
      r = await pumpFrac(tester, id);
      heights['both_empty_numer'] = r.cursor!.cursorHeight;
      closeEditor(id: id);

      // Print all heights
      for (final e in heights.entries) {
        // ignore: avoid_print
        print('Cursor height [${e.key}]: ${e.value.toStringAsFixed(2)}');
      }

      // All fraction cursor heights should be similar (~0.7x of full size)
      final reference = heights['both_filled_numer']!;
      for (final e in heights.entries) {
        expect(e.value, closeTo(reference, 2.0),
            reason: '${e.key} cursor height ${e.value} should be close to '
                'reference $reference (both_filled_numer)');
      }
    });

    // -------------------------------------------------------------------
    // Empty blocks must be centered relative to the fraction BAR
    // (the untagged Rule glyph).
    // -------------------------------------------------------------------
    testWidgets(
        'empty blocks are centered relative to fraction bar',
        (tester) async {
      for (final setup in [
        (label: 'both_empty', latex: r'\frac{}{}'),
        (label: 'with_content', latex: r'a+\frac{}{x}'),
        (label: 'after_frac', latex: r'\frac{}{21231233}+\frac{}{}'),
      ]) {
        final id = createEditorFromLatex(latex: setup.latex);
        final s = getEditorSnapshot(id: id, displayMode: false);

        // Find the untagged fraction bar(s) — Rule glyphs with no nodeId
        final fracBars = <MathNode_Rule>[];
        for (final g in s.editorLayout.untagged) {
          if (g is MathNode_Rule) {
            fracBars.add(g);
          }
        }

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

        // Get root block's origin for converting em → global px
        final rootRender = tester
            .renderObjectList<RenderEditableMathLine>(
                find.byType(EditableMathLine))
            .first;
        final rootGlobal = rootRender.localToGlobal(Offset.zero);
        final rootOriginXEm = s.editorLayout.root.leftX;

        // For each fraction command with empty blocks, check alignment
        final cmdLayouts = s.editorLayout.root.children
            .whereType<NodeLayout_Command>()
            .toList();
        final cmdRenders = tester
            .renderObjectList<RenderBox>(find.byType(CommandWidget))
            .toList();

        for (int ci = 0; ci < cmdLayouts.length; ci++) {
          final cmd = cmdLayouts[ci];
          final hasEmpty = cmd.childBlocks.any((b) => b.isEmpty);
          if (!hasEmpty) continue;

          // Find the fraction bar for this command.
          // Match bar whose center falls within the command's x range.
          final cmdLeftPx = (cmd.leftX - rootOriginXEm) * _fontSize;
          final cmdRightPx = cmdLeftPx + cmd.width * _fontSize;
          // ignore: avoid_print
          print('${setup.label} cmd[$ci]: cmdLeftPx=${cmdLeftPx.toStringAsFixed(2)} '
              'cmdRightPx=${cmdRightPx.toStringAsFixed(2)} '
              'bars=${fracBars.length}');
          MathNode_Rule? bar;
          for (final fb in fracBars) {
            final barLeftPx = (fb.x - rootOriginXEm) * _fontSize;
            final barCenterPx = barLeftPx + fb.width * _fontSize / 2;
            // Bar center must be within command range
            if (barCenterPx >= cmdLeftPx && barCenterPx <= cmdRightPx) {
              bar = fb;
              break;
            }
          }

          if (bar == null) {
            // No KaTeX fraction bar (all-empty frac uses synthetic dimensions).
            // In this case, skip bar comparison — the CommandWidget centering
            // test already covers this.
            // ignore: avoid_print
            print('${setup.label} cmd[$ci]: no fraction bar found '
                '(synthetic frac, no KaTeX glyphs) — skipping');
            continue;
          }

          // Fraction bar center in global pixels
          final barCenterPx = rootGlobal.dx +
              (bar.x - rootOriginXEm) * _fontSize +
              bar.width * _fontSize / 2;

          for (int i = 0; i < cmd.childBlocks.length; i++) {
            final bl = cmd.childBlocks[i];
            if (!bl.isEmpty) continue;

            final rendered = tester
                .renderObjectList<RenderEditableMathLine>(
                    find.byType(EditableMathLine))
                .where((r) => r.blockId == bl.blockId)
                .first;
            final blockGlobal = rendered.localToGlobal(Offset.zero);
            final blockCenterX =
                blockGlobal.dx + rendered.size.width / 2;

            final delta = (blockCenterX - barCenterPx).abs();
            // ignore: avoid_print
            print('${setup.label} cmd[$ci].block[$i]: '
                'barCenter=${barCenterPx.toStringAsFixed(2)} '
                'blockCenter=${blockCenterX.toStringAsFixed(2)} '
                'delta=${delta.toStringAsFixed(2)}');

            expect(
              blockCenterX,
              closeTo(barCenterPx, 1.0),
              reason: '${setup.label}: empty cmd[$ci].block[$i] '
                  'centerX=${blockCenterX.toStringAsFixed(2)} should be '
                  'centered over fraction bar '
                  '(barCenter=${barCenterPx.toStringAsFixed(2)}, '
                  'delta=${delta.toStringAsFixed(2)})',
            );
          }
        }

        closeEditor(id: id);
      }
    });
  });
}
