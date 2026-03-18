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

void main() {
  late String editorId;

  setUp(() {
    editorId = createEditor();
    // Insert \sqrt{} — cursor lands inside the empty radicand block
    dispatchEditor(
      id: editorId,
      intent: const EditorIntent.insertSqrt(),
      displayMode: false,
    );
  });

  tearDown(() => closeEditor(id: editorId));

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

  /// Find the sqrt command node in the layout tree.
  NodeLayout_Command? findSqrtCommand(BlockLayout block) {
    for (final child in block.children) {
      if (child is NodeLayout_Command &&
          child.kind is CommandLayoutKind_Sqrt) {
        return child;
      }
    }
    return null;
  }

  String describeCursor(BlockLayout block, {int indent = 0}) {
    final pad = '  ' * indent;
    final buf = StringBuffer();
    buf.writeln('${pad}Block(id=${block.blockId}, cursor=${block.cursorIndex}, '
        'caretPositions=${block.caretPositions}, '
        'baselineShift=${block.baselineShift.toStringAsFixed(4)}, '
        'fontScale=${block.fontScale.toStringAsFixed(4)}, '
        'leftX=${block.leftX.toStringAsFixed(4)}, '
        'isEmpty=${block.isEmpty})');
    for (final child in block.children) {
      switch (child) {
        case NodeLayout_Leaf():
          buf.writeln(
              '$pad  Leaf(id=${child.nodeId}, leftX=${child.leftX.toStringAsFixed(4)})');
        case NodeLayout_Command():
          buf.writeln(
              '$pad  Command(id=${child.nodeId}, kind=${child.kind}, leftX=${child.leftX.toStringAsFixed(4)}, width=${child.width.toStringAsFixed(4)})');
          for (final cb in child.childBlocks) {
            buf.write(describeCursor(cb, indent: indent + 2));
          }
      }
    }
    return buf.toString();
  }

  group(r'\sqrt{} caret positioning', () {
    test('cursor inside empty sqrt is in the radicand block', () {
      final s = snap(editorId);
      final layout = s.editorLayout;

      // ignore: avoid_print
      print(describeCursor(layout.root));

      // Cursor should be inside the sqrt's child block, not the root
      final cursorBlock = findCursorBlock(layout.root)!;
      expect(cursorBlock.blockId, isNot(layout.root.blockId),
          reason: 'Cursor should be inside the sqrt radicand, not in root');
      expect(cursorBlock.isEmpty, isTrue,
          reason: 'The sqrt radicand block should be empty');
      expect(cursorBlock.cursorIndex, 0,
          reason: 'Cursor should be at gap 0 in empty block');
    });

    test('empty radicand caret X is to the right of the radical sign', () {
      final s = snap(editorId);
      final layout = s.editorLayout;

      // ignore: avoid_print
      print(describeCursor(layout.root));

      final sqrtCmd = findSqrtCommand(layout.root)!;
      final radicandBlock = sqrtCmd.childBlocks.first;

      // The radical sign glyph takes up roughly 0.8–1.0em of space on the
      // left side of the sqrt command. The radicand area (where the cursor
      // should be) starts AFTER the radical sign.
      //
      // In MathQuill, .mq-sqrt-stem has margin-left: 0.9em, meaning the
      // body content starts 0.9em from the sqrt's left edge.
      //
      // The caret position (in em, absolute) should be greater than the
      // sqrt command's left_x by at least the width of the radical sign
      // prefix (~0.5em minimum, typically ~0.9em).
      final caretEmAbsolute = radicandBlock.caretPositions.first;
      final sqrtLeftX = sqrtCmd.leftX;
      final caretOffsetFromSqrtLeft = caretEmAbsolute - sqrtLeftX;

      // ignore: avoid_print
      print('sqrtCmd leftX=$sqrtLeftX, width=${sqrtCmd.width}');
      // ignore: avoid_print
      print('radicand block leftX=${radicandBlock.leftX}');
      // ignore: avoid_print
      print('radicand caret[0]=$caretEmAbsolute');
      // ignore: avoid_print
      print('caret offset from sqrt left=$caretOffsetFromSqrtLeft');

      // The caret must be at least 0.5em to the right of the sqrt's left
      // edge (past the radical sign), not at cmd_width/2 which overlaps
      // the radical sign glyph.
      expect(caretOffsetFromSqrtLeft, greaterThanOrEqualTo(0.5),
          reason: 'Caret inside \\sqrt{} must be to the right of the '
              'radical sign (~0.5em from sqrt left), not overlapping it. '
              'Got offset $caretOffsetFromSqrtLeft em from sqrt left edge.');
    });

    testWidgets('rendered cursor is under the vinculum, not on the radical sign',
        (tester) async {
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

      // Find the RenderEditableMathLine with the cursor
      final allLines = tester.renderObjectList<RenderEditableMathLine>(
        find.byType(EditableMathLine),
      );

      RenderEditableMathLine? cursorRender;
      for (final r in allLines) {
        if (r.cursorRect != null) {
          cursorRender = r;
          break;
        }
      }

      expect(cursorRender, isNotNull,
          reason: 'Should find an EditableMathLine with active cursor');

      final cursorRect = cursorRender!.cursorRect!;
      final cursorGlobalX =
          cursorRender.localToGlobal(Offset.zero).dx + cursorRect.left;

      // Also find the root EditableMathLine (the top-level expression line)
      // to get the expression's global position
      final rootRender = allLines.first;
      final exprGlobalX = rootRender.localToGlobal(Offset.zero).dx;

      // ignore: avoid_print
      print('Cursor global X: $cursorGlobalX');
      // ignore: avoid_print
      print('Expression global X: $exprGlobalX');
      // ignore: avoid_print
      print('Cursor rect: $cursorRect');

      // The radical sign is approximately 0.9em * fontSize = 18px wide.
      // The cursor should be at least 10px (0.5em) to the right of the
      // expression start, not overlapping the radical sign glyph.
      final cursorOffsetFromExprStart = cursorGlobalX - exprGlobalX;
      // ignore: avoid_print
      print('Cursor offset from expr start: $cursorOffsetFromExprStart px');

      expect(cursorOffsetFromExprStart, greaterThan(0.5 * _fontSize),
          reason:
              'Cursor in \\sqrt{} should be under the vinculum (>0.5em from '
              'expression start), not overlapping the radical sign. '
              'Got offset $cursorOffsetFromExprStart px');
    });

    testWidgets('cursor walk: before sqrt → inside → after sqrt',
        (tester) async {
      // Start fresh: create editor, insert sqrt, then move to start
      final id = createEditorFromLatex(latex: r'\sqrt{}');
      dispatchEditor(
        id: id,
        intent: const EditorIntent.moveToStart(),
        displayMode: false,
      );

      final globalXPositions = <double>[];

      // Walk through 3 positions: before sqrt, inside sqrt, after sqrt
      for (int step = 0; step < 3; step++) {
        if (step > 0) {
          dispatchEditor(
            id: id,
            intent: const EditorIntent.moveRight(),
            displayMode: false,
          );
        }

        final s = getEditorSnapshot(id: id, displayMode: false);
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

        final allLines = tester.renderObjectList<RenderEditableMathLine>(
          find.byType(EditableMathLine),
        );

        RenderEditableMathLine? cursorRender;
        for (final r in allLines) {
          if (r.cursorRect != null) {
            cursorRender = r;
            break;
          }
        }

        expect(cursorRender, isNotNull, reason: 'Step $step: cursor expected');

        final rect = cursorRender!.cursorRect!;
        final globalX =
            cursorRender.localToGlobal(Offset.zero).dx + rect.left;
        globalXPositions.add(globalX);

        // ignore: avoid_print
        print('Step $step: globalX=$globalX, rect=$rect');
      }

      // Step 0 (before sqrt) must be to the LEFT of step 1 (inside sqrt)
      expect(globalXPositions[1], greaterThan(globalXPositions[0]),
          reason: 'Cursor inside sqrt (step 1) must be to the right of '
              'cursor before sqrt (step 0). '
              'Before=${globalXPositions[0]}, Inside=${globalXPositions[1]}');

      // Step 2 (after sqrt) must be to the RIGHT of step 0 (before sqrt)
      expect(globalXPositions[2], greaterThan(globalXPositions[0]),
          reason: 'Cursor after sqrt (step 2) must be to the right of '
              'cursor before sqrt (step 0). '
              'Before=${globalXPositions[0]}, After=${globalXPositions[2]}');

      closeEditor(id: id);
    });
  });
}
