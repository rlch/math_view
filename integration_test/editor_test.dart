import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:math_view/math_view.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await RustLib.init();
  });

  group('MathView rendering', () {
    testWidgets('renders simple expression', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: MathView(latex: 'x+1', fontSize: 24),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(MathView), findsOneWidget);
    });

    testWidgets('renders fraction in display mode', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: MathView(
                latex: r'\frac{a}{b}',
                displayMode: true,
                fontSize: 24,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(MathView), findsOneWidget);
    });

    testWidgets('renders quadratic formula', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: MathView(
                latex: r'x = \frac{-b \pm \sqrt{b^2 - 4ac}}{2a}',
                displayMode: true,
                fontSize: 24,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(MathView), findsOneWidget);
    });

    testWidgets('empty latex renders without error', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: MathView(latex: '', fontSize: 24),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(MathView), findsOneWidget);
    });
  });

  group('MathEditor lifecycle', () {
    testWidgets('creates empty editor and renders', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: MathEditor(fontSize: 24, autofocus: true),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(MathEditor), findsOneWidget);
    });

    testWidgets('creates editor from latex and renders', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: MathEditor(
                initialLatex: r'\frac{x+1}{2}',
                fontSize: 24,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(MathEditor), findsOneWidget);
    });

    testWidgets('typing characters updates latex', (tester) async {
      String? lastLatex;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: MathEditor(
                fontSize: 24,
                autofocus: true,
                onChanged: (latex) => lastLatex = latex,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Focus the editor
      await tester.tap(find.byType(MathEditor));
      await tester.pumpAndSettle();

      // Type 'x'
      await tester.sendKeyEvent(LogicalKeyboardKey.keyX);
      await tester.pumpAndSettle();

      expect(lastLatex, isNotNull);
      expect(lastLatex, contains('x'));
    });

    testWidgets('multiple editors coexist', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                MathEditor(fontSize: 24),
                MathEditor(initialLatex: 'a+b', fontSize: 24),
                MathEditor(initialLatex: r'\frac{1}{2}', fontSize: 24),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(MathEditor), findsNWidgets(3));
    });
  });

  group('MathEditor navigation', () {
    testWidgets('arrow keys dispatch intents', (tester) async {
      String? lastLatex;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: MathEditor(
                initialLatex: 'abc',
                fontSize: 24,
                autofocus: true,
                onChanged: (latex) => lastLatex = latex,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(MathEditor));
      await tester.pumpAndSettle();

      // Arrow left should not change latex
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();

      // Backspace should delete a character
      await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
      await tester.pumpAndSettle();

      expect(lastLatex, isNotNull);
      // 'abc' with cursor moved left then backspace → 'ac'
      expect(lastLatex, equals('ac'));
    });

    testWidgets('Cmd+/ inserts fraction', (tester) async {
      String? lastLatex;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: MathEditor(
                fontSize: 24,
                autofocus: true,
                onChanged: (latex) => lastLatex = latex,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(MathEditor));
      await tester.pumpAndSettle();

      // Cmd+/ should insert a fraction
      await tester.sendKeyDownEvent(LogicalKeyboardKey.meta);
      await tester.sendKeyEvent(LogicalKeyboardKey.slash);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.meta);
      await tester.pumpAndSettle();

      expect(lastLatex, isNotNull);
      expect(lastLatex, contains(r'\frac'));
    });
  });

  group('Editor with fractions', () {
    testWidgets('renders fraction with nested blocks', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: MathEditor(
                initialLatex: r'\frac{x+1}{2}',
                fontSize: 24,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should find the MathEditor and nested MathLeaf widgets
      expect(find.byType(MathEditor), findsOneWidget);
      // At minimum: x, +, 1, 2 = 4 leaves (plus possible decorations)
      expect(find.byType(MathLeaf).evaluate().length, greaterThanOrEqualTo(4));
    });

    testWidgets('renders nested fractions', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: MathEditor(
                initialLatex: r'\frac{1}{1 + \frac{1}{x}}',
                fontSize: 24,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(MathEditor), findsOneWidget);
    });
  });

  group('LaTeX round-trip', () {
    testWidgets('type and export preserves expression', (tester) async {
      String? lastLatex;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: MathEditor(
                fontSize: 24,
                autofocus: true,
                onChanged: (latex) => lastLatex = latex,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(MathEditor));
      await tester.pumpAndSettle();

      // Type 'x+1'
      await tester.sendKeyEvent(LogicalKeyboardKey.keyX);
      await tester.sendKeyEvent(LogicalKeyboardKey.add);
      await tester.sendKeyEvent(LogicalKeyboardKey.digit1);
      await tester.pumpAndSettle();

      expect(lastLatex, isNotNull);
      expect(lastLatex, contains('x'));
      expect(lastLatex, contains('1'));
    });
  });
}
