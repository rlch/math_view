import 'package:flutter_test/flutter_test.dart';
import 'package:math_view/src/rust/api/editor_api.dart';
import 'package:math_view/src/rust/api/editor_layout.dart';

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

void main() {
  group('Rapid typing stress test', () {
    late String editorId;

    setUp(() {
      // Start with the quadratic formula
      editorId = createEditorFromLatex(
          latex: r'x=\frac{-b\pm\sqrt{b^{2}-4ac}}{2a}');
    });

    tearDown(() => closeEditor(id: editorId));

    EditorSnapshot dispatch(EditorIntent intent) =>
        dispatchEditor(id: editorId, intent: intent, displayMode: false);

    EditorSnapshot type_(String ch) =>
        dispatch(EditorIntent.insertSymbol(ch: ch));

    test('type 50 characters in denominator — cursor never resets to 0', () {
      // Navigate to end of denominator
      dispatch(const EditorIntent.moveToEnd());
      dispatch(const EditorIntent.moveLeft()); // enter denominator from right

      final chars = 'abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwx';

      for (int i = 0; i < chars.length; i++) {
        final ch = chars[i];
        final s = type_(ch);
        final cb = findCursorBlock(s.editorLayout.root);

        expect(cb, isNotNull,
            reason: 'After typing "$ch" (char $i): cursor block should exist');

        final carets = cb!.caretPositions.toList();
        final idx = cb.cursorIndex!;

        // Cursor position should never be 0 after the first few chars
        if (i > 0) {
          expect(carets[idx], greaterThan(0),
              reason:
                  'After typing "$ch" (char $i): cursor caret=${carets[idx]} should be > 0. '
                  'carets=$carets latex=${s.latex}');
        }

        // Caret positions should be monotonic
        for (int j = 1; j < carets.length; j++) {
          expect(carets[j], greaterThan(carets[j - 1]),
              reason:
                  'After char $i "$ch": carets[$j]=${carets[j]} <= carets[${j - 1}]=${carets[j - 1]}');
        }

        // Print every 10th step
        if (i % 10 == 0 || i == chars.length - 1) {
          // ignore: avoid_print
          print(
              'Char $i "$ch": block=${cb.blockId} cursor=$idx carets_len=${carets.length} '
              'cursor_pos=${carets[idx].toStringAsFixed(2)} latex_len=${s.latex.length}');
        }
      }
    });

    test('type 50 characters in root block after frac — cursor never resets',
        () {
      // Navigate to end of root (after the frac)
      dispatch(const EditorIntent.moveToEnd());

      final chars = 'fhiwefuhweifafweafawefoweafweafweafweafweafweafweaf'
          'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn';

      for (int i = 0; i < chars.length; i++) {
        final ch = chars[i];
        final s = type_(ch);
        final cb = findCursorBlock(s.editorLayout.root);

        expect(cb, isNotNull,
            reason: 'After typing "$ch" (char $i): cursor block should exist');

        final carets = cb!.caretPositions.toList();
        final idx = cb.cursorIndex!;

        // Cursor index should increase with each typed character
        expect(idx, greaterThan(0),
            reason: 'After char $i: cursor index should be > 0, got $idx');

        // Print every 10th step
        if (i % 10 == 0 || i == chars.length - 1) {
          // ignore: avoid_print
          print(
              'Root char $i "$ch": block=${cb.blockId} cursor=$idx '
              'carets_len=${carets.length} cursor_pos=${carets[idx].toStringAsFixed(2)} '
              'latex_len=${s.latex.length}');
        }

        // Caret positions should be monotonic
        for (int j = 1; j < carets.length; j++) {
          expect(carets[j], greaterThan(carets[j - 1]),
              reason:
                  'After char $i: carets[$j]=${carets[j]} <= carets[${j - 1}]=${carets[j - 1]}');
        }
      }
    });

    test('type 50 characters inside sqrt body — cursor never resets', () {
      // Navigate to end, then into sqrt body
      dispatch(const EditorIntent.moveToEnd());
      dispatch(const EditorIntent.moveLeft()); // into denom
      dispatch(const EditorIntent.moveLeft()); // before a
      dispatch(const EditorIntent.moveLeft()); // before 2
      dispatch(const EditorIntent.moveUp()); // into numerator
      // Now at end of numerator, move left past -4ac into sqrt
      dispatch(const EditorIntent.moveLeft()); // before c
      dispatch(const EditorIntent.moveLeft()); // before a
      dispatch(const EditorIntent.moveLeft()); // before 4
      dispatch(const EditorIntent.moveLeft()); // before -
      dispatch(const EditorIntent.moveLeft()); // into sqrt body end

      final chars = 'duhwuhdwdwfuhweifuhwefiweuhfiweuhfoweauhfoweathfuweai';

      for (int i = 0; i < chars.length; i++) {
        final ch = chars[i];
        final s = type_(ch);
        final cb = findCursorBlock(s.editorLayout.root);

        expect(cb, isNotNull,
            reason: 'After typing "$ch" (char $i): cursor block should exist');

        final carets = cb!.caretPositions.toList();
        final idx = cb.cursorIndex!;

        if (i > 0) {
          expect(carets[idx], greaterThan(0),
              reason:
                  'After char $i "$ch": cursor caret=${carets[idx]} should be > 0');
        }

        if (i % 10 == 0 || i == chars.length - 1) {
          // ignore: avoid_print
          print(
              'Sqrt char $i "$ch": block=${cb.blockId} cursor=$idx '
              'carets_len=${carets.length} cursor_pos=${carets[idx].toStringAsFixed(2)} '
              'latex_len=${s.latex.length}');
        }

        for (int j = 1; j < carets.length; j++) {
          expect(carets[j], greaterThan(carets[j - 1]),
              reason:
                  'After char $i: carets[$j]=${carets[j]} <= carets[${j - 1}]=${carets[j - 1]}');
        }
      }
    });
  });
}
