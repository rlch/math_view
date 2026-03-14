# math_view

## Development Workflow

- **Always write a failing test first** before fixing any rendering or editor bug. The test should reproduce the issue, fail, and only pass after the fix is applied.
- Rust tests: `cd rust && cargo test`
- Flutter tests: `flutter test`
- After Rust changes, rebuild release dylib: `cd rust && cargo clean -p math_view --release && cargo build --release`
- Flutter tests load the RELEASE dylib first (`flutter_test_config.dart`), so always rebuild release after Rust changes.

## Architecture

- Rust arena-based math editor (`rust/src/editor/`) with Flutter rendering (`lib/src/render/`)
- Layout computed in Rust (`rust/src/api/editor_layout.rs`), rendered by Flutter widget tree
- `EditorLayout` → `BlockLayout` / `NodeLayout` hierarchy mirrors the arena
- Empty blocks get patched in `patch_empty_child_blocks()` for correct baseline_shift, font_scale, left_x
- Untagged glyphs (fraction bars, radical signs) painted by `_UntaggedPainter` overlay
