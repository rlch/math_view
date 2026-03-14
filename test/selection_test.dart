import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_view/math_view.dart';

Widget testApp(Widget child) => MaterialApp(home: Scaffold(body: Center(child: child)));

void main() {
  group('Selection rendering', () {
    testWidgets('selection highlight renders between anticursor and cursor', (tester) async {
      final id = createEditorFromLatex(latex: r'abcde');
      dispatchEditor(id: id, intent: const EditorIntent.moveToStart(), displayMode: false);
      dispatchEditor(id: id, intent: const EditorIntent.moveRight(), displayMode: false);
      dispatchEditor(id: id, intent: const EditorIntent.selectRight(), displayMode: false);
      dispatchEditor(id: id, intent: const EditorIntent.selectRight(), displayMode: false);
      final s = getEditorSnapshot(id: id, displayMode: false);

      await tester.pumpWidget(testApp(
        MathBlockWidget(
          block: s.editorLayout.root,
          untaggedGlyphs: s.editorLayout.untagged,
          isEditable: true,
          fontSize: 20,
          color: const Color(0xFF000000),
          cursorColor: const Color(0xFF0066FF),
          cursorOpacity: 1.0,
          selectionColor: const Color(0x4D0066FF),
        ),
      ));

      // Verify render tree exists
      expect(find.byType(MathBlockWidget), findsOneWidget);
      closeEditor(id: id);
    });

    test('selectAll then type replaces all', () {
      final id = createEditorFromLatex(latex: r'hello');
      dispatchEditor(id: id, intent: const EditorIntent.selectAll(), displayMode: false);
      final s = dispatchEditor(id: id, intent: const EditorIntent.insertSymbol(ch: 'x'), displayMode: false);
      expect(s.latex, 'x');
      closeEditor(id: id);
    });

    test('selectLeft then delete removes selected', () {
      final id = createEditorFromLatex(latex: r'abc');
      dispatchEditor(id: id, intent: const EditorIntent.moveToEnd(), displayMode: false);
      dispatchEditor(id: id, intent: const EditorIntent.selectLeft(), displayMode: false);
      final s = dispatchEditor(id: id, intent: const EditorIntent.deleteBackward(), displayMode: false);
      expect(s.latex, 'ab');
      closeEditor(id: id);
    });
  });
}
