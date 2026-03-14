import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';

import 'font_mapping.dart';
import 'rust/api/math_api.dart';

/// A [RenderBox] that paints pre-positioned math layout nodes from katex-rs.
///
/// All layout computation is done in Rust. This render object simply paints
/// glyphs via [TextPainter], rules via [Canvas.drawRect], and stretchy paths
/// via [Canvas.drawPath] from pre-parsed path commands.
class RenderMath extends RenderBox {
  RenderMath({
    required String latex,
    required bool displayMode,
    required double fontSize,
    required Color color,
  })  : _latex = latex,
        _displayMode = displayMode,
        _fontSize = fontSize,
        _color = color;

  MathLayout? _layout;

  String _latex;
  String get latex => _latex;
  set latex(String value) {
    if (_latex == value) return;
    _latex = value;
    _layout = null;
    markNeedsLayout();
  }

  bool _displayMode;
  bool get displayMode => _displayMode;
  set displayMode(bool value) {
    if (_displayMode == value) return;
    _displayMode = value;
    _layout = null;
    markNeedsLayout();
  }

  double _fontSize;
  double get fontSize => _fontSize;
  set fontSize(double value) {
    if (_fontSize == value) return;
    _fontSize = value;
    markNeedsLayout();
  }

  Color _color;
  Color get color => _color;
  set color(Color value) {
    if (_color == value) return;
    _color = value;
    markNeedsPaint();
  }

  bool _debugBaseline = false;
  bool get debugBaseline => _debugBaseline;
  set debugBaseline(bool value) {
    if (_debugBaseline == value) return;
    _debugBaseline = value;
    markNeedsPaint();
  }

  MathLayout _ensureLayout() {
    return _layout ??=
        layoutMath(latex: _latex, displayMode: _displayMode);
  }

  // Cache the primary font's natural ascent/descent at the current fontSize.
  // This ensures our widget is at least as tall as a line of text in the
  // primary math font, so WidgetSpan baseline alignment works correctly.
  double? _cachedFontAscent;
  double? _cachedFontDescent;
  double _cachedForFontSize = 0;

  void _ensureFontMetrics() {
    if (_cachedForFontSize == _fontSize) return;
    final tp = TextPainter(
      text: TextSpan(
        text: 'M', // Use 'M' — full ascent reference
        style: TextStyle(
          fontFamily: 'KaTeX_Main',
          fontSize: _fontSize,
          package: 'math_view',
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    _cachedFontAscent = tp.computeDistanceToActualBaseline(
            TextBaseline.alphabetic) ??
        _fontSize * 0.75;
    _cachedFontDescent = tp.height - _cachedFontAscent!;
    _cachedForFontSize = _fontSize;
    tp.dispose();
  }

  /// The pixel distance from the widget's top to the math baseline.
  /// Uses the larger of katex-rs's computed height and the primary font's
  /// natural ascent, so that inline math aligns with surrounding text.
  double get _baselineFromTop {
    final l = _ensureLayout();
    _ensureFontMetrics();
    return math.max(l.height * _fontSize, _cachedFontAscent!);
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    final l = _ensureLayout();
    return l.width * _fontSize;
  }

  @override
  double computeMaxIntrinsicWidth(double height) =>
      computeMinIntrinsicWidth(height);

  @override
  double computeMinIntrinsicHeight(double width) {
    final l = _ensureLayout();
    _ensureFontMetrics();
    final ascent = math.max(l.height * _fontSize, _cachedFontAscent!);
    final descent = math.max(l.depth * _fontSize, _cachedFontDescent!);
    return ascent + descent;
  }

  @override
  double computeMaxIntrinsicHeight(double width) =>
      computeMinIntrinsicHeight(width);

  @override
  void performLayout() {
    final l = _ensureLayout();
    _ensureFontMetrics();
    final ascent = math.max(l.height * _fontSize, _cachedFontAscent!);
    final descent = math.max(l.depth * _fontSize, _cachedFontDescent!);
    size = constraints.constrain(Size(l.width * _fontSize, ascent + descent));
  }

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) =>
      _baselineFromTop;

  @override
  double? computeDryBaseline(
      covariant BoxConstraints constraints, TextBaseline baseline) =>
      _baselineFromTop;

  @override
  void paint(PaintingContext context, Offset offset) {
    final l = _ensureLayout();
    final canvas = context.canvas;
    final baselineFromTop = _baselineFromTop;

    for (final node in l.nodes) {
      switch (node) {
        case MathNode_Glyph():
          _paintGlyph(canvas, offset, baselineFromTop, node);
        case MathNode_Rule():
          _paintRule(canvas, offset, baselineFromTop, node);
        case MathNode_SvgPath():
          _paintSvgPath(canvas, offset, baselineFromTop, node);
      }
    }

    if (_debugBaseline) {
      final paint = Paint()..strokeWidth = 1;
      paint.color = const Color(0x400000FF);
      canvas.drawRect(
        Rect.fromLTWH(offset.dx, offset.dy, size.width, size.height),
        paint,
      );
      paint.color = const Color(0xFFFF0000);
      canvas.drawLine(
        Offset(offset.dx, offset.dy + baselineFromTop),
        Offset(offset.dx + size.width, offset.dy + baselineFromTop),
        paint,
      );
    }
  }

  void _paintGlyph(
    ui.Canvas canvas,
    Offset offset,
    double baselineFromTop,
    MathNode_Glyph glyph,
  ) {
    final fontInfo =
        katexFontMap[glyph.fontName] ?? katexFontMap['Main-Regular']!;
    final glyphColor = glyph.color != null
        ? _parseColor(glyph.color!) ?? _color
        : _color;

    final tp = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(glyph.codepoint),
        style: TextStyle(
          fontFamily: fontInfo.family,
          fontWeight: fontInfo.weight,
          fontStyle: fontInfo.style,
          fontSize: glyph.scale * _fontSize,
          color: glyphColor,
          letterSpacing: 0,
          package: 'math_view',
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();

    // Position glyph so its baseline aligns with the target y-coordinate.
    // katex-rs glyph.y is baseline-relative (positive = above expression baseline).
    final ascent = tp.computeDistanceToActualBaseline(TextBaseline.alphabetic) ??
        tp.height;
    final dx = offset.dx + glyph.x * _fontSize;
    final dy = offset.dy + baselineFromTop - glyph.y * _fontSize - ascent;

    tp.paint(canvas, Offset(dx, dy));
    tp.dispose();
  }

  void _paintRule(
    ui.Canvas canvas,
    Offset offset,
    double baselineFromTop,
    MathNode_Rule rule,
  ) {
    final ruleColor = rule.color != null
        ? _parseColor(rule.color!) ?? _color
        : _color;

    final paint = Paint()..color = ruleColor;
    final rect = Rect.fromLTWH(
      offset.dx + rule.x * _fontSize,
      offset.dy + baselineFromTop - rule.y * _fontSize - rule.height * _fontSize,
      rule.width * _fontSize,
      rule.height * _fontSize,
    );
    canvas.drawRect(rect, paint);
  }

  void _paintSvgPath(
    ui.Canvas canvas,
    Offset offset,
    double baselineFromTop,
    MathNode_SvgPath svgPath,
  ) {
    if (svgPath.commands.isEmpty) return;

    final displayWidth = svgPath.width * _fontSize;
    final displayHeight = svgPath.height * _fontSize;

    // Build Flutter Path from pre-parsed commands.
    final path = ui.Path();
    for (final cmd in svgPath.commands) {
      switch (cmd) {
        case PathCommand_MoveTo(:final x, :final y):
          path.moveTo(x, y);
        case PathCommand_LineTo(:final x, :final y):
          path.lineTo(x, y);
        case PathCommand_CubicTo(:final x1, :final y1, :final x2, :final y2, :final x, :final y):
          path.cubicTo(x1, y1, x2, y2, x, y);
        case PathCommand_QuadTo(:final x1, :final y1, :final x, :final y):
          path.quadraticBezierTo(x1, y1, x, y);
        case PathCommand_Close():
          path.close();
      }
    }

    // Position: top-left corner in pixel space.
    final dx = offset.dx + svgPath.x * _fontSize;
    final dy = offset.dy + baselineFromTop - svgPath.y * _fontSize - displayHeight;

    canvas.save();
    canvas.clipRect(Rect.fromLTWH(dx, dy, displayWidth, displayHeight));

    // Transform from viewBox coords to display coords.
    final scaleY = displayHeight / svgPath.viewBoxHeight;
    final scale = scaleY.isFinite ? scaleY : displayWidth / svgPath.viewBoxWidth;

    canvas.translate(dx - svgPath.viewBoxX * scale, dy - svgPath.viewBoxY * scale);
    canvas.scale(scale);

    canvas.drawPath(path, Paint()..color = _color);
    canvas.restore();
  }

  static Color? _parseColor(String css) {
    if (css.startsWith('#')) {
      final hex = css.substring(1);
      if (hex.length == 6) {
        final value = int.tryParse(hex, radix: 16);
        if (value != null) return Color(0xFF000000 | value);
      } else if (hex.length == 3) {
        final r = hex[0], g = hex[1], b = hex[2];
        final value = int.tryParse('$r$r$g$g$b$b', radix: 16);
        if (value != null) return Color(0xFF000000 | value);
      }
    }
    return null;
  }

  @override
  bool get sizedByParent => false;
}
