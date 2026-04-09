# math_view

A Flutter plugin for rendering and editing mathematical expressions, powered by a Rust engine built on [katex-rs](https://github.com/nickmass/katex-rs) and KaTeX fonts.

## Features

**MathView** — read-only LaTeX rendering with two modes:
- **Fast path**: single canvas paint, maximum performance
- **Selectable path**: widget tree with Flutter `SelectionArea` support

**MathEditor** — structural math editor:
- Direct AST editing (not string manipulation)
- Cursor navigation into fractions, superscripts, radicals, matrices, etc.
- LaTeX command input (`\frac`, `\alpha`, ...)
- LiveFraction: type `/` to wrap preceding content into a fraction
- Auto-subscript: `x2` becomes `x_{2}`
- Auto-operator detection: `sin`, `cos`, `log`, and 30+ more
- Copy/cut/paste LaTeX, undo/redo (100 levels)
- Mouse click-to-cursor and drag selection
- Keyboard selection with Shift+Arrow

**Supported math constructs**: fractions, superscripts, subscripts, square/nth roots, parentheses, brackets, braces, absolute value, summation, product, integral, limit, overline/underline, accents, overbrace/underbrace, extensible arrows, matrices, text mode, colors, font styles, sizing commands, phantom elements.

See [FEATURE_PARITY.md](FEATURE_PARITY.md) for a detailed comparison with MathQuill.

## Usage

```dart
import 'package:math_view/math_view.dart';

// Read-only rendering
MathView(
  latex: r'\frac{-b \pm \sqrt{b^2 - 4ac}}{2a}',
  displayMode: true,
  fontSize: 20,
  color: Colors.black,
)

// Selectable rendering
MathView(
  latex: r'\int_0^\infty e^{-x} \, dx = 1',
  displayMode: true,
  fontSize: 20,
  selectable: true,
)

// Interactive editor
MathEditor(
  initialLatex: r'\frac{x+1}{2}',
  displayMode: false,
  fontSize: 24,
  onChanged: (latex) => print(latex),
  autofocus: true,
)
```

## Architecture

```
User Input (keyboard/mouse)
        │
   Flutter: MathEditor
        │
   Rust FFI (flutter_rust_bridge)
        │
   Arena-based AST ──► Reducer (intent → state)
        │
   EditorSnapshot (layout tree + LaTeX)
        │
   Flutter: Widget tree rendering
        ├── Glyph painting (KaTeX fonts)
        ├── SVG path rendering (radicals, arrows)
        └── Cursor / selection overlays
```

**Rust** (`rust/src/`) handles all structural editing and layout:
- `editor/arena.rs` — doubly-linked tree AST with `BlockId`/`NodeId` indices
- `editor/reduce.rs` — pure state reducer that applies editing intents
- `editor/navigate.rs` — cursor movement through the tree
- `editor/convert.rs` — LaTeX string to arena deserialization
- `editor/serialize.rs` — arena to LaTeX serialization
- `api/editor_api.rs` — FFI entry point, editor registry, undo/redo stack
- `api/editor_layout.rs` — builds hierarchical layout from arena for Flutter
- `api/math_api.rs` — katex-rs integration for read-only rendering

**Flutter** (`lib/src/`) handles rendering and interaction:
- `math_view.dart` — `MathView` widget (read-only)
- `math_editor.dart` — `MathEditor` widget (interactive)
- `render_math.dart` — `RenderMath` render object (flat canvas path)
- `render/math_block_widget.dart` — recursive widget tree builder
- `render/editable_math_line.dart` — cursor/selection painting
- `render/math_paint.dart` — shared painting utilities
- `font_mapping.dart` — KaTeX font to Flutter font mapping

All coordinates flow from Rust in **em** units; Flutter multiplies by `fontSize` for pixels.

## Project Structure

```
math_view/
├── lib/
│   ├── math_view.dart              # Public API exports
│   └── src/
│       ├── math_view.dart          # MathView widget
│       ├── math_editor.dart        # MathEditor widget
│       ├── render_math.dart        # Flat canvas renderer
│       ├── font_mapping.dart       # KaTeX font mapping
│       ├── render/                 # Widget tree rendering
│       └── rust/                   # Auto-generated FFI bindings
├── rust/
│   └── src/
│       ├── api/                    # FFI bridge layer
│       └── editor/                 # Core editing engine
├── fonts/                          # 22 KaTeX font files (TTF)
├── test/                           # Flutter widget & integration tests
├── example/                        # Demo app
└── cargokit/                       # Rust build orchestration
```

## Development

### Prerequisites

- Flutter SDK >= 3.3.0 / Dart SDK >= 3.11.1
- Rust toolchain (rustc, cargo)
- Platform-specific compilers (clang on macOS/Linux, MSVC on Windows)

### Commands

```bash
# Rust tests
cd rust && cargo test

# Flutter tests
flutter test

# After Rust changes, rebuild the release dylib
# (Flutter tests load the release build via flutter_test_config.dart)
cd rust && cargo clean -p math_view --release && cargo build --release

# Run the example app
cd example && flutter run
```

### Workflow

Always write a failing test first before fixing any rendering or editor bug. The test should reproduce the issue, fail, and then pass after the fix is applied.

## Platforms

iOS, Android, macOS, Linux, Windows — via Flutter FFI plugin with Cargokit build integration.
