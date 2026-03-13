import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Parent data for children of [RenderMathLine].
class MathLineParentData extends ContainerBoxParentData<RenderBox> {}

/// A horizontal, baseline-aligned multi-child layout for math blocks.
///
/// This mirrors flutter_math_fork's `RenderLine`: children are laid out
/// left-to-right, aligned along a common baseline. After layout, it builds
/// [caretOffsets] — the x-coordinate at each child gap (0 = before first
/// child, n = after last child).
///
/// Use [MathLine] widget to create this render object.
class MathLine extends MultiChildRenderObjectWidget {
  const MathLine({super.key, super.children});

  @override
  RenderMathLine createRenderObject(BuildContext context) => RenderMathLine();

  @override
  void updateRenderObject(BuildContext context, RenderMathLine renderObject) {}
}

/// RenderBox with [ContainerRenderObjectMixin] for baseline-aligned layout.
class RenderMathLine extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, MathLineParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, MathLineParentData> {
  /// X-coordinate at each child boundary (length = childCount + 1).
  /// Index 0 = left edge, index childCount = right edge.
  List<double> get caretOffsets => _caretOffsets;
  List<double> _caretOffsets = const [];

  double _maxHeightAboveBaseline = 0;

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! MathLineParentData) {
      child.parentData = MathLineParentData();
    }
  }

  @override
  void performLayout() {
    double maxAscent = 0;
    double maxDescent = 0;

    // First pass: layout children and collect max ascent/descent
    var child = firstChild;
    while (child != null) {
      child.layout(
        const BoxConstraints(),
        parentUsesSize: true,
      );
      final baseline =
          child.getDistanceToBaseline(TextBaseline.alphabetic) ??
              child.size.height;
      maxAscent = math.max(maxAscent, baseline);
      maxDescent = math.max(maxDescent, child.size.height - baseline);
      child = childAfter(child);
    }

    _maxHeightAboveBaseline = maxAscent;

    // Second pass: position children horizontally, align baselines
    double x = 0;
    final offsets = <double>[0]; // caret before first child
    child = firstChild;
    while (child != null) {
      final parentData = child.parentData! as MathLineParentData;
      final childBaseline =
          child.getDistanceToBaseline(TextBaseline.alphabetic) ??
              child.size.height;
      final dy = maxAscent - childBaseline;
      parentData.offset = Offset(x, dy);
      x += child.size.width;
      offsets.add(x); // caret after this child
      child = childAfter(child);
    }

    _caretOffsets = offsets;
    size = constraints.constrain(Size(x, maxAscent + maxDescent));
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
    // Cannot call getDistanceToActualBaseline during intrinsic queries
    // (children aren't laid out yet). Use max child height as approximation.
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
