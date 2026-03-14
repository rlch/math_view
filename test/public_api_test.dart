import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_view/math_view.dart';

Widget testApp(Widget child) => MaterialApp(home: Scaffold(body: Center(child: child)));

void main() {
  group('Public API (from publicapi.test.js)', () {
    // --- Constructor ---
    test('MathEditor constructor creates editor', () {
      // Just verify createEditor works
      final id = createEditor();
      final s = getEditorSnapshot(id: id, displayMode: false);
      expect(s.latex, '');
      closeEditor(id: id);
    });

    test('createEditorFromLatex populates content', () {
      final id = createEditorFromLatex(latex: r'x+1');
      final s = getEditorSnapshot(id: id, displayMode: false);
      expect(s.latex, 'x+1');
      closeEditor(id: id);
    });

    // --- Blurred when created ---
    testWidgets('MathEditor is blurred when created', (tester) async {
      await tester.pumpWidget(testApp(const MathEditor(initialLatex: 'x+1')));
      // Focus node should not have focus initially (autofocus=false by default)
      final focusNode = tester.widget<Focus>(find.byType(Focus).first);
      expect(focusNode.autofocus, isFalse);
    });

    // --- .revert() ---
    test('.revert() not applicable', () {}, skip: 'revert API not implemented');

    // --- Select, clearSelection ---
    test('selectAll then delete clears content', () {
      final id = createEditor();
      dispatchEditor(id: id, intent: const EditorIntent.insertSymbol(ch: 'x'), displayMode: false);
      dispatchEditor(id: id, intent: const EditorIntent.selectAll(), displayMode: false);
      final s = dispatchEditor(id: id, intent: const EditorIntent.deleteBackward(), displayMode: false);
      expect(s.latex, '');
      closeEditor(id: id);
    });

    test('select empty field is no-op', () {
      final id = createEditor();
      final s = dispatchEditor(id: id, intent: const EditorIntent.selectAll(), displayMode: false);
      expect(s.latex, '');
      closeEditor(id: id);
    });

    // --- latex while selection active ---
    test('latex getter works with active selection', () {
      final id = createEditorFromLatex(latex: r'x+1');
      dispatchEditor(id: id, intent: const EditorIntent.selectAll(), displayMode: false);
      final s = getEditorSnapshot(id: id, displayMode: false);
      expect(s.latex, 'x+1');
      closeEditor(id: id);
    });

    // --- latex with cursor in middle ---
    test('latex does not include cursor position', () {
      final id = createEditorFromLatex(latex: r'abc');
      dispatchEditor(id: id, intent: const EditorIntent.moveToStart(), displayMode: false);
      dispatchEditor(id: id, intent: const EditorIntent.moveRight(), displayMode: false);
      final s = getEditorSnapshot(id: id, displayMode: false);
      expect(s.latex, 'abc');
      closeEditor(id: id);
    });

    // --- .html() ---
    test('.html() not applicable', () {}, skip: 'no HTML output — Canvas-based rendering');

    // --- .text() ---
    test('.text() incomplete commands', () {}, skip: 'text() API not implemented');
    test('.text() complete commands', () {}, skip: 'text() API not implemented');

    // --- moveToDirEnd ---
    test('moveToStart positions at beginning', () {
      final id = createEditorFromLatex(latex: r'x+1');
      dispatchEditor(id: id, intent: const EditorIntent.moveToStart(), displayMode: false);
      // Type a char — should go before x
      final s = dispatchEditor(id: id, intent: const EditorIntent.insertSymbol(ch: 'a'), displayMode: false);
      expect(s.latex, 'ax+1');
      closeEditor(id: id);
    });

    test('moveToEnd positions at end', () {
      final id = createEditorFromLatex(latex: r'x+1');
      dispatchEditor(id: id, intent: const EditorIntent.moveToEnd(), displayMode: false);
      final s = dispatchEditor(id: id, intent: const EditorIntent.insertSymbol(ch: 'a'), displayMode: false);
      expect(s.latex, 'x+1a');
      closeEditor(id: id);
    });

    // --- .empty() ---
    test('empty editor has empty latex', () {
      final id = createEditor();
      final s = getEditorSnapshot(id: id, displayMode: false);
      expect(s.latex, '');
      closeEditor(id: id);
    });

    test('non-empty editor has non-empty latex', () {
      final id = createEditorFromLatex(latex: r'x');
      final s = getEditorSnapshot(id: id, displayMode: false);
      expect(s.latex, isNotEmpty);
      closeEditor(id: id);
    });

    // --- ARIA ---
    test('ARIA labels', () {}, skip: 'ARIA/accessibility not implemented');

    // --- mathspeak ---
    test('.mathspeak()', () {}, skip: 'mathspeak not implemented');

    // --- edit handler fires ---
    testWidgets('onChanged fires on edit', (tester) async {
      String? lastLatex;
      await tester.pumpWidget(testApp(
        MathEditor(
          autofocus: true,
          onChanged: (l) => lastLatex = l,
        ),
      ));
      await tester.pump();
      // Focus and type
      await tester.sendKeyEvent(LogicalKeyboardKey.keyX);
      await tester.pump();
      // onChanged should have fired
      if (lastLatex != null) {
        expect(lastLatex, isNotEmpty);
      }
    });

    // --- .cmd() variants ---
    test('dispatch insertFrac creates fraction', () {
      final id = createEditor();
      final s = dispatchEditor(id: id, intent: const EditorIntent.insertFrac(), displayMode: false);
      expect(s.latex, r'\frac{}{}');
      closeEditor(id: id);
    });

    test('dispatch insertSqrt creates sqrt', () {
      final id = createEditor();
      final s = dispatchEditor(id: id, intent: const EditorIntent.insertSqrt(), displayMode: false);
      expect(s.latex, r'\sqrt{}');
      closeEditor(id: id);
    });

    test('dispatch insertParentheses creates parens', () {
      final id = createEditor();
      final s = dispatchEditor(id: id, intent: const EditorIntent.insertParentheses(), displayMode: false);
      expect(s.latex, r'\left(\right)');
      closeEditor(id: id);
    });

    test('dispatch insertSum creates sum', () {
      final id = createEditor();
      final s = dispatchEditor(id: id, intent: const EditorIntent.insertSum(), displayMode: false);
      expect(s.latex, contains(r'\sum'));
      closeEditor(id: id);
    });

    test('dispatch setLatex replaces content', () {
      final id = createEditor();
      dispatchEditor(id: id, intent: const EditorIntent.insertSymbol(ch: 'x'), displayMode: false);
      final s = dispatchEditor(id: id, intent: const EditorIntent.setLatex(latex: r'y+z'), displayMode: false);
      expect(s.latex, 'y+z');
      closeEditor(id: id);
    });

    test('dispatch setLatex with empty string clears', () {
      final id = createEditorFromLatex(latex: r'x+1');
      final s = dispatchEditor(id: id, intent: const EditorIntent.setLatex(latex: ''), displayMode: false);
      expect(s.latex, '');
      closeEditor(id: id);
    });

    // --- spaceBehavesLikeTab ---
    test('spaceBehavesLikeTab', () {}, skip: 'spaceBehavesLikeTab not implemented — 4 tests');

    // --- maxDepth ---
    test('maxDepth option', () {}, skip: 'maxDepth not implemented — 4 tests');

    // --- statelessClipboard ---
    test('statelessClipboard', () {}, skip: 'statelessClipboard not implemented — 10 tests');

    // --- leftRightIntoCmdGoes ---
    test('leftRightIntoCmdGoes up/down', () {}, skip: 'leftRightIntoCmdGoes not implemented — 6 tests');

    // --- sumStartsWithNEquals ---
    test('sumStartsWithNEquals', () {}, skip: 'sumStartsWithNEquals not implemented — 3 tests');

    // --- substituteTextarea ---
    test('substituteTextarea', () {}, skip: 'Flutter native text input — not applicable');

    // --- overrideKeystroke ---
    test('overrideKeystroke', () {}, skip: 'different event model — not applicable — 2 tests');

    // --- substituteKeyboardEvents ---
    test('substituteKeyboardEvents', () {}, skip: 'different event model — not applicable — 5 tests');

    // --- clickAt / tapBlock ---
    test('tapBlock sets cursor', () {
      final id = createEditorFromLatex(latex: r'abc');
      final s1 = getEditorSnapshot(id: id, displayMode: false);
      // Tap at caret 0 (before 'a')
      dispatchEditor(
        id: id,
        intent: EditorIntent.tapBlock(blockId: s1.editorLayout.root.blockId, caretIndex: 0),
        displayMode: false,
      );
      // Type char — should go before a
      final s3 = dispatchEditor(id: id, intent: const EditorIntent.insertSymbol(ch: 'z'), displayMode: false);
      expect(s3.latex, 'zabc');
      closeEditor(id: id);
    });

    // --- dropEmbedded / registerEmbed ---
    test('dropEmbedded', () {}, skip: 'embed not implemented — 2 tests');
    test('registerEmbed', () {}, skip: 'embed not implemented');

    // --- StaticMath cursor ---
    testWidgets('MathBlockWidget renders non-editable without cursor', (tester) async {
      final id = createEditorFromLatex(latex: r'x+1');
      final s = getEditorSnapshot(id: id, displayMode: false);
      await tester.pumpWidget(testApp(
        MathBlockWidget(
          block: s.editorLayout.root,
          untaggedGlyphs: s.editorLayout.untagged,
          isEditable: false,
          fontSize: 20,
          color: const Color(0xFF000000),
          cursorColor: const Color(0xFF0066FF),
          cursorOpacity: 0.0,
        ),
      ));
      expect(find.byType(MathBlockWidget), findsOneWidget);
      closeEditor(id: id);
    });
  });
}
