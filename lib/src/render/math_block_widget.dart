import 'package:flutter/widgets.dart';

import '../rust/api/editor_layout.dart';
import '../rust/api/math_api.dart';
import 'editable_math_line.dart';
import 'math_leaf.dart';
import 'math_line.dart';
import 'math_paint.dart';

/// Recursively builds the widget tree from a [BlockLayout].
///
/// All glyph coordinates are absolute em-units from katex-rs. Each block
/// widget paints its glyphs at their absolute positions scaled by [fontSize],
/// relative to the expression baseline.
///
/// The tree structure provides:
/// - Block-scoped cursor height (cursor fills only the block it's in)
/// - Block-scoped selection highlighting
/// - Proper hit testing (tap → block ID + caret index)
class MathBlockWidget extends StatelessWidget {
  final BlockLayout block;
  final bool isEditable;
  final double fontSize;
  final Color color;
  final Color cursorColor;
  final double cursorOpacity;
  final Color selectionColor;

  const MathBlockWidget({
    super.key,
    required this.block,
    required this.isEditable,
    required this.fontSize,
    required this.color,
    this.cursorColor = const Color(0xFF0066FF),
    this.cursorOpacity = 0.0,
    this.selectionColor = const Color(0x4D0066FF),
  });

  @override
  Widget build(BuildContext context) {
    // Collect all glyphs for this block's children into leaf/command widgets
    final children = <Widget>[];

    for (final node in block.children) {
      switch (node) {
        case NodeLayout_Leaf():
          children.add(MathLeaf(
            key: ValueKey('leaf_${node.nodeId}'),
            glyphs: node.glyphs,
            fontSize: fontSize,
            color: color,
          ));
        case NodeLayout_Command():
          children.add(_CommandWidget(
            key: ValueKey('cmd_${node.nodeId}'),
            command: node,
            isEditable: isEditable,
            fontSize: fontSize,
            color: color,
            cursorColor: cursorColor,
            cursorOpacity: cursorOpacity,
            selectionColor: selectionColor,
          ));
      }
    }

    if (isEditable) {
      return EditableMathLine(
        blockId: block.blockId,
        cursorIndex: block.cursorIndex,
        selectionStart: block.selection?.start,
        selectionEnd: block.selection?.end,
        cursorColor: cursorColor,
        cursorOpacity: cursorOpacity,
        selectionColor: selectionColor,
        children: children,
      );
    }

    return MathLine(children: children);
  }
}

/// Widget for a command node (frac, sqrt, sup, etc.).
///
/// Paints decorations (fraction bars, radical signs) and lays out child blocks.
/// Uses a [CustomPaint] for decorations overlaid on a [MathLine] containing
/// child block widgets.
///
/// Child blocks are wrapped in [MathBlockWidget] recursively, so the cursor
/// and selection are properly scoped when editing within nested structures.
class _CommandWidget extends StatelessWidget {
  final NodeLayout_Command command;
  final bool isEditable;
  final double fontSize;
  final Color color;
  final Color cursorColor;
  final double cursorOpacity;
  final Color selectionColor;

  const _CommandWidget({
    super.key,
    required this.command,
    required this.isEditable,
    required this.fontSize,
    required this.color,
    required this.cursorColor,
    required this.cursorOpacity,
    required this.selectionColor,
  });

  @override
  Widget build(BuildContext context) {
    // Build child block widgets
    final childBlockWidgets = command.childBlocks.map((b) => MathBlockWidget(
      key: ValueKey('block_${b.blockId}'),
      block: b,
      isEditable: isEditable,
      fontSize: fontSize,
      color: color,
      cursorColor: cursorColor,
      cursorOpacity: cursorOpacity,
      selectionColor: selectionColor,
    )).toList();

    // Build the command-specific layout
    Widget content;
    switch (command.kind) {
      case CommandLayoutKind_Frac():
        content = _buildFrac(childBlockWidgets);
      case CommandLayoutKind_Sqrt():
      case CommandLayoutKind_NthRoot():
        content = _buildSingleChild(childBlockWidgets);
      case CommandLayoutKind_Sup():
      case CommandLayoutKind_Sub():
      case CommandLayoutKind_SupSub():
        content = _buildSupSub(childBlockWidgets);
      case CommandLayoutKind_Overline():
      case CommandLayoutKind_Underline():
      case CommandLayoutKind_Text():
      case CommandLayoutKind_Other():
      case CommandLayoutKind_LeftRight():
        content = _buildSingleChild(childBlockWidgets);
      case CommandLayoutKind_SumLike():
        content = _buildSumLike(childBlockWidgets);
      case CommandLayoutKind_Matrix():
        content = _buildMatrix(childBlockWidgets);
    }

    // Overlay decorations (fraction bars, radical signs, delimiters)
    if (command.decorations.isNotEmpty) {
      return _DecorationOverlay(
        decorations: command.decorations,
        fontSize: fontSize,
        color: color,
        child: content,
      );
    }

    return content;
  }

  /// Fraction: numerator centered above, denominator centered below.
  Widget _buildFrac(List<Widget> children) {
    if (children.length < 2) return _buildSingleChild(children);

    return _FracLayout(
      fontSize: fontSize,
      numer: children[0],
      denom: children[1],
    );
  }

  /// Sup/sub: small blocks positioned above/below the baseline.
  Widget _buildSupSub(List<Widget> children) {
    if (children.isEmpty) return const SizedBox.shrink();

    switch (command.kind) {
      case CommandLayoutKind_Sup():
        // Single superscript — shift up
        return _SupSubLayout(
          fontSize: fontSize,
          sup: children.isNotEmpty ? children[0] : null,
          sub: null,
        );
      case CommandLayoutKind_Sub():
        // Single subscript — shift down
        return _SupSubLayout(
          fontSize: fontSize,
          sup: null,
          sub: children.isNotEmpty ? children[0] : null,
        );
      case CommandLayoutKind_SupSub():
        // Both — blocks[0] = sup, blocks[1] = sub
        return _SupSubLayout(
          fontSize: fontSize,
          sup: children.isNotEmpty ? children[0] : null,
          sub: children.length > 1 ? children[1] : null,
        );
      default:
        return _buildSingleChild(children);
    }
  }

  /// Sum-like: big operator with below/above limits stacked vertically.
  Widget _buildSumLike(List<Widget> children) {
    if (children.isEmpty) return const SizedBox.shrink();
    // blocks[0] = below, blocks[1] = above (if present)
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (children.length > 1) children[1], // above
        if (children.isNotEmpty) children[0],  // below
      ],
    );
  }

  /// Matrix: grid of child blocks.
  Widget _buildMatrix(List<Widget> children) {
    final kind = command.kind as CommandLayoutKind_Matrix;
    final cols = kind.cols;
    if (cols == 0 || children.isEmpty) return const SizedBox.shrink();

    final rows = <Widget>[];
    for (int i = 0; i < children.length; i += cols) {
      final end = (i + cols).clamp(0, children.length);
      rows.add(Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: children.sublist(i, end),
      ));
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: rows,
    );
  }

  /// Default: lay out children horizontally.
  Widget _buildSingleChild(List<Widget> children) {
    if (children.isEmpty) return const SizedBox.shrink();
    if (children.length == 1) return children.first;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: children,
    );
  }
}

/// Fraction layout: numerator on top, line in middle (via decoration), denom below.
///
/// Centers children horizontally and uses TeX-standard vertical spacing.
class _FracLayout extends StatelessWidget {
  final double fontSize;
  final Widget numer;
  final Widget denom;

  const _FracLayout({
    required this.fontSize,
    required this.numer,
    required this.denom,
  });

  @override
  Widget build(BuildContext context) {
    // TeX standard: ~0.12em gap between numerator/denominator and fraction bar
    final gap = 0.12 * fontSize;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        numer,
        SizedBox(height: gap),
        // Fraction bar is painted by the decoration overlay
        SizedBox(height: gap),
        denom,
      ],
    );
  }
}

/// Superscript/subscript layout using fractional vertical shifts.
class _SupSubLayout extends StatelessWidget {
  final double fontSize;
  final Widget? sup;
  final Widget? sub;

  const _SupSubLayout({
    required this.fontSize,
    this.sup,
    this.sub,
  });

  @override
  Widget build(BuildContext context) {
    // TeX standard shifts (approximate em values)
    const supShift = 0.4; // fraction of fontSize to shift up
    const subShift = 0.2; // fraction of fontSize to shift down

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (sup != null)
          Transform.translate(
            offset: Offset(0, -supShift * fontSize),
            child: sup,
          ),
        if (sub != null)
          Transform.translate(
            offset: Offset(0, subShift * fontSize),
            child: sub,
          ),
      ],
    );
  }
}

/// Overlays command decorations (fraction bars, radical signs, delimiters)
/// on top of child content.
class _DecorationOverlay extends StatelessWidget {
  final List<MathNode> decorations;
  final double fontSize;
  final Color color;
  final Widget child;

  const _DecorationOverlay({
    required this.decorations,
    required this.fontSize,
    required this.color,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: _DecorationPainter(
        decorations: decorations,
        fontSize: fontSize,
        color: color,
      ),
      child: child,
    );
  }
}

class _DecorationPainter extends CustomPainter {
  final List<MathNode> decorations;
  final double fontSize;
  final Color color;

  _DecorationPainter({
    required this.decorations,
    required this.fontSize,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Use the widget's center as approximate baseline reference.
    // For fraction bars, the bar should be roughly at vertical center.
    final baselineFromTop = size.height * 0.5;

    for (final node in decorations) {
      switch (node) {
        case MathNode_Glyph():
          MathPaint.paintGlyph(
            canvas, Offset.zero, baselineFromTop, fontSize, color, node,
          );
        case MathNode_Rule():
          MathPaint.paintRule(
            canvas, Offset.zero, baselineFromTop, fontSize, color, node,
          );
        case MathNode_SvgPath():
          MathPaint.paintSvgPath(
            canvas, Offset.zero, baselineFromTop, fontSize, color, node,
          );
      }
    }
  }

  @override
  bool shouldRepaint(_DecorationPainter oldDelegate) {
    return decorations != oldDelegate.decorations ||
        fontSize != oldDelegate.fontSize ||
        color != oldDelegate.color;
  }
}
