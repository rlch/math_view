import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../rust/api/editor_layout.dart';
import '../rust/api/math_api.dart';
import 'editable_math_line.dart';
import 'math_leaf.dart';
import 'math_line.dart';
import 'math_paint.dart';

/// Builds a widget tree from a [BlockLayout] tree.
///
/// Each block becomes a [MathLine] (or [EditableMathLine] if editable),
/// each leaf node becomes a [MathLeaf], and each command node becomes
/// a [CommandWidget] with its own children and decorations.
class MathBlockWidget extends StatelessWidget {
  final BlockLayout block;

  /// Untagged decoration nodes (fraction bars, radical signs) from katex-rs
  /// that have no arena node_id.
  final List<MathNode> untaggedGlyphs;
  final bool isEditable;
  final double fontSize;
  final Color color;
  final Color cursorColor;
  final double cursorOpacity;
  final Color selectionColor;

  const MathBlockWidget({
    super.key,
    required this.block,
    this.untaggedGlyphs = const [],
    required this.isEditable,
    required this.fontSize,
    required this.color,
    this.cursorColor = const Color(0xFF0066FF),
    this.cursorOpacity = 0.0,
    this.selectionColor = const Color(0x4D0066FF),
  });

  @override
  Widget build(BuildContext context) {
    final blockWidget = _buildBlock(block);

    if (untaggedGlyphs.isNotEmpty) {
      final rootMinX = block.leftX;
      return CustomPaint(
        foregroundPainter: _UntaggedPainter(
          glyphs: untaggedGlyphs,
          fontSize: fontSize,
          color: color,
          baselineFromTop: block.height * fontSize,
          originXEm: rootMinX,
        ),
        child: blockWidget,
      );
    }

    return blockWidget;
  }

  Widget _buildBlock(BlockLayout block) {
    final children = block.children
        .map((node) => AbsolutePosition(
              xEm: switch (node) {
                NodeLayout_Leaf() => node.leftX,
                NodeLayout_Command() => node.leftX,
              },
              child: _buildNode(node),
            ))
        .toList();

    if (isEditable) {
      // Suppress block-level cursor when a LatexCommandInput is active
      // (it draws its own cursor internally).
      final hasCommandInput = block.children.any((n) =>
          n is NodeLayout_Command &&
          n.kind is CommandLayoutKind_LatexCommandInput);
      return EditableMathLine(
        blockId: block.blockId,
        fontSize: fontSize,
        caretPositions: block.caretPositions,
        cursorScale: block.fontScale,
        cursorBaselineShift: block.baselineShift,
        cursorIndex: hasCommandInput ? null : block.cursorIndex,
        selectionStart: block.selection?.start,
        selectionEnd: block.selection?.end,
        cursorColor: cursorColor,
        cursorOpacity: cursorOpacity,
        selectionColor: selectionColor,
        isEmpty: block.isEmpty,
        children: children,
      );
    }

    return MathLine(fontSize: fontSize, children: children);
  }

  Widget _buildNode(NodeLayout node) {
    switch (node) {
      case NodeLayout_Leaf():
        return MathLeaf(glyphs: node.glyphs, fontSize: fontSize, color: color);
      case NodeLayout_Command():
        // LatexCommandInput: render as styled inline box instead of normal command
        if (node.kind is CommandLayoutKind_LatexCommandInput) {
          final lciKind = node.kind as CommandLayoutKind_LatexCommandInput;
          return LatexCommandInputWidget(
            text: lciKind.text,
            fontSize: fontSize,
            cursorColor: cursorColor,
            cursorOpacity: cursorOpacity,
          );
        }
        final childBlockWidgets = node.childBlocks
            .map((b) => AbsolutePosition(
                  xEm: b.leftX,
                  child: _buildBlock(b),
                ))
            .toList();
        return CommandWidget(
          decorations: node.decorations,
          nodeWidth: node.width,
          nodeHeight: node.height,
          nodeDepth: node.depth,
          nodeLeftX: node.leftX,
          fontSize: fontSize,
          color: color,
          children: childBlockWidgets,
        );
    }
  }
}

/// Renders a command node (frac, sqrt, etc.) with decoration painting
/// and absolutely-positioned child blocks.
class CommandWidget extends MultiChildRenderObjectWidget {
  final List<MathNode> decorations;
  final double nodeWidth;
  final double nodeHeight;
  final double nodeDepth;
  final double nodeLeftX;
  final double fontSize;
  final Color color;

  const CommandWidget({
    super.key,
    required this.decorations,
    required this.nodeWidth,
    required this.nodeHeight,
    required this.nodeDepth,
    required this.nodeLeftX,
    required this.fontSize,
    required this.color,
    super.children,
  });

  @override
  RenderCommandBox createRenderObject(BuildContext context) {
    return RenderCommandBox(
      decorations: decorations,
      nodeWidth: nodeWidth,
      nodeHeight: nodeHeight,
      nodeDepth: nodeDepth,
      nodeLeftX: nodeLeftX,
      fontSize: fontSize,
      color: color,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderCommandBox renderObject) {
    renderObject
      ..decorations = decorations
      ..nodeWidth = nodeWidth
      ..nodeHeight = nodeHeight
      ..nodeDepth = nodeDepth
      ..nodeLeftX = nodeLeftX
      ..fontSize = fontSize
      ..color = color;
  }
}

/// RenderBox for command nodes. Positions child blocks at absolute offsets,
/// baseline-aligns them, and paints decorations (fraction bars, radical signs).
class RenderCommandBox extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, MathParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, MathParentData> {
  RenderCommandBox({
    required List<MathNode> decorations,
    required double nodeWidth,
    required double nodeHeight,
    required double nodeDepth,
    required double nodeLeftX,
    required double fontSize,
    required Color color,
  })  : _decorations = decorations,
        _nodeWidth = nodeWidth,
        _nodeHeight = nodeHeight,
        _nodeDepth = nodeDepth,
        _nodeLeftX = nodeLeftX,
        _fontSize = fontSize,
        _color = color;

  List<MathNode> _decorations;
  set decorations(List<MathNode> value) {
    _decorations = value;
    markNeedsPaint();
  }

  double _nodeWidth;
  set nodeWidth(double value) {
    if (_nodeWidth == value) return;
    _nodeWidth = value;
    markNeedsLayout();
  }

  double _nodeHeight;
  set nodeHeight(double value) {
    if (_nodeHeight == value) return;
    _nodeHeight = value;
    markNeedsLayout();
  }

  double _nodeDepth;
  set nodeDepth(double value) {
    if (_nodeDepth == value) return;
    _nodeDepth = value;
    markNeedsLayout();
  }

  double _nodeLeftX;
  set nodeLeftX(double value) {
    if (_nodeLeftX == value) return;
    _nodeLeftX = value;
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

  double _originXEm = 0;
  double _maxHeightAboveBaseline = 0;

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! MathParentData) {
      child.parentData = MathParentData();
    }
  }

  @override
  void performLayout() {
    // Vertical extents from Rust (accurate, from katex-rs absolute positions)
    final maxAscent = _nodeHeight * _fontSize;
    final maxDescent = _nodeDepth * _fontSize;

    _originXEm = _nodeLeftX;
    _maxHeightAboveBaseline = maxAscent;

    // Layout children, position at absolute offsets with baseline alignment,
    // and compute width from actual rendered sizes.
    double maxRight = 0;
    var child = firstChild;
    while (child != null) {
      child.layout(const BoxConstraints(), parentUsesSize: true);
      final pd = child.parentData! as MathParentData;
      final childBaseline =
          child.getDistanceToBaseline(TextBaseline.alphabetic) ??
              child.size.height;
      final dx = (pd.absoluteXEm - _originXEm) * _fontSize;
      final dy = maxAscent - childBaseline;
      pd.offset = Offset(dx, dy);
      maxRight = math.max(maxRight, dx + child.size.width);
      child = childAfter(child);
    }

    // Use Rust command width if larger than rendered children
    final cmdWidthPx = _nodeWidth * _fontSize;
    final totalWidth = math.max(maxRight, cmdWidthPx);
    size = constraints.constrain(Size(totalWidth, maxAscent + maxDescent));

    // Center empty child blocks within the Rust command width (= fraction bar span).
    child = firstChild;
    while (child != null) {
      if (child is RenderEditableMathLine && child.isEmpty) {
        final pd = child.parentData! as MathParentData;
        final centeredDx = (cmdWidthPx - child.size.width) / 2;
        pd.offset = Offset(centeredDx, pd.offset.dy);
      }
      child = childAfter(child);
    }
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
    // Paint decorations at relative positions
    final canvas = context.canvas;
    final shifted = offset.translate(-_originXEm * _fontSize, 0);
    final bft = _maxHeightAboveBaseline;

    for (final deco in _decorations) {
      switch (deco) {
        case MathNode_Glyph():
          MathPaint.paintGlyph(canvas, shifted, bft, _fontSize, _color, deco);
        case MathNode_Rule():
          MathPaint.paintRule(canvas, shifted, bft, _fontSize, _color, deco);
        case MathNode_SvgPath():
          MathPaint.paintSvgPath(canvas, shifted, bft, _fontSize, _color, deco);
      }
    }

    // Paint children
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

// ---------------------------------------------------------------------------
// LatexCommandInput widget — inline command input box
// ---------------------------------------------------------------------------

/// Renders a `\commandname` input box inline in the math expression.
/// Shows a colored background with the backslash prefix and typed text,
/// plus a blinking cursor at the end.
class LatexCommandInputWidget extends LeafRenderObjectWidget {
  final String text;
  final double fontSize;
  final Color cursorColor;
  final double cursorOpacity;

  const LatexCommandInputWidget({
    super.key,
    required this.text,
    required this.fontSize,
    required this.cursorColor,
    required this.cursorOpacity,
  });

  @override
  RenderLatexCommandInput createRenderObject(BuildContext context) {
    return RenderLatexCommandInput(
      text: text,
      fontSize: fontSize,
      cursorColor: cursorColor,
      cursorOpacity: cursorOpacity,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    RenderLatexCommandInput renderObject,
  ) {
    renderObject
      ..text = text
      ..fontSize = fontSize
      ..cursorColor = cursorColor
      ..cursorOpacity = cursorOpacity;
  }
}

class RenderLatexCommandInput extends RenderBox {
  RenderLatexCommandInput({
    required String text,
    required double fontSize,
    required Color cursorColor,
    required double cursorOpacity,
  })  : _text = text,
        _fontSize = fontSize,
        _cursorColor = cursorColor,
        _cursorOpacity = cursorOpacity;

  String _text;
  set text(String value) {
    if (_text == value) return;
    _text = value;
    _textPainter = null;
    markNeedsLayout();
  }

  double _fontSize;
  set fontSize(double value) {
    if (_fontSize == value) return;
    _fontSize = value;
    _textPainter = null;
    markNeedsLayout();
  }

  Color _cursorColor;
  set cursorColor(Color value) {
    if (_cursorColor == value) return;
    _cursorColor = value;
    markNeedsPaint();
  }

  double _cursorOpacity;
  set cursorOpacity(double value) {
    if (_cursorOpacity == value) return;
    _cursorOpacity = value;
    markNeedsPaint();
  }

  TextPainter? _textPainter;
  double _baseline = 0;

  TextPainter _ensureTextPainter() {
    if (_textPainter != null) return _textPainter!;
    final tp = TextPainter(
      text: TextSpan(
        text: '\\$_text',
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: _fontSize * 0.85,
          color: _cursorColor,
          height: 1.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    _textPainter = tp;
    return tp;
  }

  @override
  void performLayout() {
    final tp = _ensureTextPainter();
    _baseline = tp.computeDistanceToActualBaseline(TextBaseline.alphabetic);
    final padding = _fontSize * 0.1;
    size = constraints.constrain(Size(
      tp.width + padding * 2 + 1.5, // +1.5 for cursor
      tp.height + padding * 2,
    ));
  }

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) {
    final padding = _fontSize * 0.1;
    return _baseline + padding;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final canvas = context.canvas;
    final padding = _fontSize * 0.1;
    final tp = _ensureTextPainter();

    // Background
    final bgRect = Rect.fromLTWH(
      offset.dx,
      offset.dy,
      size.width,
      size.height,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(bgRect, Radius.circular(padding)),
      Paint()..color = _cursorColor.withValues(alpha: 0.1),
    );
    // Border
    canvas.drawRRect(
      RRect.fromRectAndRadius(bgRect, Radius.circular(padding)),
      Paint()
        ..color = _cursorColor.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    // Text
    tp.paint(canvas, offset.translate(padding, padding));

    // Cursor
    if (_cursorOpacity > 0) {
      final cursorX = offset.dx + padding + tp.width;
      final cursorTop = offset.dy + padding;
      final cursorBottom = offset.dy + padding + tp.height;
      canvas.drawLine(
        Offset(cursorX, cursorTop),
        Offset(cursorX, cursorBottom),
        Paint()
          ..color = _cursorColor.withValues(alpha: _cursorOpacity)
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke,
      );
    }
  }

  @override
  bool hitTestSelf(Offset position) => true;
}

// ---------------------------------------------------------------------------
// Untagged glyph painter
// ---------------------------------------------------------------------------

/// Paints orphan decoration nodes (no arena node_id) at absolute positions.
class _UntaggedPainter extends CustomPainter {
  final List<MathNode> glyphs;
  final double fontSize;
  final Color color;
  final double baselineFromTop;
  final double originXEm;

  _UntaggedPainter({
    required this.glyphs,
    required this.fontSize,
    required this.color,
    required this.baselineFromTop,
    required this.originXEm,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final shifted = Offset(-originXEm * fontSize, 0);
    for (final node in glyphs) {
      switch (node) {
        case MathNode_Glyph():
          MathPaint.paintGlyph(
              canvas, shifted, baselineFromTop, fontSize, color, node);
        case MathNode_Rule():
          MathPaint.paintRule(
              canvas, shifted, baselineFromTop, fontSize, color, node);
        case MathNode_SvgPath():
          MathPaint.paintSvgPath(
              canvas, shifted, baselineFromTop, fontSize, color, node);
      }
    }
  }

  @override
  bool shouldRepaint(_UntaggedPainter old) =>
      glyphs != old.glyphs ||
      fontSize != old.fontSize ||
      color != old.color ||
      baselineFromTop != old.baselineFromTop ||
      originXEm != old.originXEm;
}

