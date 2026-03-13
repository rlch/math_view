import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'render/math_block_widget.dart';
import 'rust/api/editor_api.dart';

/// An interactive structural math editor backed by a Rust arena reducer.
///
/// Users edit a math AST directly — not LaTeX strings. The cursor navigates
/// the tree structure (into fraction numerators, out of superscripts, etc.).
///
/// ```dart
/// MathEditor(
///   initialLatex: r'\frac{x+1}{2}',
///   displayMode: false,
///   fontSize: 24,
///   onChanged: (latex) => print(latex),
/// )
/// ```
class MathEditor extends StatefulWidget {
  /// Initial LaTeX expression to populate the editor.
  final String? initialLatex;

  /// Whether to render in display (block) mode.
  final bool displayMode;

  /// Font size in logical pixels.
  final double? fontSize;

  /// Text color.
  final Color? color;

  /// Cursor color.
  final Color? cursorColor;

  /// Selection highlight color.
  final Color? selectionColor;

  /// Called when the LaTeX content changes.
  final ValueChanged<String>? onChanged;

  /// Whether the editor should autofocus.
  final bool autofocus;

  const MathEditor({
    super.key,
    this.initialLatex,
    this.displayMode = false,
    this.fontSize,
    this.color,
    this.cursorColor,
    this.selectionColor,
    this.onChanged,
    this.autofocus = false,
  });

  @override
  State<MathEditor> createState() => _MathEditorState();
}

class _MathEditorState extends State<MathEditor> with TickerProviderStateMixin {
  late String _editorId;
  late EditorSnapshot _snapshot;
  late AnimationController _cursorBlink;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _editorId = widget.initialLatex != null
        ? createEditorFromLatex(latex: widget.initialLatex!)
        : createEditor();
    _snapshot = getEditorSnapshot(
      id: _editorId,
      displayMode: widget.displayMode,
    );
    _cursorBlink = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 530),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _cursorBlink.dispose();
    _focusNode.dispose();
    closeEditor(id: _editorId);
    super.dispose();
  }

  void _dispatch(EditorIntent intent) {
    final snap = dispatchEditor(
      id: _editorId,
      intent: intent,
      displayMode: widget.displayMode,
    );
    setState(() => _snapshot = snap);
    _cursorBlink.forward(from: 1.0); // Reset blink on edit
    widget.onChanged?.call(snap.latex);
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    final key = event.logicalKey;
    final shift = HardwareKeyboard.instance.isShiftPressed;
    final meta = HardwareKeyboard.instance.isMetaPressed ||
        HardwareKeyboard.instance.isControlPressed;

    // Navigation
    if (key == LogicalKeyboardKey.arrowLeft) {
      _dispatch(shift
          ? const EditorIntent.selectLeft()
          : const EditorIntent.moveLeft());
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowRight) {
      _dispatch(shift
          ? const EditorIntent.selectRight()
          : const EditorIntent.moveRight());
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowUp) {
      _dispatch(const EditorIntent.moveUp());
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowDown) {
      _dispatch(const EditorIntent.moveDown());
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.home || (meta && key == LogicalKeyboardKey.arrowLeft)) {
      _dispatch(const EditorIntent.moveToStart());
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.end || (meta && key == LogicalKeyboardKey.arrowRight)) {
      _dispatch(const EditorIntent.moveToEnd());
      return KeyEventResult.handled;
    }

    // Select all
    if (meta && key == LogicalKeyboardKey.keyA) {
      _dispatch(const EditorIntent.selectAll());
      return KeyEventResult.handled;
    }

    // Deletion
    if (key == LogicalKeyboardKey.backspace) {
      _dispatch(const EditorIntent.deleteBackward());
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.delete) {
      _dispatch(const EditorIntent.deleteForward());
      return KeyEventResult.handled;
    }

    // Structural shortcuts
    if (key == LogicalKeyboardKey.slash && meta) {
      _dispatch(const EditorIntent.insertFrac());
      return KeyEventResult.handled;
    }

    // Character input
    if (event.character != null && event.character!.isNotEmpty && !meta) {
      final ch = event.character!;
      // Filter out control characters
      if (ch.codeUnitAt(0) >= 32) {
        _dispatch(EditorIntent.insertSymbol(ch: ch));
        return KeyEventResult.handled;
      }
    }

    return KeyEventResult.ignored;
  }

  void _handleTapDown(TapDownDetails details) {
    _focusNode.requestFocus();
    _handleWidgetTreeTap(details.localPosition);
  }

  void _handleWidgetTreeTap(Offset localPosition) {
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final result = BoxHitTestResult();
    renderBox.hitTest(result, position: localPosition);

    for (final entry in result.path) {
      final target = entry.target;
      if (target is RenderMathBlock) {
        final localPos = target.globalToLocal(
          renderBox.localToGlobal(localPosition),
        );
        final (blockId, caretIndex) = target.hitTestForCaret(localPos);
        _dispatch(EditorIntent.tapBlock(
          blockId: blockId,
          caretIndex: caretIndex,
        ));
        return;
      }
    }

    _dispatch(const EditorIntent.moveToEnd());
  }

  @override
  Widget build(BuildContext context) {
    final style = DefaultTextStyle.of(context).style;
    final fontSize = widget.fontSize ?? style.fontSize ?? 16.0;
    final color = widget.color ?? style.color ?? const Color(0xFF000000);
    final cursorColor = widget.cursorColor ?? const Color(0xFF0066FF);
    final selectionColor =
        widget.selectionColor ?? cursorColor.withValues(alpha: 0.3);

    return GestureDetector(
      onTapDown: _handleTapDown,
      child: Focus(
        focusNode: _focusNode,
        autofocus: widget.autofocus,
        onKeyEvent: _handleKey,
        child: AnimatedBuilder(
          animation: _cursorBlink,
          builder: (context, _) => MathBlockWidget(
            block: _snapshot.editorLayout.root,
            isEditable: true,
            fontSize: fontSize,
            color: color,
            cursorColor: cursorColor,
            cursorOpacity: _focusNode.hasFocus ? _cursorBlink.value : 0.0,
            selectionColor: selectionColor,
          ),
        ),
      ),
    );
  }
}
