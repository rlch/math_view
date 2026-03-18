import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'render/editable_math_line.dart';
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
    );
    _focusNode.addListener(_onFocusChanged);
    if (widget.autofocus) {
      _cursorBlink.repeat(reverse: true);
    }
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus) {
      _cursorBlink.repeat(reverse: true);
    } else {
      _cursorBlink.stop();
      _cursorBlink.value = 0.0;
    }
    setState(() {});
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
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
    _cursorBlink.forward(from: 1.0);
    widget.onChanged?.call(snap.latex);
  }

  // ---------------------------------------------------------------------------
  // Keyboard
  // ---------------------------------------------------------------------------

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    final key = event.logicalKey;
    final shift = HardwareKeyboard.instance.isShiftPressed;
    final meta = HardwareKeyboard.instance.isMetaPressed ||
        HardwareKeyboard.instance.isControlPressed;

    // --- Command input mode ---
    if (_snapshot.inCommandInput) {
      if (key == LogicalKeyboardKey.backspace) {
        _dispatch(const EditorIntent.commandInputBackspace());
        return KeyEventResult.handled;
      }

      if (key == LogicalKeyboardKey.space ||
          key == LogicalKeyboardKey.tab ||
          key == LogicalKeyboardKey.enter) {
        _dispatch(const EditorIntent.resolveCommandInput());
        return KeyEventResult.handled;
      }

      if (key == LogicalKeyboardKey.escape) {
        _dispatch(const EditorIntent.cancelCommandInput());
        return KeyEventResult.handled;
      }

      if (event.character != null && event.character!.isNotEmpty && !meta) {
        final ch = event.character!;
        if (ch.codeUnitAt(0) >= 32) {
          _dispatch(EditorIntent.commandInputType(ch: ch));
          return KeyEventResult.handled;
        }
      }

      // Any other key cancels command input and falls through
      _dispatch(const EditorIntent.cancelCommandInput());
    }

    // --- Undo / Redo ---
    if (meta && key == LogicalKeyboardKey.keyZ) {
      _dispatch(shift
          ? const EditorIntent.redo()
          : const EditorIntent.undo());
      return KeyEventResult.handled;
    }

    // --- Copy / Cut / Paste ---
    if (meta && key == LogicalKeyboardKey.keyC) {
      _copySelection();
      return KeyEventResult.handled;
    }
    if (meta && key == LogicalKeyboardKey.keyX) {
      _cutSelection();
      return KeyEventResult.handled;
    }
    if (meta && key == LogicalKeyboardKey.keyV) {
      _pasteFromClipboard();
      return KeyEventResult.handled;
    }

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
    // LiveFraction: bare "/" wraps left content into numerator
    if (key == LogicalKeyboardKey.slash && !meta) {
      _dispatch(const EditorIntent.liveFraction());
      return KeyEventResult.handled;
    }

    // Space = escape right (MathQuill-style: exit current block)
    if (key == LogicalKeyboardKey.space && !meta) {
      _dispatch(const EditorIntent.escapeRight());
      return KeyEventResult.handled;
    }

    // Character input
    if (event.character != null && event.character!.isNotEmpty && !meta) {
      final ch = event.character!;
      if (ch.codeUnitAt(0) >= 32) {
        if (ch == '\\') {
          _dispatch(const EditorIntent.insertCommandInput());
          return KeyEventResult.handled;
        }
        _dispatch(EditorIntent.insertSymbol(ch: ch));
        return KeyEventResult.handled;
      }
    }

    return KeyEventResult.ignored;
  }

  // ---------------------------------------------------------------------------
  // Clipboard
  // ---------------------------------------------------------------------------

  void _copySelection() {
    final latex = getSelectedLatex(id: _editorId);
    if (latex.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: latex));
    }
  }

  void _cutSelection() {
    _copySelection();
    _dispatch(const EditorIntent.deleteBackward());
  }

  void _pasteFromClipboard() {
    // Clipboard.getData is async; handle result in microtask
    Clipboard.getData('text/plain').then((data) {
      if (data?.text != null && data!.text!.isNotEmpty && mounted) {
        _dispatch(EditorIntent.insertLatex(latex: data.text!));
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Pointer / Drag selection
  // ---------------------------------------------------------------------------

  /// Resolve a local widget position to (blockId, caretIndex) via hit testing.
  ({int blockId, int caretIndex})? _resolvePosition(Offset localPosition) {
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return null;

    final result = BoxHitTestResult();
    renderBox.hitTest(result, position: localPosition);

    for (final entry in result.path) {
      final target = entry.target;
      if (target is RenderEditableMathLine) {
        final localPos = target.globalToLocal(
          renderBox.localToGlobal(localPosition),
        );
        final caretIndex = target.getCaretIndexForPoint(localPos);
        return (blockId: target.blockId, caretIndex: caretIndex);
      }
    }
    return null;
  }

  void _onPanStart(DragStartDetails details) {
    _focusNode.requestFocus();
    final hit = _resolvePosition(details.localPosition);
    if (hit != null) {
      _dispatch(EditorIntent.dragStart(
        blockId: hit.blockId,
        caretIndex: hit.caretIndex,
      ));
    } else {
      _dispatch(const EditorIntent.moveToEnd());
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final hit = _resolvePosition(details.localPosition);
    if (hit != null) {
      _dispatch(EditorIntent.dragUpdate(
        blockId: hit.blockId,
        caretIndex: hit.caretIndex,
      ));
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final style = DefaultTextStyle.of(context).style;
    final fontSize = widget.fontSize ?? style.fontSize ?? 16.0;
    final color = widget.color ?? style.color ?? const Color(0xFF000000);
    final cursorColor = widget.cursorColor ?? const Color(0xFF0066FF);
    final selectionColor =
        widget.selectionColor ?? cursorColor.withValues(alpha: 0.3);

    return GestureDetector(
      // Pan gestures subsume taps: a tap is onPanStart + onPanEnd with no update.
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      child: Focus(
        focusNode: _focusNode,
        autofocus: widget.autofocus,
        onKeyEvent: _handleKey,
        child: AnimatedBuilder(
          animation: _cursorBlink,
          builder: (context, _) => MathBlockWidget(
            block: _snapshot.editorLayout.root,
            untaggedGlyphs: _snapshot.editorLayout.untagged,
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
