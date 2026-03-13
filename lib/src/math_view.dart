import 'package:flutter/widgets.dart';

import 'render/math_block_widget.dart';
import 'render_math.dart';
import 'rust/api/editor_layout.dart';
import 'rust/api/math_api.dart';

/// Renders a LaTeX math expression using katex-rs layout + Flutter canvas.
///
/// All layout computation happens in Rust. This widget simply paints the
/// pre-positioned glyphs, rules, and SVG paths using KaTeX fonts.
///
/// When [selectable] is true, builds a widget tree from the hierarchical
/// layout, enabling text selection via Flutter's [SelectionArea].
///
/// ```dart
/// MathView(
///   latex: r'\frac{-b \pm \sqrt{b^2 - 4ac}}{2a}',
///   displayMode: true,
///   fontSize: 20,
/// )
/// ```
class MathView extends StatelessWidget {
  /// The LaTeX expression to render.
  final String latex;

  /// Whether to render in display (block) mode.
  /// When false, renders in inline mode.
  final bool displayMode;

  /// Font size in logical pixels. Defaults to the ambient [DefaultTextStyle]
  /// font size, or 16 if none.
  final double? fontSize;

  /// Text color. Defaults to the ambient [DefaultTextStyle] color, or black.
  final Color? color;

  /// Draw debug baseline and bounding box overlay.
  final bool debugBaseline;

  /// Whether the math content is selectable.
  /// When false (default), uses the fast single-paint [RenderMath] path.
  /// When true, builds a widget tree and wraps in [SelectionArea].
  final bool selectable;

  const MathView({
    super.key,
    required this.latex,
    this.displayMode = false,
    this.fontSize,
    this.color,
    this.debugBaseline = false,
    this.selectable = false,
  });

  @override
  Widget build(BuildContext context) {
    if (selectable) {
      return _SelectableMathView(
        latex: latex,
        displayMode: displayMode,
        fontSize: fontSize,
        color: color,
      );
    }

    return _FastMathView(
      latex: latex,
      displayMode: displayMode,
      fontSize: fontSize,
      color: color,
      debugBaseline: debugBaseline,
    );
  }
}

/// Fast path: single [RenderMath] LeafRenderObjectWidget (unchanged behavior).
class _FastMathView extends LeafRenderObjectWidget {
  final String latex;
  final bool displayMode;
  final double? fontSize;
  final Color? color;
  final bool debugBaseline;

  const _FastMathView({
    required this.latex,
    required this.displayMode,
    this.fontSize,
    this.color,
    this.debugBaseline = false,
  });

  @override
  RenderMath createRenderObject(BuildContext context) {
    final style = DefaultTextStyle.of(context).style;
    return RenderMath(
      latex: latex,
      displayMode: displayMode,
      fontSize: fontSize ?? style.fontSize ?? 16,
      color: color ?? style.color ?? const Color(0xFF000000),
    )..debugBaseline = debugBaseline;
  }

  @override
  void updateRenderObject(BuildContext context, RenderMath renderObject) {
    final style = DefaultTextStyle.of(context).style;
    renderObject
      ..latex = latex
      ..displayMode = displayMode
      ..fontSize = fontSize ?? style.fontSize ?? 16
      ..color = color ?? style.color ?? const Color(0xFF000000)
      ..debugBaseline = debugBaseline;
  }
}

/// Selectable path: builds widget tree from hierarchical layout.
class _SelectableMathView extends StatelessWidget {
  final String latex;
  final bool displayMode;
  final double? fontSize;
  final Color? color;

  const _SelectableMathView({
    required this.latex,
    required this.displayMode,
    this.fontSize,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final style = DefaultTextStyle.of(context).style;
    final fs = fontSize ?? style.fontSize ?? 16.0;
    final c = color ?? style.color ?? const Color(0xFF000000);

    final EditorLayout layout = layoutMathTree(
      latex: latex,
      displayMode: displayMode,
    );

    return MathBlockWidget(
      block: layout.root,
      untaggedGlyphs: layout.untagged,
      isEditable: false,
      fontSize: fs,
      color: c,
    );
  }
}
