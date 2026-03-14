import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Parent data for children of [RenderMathLine] and [RenderCommandBox].
class MathParentData extends ContainerBoxParentData<RenderBox> {
  /// Absolute x-position (em) from katex-rs. Set by [AbsolutePosition].
  double absoluteXEm = 0;
}

/// Sets the absolute x-position (em) for a child of [MathLine],
/// [EditableMathLine], or [CommandWidget].
class AbsolutePosition extends ParentDataWidget<MathParentData> {
  final double xEm;

  const AbsolutePosition({super.key, required this.xEm, required super.child});

  @override
  void applyParentData(RenderObject renderObject) {
    final pd = renderObject.parentData as MathParentData;
    if (pd.absoluteXEm != xEm) {
      pd.absoluteXEm = xEm;
      renderObject.parent?.markNeedsLayout();
    }
  }

  @override
  Type get debugTypicalAncestorWidgetClass => MathLine;
}

/// A horizontal, baseline-aligned multi-child layout for math blocks.
///
/// Children are positioned at absolute x-coordinates (em) from katex-rs,
/// converted to pixels via [fontSize]. Baseline alignment uses each child's
/// reported alphabetic baseline.
class MathLine extends MultiChildRenderObjectWidget {
  final double fontSize;

  const MathLine({super.key, required this.fontSize, super.children});

  @override
  RenderMathLine createRenderObject(BuildContext context) =>
      RenderMathLine(fontSize: fontSize);

  @override
  void updateRenderObject(BuildContext context, RenderMathLine renderObject) {
    renderObject.fontSize = fontSize;
  }
}

/// RenderBox with [ContainerRenderObjectMixin] for baseline-aligned layout.
///
/// Children must be wrapped in [AbsolutePosition] to provide their x-offset
/// in em units. The render object converts these to pixel positions using
/// [fontSize] and aligns children along a common alphabetic baseline.
class RenderMathLine extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, MathParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, MathParentData> {
  RenderMathLine({required double fontSize}) : _fontSize = fontSize;

  double _fontSize;
  double get fontSize => _fontSize;
  set fontSize(double value) {
    if (_fontSize == value) return;
    _fontSize = value;
    markNeedsLayout();
  }

  /// X-coordinate at each child boundary (length = childCount + 1).
  /// Index 0 = left edge of first child, index childCount = right edge of last.
  List<double> get caretOffsets => _caretOffsets;
  List<double> _caretOffsets = const [];

  double get maxHeightAboveBaseline => _maxHeightAboveBaseline;
  double _maxHeightAboveBaseline = 0;

  /// Block origin x in em (leftmost child absoluteXEm), set during layout.
  double get originXEm => _originXEm;
  double _originXEm = 0;

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! MathParentData) {
      child.parentData = MathParentData();
    }
  }

  @override
  void performLayout() {
    double maxAscent = 0;
    double maxDescent = 0;
    double blockMinX = double.infinity;
    double blockMaxX = double.negativeInfinity;

    // First pass: layout children, collect baselines and x-extents
    var child = firstChild;
    while (child != null) {
      child.layout(const BoxConstraints(), parentUsesSize: true);
      final baseline =
          child.getDistanceToBaseline(TextBaseline.alphabetic) ??
              child.size.height;
      maxAscent = math.max(maxAscent, baseline);
      maxDescent = math.max(maxDescent, child.size.height - baseline);

      final pd = child.parentData! as MathParentData;
      blockMinX = math.min(blockMinX, pd.absoluteXEm);
      blockMaxX = math.max(
          blockMaxX, pd.absoluteXEm + child.size.width / _fontSize);
      child = childAfter(child);
    }

    _maxHeightAboveBaseline = maxAscent;
    _originXEm = blockMinX.isFinite ? blockMinX : 0.0;
    final originX = _originXEm;

    // Second pass: position children at absolute offsets
    final offsets = <double>[];
    child = firstChild;
    while (child != null) {
      final pd = child.parentData! as MathParentData;
      final childBaseline =
          child.getDistanceToBaseline(TextBaseline.alphabetic) ??
              child.size.height;
      final dx = (pd.absoluteXEm - originX) * _fontSize;
      final dy = maxAscent - childBaseline;
      pd.offset = Offset(dx, dy);
      offsets.add(dx); // caret before this child
      child = childAfter(child);
    }

    // Final caret = right edge
    if (firstChild == null) {
      offsets.add(0);
    } else {
      final lastPd = lastChild!.parentData! as MathParentData;
      offsets.add(lastPd.offset.dx + lastChild!.size.width);
    }

    _caretOffsets = offsets;
    final width =
        blockMinX.isFinite ? (blockMaxX - blockMinX) * _fontSize : 0.0;
    size = constraints.constrain(Size(width, maxAscent + maxDescent));
  }

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) {
    return _maxHeightAboveBaseline;
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    return defaultHitTestChildren(result, position: position);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    defaultPaint(context, offset);
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    double total = 0;
    var child = firstChild;
    while (child != null) {
      total += child.getMinIntrinsicWidth(height);
      child = childAfter(child);
    }
    return total;
  }

  @override
  double computeMaxIntrinsicWidth(double height) =>
      computeMinIntrinsicWidth(height);

  @override
  double computeMinIntrinsicHeight(double width) {
    double maxHeight = 0;
    var child = firstChild;
    while (child != null) {
      maxHeight = math.max(maxHeight, child.getMinIntrinsicHeight(width));
      child = childAfter(child);
    }
    return maxHeight;
  }

  @override
  double computeMaxIntrinsicHeight(double width) =>
      computeMinIntrinsicHeight(width);
}
