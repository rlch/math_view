use std::collections::HashMap;
use std::sync::Mutex;

use flutter_rust_bridge::frb;

use crate::api::editor_layout::{build_editor_layout, BlockLayout, EditorLayout};
use crate::api::math_api::MathLayout;
use crate::editor;

// ---------------------------------------------------------------------------
// Registry — editors live in Rust, Dart holds an ID string
// ---------------------------------------------------------------------------

static EDITORS: Mutex<Option<HashMap<String, EditorEntry>>> = Mutex::new(None);

struct EditorEntry {
    state: editor::State,
    undo_stack: Vec<editor::State>,
    redo_stack: Vec<editor::State>,
}

const MAX_UNDO: usize = 100;

fn with_registry<R>(f: impl FnOnce(&mut HashMap<String, EditorEntry>) -> R) -> R {
    let mut guard = EDITORS.lock().unwrap();
    let map = guard.get_or_insert_with(HashMap::new);
    f(map)
}

fn next_id() -> String {
    use std::sync::atomic::{AtomicU64, Ordering};
    static COUNTER: AtomicU64 = AtomicU64::new(0);
    format!("editor_{}", COUNTER.fetch_add(1, Ordering::Relaxed))
}

// ---------------------------------------------------------------------------
// Snapshot — non_opaque, Dart receives the full struct
// ---------------------------------------------------------------------------

/// Snapshot of the editor state, returned after every dispatch.
#[frb(non_opaque)]
#[derive(Clone, Debug)]
pub struct EditorSnapshot {
    /// Hierarchical layout tree for widget-tree rendering.
    pub editor_layout: EditorLayout,
    /// Current LaTeX string.
    pub latex: String,
    /// Whether the cursor is in command input mode (inside a LatexCommandInput node).
    pub in_command_input: bool,
}

// ---------------------------------------------------------------------------
// Intent — non_opaque, Dart constructs and passes to dispatch
// ---------------------------------------------------------------------------

#[frb(non_opaque)]
#[derive(Clone, Debug)]
pub enum EditorIntent {
    InsertSymbol { ch: String },
    InsertFrac,
    /// MathQuill-style LiveFraction: wrap left content into numerator, cursor in denominator.
    LiveFraction,
    InsertSqrt,
    InsertNthRoot,
    InsertSup,
    InsertSub,
    InsertParentheses,
    InsertBrackets,
    InsertBraces,
    InsertAbs,
    InsertSum,
    InsertProduct,
    InsertIntegral,
    InsertLimit,
    InsertOverline,
    InsertUnderline,
    InsertText,
    /// Begin command input mode: insert LatexCommandInput node.
    InsertCommandInput,
    /// Append a character to the active command input.
    CommandInputType { ch: String },
    /// Remove last character from command input, or remove it if empty.
    CommandInputBackspace,
    /// Resolve the active command input (extract name, insert command/symbol).
    ResolveCommandInput,
    /// Cancel command input mode (remove the node).
    CancelCommandInput,
    MoveLeft,
    MoveRight,
    /// Space key: exit current block to the right (MathQuill-style).
    EscapeRight,
    MoveUp,
    MoveDown,
    MoveToStart,
    MoveToEnd,
    SelectLeft,
    SelectRight,
    SelectAll,
    DeleteBackward,
    DeleteForward,
    SetLatex { latex: String },
    /// Insert parsed LaTeX at cursor (paste).
    InsertLatex { latex: String },
    TapBlock { block_id: u32, caret_index: u32 },
    /// Begin drag selection: set anchor and cursor.
    DragStart { block_id: u32, caret_index: u32 },
    /// Continue drag selection: move cursor, keep anchor.
    DragUpdate { block_id: u32, caret_index: u32 },
    Undo,
    Redo,
}

// ---------------------------------------------------------------------------
// FRB API — thin, follows modality dispatch pattern
// ---------------------------------------------------------------------------

/// Create a new empty math editor. Returns an editor ID.
#[frb(sync)]
pub fn create_editor() -> String {
    let id = next_id();
    with_registry(|map| {
        map.insert(id.clone(), EditorEntry { state: editor::State::new(), undo_stack: Vec::new(), redo_stack: Vec::new() });
    });
    id
}

/// Create a math editor pre-populated with LaTeX. Returns an editor ID.
#[frb(sync)]
pub fn create_editor_from_latex(latex: String) -> String {
    let id = next_id();
    let state = editor::convert::import_latex(&latex).unwrap_or_else(|_| editor::State::new());
    with_registry(|map| {
        map.insert(id.clone(), EditorEntry { state, undo_stack: Vec::new(), redo_stack: Vec::new() });
    });
    id
}

/// Get the LaTeX of the current selection (for copy). Empty string if no selection.
#[frb(sync)]
pub fn get_selected_latex(id: String) -> String {
    with_registry(|map| {
        let entry = match map.get(&id) {
            Some(e) => e,
            None => return String::new(),
        };
        let sel = match &entry.state.selection {
            Some(s) => s,
            None => return String::new(),
        };
        let (left, right) = editor::reduce::order_cursors_pub(
            &sel.anticursor, &entry.state.cursor, &entry.state.arena,
        );
        if left.parent != right.parent {
            return String::new();
        }
        let nodes = entry.state.arena.selected_nodes(left, right);
        if nodes.is_empty() {
            return String::new();
        }
        crate::editor::serialize::serialize_nodes(&entry.state.arena, &nodes)
    })
}

/// Dispatch an intent and get back the new snapshot.
#[frb(sync)]
pub fn dispatch_editor(id: String, intent: EditorIntent, display_mode: bool) -> EditorSnapshot {
    with_registry(|map| {
        let entry = match map.get_mut(&id) {
            Some(e) => e,
            None => return empty_snapshot(),
        };

        // Handle undo/redo separately (they swap state, not mutate it)
        match &intent {
            EditorIntent::Undo => {
                if let Some(prev) = entry.undo_stack.pop() {
                    let current = std::mem::replace(&mut entry.state, prev);
                    entry.redo_stack.push(current);
                }
                return build_snapshot(&entry.state, display_mode);
            }
            EditorIntent::Redo => {
                if let Some(next) = entry.redo_stack.pop() {
                    let current = std::mem::replace(&mut entry.state, next);
                    entry.undo_stack.push(current);
                }
                return build_snapshot(&entry.state, display_mode);
            }
            _ => {}
        }

        // Snapshot before mutating intents (skip pure navigation)
        let is_navigation = matches!(
            &intent,
            EditorIntent::MoveLeft | EditorIntent::MoveRight
            | EditorIntent::MoveUp | EditorIntent::MoveDown
            | EditorIntent::MoveToStart | EditorIntent::MoveToEnd
            | EditorIntent::EscapeRight
            | EditorIntent::SelectLeft | EditorIntent::SelectRight
            | EditorIntent::SelectAll
            | EditorIntent::TapBlock { .. }
            | EditorIntent::DragStart { .. } | EditorIntent::DragUpdate { .. }
        );
        if !is_navigation {
            entry.undo_stack.push(entry.state.clone());
            if entry.undo_stack.len() > MAX_UNDO {
                entry.undo_stack.remove(0);
            }
            entry.redo_stack.clear();
        }

        let core_intent = convert_intent(intent, &entry.state.arena);
        editor::reduce(&mut entry.state, core_intent);
        build_snapshot(&entry.state, display_mode)
    })
}

/// Get the current snapshot without dispatching.
#[frb(sync)]
pub fn get_editor_snapshot(id: String, display_mode: bool) -> EditorSnapshot {
    with_registry(|map| {
        let entry = match map.get_mut(&id) {
            Some(e) => e,
            None => return empty_snapshot(),
        };
        build_snapshot(&entry.state, display_mode)
    })
}

/// Close and dispose an editor.
#[frb(sync)]
pub fn close_editor(id: String) {
    with_registry(|map| {
        map.remove(&id);
    });
}

// ---------------------------------------------------------------------------
// Internal helpers
// ---------------------------------------------------------------------------

fn empty_snapshot() -> EditorSnapshot {
    EditorSnapshot {
        editor_layout: EditorLayout {
            root: BlockLayout {
                block_id: 0,
                width: 0.0,
                height: 0.0,
                depth: 0.0,
                caret_positions: vec![0.0],
                baseline_shift: 0.0,
                font_scale: 1.0,
                left_x: 0.0,
                children: Vec::new(),
                cursor_index: None,
                selection: None,
                is_empty: true,
            },
            untagged: Vec::new(),
        },
        latex: String::new(),
        in_command_input: false,
    }
}

pub(crate) fn build_snapshot(state: &editor::State, display_mode: bool) -> EditorSnapshot {
    // Export LaTeX excludes transient LatexCommandInput nodes
    let latex = state.arena.to_latex();
    // Render LaTeX includes \kern placeholders for LatexCommandInput space
    let render_latex = state.arena.to_render_latex();

    let ctx = katex::KatexContext::default();
    let mut settings = katex::Settings::default();
    settings.display_mode = display_mode;

    let leaf_ids = collect_leaf_ids(&state.arena);

    let layout = katex::render_to_layout_tagged(&ctx, &render_latex, &settings, leaf_ids)
        .map(MathLayout::from)
        .unwrap_or(MathLayout {
            width: 0.0,
            height: 0.0,
            depth: 0.0,
            nodes: Vec::new(),
        });

    let editor_layout = build_editor_layout(state, &layout);

    let in_command_input = state.cursor.left.map_or(false, |left_id| {
        matches!(
            &state.arena.node(left_id).kind,
            editor::NodeKind::LatexCommandInput { .. }
        )
    });

    EditorSnapshot {
        editor_layout,
        latex,
        in_command_input,
    }
}

/// Collect all leaf node IDs in left-to-right tree order.
/// This matches the order katex-rs encounters SymbolNodes during layout.
pub(crate) fn collect_leaf_ids(arena: &editor::Arena) -> Vec<u32> {
    let mut ids = Vec::new();
    collect_leaves_in_block(arena, arena.root, &mut ids);
    ids
}

fn collect_leaves_in_block(arena: &editor::Arena, block_id: editor::BlockId, ids: &mut Vec<u32>) {
    let mut current = arena.block(block_id).first;
    while let Some(nid) = current {
        let node = arena.node(nid);
        if matches!(&node.kind, editor::NodeKind::LatexCommandInput { .. }) {
            // Skip — LatexCommandInput has no KaTeX glyphs (rendered as \kern)
        } else if node.kind.is_leaf() {
            ids.push(nid.0);
        } else {
            // Walk child blocks in the order katex-rs encounters them during layout.
            // For fractions, katex-rs builds a vlist with [denom, rule, numer],
            // so the denominator symbols are encountered before numerator symbols.
            // Arena stores [numer=blocks[0], denom=blocks[1]], so we reverse.
            let blocks_in_katex_order: Vec<editor::BlockId> = match &node.kind {
                editor::node_kind::NodeKind::Frac => node.blocks.iter().rev().copied().collect(),
                _ => node.blocks.clone(),
            };
            for child_block in blocks_in_katex_order {
                collect_leaves_in_block(arena, child_block, ids);
            }
        }
        current = node.right;
    }
}

fn convert_intent(intent: EditorIntent, arena: &editor::Arena) -> editor::Intent {
    match intent {
        EditorIntent::InsertSymbol { ch } => {
            editor::Intent::InsertSymbol(ch.chars().next().unwrap_or(' '))
        }
        EditorIntent::InsertFrac => editor::Intent::InsertCommand(editor::CommandKind::Frac),
        EditorIntent::LiveFraction => editor::Intent::LiveFraction,
        EditorIntent::InsertSqrt => editor::Intent::InsertCommand(editor::CommandKind::Sqrt),
        EditorIntent::InsertNthRoot => editor::Intent::InsertCommand(editor::CommandKind::NthRoot),
        EditorIntent::InsertSup => editor::Intent::InsertCommand(editor::CommandKind::Sup),
        EditorIntent::InsertSub => editor::Intent::InsertCommand(editor::CommandKind::Sub),
        EditorIntent::InsertParentheses => editor::Intent::InsertCommand(editor::CommandKind::Parentheses),
        EditorIntent::InsertBrackets => editor::Intent::InsertCommand(editor::CommandKind::Brackets),
        EditorIntent::InsertBraces => editor::Intent::InsertCommand(editor::CommandKind::Braces),
        EditorIntent::InsertAbs => editor::Intent::InsertCommand(editor::CommandKind::Abs),
        EditorIntent::InsertSum => editor::Intent::InsertCommand(editor::CommandKind::Sum),
        EditorIntent::InsertProduct => editor::Intent::InsertCommand(editor::CommandKind::Product),
        EditorIntent::InsertIntegral => editor::Intent::InsertCommand(editor::CommandKind::Integral),
        EditorIntent::InsertLimit => editor::Intent::InsertCommand(editor::CommandKind::Limit),
        EditorIntent::InsertOverline => editor::Intent::InsertCommand(editor::CommandKind::Overline),
        EditorIntent::InsertUnderline => editor::Intent::InsertCommand(editor::CommandKind::Underline),
        EditorIntent::InsertText => editor::Intent::InsertCommand(editor::CommandKind::Text),
        EditorIntent::InsertCommandInput => editor::Intent::InsertCommandInput,
        EditorIntent::CommandInputType { ch } => {
            editor::Intent::CommandInputType(ch.chars().next().unwrap_or(' '))
        }
        EditorIntent::CommandInputBackspace => editor::Intent::CommandInputBackspace,
        EditorIntent::ResolveCommandInput => editor::Intent::ResolveCurrentCommandInput,
        EditorIntent::CancelCommandInput => editor::Intent::CancelCommandInput,
        EditorIntent::MoveLeft => editor::Intent::MoveLeft,
        EditorIntent::MoveRight => editor::Intent::MoveRight,
        EditorIntent::EscapeRight => editor::Intent::EscapeRight,
        EditorIntent::MoveUp => editor::Intent::MoveUp,
        EditorIntent::MoveDown => editor::Intent::MoveDown,
        EditorIntent::MoveToStart => editor::Intent::MoveToStart,
        EditorIntent::MoveToEnd => editor::Intent::MoveToEnd,
        EditorIntent::SelectLeft => editor::Intent::SelectLeft,
        EditorIntent::SelectRight => editor::Intent::SelectRight,
        EditorIntent::SelectAll => editor::Intent::SelectAll,
        EditorIntent::DeleteBackward => editor::Intent::DeleteBackward,
        EditorIntent::DeleteForward => editor::Intent::DeleteForward,
        EditorIntent::SetLatex { latex } => editor::Intent::SetLatex(latex),
        EditorIntent::InsertLatex { latex } => editor::Intent::InsertLatex(latex),
        EditorIntent::TapBlock { block_id, caret_index } => {
            resolve_tap_block(arena, block_id, caret_index)
        }
        EditorIntent::DragStart { block_id, caret_index } => {
            resolve_tap_block(arena, block_id, caret_index)
        }
        EditorIntent::DragUpdate { block_id, caret_index } => {
            // Resolve position, then apply as selection extension
            let cursor = resolve_tap_cursor(arena, block_id, caret_index);
            editor::Intent::DragUpdate(cursor)
        }
        // Undo/Redo handled in dispatch_editor before convert_intent is called
        EditorIntent::Undo | EditorIntent::Redo => unreachable!(),
    }
}

/// Resolve a block-level tap into a Cursor by walking to the caret_index-th gap.
fn resolve_tap_block(arena: &editor::Arena, block_id: u32, caret_index: u32) -> editor::Intent {
    let bid = editor::BlockId(block_id);
    if bid.0 as usize >= arena.blocks.len() {
        return editor::Intent::MoveToEnd;
    }

    let block = arena.block(bid);
    if caret_index == 0 {
        return editor::Intent::SetCursor(editor::Cursor {
            parent: bid,
            left: None,
            right: block.first,
        });
    }

    let mut current = block.first;
    let mut count = 0u32;
    while let Some(nid) = current {
        count += 1;
        if count == caret_index {
            let node = arena.node(nid);
            return editor::Intent::SetCursor(editor::Cursor {
                parent: bid,
                left: Some(nid),
                right: node.right,
            });
        }
        current = arena.node(nid).right;
    }

    // Past end — cursor at block end
    editor::Intent::SetCursor(editor::Cursor {
        parent: bid,
        left: block.last,
        right: None,
    })
}

/// Resolve block_id + caret_index into a Cursor (without wrapping in Intent).
fn resolve_tap_cursor(arena: &editor::Arena, block_id: u32, caret_index: u32) -> editor::Cursor {
    let bid = editor::BlockId(block_id);
    if bid.0 as usize >= arena.blocks.len() {
        return arena.move_to_end();
    }
    let block = arena.block(bid);
    if caret_index == 0 {
        return editor::Cursor { parent: bid, left: None, right: block.first };
    }
    let mut current = block.first;
    let mut count = 0u32;
    while let Some(nid) = current {
        count += 1;
        if count == caret_index {
            let node = arena.node(nid);
            return editor::Cursor { parent: bid, left: Some(nid), right: node.right };
        }
        current = arena.node(nid).right;
    }
    editor::Cursor { parent: bid, left: block.last, right: None }
}
