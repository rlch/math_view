import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import '../rust/api/editor_layout.dart';
import '../rust/api/math_api.dart';
import 'math_paint.dart';

/// Renders a math expression from an [EditorLayout] tree.
///
/// Uses flat (absolute-coordinate) painting for glyphs — katex-rs is
/// authoritative for all positioning. The [BlockLayout] tree structure
/// provides cursor/selection scoping and hit testing (tap → block + gap).
class MathBlockWidget extends LeafRenderObjectWidget {
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
  RenderMathBlock createRenderObject(BuildContext context) {
    return RenderMathBlock(
      block: block,
      untaggedGlyphs: untaggedGlyphs,
      isEditable: isEditable,
      fontSize: fontSize,
      color: color,
      cursorColor: cursorColor,
      cursorOpacity: cursorOpacity,
      selectionColor: selectionColor,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderMathBlock renderObject) {
    renderObject
      ..block = block
      ..untaggedGlyphs = untaggedGlyphs
      ..isEditable = isEditable
      ..fontSize = fontSize
      ..color = color
      ..cursorColor = cursorColor
      ..cursorOpacity = cursorOpacity
      ..selectionColor = selectionColor;
  }
}

/// Flat-painting RenderBox that paints all glyphs at their absolute katex-rs
/// positions, with cursor and selection overlays scoped to block height.
class RenderMathBlock extends RenderBox {
  RenderMathBlock({
    required BlockLayout block,
    required List<MathNode> untaggedGlyphs,
    required bool isEditable,
    required double fontSize,
    required Color color,
    required Color cursorColor,
    required double cursorOpacity,
    required Color selectionColor,
  })  : _block = block,
        _untaggedGlyphs = untaggedGlyphs,
        _isEditable = isEditable,
        _fontSize = fontSize,
        _color = color,
        _cursorColor = cursorColor,
        _cursorOpacity = cursorOpacity,
        _selectionColor = selectionColor;

  BlockLayout _block;
  set block(BlockLayout value) {
    _block = value;
    markNeedsLayout();
  }

  List<MathNode> _untaggedGlyphs;
  set untaggedGlyphs(List<MathNode> value) {
    _untaggedGlyphs = value;
    markNeedsLayout();
  }

  bool _isEditable;
  set isEditable(bool value) {
    if (_isEditable == value) return;
    _isEditable = value;
    markNeedsPaint();
  }

  double _fontSize;
  set fontSize(double value) {
    if (_fontSize == value) return;
    _fontSize = value;
    _fontMetricsForSize = 0;
    markNeedsLayout();
  }

  Color _color;
  set color(Color value) {
    if (_color == value) return;
    _color = value;
    markNeedsPaint();
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

  Color _selectionColor;
  set selectionColor(Color value) {
    if (_selectionColor == value) return;
    _selectionColor = value;
    markNeedsPaint();
  }

  // -- Cached layout state --
  List<MathNode> _allGlyphs = const [];
  double _exprWidth = 0; // em
  double _exprHeight = 0; // above baseline, em
  double _exprDepth = 0; // below baseline, em

  // Font metrics cache (for minimum height / baseline)
  double _fontAscent = 0;
  double _fontDescent = 0;
  double _fontMetricsForSize = 0;

  // Cursor / selection paint info (pixels, widget-local)
  _CursorPaint? _cursorPaint;
  _SelectionPaint? _selectionPaint;

  double get _baselineFromTop =>
      math.max(_exprHeight * _fontSize, _fontAscent);

  void _ensureFontMetrics() {
    if (_fontMetricsForSize == _fontSize) return;
    final tp = TextPainter(
      text: TextSpan(
        text: 'M',
        style: TextStyle(
          fontFamily: 'KaTeX_Main',
          fontSize: _fontSize,
          package: 'math_view',
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    _fontAscent =
        tp.computeDistanceToActualBaseline(TextBaseline.alphabetic);
    _fontDescent = tp.height - _fontAscent;
    _fontMetricsForSize = _fontSize;
  }

  @override
  void performLayout() {
    _ensureFontMetrics();
    _allGlyphs = _collectAllGlyphs(_block);
    _allGlyphs.addAll(_untaggedGlyphs);
    _computeExprExtents();

    final ascent = _baselineFromTop;
    final descent = math.max(_exprDepth * _fontSize, _fontDescent);
    final w = _exprWidth * _fontSize;
    final h = ascent + descent;

    size = constraints.constrain(Size(
      math.max(w, _isEditable ? 2.0 : 0.0),
      math.max(h, _fontSize),
    ));

    if (_isEditable) {
      _cursorPaint = _buildCursorPaint(_block);
      _selectionPaint = _buildSelectionPaint(_block);
    }
  }

  void _computeExprExtents() {
    if (_allGlyphs.isEmpty) {
      _exprWidth = _exprHeight = _exprDepth = 0;
      return;
    }
    double minX = double.infinity, maxX = double.negativeInfinity;
    double maxH = 0.0, maxD = 0.0;
    for (final g in _allGlyphs) {
      final b = _mathNodeBounds(g);
      minX = math.min(minX, b.x);
      maxX = math.max(maxX, b.rightX);
      maxH = math.max(maxH, b.above);
      maxD = math.max(maxD, b.below);
    }
    _exprWidth = maxX > minX ? maxX - minX : 0;
    _exprHeight = maxH.clamp(0, double.infinity);
    _exprDepth = maxD.clamp(0, double.infinity);
  }

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) =>
      _baselineFromTop;

  @override
  double computeMinIntrinsicWidth(double height) =>
      (_block.width) * _fontSize;

  @override
  double computeMaxIntrinsicWidth(double height) =>
      computeMinIntrinsicWidth(height);

  @override
  double computeMinIntrinsicHeight(double width) {
    _ensureFontMetrics();
    final h = (_block.height + _block.depth) * _fontSize;
    return math.max(h, _fontSize);
  }

  @override
  double computeMaxIntrinsicHeight(double width) =>
      computeMinIntrinsicHeight(width);

  // ---------- Painting ----------

  @override
  void paint(PaintingContext context, Offset offset) {
    final canvas = context.canvas;
    final bft = _baselineFromTop;

    // Selection highlight (behind glyphs)
    if (_selectionPaint case final sel?) {
      canvas.drawRect(
        Rect.fromLTWH(
          offset.dx + sel.x, offset.dy + sel.top, sel.width, sel.height,
        ),
        Paint()..color = _selectionColor,
      );
    }

    // All glyphs at absolute katex-rs positions
    for (final node in _allGlyphs) {
      switch (node) {
        case MathNode_Glyph():
          MathPaint.paintGlyph(canvas, offset, bft, _fontSize, _color, node);
        case MathNode_Rule():
          MathPaint.paintRule(canvas, offset, bft, _fontSize, _color, node);
        case MathNode_SvgPath():
          MathPaint.paintSvgPath(canvas, offset, bft, _fontSize, _color, node);
      }
    }

    // Cursor (in front of glyphs)
    if (_cursorPaint case final cur? when _cursorOpacity > 0) {
      canvas.drawRect(
        Rect.fromLTWH(
          offset.dx + cur.x - 0.75,
          offset.dy + cur.top,
          1.5,
          cur.height,
        ),
        Paint()..color = _cursorColor.withValues(alpha: _cursorOpacity),
      );
    }
  }

  // ---------- Hit testing ----------

  @override
  bool hitTestSelf(Offset position) => _isEditable;

  /// Resolve a local tap position into (blockId, caretIndex).
  (int, int) hitTestForCaret(Offset localPosition) {
    final bft = _baselineFromTop;
    final xEm = localPosition.dx / _fontSize;
    final yEm = (bft - localPosition.dy) / _fontSize; // positive = above baseline
    return _hitTestBlock(_block, xEm, yEm);
  }

  // ---------- Private: cursor / selection ----------

  _CursorPaint? _buildCursorPaint(BlockLayout block, {double? fallbackXEm}) {
    if (block.cursorIndex != null) {
      final idx = block.cursorIndex!;
      final xEm = block.children.isEmpty
          ? (fallbackXEm ?? 0.0)
          : _gapXEm(block, idx);
      final bounds = _blockBoundsEm(block);
      final bft = _baselineFromTop;
      return _CursorPaint(
        x: xEm * _fontSize,
        top: bft - bounds.above * _fontSize,
        height: math.max((bounds.above + bounds.below) * _fontSize, _fontSize * 0.6),
      );
    }
    for (final child in block.children) {
      if (child is NodeLayout_Command) {
        final cmdCx = (_nodeLeftXEm(child) + _nodeRightXEm(child)) / 2;
        for (final cb in child.childBlocks) {
          final info = _buildCursorPaint(cb, fallbackXEm: cmdCx);
          if (info != null) return info;
        }
      }
    }
    return null;
  }

  _SelectionPaint? _buildSelectionPaint(BlockLayout block) {
    if (block.selection case final sel?) {
      final startX = _gapXEm(block, sel.start);
      final endX = _gapXEm(block, sel.end);
      final bounds = _blockBoundsEm(block);
      final bft = _baselineFromTop;
      final leftX = math.min(startX, endX);
      final rightX = math.max(startX, endX);
      return _SelectionPaint(
        x: leftX * _fontSize,
        top: bft - bounds.above * _fontSize,
        width: (rightX - leftX) * _fontSize,
        height: (bounds.above + bounds.below) * _fontSize,
      );
    }
    for (final child in block.children) {
      if (child is NodeLayout_Command) {
        for (final cb in child.childBlocks) {
          final info = _buildSelectionPaint(cb);
          if (info != null) return info;
        }
      }
    }
    return null;
  }

  /// X-position (em) of the gap at [gapIndex] within [block].
  double _gapXEm(BlockLayout block, int gapIndex) {
    if (block.children.isEmpty) return 0;
    if (gapIndex <= 0) return _nodeLeftXEm(block.children.first);
    if (gapIndex >= block.children.length) {
      return _nodeRightXEm(block.children.last);
    }
    return (_nodeRightXEm(block.children[gapIndex - 1]) +
            _nodeLeftXEm(block.children[gapIndex])) /
        2;
  }

  (int, int) _hitTestBlock(BlockLayout block, double xEm, double yEm) {
    // Try child blocks of command nodes (depth-first for deepest match)
    for (final child in block.children) {
      if (child is NodeLayout_Command) {
        for (final cb in child.childBlocks) {
          final b = _blockBoundsEm(cb);
          // Generous padding so empty-ish blocks are hittable
          if (xEm >= b.left - 0.15 &&
              xEm <= b.right + 0.15 &&
              yEm >= -b.below - 0.15 &&
              yEm <= b.above + 0.15) {
            return _hitTestBlock(cb, xEm, yEm);
          }
        }
      }
    }
    return (block.blockId, _nearestGap(block, xEm));
  }

  int _nearestGap(BlockLayout block, double xEm) {
    if (block.children.isEmpty) return 0;
    double bestDist = double.infinity;
    int bestIdx = 0;
    for (int i = 0; i <= block.children.length; i++) {
      final gx = _gapXEm(block, i);
      final d = (gx - xEm).abs();
      if (d < bestDist) {
        bestDist = d;
        bestIdx = i;
      }
    }
    return bestIdx;
  }
}

// ---------------------------------------------------------------------------
// Data classes
// ---------------------------------------------------------------------------

class _CursorPaint {
  final double x, top, height;
  _CursorPaint({required this.x, required this.top, required this.height});
}

class _SelectionPaint {
  final double x, top, width, height;
  _SelectionPaint({
    required this.x,
    required this.top,
    required this.width,
    required this.height,
  });
}

// ---------------------------------------------------------------------------
// Helper functions (stateless, operate on tree data)
// ---------------------------------------------------------------------------

/// Recursively collect every [MathNode] from a [BlockLayout] tree.
List<MathNode> _collectAllGlyphs(BlockLayout block) {
  final out = <MathNode>[];
  _collectFromBlock(block, out);
  return out;
}

void _collectFromBlock(BlockLayout block, List<MathNode> out) {
  for (final child in block.children) {
    switch (child) {
      case NodeLayout_Leaf():
        out.addAll(child.glyphs);
      case NodeLayout_Command():
        out.addAll(child.decorations);
        for (final cb in child.childBlocks) {
          _collectFromBlock(cb, out);
        }
    }
  }
}

/// Bounding box of a single [MathNode] in em units.
({double x, double rightX, double above, double below}) _mathNodeBounds(
    MathNode node) {
  switch (node) {
    case MathNode_Glyph():
      final w = 0.5 * node.scale; // approximate
      return (
        x: node.x,
        rightX: node.x + w,
        above: node.y + node.scale,
        below: (-node.y).clamp(0.0, double.infinity),
      );
    case MathNode_Rule():
      return (
        x: node.x,
        rightX: node.x + node.width,
        above: node.y + node.height,
        below: (-node.y).clamp(0.0, double.infinity),
      );
    case MathNode_SvgPath():
      return (
        x: node.x,
        rightX: node.x + node.width,
        above: node.y + node.height,
        below: (-node.y).clamp(0.0, double.infinity),
      );
  }
}

/// Leftmost x (em) of all glyphs owned by [node].
double _nodeLeftXEm(NodeLayout node) {
  switch (node) {
    case NodeLayout_Leaf():
      if (node.glyphs.isEmpty) return 0;
      double v = double.infinity;
      for (final g in node.glyphs) {
        v = math.min(v, _mathNodeBounds(g).x);
      }
      return v.isFinite ? v : 0;
    case NodeLayout_Command():
      double v = double.infinity;
      for (final g in node.decorations) {
        v = math.min(v, _mathNodeBounds(g).x);
      }
      for (final cb in node.childBlocks) {
        for (final child in cb.children) {
          v = math.min(v, _nodeLeftXEm(child));
        }
      }
      return v.isFinite ? v : 0;
  }
}

/// Rightmost x (em) of all glyphs owned by [node].
double _nodeRightXEm(NodeLayout node) {
  switch (node) {
    case NodeLayout_Leaf():
      if (node.glyphs.isEmpty) return 0;
      double v = double.negativeInfinity;
      for (final g in node.glyphs) {
        v = math.max(v, _mathNodeBounds(g).rightX);
      }
      return v.isFinite ? v : 0;
    case NodeLayout_Command():
      double v = double.negativeInfinity;
      for (final g in node.decorations) {
        v = math.max(v, _mathNodeBounds(g).rightX);
      }
      for (final cb in node.childBlocks) {
        for (final child in cb.children) {
          v = math.max(v, _nodeRightXEm(child));
        }
      }
      return v.isFinite ? v : 0;
  }
}

/// Bounding box (em) of all glyphs in a block's subtree.
({double left, double right, double above, double below}) _blockBoundsEm(
    BlockLayout block) {
  final glyphs = _collectAllGlyphs(block);
  if (glyphs.isEmpty) {
    return (left: 0, right: 0, above: 0.8, below: 0.2);
  }
  double minX = double.infinity, maxX = double.negativeInfinity;
  double maxH = 0.0, maxD = 0.0;
  for (final g in glyphs) {
    final b = _mathNodeBounds(g);
    minX = math.min(minX, b.x);
    maxX = math.max(maxX, b.rightX);
    maxH = math.max(maxH, b.above);
    maxD = math.max(maxD, b.below);
  }
  return (
    left: minX.isFinite ? minX : 0,
    right: maxX.isFinite ? maxX : 0,
    above: maxH,
    below: maxD,
  );
}
