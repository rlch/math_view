import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_view/src/render/editable_math_line.dart';
import 'package:math_view/src/render/math_leaf.dart';
import 'package:math_view/src/render/math_line.dart';
import 'package:math_view/src/rust/api/math_api.dart';

/// Helper to wrap a widget in a MaterialApp for testing.
Widget testApp(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: Center(child: child),
    ),
  );
}

/// Create a simple glyph MathNode for testing.
MathNode testGlyph({
  required int codepoint,
  double x = 0,
  double y = 0,
  String fontName = 'Main-Regular',
  double scale = 1.0,
}) {
  return MathNode.glyph(
    codepoint: codepoint,
    x: x,
    y: y,
    fontName: fontName,
    scale: scale,
    width: 0.5 * scale,
    color: null,
    nodeId: null,
  );
}

/// Create a rule MathNode for testing.
MathNode testRule({
  double x = 0,
  double y = 0,
  double width = 1.0,
  double height = 0.04,
}) {
  return MathNode.rule(
    x: x,
    y: y,
    width: width,
    height: height,
    color: null,
    nodeId: null,
  );
}

const _fontSize = 20.0;
const _color = Color(0xFF000000);

void main() {
  group('MathLeaf', () {
    testWidgets('renders without error with single glyph', (tester) async {
      await tester.pumpWidget(testApp(
        MathLeaf(
          glyphs: [testGlyph(codepoint: 0x78)], // 'x'
          fontSize: _fontSize,
          color: _color,
        ),
      ));

      expect(find.byType(MathLeaf), findsOneWidget);
      final renderBox = tester.renderObject<RenderBox>(find.byType(MathLeaf));
      expect(renderBox.size.width, greaterThan(0));
      expect(renderBox.size.height, greaterThan(0));
    });

    testWidgets('renders without error with multiple glyphs', (tester) async {
      await tester.pumpWidget(testApp(
        MathLeaf(
          glyphs: [
            testGlyph(codepoint: 0x78, x: 0),
            testGlyph(codepoint: 0x2B, x: 0.5),
            testGlyph(codepoint: 0x31, x: 1.0),
          ],
          fontSize: _fontSize,
          color: _color,
        ),
      ));

      expect(find.byType(MathLeaf), findsOneWidget);
    });

    testWidgets('renders empty glyph list without error', (tester) async {
      await tester.pumpWidget(testApp(
        const MathLeaf(
          glyphs: [],
          fontSize: _fontSize,
          color: _color,
        ),
      ));

      expect(find.byType(MathLeaf), findsOneWidget);
    });

    testWidgets('computes non-zero size for glyph', (tester) async {
      await tester.pumpWidget(testApp(
        MathLeaf(
          glyphs: [testGlyph(codepoint: 0x78)],
          fontSize: _fontSize,
          color: _color,
        ),
      ));

      final renderBox =
          tester.renderObject<RenderMathLeaf>(find.byType(MathLeaf));
      expect(renderBox.size.width, greaterThan(0));
      expect(renderBox.size.height, greaterThan(0));
    });
  });

  group('MathLine', () {
    testWidgets('lays out children at absolute positions', (tester) async {
      await tester.pumpWidget(testApp(
        MathLine(
          fontSize: _fontSize,
          children: [
            AbsolutePosition(
              xEm: 0,
              child: MathLeaf(
                glyphs: [testGlyph(codepoint: 0x78, x: 0)],
                fontSize: _fontSize,
                color: _color,
              ),
            ),
            AbsolutePosition(
              xEm: 0.6,
              child: MathLeaf(
                glyphs: [testGlyph(codepoint: 0x79, x: 0.6)],
                fontSize: _fontSize,
                color: _color,
              ),
            ),
          ],
        ),
      ));

      expect(find.byType(MathLine), findsOneWidget);
      expect(find.byType(MathLeaf), findsNWidgets(2));

      final lineRender =
          tester.renderObject<RenderMathLine>(find.byType(MathLine));
      expect(lineRender.size.width, greaterThan(0));
      // Should have 3 caret offsets (before first, before second, after last)
      expect(lineRender.caretOffsets.length, equals(3));
      expect(lineRender.caretOffsets[0], equals(0));
      // Last caret should equal total width
      expect(lineRender.caretOffsets[2],
          closeTo(lineRender.size.width, 0.01));
    });

    testWidgets('handles empty children list', (tester) async {
      await tester.pumpWidget(testApp(
        const MathLine(fontSize: _fontSize, children: []),
      ));

      final lineRender =
          tester.renderObject<RenderMathLine>(find.byType(MathLine));
      expect(lineRender.caretOffsets, equals([0]));
    });

    testWidgets('caret offsets are monotonically increasing', (tester) async {
      await tester.pumpWidget(testApp(
        MathLine(
          fontSize: _fontSize,
          children: [
            AbsolutePosition(
              xEm: 0,
              child: MathLeaf(
                glyphs: [testGlyph(codepoint: 0x61, x: 0)], // a
                fontSize: _fontSize,
                color: _color,
              ),
            ),
            AbsolutePosition(
              xEm: 0.5,
              child: MathLeaf(
                glyphs: [testGlyph(codepoint: 0x62, x: 0.5)], // b
                fontSize: _fontSize,
                color: _color,
              ),
            ),
            AbsolutePosition(
              xEm: 1.0,
              child: MathLeaf(
                glyphs: [testGlyph(codepoint: 0x63, x: 1.0)], // c
                fontSize: _fontSize,
                color: _color,
              ),
            ),
          ],
        ),
      ));

      final lineRender =
          tester.renderObject<RenderMathLine>(find.byType(MathLine));
      final offsets = lineRender.caretOffsets;
      expect(offsets.length, equals(4));
      for (int i = 1; i < offsets.length; i++) {
        expect(offsets[i], greaterThanOrEqualTo(offsets[i - 1]));
      }
    });
  });

  group('EditableMathLine', () {
    testWidgets('renders with cursor', (tester) async {
      await tester.pumpWidget(testApp(
        EditableMathLine(
          blockId: 0,
          fontSize: _fontSize,
          caretPositions: Float64List.fromList([0.0, 0.5, 1.0]),
          cursorIndex: 1,
          cursorColor: const Color(0xFF0066FF),
          cursorOpacity: 1.0,
          selectionColor: const Color(0x4D0066FF),
          children: [
            AbsolutePosition(
              xEm: 0,
              child: MathLeaf(
                glyphs: [testGlyph(codepoint: 0x78, x: 0)],
                fontSize: _fontSize,
                color: _color,
              ),
            ),
            AbsolutePosition(
              xEm: 0.5,
              child: MathLeaf(
                glyphs: [testGlyph(codepoint: 0x79, x: 0.5)],
                fontSize: _fontSize,
                color: _color,
              ),
            ),
          ],
        ),
      ));

      expect(find.byType(EditableMathLine), findsOneWidget);
      final render = tester.renderObject<RenderEditableMathLine>(
        find.byType(EditableMathLine),
      );
      expect(render.blockId, equals(0));
    });

    testWidgets('renders with selection', (tester) async {
      await tester.pumpWidget(testApp(
        EditableMathLine(
          blockId: 0,
          fontSize: _fontSize,
          caretPositions: Float64List.fromList([0.0, 0.5, 1.0]),
          selectionStart: 0,
          selectionEnd: 2,
          cursorColor: const Color(0xFF0066FF),
          cursorOpacity: 0.0,
          selectionColor: const Color(0x4D0066FF),
          children: [
            AbsolutePosition(
              xEm: 0,
              child: MathLeaf(
                glyphs: [testGlyph(codepoint: 0x78, x: 0)],
                fontSize: _fontSize,
                color: _color,
              ),
            ),
            AbsolutePosition(
              xEm: 0.5,
              child: MathLeaf(
                glyphs: [testGlyph(codepoint: 0x79, x: 0.5)],
                fontSize: _fontSize,
                color: _color,
              ),
            ),
          ],
        ),
      ));

      expect(find.byType(EditableMathLine), findsOneWidget);
    });

    testWidgets('hitTestSelf returns true', (tester) async {
      await tester.pumpWidget(testApp(
        EditableMathLine(
          blockId: 0,
          fontSize: _fontSize,
          caretPositions: Float64List.fromList([0.0, 0.5]),
          cursorColor: const Color(0xFF0066FF),
          cursorOpacity: 0.0,
          selectionColor: const Color(0x4D0066FF),
          children: [
            AbsolutePosition(
              xEm: 0,
              child: MathLeaf(
                glyphs: [testGlyph(codepoint: 0x78, x: 0)],
                fontSize: _fontSize,
                color: _color,
              ),
            ),
          ],
        ),
      ));

      final render = tester.renderObject<RenderEditableMathLine>(
        find.byType(EditableMathLine),
      );
      expect(render.hitTestSelf(Offset.zero), isTrue);
    });

    testWidgets('getCaretIndexForPoint resolves nearest gap', (tester) async {
      await tester.pumpWidget(testApp(
        EditableMathLine(
          blockId: 0,
          fontSize: _fontSize,
          caretPositions: Float64List.fromList([0.0, 0.5, 1.0]),
          cursorColor: const Color(0xFF0066FF),
          cursorOpacity: 0.0,
          selectionColor: const Color(0x4D0066FF),
          children: [
            AbsolutePosition(
              xEm: 0,
              child: MathLeaf(
                glyphs: [testGlyph(codepoint: 0x78, x: 0)],
                fontSize: _fontSize,
                color: _color,
              ),
            ),
            AbsolutePosition(
              xEm: 0.5,
              child: MathLeaf(
                glyphs: [testGlyph(codepoint: 0x79, x: 0.5)],
                fontSize: _fontSize,
                color: _color,
              ),
            ),
          ],
        ),
      ));

      final render = tester.renderObject<RenderEditableMathLine>(
        find.byType(EditableMathLine),
      );

      // Tap at x=0 should give caret index 0 (before first child)
      expect(render.getCaretIndexForPoint(const Offset(0, 5)), equals(0));

      // Tap at far right should give caret index 2 (after last child)
      expect(
        render.getCaretIndexForPoint(Offset(render.size.width + 10, 5)),
        equals(2),
      );
    });

    testWidgets('renders without cursor when opacity is 0', (tester) async {
      await tester.pumpWidget(testApp(
        EditableMathLine(
          blockId: 0,
          fontSize: _fontSize,
          caretPositions: Float64List.fromList([0.0, 0.5]),
          cursorIndex: 1,
          cursorColor: const Color(0xFF0066FF),
          cursorOpacity: 0.0,
          selectionColor: const Color(0x4D0066FF),
          children: [
            AbsolutePosition(
              xEm: 0,
              child: MathLeaf(
                glyphs: [testGlyph(codepoint: 0x78, x: 0)],
                fontSize: _fontSize,
                color: _color,
              ),
            ),
          ],
        ),
      ));

      expect(find.byType(EditableMathLine), findsOneWidget);
    });
  });

  group('MathBlockWidget integration', () {
    testWidgets('renders simple leaf-only block via widget tree',
        (tester) async {
      // Build widget tree manually (same structure MathBlockWidget would build)
      await tester.pumpWidget(testApp(
        MathLine(
          fontSize: _fontSize,
          children: [
            AbsolutePosition(
              xEm: 0,
              child: MathLeaf(
                glyphs: [testGlyph(codepoint: 0x78, x: 0)], // x
                fontSize: _fontSize,
                color: _color,
              ),
            ),
            AbsolutePosition(
              xEm: 0.5,
              child: MathLeaf(
                glyphs: [testGlyph(codepoint: 0x79, x: 0.5)], // y
                fontSize: _fontSize,
                color: _color,
              ),
            ),
          ],
        ),
      ));

      expect(find.byType(MathLine), findsOneWidget);
      expect(find.byType(MathLeaf), findsNWidgets(2));
    });

    testWidgets('renders editable block with cursor via widget tree',
        (tester) async {
      await tester.pumpWidget(testApp(
        EditableMathLine(
          blockId: 0,
          fontSize: _fontSize,
          caretPositions: Float64List.fromList([0.0, 0.5, 1.0]),
          cursorIndex: 1,
          cursorColor: const Color(0xFF0066FF),
          cursorOpacity: 1.0,
          selectionColor: const Color(0x4D0066FF),
          children: [
            AbsolutePosition(
              xEm: 0,
              child: MathLeaf(
                glyphs: [testGlyph(codepoint: 0x78, x: 0)],
                fontSize: _fontSize,
                color: _color,
              ),
            ),
            AbsolutePosition(
              xEm: 0.5,
              child: MathLeaf(
                glyphs: [testGlyph(codepoint: 0x79, x: 0.5)],
                fontSize: _fontSize,
                color: _color,
              ),
            ),
          ],
        ),
      ));

      expect(find.byType(EditableMathLine), findsOneWidget);
      expect(find.byType(MathLeaf), findsNWidgets(2));
    });
  });
}
