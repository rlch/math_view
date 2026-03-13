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

void main() {
  group('MathLeaf', () {
    testWidgets('renders without error with single glyph', (tester) async {
      await tester.pumpWidget(testApp(
        MathLeaf(
          glyphs: [testGlyph(codepoint: 0x78)], // 'x'
          fontSize: 20,
          color: const Color(0xFF000000),
        ),
      ));

      expect(find.byType(MathLeaf), findsOneWidget);
      // Should have non-zero size
      final renderBox = tester.renderObject<RenderBox>(find.byType(MathLeaf));
      expect(renderBox.size.width, greaterThan(0));
      expect(renderBox.size.height, greaterThan(0));
    });

    testWidgets('renders without error with multiple glyphs', (tester) async {
      await tester.pumpWidget(testApp(
        MathLeaf(
          glyphs: [
            testGlyph(codepoint: 0x78, x: 0),    // 'x'
            testGlyph(codepoint: 0x2B, x: 0.5),  // '+'
            testGlyph(codepoint: 0x31, x: 1.0),   // '1'
          ],
          fontSize: 20,
          color: const Color(0xFF000000),
        ),
      ));

      expect(find.byType(MathLeaf), findsOneWidget);
    });

    testWidgets('renders empty glyph list without error', (tester) async {
      await tester.pumpWidget(testApp(
        const MathLeaf(
          glyphs: [],
          fontSize: 20,
          color: Color(0xFF000000),
        ),
      ));

      expect(find.byType(MathLeaf), findsOneWidget);
    });

    testWidgets('computes non-zero size for glyph', (tester) async {
      await tester.pumpWidget(testApp(
        MathLeaf(
          glyphs: [testGlyph(codepoint: 0x78)],
          fontSize: 20,
          color: const Color(0xFF000000),
        ),
      ));

      final renderBox =
          tester.renderObject<RenderMathLeaf>(find.byType(MathLeaf));
      expect(renderBox.size.width, greaterThan(0));
      expect(renderBox.size.height, greaterThan(0));
    });
  });

  group('MathLine', () {
    testWidgets('lays out children horizontally', (tester) async {
      await tester.pumpWidget(testApp(
        MathLine(
          children: [
            MathLeaf(
              glyphs: [testGlyph(codepoint: 0x78)],
              fontSize: 20,
              color: const Color(0xFF000000),
            ),
            MathLeaf(
              glyphs: [testGlyph(codepoint: 0x79)],
              fontSize: 20,
              color: const Color(0xFF000000),
            ),
          ],
        ),
      ));

      expect(find.byType(MathLine), findsOneWidget);
      expect(find.byType(MathLeaf), findsNWidgets(2));

      final lineRender =
          tester.renderObject<RenderMathLine>(find.byType(MathLine));
      // Width should be sum of children
      expect(lineRender.size.width, greaterThan(0));
      // Should have 3 caret offsets (before first, between, after last)
      expect(lineRender.caretOffsets.length, equals(3));
      expect(lineRender.caretOffsets[0], equals(0));
      expect(lineRender.caretOffsets[2], equals(lineRender.size.width));
    });

    testWidgets('handles empty children list', (tester) async {
      await tester.pumpWidget(testApp(
        const MathLine(children: []),
      ));

      final lineRender =
          tester.renderObject<RenderMathLine>(find.byType(MathLine));
      expect(lineRender.caretOffsets, equals([0]));
    });

    testWidgets('caret offsets are monotonically increasing', (tester) async {
      await tester.pumpWidget(testApp(
        MathLine(
          children: [
            MathLeaf(
              glyphs: [testGlyph(codepoint: 0x61)], // a
              fontSize: 20,
              color: const Color(0xFF000000),
            ),
            MathLeaf(
              glyphs: [testGlyph(codepoint: 0x62)], // b
              fontSize: 20,
              color: const Color(0xFF000000),
            ),
            MathLeaf(
              glyphs: [testGlyph(codepoint: 0x63)], // c
              fontSize: 20,
              color: const Color(0xFF000000),
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
          cursorIndex: 1,
          cursorColor: const Color(0xFF0066FF),
          cursorOpacity: 1.0,
          selectionColor: const Color(0x4D0066FF),
          children: [
            MathLeaf(
              glyphs: [testGlyph(codepoint: 0x78)],
              fontSize: 20,
              color: const Color(0xFF000000),
            ),
            MathLeaf(
              glyphs: [testGlyph(codepoint: 0x79)],
              fontSize: 20,
              color: const Color(0xFF000000),
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
          selectionStart: 0,
          selectionEnd: 2,
          cursorColor: const Color(0xFF0066FF),
          cursorOpacity: 0.0,
          selectionColor: const Color(0x4D0066FF),
          children: [
            MathLeaf(
              glyphs: [testGlyph(codepoint: 0x78)],
              fontSize: 20,
              color: const Color(0xFF000000),
            ),
            MathLeaf(
              glyphs: [testGlyph(codepoint: 0x79)],
              fontSize: 20,
              color: const Color(0xFF000000),
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
          cursorColor: const Color(0xFF0066FF),
          cursorOpacity: 0.0,
          selectionColor: const Color(0x4D0066FF),
          children: [
            MathLeaf(
              glyphs: [testGlyph(codepoint: 0x78)],
              fontSize: 20,
              color: const Color(0xFF000000),
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
          cursorColor: const Color(0xFF0066FF),
          cursorOpacity: 0.0,
          selectionColor: const Color(0x4D0066FF),
          children: [
            MathLeaf(
              glyphs: [testGlyph(codepoint: 0x78)],
              fontSize: 20,
              color: const Color(0xFF000000),
            ),
            MathLeaf(
              glyphs: [testGlyph(codepoint: 0x79)],
              fontSize: 20,
              color: const Color(0xFF000000),
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
          cursorIndex: 1,
          cursorColor: const Color(0xFF0066FF),
          cursorOpacity: 0.0, // hidden
          selectionColor: const Color(0x4D0066FF),
          children: [
            MathLeaf(
              glyphs: [testGlyph(codepoint: 0x78)],
              fontSize: 20,
              color: const Color(0xFF000000),
            ),
          ],
        ),
      ));

      // Should render without error even with cursor hidden
      expect(find.byType(EditableMathLine), findsOneWidget);
    });
  });

  group('MathBlockWidget integration', () {
    // These tests use hand-crafted BlockLayout data (no Rust needed)

    testWidgets('renders simple leaf-only block', (tester) async {
      // Simulate what Rust would return for "xy"
      await tester.pumpWidget(testApp(
        _buildMathBlockFromLeaves(
          blockId: 0,
          glyphs: [
            [testGlyph(codepoint: 0x78)], // x
            [testGlyph(codepoint: 0x79)], // y
          ],
          isEditable: false,
        ),
      ));

      expect(find.byType(MathLine), findsOneWidget);
      expect(find.byType(MathLeaf), findsNWidgets(2));
    });

    testWidgets('renders editable block with cursor', (tester) async {
      await tester.pumpWidget(testApp(
        _buildMathBlockFromLeaves(
          blockId: 0,
          glyphs: [
            [testGlyph(codepoint: 0x78)],
            [testGlyph(codepoint: 0x79)],
          ],
          isEditable: true,
          cursorIndex: 1,
        ),
      ));

      expect(find.byType(EditableMathLine), findsOneWidget);
      expect(find.byType(MathLeaf), findsNWidgets(2));
    });
  });
}

/// Helper to build a MathBlockWidget from a list of glyph groups (one per leaf).
Widget _buildMathBlockFromLeaves({
  required int blockId,
  required List<List<MathNode>> glyphs,
  required bool isEditable,
  int? cursorIndex,
}) {
  // Import here to access types
  // ignore: depend_on_referenced_packages
  final block = _makeBlockLayout(blockId, glyphs, cursorIndex);
  return _MathBlockFromLayout(
    block: block,
    isEditable: isEditable,
  );
}

// We can't import editor_layout.dart types directly without FRB init,
// so we build the widget tree manually to match what MathBlockWidget would do.
class _MathBlockFromLayout extends StatelessWidget {
  final _SimpleBlock block;
  final bool isEditable;

  const _MathBlockFromLayout({
    required this.block,
    required this.isEditable,
  });

  @override
  Widget build(BuildContext context) {
    final children = block.glyphs.map((g) => MathLeaf(
      glyphs: g,
      fontSize: 20,
      color: const Color(0xFF000000),
    )).toList();

    if (isEditable) {
      return EditableMathLine(
        blockId: block.blockId,
        cursorIndex: block.cursorIndex,
        cursorColor: const Color(0xFF0066FF),
        cursorOpacity: 1.0,
        selectionColor: const Color(0x4D0066FF),
        children: children,
      );
    }

    return MathLine(children: children);
  }
}

class _SimpleBlock {
  final int blockId;
  final List<List<MathNode>> glyphs;
  final int? cursorIndex;

  _SimpleBlock({
    required this.blockId,
    required this.glyphs,
    this.cursorIndex,
  });
}

_SimpleBlock _makeBlockLayout(
  int blockId,
  List<List<MathNode>> glyphs,
  int? cursorIndex,
) {
  return _SimpleBlock(
    blockId: blockId,
    glyphs: glyphs,
    cursorIndex: cursorIndex,
  );
}
