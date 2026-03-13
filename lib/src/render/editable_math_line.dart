import 'package:flutter/widgets.dart';

import 'math_line.dart';

/// An editable version of [MathLine] that paints cursor and selection
/// highlights scoped to the block's own height.
///
/// This mirrors flutter_math_fork's `RenderEditableLine`: it overrides
/// [hitTestSelf] to accept taps, provides [getCaretIndexForPoint] for
/// click-to-cursor resolution, and paints cursor/selection within the block.
class EditableMathLine extends MultiChildRenderObjectWidget {
  final int blockId;
  final int? cursorIndex;
  final int? selectionStart;
  final int? selectionEnd;
  final Color cursorColor;
  final double cursorOpacity;
  final Color selectionColor;

  const EditableMathLine({
    super.key,
    super.children,
    required this.blockId,
    this.cursorIndex,
    this.selectionStart,
    this.selectionEnd,
    required this.cursorColor,
    required this.cursorOpacity,
    required this.selectionColor,
  });

  @override
  RenderEditableMathLine createRenderObject(BuildContext context) {
    return RenderEditableMathLine(
      blockId: blockId,
      cursorIndex: cursorIndex,
      selectionStart: selectionStart,
      selectionEnd: selectionEnd,
      cursorColor: cursorColor,
      cursorOpacity: cursorOpacity,
      selectionColor: selectionColor,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    RenderEditableMathLine renderObject,
  ) {
    renderObject
      ..blockId = blockId
      ..cursorIndex = cursorIndex
      ..selectionStart = selectionStart
      ..selectionEnd = selectionEnd
      ..cursorColor = cursorColor
      ..cursorOpacity = cursorOpacity
      ..selectionColor = selectionColor;
  }
}

/// RenderBox that extends [RenderMathLine] behavior with editing visuals.
class RenderEditableMathLine extends RenderMathLine {
  RenderEditableMathLine({
    required int blockId,
    int? cursorIndex,
    int? selectionStart,
    int? selectionEnd,
    required Color cursorColor,
    required double cursorOpacity,
    required Color selectionColor,
  })  : _blockId = blockId,
        _cursorIndex = cursorIndex,
        _selectionStart = selectionStart,
        _selectionEnd = selectionEnd,
        _cursorColor = cursorColor,
        _cursorOpacity = cursorOpacity,
        _selectionColor = selectionColor;

  int _blockId;
  set blockId(int value) {
    if (_blockId == value) return;
    _blockId = value;
    markNeedsPaint();
  }

  int get blockId => _blockId;

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
    final canvas = context.canvas;
    final offsets = caretOffsets;

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
            offset.dy,
            right - left,
            size.height,
          ),
          Paint()..color = _selectionColor,
        );
      }
    }

    // 2. Paint children
    defaultPaint(context, offset);

    // 3. Paint cursor (after children)
    if (_cursorOpacity > 0 && _cursorIndex != null) {
      final idx = _cursorIndex!;
      if (idx < offsets.length) {
        final x = offset.dx + offsets[idx];
        final cursorPaint = Paint()
          ..color = _cursorColor.withValues(alpha: _cursorOpacity)
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke;
        canvas.drawLine(
          Offset(x, offset.dy),
          Offset(x, offset.dy + size.height),
          cursorPaint,
        );
      }
    }
  }
}
