import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import 'math_line.dart';

/// An editable version of [MathLine] that paints cursor and selection
/// highlights scoped to the block's own height.
///
/// Overrides [hitTestSelf] to accept taps, provides [getCaretIndexForPoint]
/// for click-to-cursor resolution, and paints cursor/selection within the block.
class EditableMathLine extends MultiChildRenderObjectWidget {
  final int blockId;
  final double fontSize;

  /// Caret gap x-positions (em) from Rust. Length = childCount + 1.
  final Float64List caretPositions;

  /// Effective font-size multiplier for leaf content (from Rust).
  final double cursorScale;

  /// Y-offset (em) of this block's leaf baseline from expression baseline (from Rust).
  final double cursorBaselineShift;
  final int? cursorIndex;
  final int? selectionStart;
  final int? selectionEnd;
  final Color cursorColor;
  final double cursorOpacity;
  final Color selectionColor;

  /// Whether this block is empty (no child nodes in the arena).
  final bool isEmpty;

  const EditableMathLine({
    super.key,
    super.children,
    required this.blockId,
    required this.fontSize,
    required this.caretPositions,
    this.cursorScale = 1.0,
    this.cursorBaselineShift = 0.0,
    this.cursorIndex,
    this.selectionStart,
    this.selectionEnd,
    required this.cursorColor,
    required this.cursorOpacity,
    required this.selectionColor,
    this.isEmpty = false,
  });

  @override
  RenderEditableMathLine createRenderObject(BuildContext context) {
    return RenderEditableMathLine(
      blockId: blockId,
      fontSize: fontSize,
      caretPositionsEm: caretPositions,
      cursorScale: cursorScale,
      cursorBaselineShift: cursorBaselineShift,
      cursorIndex: cursorIndex,
      selectionStart: selectionStart,
      selectionEnd: selectionEnd,
      cursorColor: cursorColor,
      cursorOpacity: cursorOpacity,
      selectionColor: selectionColor,
      isEmpty: isEmpty,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    RenderEditableMathLine renderObject,
  ) {
    renderObject
      ..blockId = blockId
      ..fontSize = fontSize
      ..caretPositionsEm = caretPositions
      ..cursorScale = cursorScale
      ..cursorBaselineShift = cursorBaselineShift
      ..cursorIndex = cursorIndex
      ..selectionStart = selectionStart
      ..selectionEnd = selectionEnd
      ..cursorColor = cursorColor
      ..cursorOpacity = cursorOpacity
      ..selectionColor = selectionColor
      ..isEmpty = isEmpty;
  }
}

/// RenderBox that extends [RenderMathLine] behavior with editing visuals.
class RenderEditableMathLine extends RenderMathLine {
  RenderEditableMathLine({
    required int blockId,
    required super.fontSize,
    required Float64List caretPositionsEm,
    double cursorScale = 1.0,
    double cursorBaselineShift = 0.0,
    int? cursorIndex,
    int? selectionStart,
    int? selectionEnd,
    required Color cursorColor,
    required double cursorOpacity,
    required Color selectionColor,
    bool isEmpty = false,
  })  : _blockId = blockId,
        _caretPositionsEm = caretPositionsEm,
        _cursorScale = cursorScale,
        _cursorBaselineShift = cursorBaselineShift,
        _cursorIndex = cursorIndex,
        _selectionStart = selectionStart,
        _selectionEnd = selectionEnd,
        _cursorColor = cursorColor,
        _cursorOpacity = cursorOpacity,
        _selectionColor = selectionColor,
        _isEmpty = isEmpty;

  int _blockId;
  set blockId(int value) {
    if (_blockId == value) return;
    _blockId = value;
    markNeedsPaint();
  }

  int get blockId => _blockId;

  Float64List _caretPositionsEm;
  set caretPositionsEm(Float64List value) {
    _caretPositionsEm = value;
    markNeedsPaint();
  }

  /// Caret offsets in pixels, converted from Rust em values using block origin.
  @override
  List<double> get caretOffsets {
    final origin = originXEm;
    return [
      for (final em in _caretPositionsEm) (em - origin) * fontSize,
    ];
  }

  double _cursorScale;
  set cursorScale(double value) {
    if (_cursorScale == value) return;
    _cursorScale = value;
    _fontMetricsForSize = 0;
    markNeedsPaint();
  }

  double _cursorBaselineShift;
  set cursorBaselineShift(double value) {
    if (_cursorBaselineShift == value) return;
    _cursorBaselineShift = value;
    markNeedsPaint();
  }

  int? _cursorIndex;
  set cursorIndex(int? value) {
    if (_cursorIndex == value) return;
    _cursorIndex = value;
    markNeedsPaint();
  }

  int? _selectionStart;
  set selectionStart(int? value) {
    if (_selectionStart == value) return;
    _selectionStart = value;
    markNeedsPaint();
  }

  int? _selectionEnd;
  set selectionEnd(int? value) {
    if (_selectionEnd == value) return;
    _selectionEnd = value;
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

  bool _isEmpty;
  bool get isEmpty => _isEmpty;
  set isEmpty(bool value) {
    if (_isEmpty == value) return;
    _isEmpty = value;
    markNeedsLayout();
  }

  double _fontAscent = 0;
  double _fontDescent = 0;
  double _fontMetricsForSize = 0;

  void _ensureFontMetrics() {
    final effectiveSize = fontSize * _cursorScale;
    if (_fontMetricsForSize == effectiveSize) return;
    final tp = TextPainter(
      text: TextSpan(
        text: 'M',
        style: TextStyle(
          fontFamily: 'KaTeX_Main',
          fontSize: effectiveSize,
          package: 'math_view',
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    _fontAscent =
        tp.computeDistanceToActualBaseline(TextBaseline.alphabetic);
    _fontDescent = tp.height - _fontAscent;
    _fontMetricsForSize = effectiveSize;
    tp.dispose();
  }

  /// The cursor rectangle in local coordinates, or null if no cursor is active.
  ///
  /// Useful for testing that cursor position and height match Rust-provided values.
  Rect? get cursorRect {
    if (_cursorIndex == null) return null;
    _ensureFontMetrics();
    if (_isEmpty) {
      // Empty block: cursor centered horizontally, full placeholder height
      final x = size.width / 2;
      return Rect.fromLTRB(x, 0, x + 1.5, size.height);
    }
    final offsets = caretOffsets;
    final idx = _cursorIndex!;
    if (idx >= offsets.length) return null;
    final x = offsets[idx];
    final baselineY =
        maxHeightAboveBaseline - _cursorBaselineShift * fontSize;
    return Rect.fromLTRB(
        x, baselineY - _fontAscent, x + 1.5, baselineY + _fontDescent);
  }

  @override
  void performLayout() {
    super.performLayout();
    if (_isEmpty) {
      // MathQuill empty blocks: padding 0 .2em → total width 0.4em at scaled size.
      // Height from scaled font metrics (ascent + descent).
      _ensureFontMetrics();
      final scale = _cursorScale > 0 ? _cursorScale : 1.0;
      final w = fontSize * 0.4 * scale;
      final h = _fontAscent + _fontDescent;
      size = constraints.constrain(Size(w, h));
    }
  }

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) {
    if (_isEmpty) {
      _ensureFontMetrics();
      // Shift baseline so CommandWidget positions numer above / denom below
      return _fontAscent + _cursorBaselineShift * fontSize;
    }
    return super.computeDistanceToActualBaseline(baseline);
  }

  /// Accept taps on this block for cursor positioning.
  @override
  bool hitTestSelf(Offset position) => true;

  /// Find the caret index (gap position) nearest to a local x coordinate.
  int getCaretIndexForPoint(Offset local) {
    final offsets = caretOffsets;
    if (offsets.isEmpty) return 0;

    double bestDist = double.infinity;
    int bestIndex = 0;
    for (int i = 0; i < offsets.length; i++) {
      final dist = (local.dx - offsets[i]).abs();
      if (dist < bestDist) {
        bestDist = dist;
        bestIndex = i;
      }
    }
    return bestIndex;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    _ensureFontMetrics();
    final canvas = context.canvas;
    final offsets = caretOffsets;
    // Local glyph baseline: expression baseline shifted by glyph y-offset.
    final glyphBaselineY =
        offset.dy + maxHeightAboveBaseline - _cursorBaselineShift * fontSize;

    // Paint empty block placeholder (MathQuill-style small gray box)
    if (_isEmpty) {
      final r = fontSize * 0.04;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(offset.dx, offset.dy, size.width, size.height),
          Radius.circular(r),
        ),
        Paint()..color = const Color(0x33000000), // ~20% opacity black
      );

      // Cursor centered in placeholder box
      if (_cursorOpacity > 0 && _cursorIndex != null) {
        final x = offset.dx + size.width / 2;
        canvas.drawLine(
          Offset(x, offset.dy),
          Offset(x, offset.dy + size.height),
          Paint()
            ..color = _cursorColor.withValues(alpha: _cursorOpacity)
            ..strokeWidth = 1.5
            ..style = PaintingStyle.stroke,
        );
      }
      return; // No children or selection to paint
    }

    // 1. Paint selection highlight (before children)
    if (_selectionStart != null && _selectionEnd != null) {
      final start = _selectionStart!;
      final end = _selectionEnd!;
      if (start < offsets.length && end < offsets.length && start != end) {
        final left = offsets[start];
        final right = offsets[end];
        canvas.drawRect(
          Rect.fromLTWH(
            offset.dx + left,
            glyphBaselineY - _fontAscent,
            right - left,
            _fontAscent + _fontDescent,
          ),
          Paint()..color = _selectionColor,
        );
      }
    }

    // 2. Paint children
    defaultPaint(context, offset);

    // 3. Paint cursor at local glyph baseline
    if (_cursorOpacity > 0 && _cursorIndex != null) {
      final idx = _cursorIndex!;
      if (idx < offsets.length) {
        final x = offset.dx + offsets[idx];
        final cursorPaint = Paint()
          ..color = _cursorColor.withValues(alpha: _cursorOpacity)
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke;
        canvas.drawLine(
          Offset(x, glyphBaselineY - _fontAscent),
          Offset(x, glyphBaselineY + _fontDescent),
          cursorPaint,
        );
      }
    }
  }
}
