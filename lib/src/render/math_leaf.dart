import 'package:flutter/widgets.dart';

import '../rust/api/math_api.dart';
import 'math_paint.dart';

/// A leaf render widget that paints a list of [MathNode] glyphs.
///
/// Tracks its own origin (leftmost glyph x in em) and paints glyphs relative
/// to that origin. The parent [RenderMathLine] positions this widget at the
/// absolute offset via [AbsolutePosition].
class MathLeaf extends LeafRenderObjectWidget {
  final List<MathNode> glyphs;
  final double fontSize;
  final Color color;

  const MathLeaf({
    super.key,
    required this.glyphs,
    required this.fontSize,
    required this.color,
  });

  @override
  RenderMathLeaf createRenderObject(BuildContext context) {
    return RenderMathLeaf(
      glyphs: glyphs,
      fontSize: fontSize,
      color: color,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderMathLeaf renderObject) {
    renderObject
      ..glyphs = glyphs
      ..fontSize = fontSize
      ..color = color;
  }
}

/// RenderBox that paints a group of [MathNode] glyphs for a single arena leaf node.
///
/// Computes its own size from actual [TextPainter] measurements, and reports
/// baseline distance for proper alignment in [RenderMathLine].
///
/// Paints glyphs relative to its origin (`_originXEm`) so that the parent's
/// absolute positioning places them correctly.
class RenderMathLeaf extends RenderBox {
  RenderMathLeaf({
    required List<MathNode> glyphs,
    required double fontSize,
    required Color color,
  })  : _glyphs = glyphs,
        _fontSize = fontSize,
        _color = color;

  List<MathNode> _glyphs;
  set glyphs(List<MathNode> value) {
    _glyphs = value;
    markNeedsLayout();
  }

  double _fontSize;
  set fontSize(double value) {
    if (_fontSize == value) return;
    _fontSize = value;
    markNeedsLayout();
  }

  Color _color;
  set color(Color value) {
    if (_color == value) return;
    _color = value;
    markNeedsPaint();
  }

  // Cached layout metrics
  double _width = 0;
  double _heightAboveBaseline = 0;
  double _depthBelowBaseline = 0;
  double _originXEm = 0;

  @override
  void performLayout() {
    _computeMetrics();
    final w = _width;
    final h = _heightAboveBaseline + _depthBelowBaseline;
    size = constraints.constrain(
      Size(w.clamp(0, double.infinity), h.clamp(0, double.infinity)),
    );
  }

  void _computeMetrics() {
    if (_glyphs.isEmpty) {
      _width = 0;
      _heightAboveBaseline = 0;
      _depthBelowBaseline = 0;
      _originXEm = 0;
      return;
    }

    double minXEm = double.infinity;
    double maxX = double.negativeInfinity; // pixels
    double maxAscent = 0;
    double maxDescent = 0;

    for (final node in _glyphs) {
      switch (node) {
        case MathNode_Glyph():
          final w = MathPaint.measureGlyphWidth(node, _fontSize);
          final x = node.x * _fontSize;
          minXEm = minXEm < node.x ? minXEm : node.x;
          maxX = maxX > (x + w) ? maxX : (x + w);
          final aboveBaseline = node.y * _fontSize + node.scale * _fontSize;
          final belowBaseline = -node.y * _fontSize;
          maxAscent = maxAscent > aboveBaseline ? maxAscent : aboveBaseline;
          maxDescent = maxDescent > belowBaseline ? maxDescent : belowBaseline;
        case MathNode_Rule():
          final x = node.x * _fontSize;
          final w = node.width * _fontSize;
          minXEm = minXEm < node.x ? minXEm : node.x;
          maxX = maxX > (x + w) ? maxX : (x + w);
          final aboveBaseline =
              node.y * _fontSize + node.height * _fontSize;
          final belowBaseline = -node.y * _fontSize;
          maxAscent = maxAscent > aboveBaseline ? maxAscent : aboveBaseline;
          maxDescent = maxDescent > belowBaseline ? maxDescent : belowBaseline;
        case MathNode_SvgPath():
          final x = node.x * _fontSize;
          final w = node.width * _fontSize;
          minXEm = minXEm < node.x ? minXEm : node.x;
          maxX = maxX > (x + w) ? maxX : (x + w);
          final aboveBaseline =
              node.y * _fontSize + node.height * _fontSize;
          final belowBaseline = -node.y * _fontSize;
          maxAscent = maxAscent > aboveBaseline ? maxAscent : aboveBaseline;
          maxDescent = maxDescent > belowBaseline ? maxDescent : belowBaseline;
      }
    }

    _originXEm = minXEm.isFinite ? minXEm : 0;
    _width = maxX > (_originXEm * _fontSize) ? maxX - _originXEm * _fontSize : 0;
    _heightAboveBaseline = maxAscent.clamp(0, double.infinity);
    _depthBelowBaseline = maxDescent.clamp(0, double.infinity);
  }

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) {
    return _heightAboveBaseline;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final canvas = context.canvas;
    final baselineFromTop = _heightAboveBaseline;
    // Shift offset to account for origin — glyphs paint at absolute x,
    // but we need them relative to this widget's left edge.
    final shifted = offset.translate(-_originXEm * _fontSize, 0);

    for (final node in _glyphs) {
      switch (node) {
        case MathNode_Glyph():
          MathPaint.paintGlyph(
            canvas, shifted, baselineFromTop, _fontSize, _color, node,
          );
        case MathNode_Rule():
          MathPaint.paintRule(
            canvas, shifted, baselineFromTop, _fontSize, _color, node,
          );
        case MathNode_SvgPath():
          MathPaint.paintSvgPath(
            canvas, shifted, baselineFromTop, _fontSize, _color, node,
          );
      }
    }
  }

  @override
  bool get sizedByParent => false;
}
