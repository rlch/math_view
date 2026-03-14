import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import '../font_mapping.dart';
import '../rust/api/math_api.dart';

/// Shared painting utilities for math layout nodes.
///
/// Used by both [RenderMathLeaf] (widget tree path) and the legacy
/// [RenderMath] / [RenderMathEditorBox] (flat rendering path).
abstract final class MathPaint {
  /// Paint a glyph node at baseline-relative coordinates.
  static void paintGlyph(
    ui.Canvas canvas,
    Offset offset,
    double baselineFromTop,
    double fontSize,
    Color defaultColor,
    MathNode_Glyph glyph,
  ) {
    final fontInfo =
        katexFontMap[glyph.fontName] ?? katexFontMap['Main-Regular']!;
    final glyphColor = glyph.color != null
        ? parseColor(glyph.color!) ?? defaultColor
        : defaultColor;

    final tp = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(glyph.codepoint),
        style: TextStyle(
          fontFamily: fontInfo.family,
          fontWeight: fontInfo.weight,
          fontStyle: fontInfo.style,
          fontSize: glyph.scale * fontSize,
          color: glyphColor,
          letterSpacing: 0,
          height: 1.0,
          leadingDistribution: TextLeadingDistribution.even,
          package: 'math_view',
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();

    final ascent =
        tp.computeDistanceToActualBaseline(TextBaseline.alphabetic);
    final dx = offset.dx + glyph.x * fontSize;
    final dy = offset.dy + baselineFromTop - glyph.y * fontSize - ascent;
    tp.paint(canvas, Offset(dx, dy));
    tp.dispose();
  }

  /// Paint a rule (fraction bar, overline, etc.) node.
  static void paintRule(
    ui.Canvas canvas,
    Offset offset,
    double baselineFromTop,
    double fontSize,
    Color defaultColor,
    MathNode_Rule rule,
  ) {
    final ruleColor = rule.color != null
        ? parseColor(rule.color!) ?? defaultColor
        : defaultColor;

    final paint = Paint()..color = ruleColor;
    final rect = Rect.fromLTWH(
      offset.dx + rule.x * fontSize,
      offset.dy + baselineFromTop - rule.y * fontSize - rule.height * fontSize,
      rule.width * fontSize,
      rule.height * fontSize,
    );
    canvas.drawRect(rect, paint);
  }

  /// Paint an SVG path node (radical signs, large delimiters, wide accents).
  static void paintSvgPath(
    ui.Canvas canvas,
    Offset offset,
    double baselineFromTop,
    double fontSize,
    Color defaultColor,
    MathNode_SvgPath svgPath,
  ) {
    if (svgPath.commands.isEmpty) return;

    final displayWidth = svgPath.width * fontSize;
    final displayHeight = svgPath.height * fontSize;

    final path = ui.Path();
    for (final cmd in svgPath.commands) {
      switch (cmd) {
        case PathCommand_MoveTo(:final x, :final y):
          path.moveTo(x, y);
        case PathCommand_LineTo(:final x, :final y):
          path.lineTo(x, y);
        case PathCommand_CubicTo(
          :final x1,
          :final y1,
          :final x2,
          :final y2,
          :final x,
          :final y
        ):
          path.cubicTo(x1, y1, x2, y2, x, y);
        case PathCommand_QuadTo(:final x1, :final y1, :final x, :final y):
          path.quadraticBezierTo(x1, y1, x, y);
        case PathCommand_Close():
          path.close();
      }
    }

    final dx = offset.dx + svgPath.x * fontSize;
    final dy =
        offset.dy + baselineFromTop - svgPath.y * fontSize - displayHeight;

    canvas.save();
    canvas.clipRect(Rect.fromLTWH(dx, dy, displayWidth, displayHeight));

    final scaleY = displayHeight / svgPath.viewBoxHeight;
    final scale =
        scaleY.isFinite ? scaleY : displayWidth / svgPath.viewBoxWidth;

    canvas.translate(
      dx - svgPath.viewBoxX * scale,
      dy - svgPath.viewBoxY * scale,
    );
    canvas.scale(scale);

    canvas.drawPath(path, Paint()..color = defaultColor);
    canvas.restore();
  }

  /// Parse a CSS color string (#rgb or #rrggbb) into a Flutter [Color].
  static Color? parseColor(String css) {
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

  /// Measure a single glyph's width using [TextPainter].
  static double measureGlyphWidth(MathNode_Glyph glyph, double fontSize) {
    final fontInfo =
        katexFontMap[glyph.fontName] ?? katexFontMap['Main-Regular']!;
    final tp = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(glyph.codepoint),
        style: TextStyle(
          fontFamily: fontInfo.family,
          fontWeight: fontInfo.weight,
          fontStyle: fontInfo.style,
          fontSize: glyph.scale * fontSize,
          letterSpacing: 0,
          height: 1.0,
          leadingDistribution: TextLeadingDistribution.even,
          package: 'math_view',
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    final width = tp.width;
    tp.dispose();
    return width;
  }
}
