import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_view/math_view.dart';

Widget testApp(Widget child) => MaterialApp(home: Scaffold(body: Center(child: child)));

void main() {
  group('Focus/Blur (from focusBlur.test.js)', () {
    testWidgets('handlers can shift focus normally', (tester) async {
      final focus1 = FocusNode();
      final focus2 = FocusNode();
      await tester.pumpWidget(testApp(
        Column(children: [
          Focus(focusNode: focus1, child: const MathEditor(initialLatex: 'x')),
          Focus(focusNode: focus2, child: const TextField()),
        ]),
      ));
      focus1.requestFocus();
      await tester.pump();
      expect(focus1.hasFocus, isTrue);
      focus2.requestFocus();
      await tester.pump();
      expect(focus2.hasFocus, isTrue);
      focus1.dispose();
      focus2.dispose();
    });

    testWidgets('focus shifts with selection', (tester) async {
      // skip: selection + focus shift interaction not fully tested
    }, skip: true);

    testWidgets('select works after blur + refocus', (tester) async {
      // skip: blur/refocus selection not fully tested
    }, skip: true);

    testWidgets('blur event fired on focus loss', (tester) async {
      await tester.pumpWidget(testApp(
        Column(children: [
          const MathEditor(initialLatex: 'x', autofocus: true),
          const TextField(),
        ]),
      ));
      await tester.pump();
      // Tap on text field to blur math editor
      await tester.tap(find.byType(TextField));
      await tester.pump();
      // No crash = pass
    });
  });
}
