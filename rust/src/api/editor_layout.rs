use flutter_rust_bridge::frb;

use crate::api::math_api::MathNode;
use crate::editor::arena::{Arena, BlockId, NodeId};
use crate::editor::cursor::Cursor;
use crate::editor::node_kind::NodeKind;
use crate::editor::state::State;

// ---------------------------------------------------------------------------
// Hierarchical layout tree — mirrors Arena block/node structure
// ---------------------------------------------------------------------------

/// Tree-structured layout output for the widget tree renderer.
#[frb(non_opaque)]
#[derive(Clone, Debug)]
pub struct EditorLayout {
    pub root: BlockLayout,
}

/// Layout for a single block (sequence of nodes).
#[frb(non_opaque)]
#[derive(Clone, Debug)]
pub struct BlockLayout {
    pub block_id: u32,
    pub width: f64,
    pub height: f64,
    pub depth: f64,
    pub children: Vec<NodeLayout>,
    /// Caret position if cursor is in this block (index into children gaps: 0 = before first, n = after last).
    pub cursor_index: Option<u32>,
    /// Selection range if active in this block.
    pub selection: Option<BlockSelection>,
}

/// Selection range within a block (indices into children gaps).
#[frb(non_opaque)]
#[derive(Clone, Debug)]
pub struct BlockSelection {
    pub start: u32,
    pub end: u32,
}

/// Layout for a single node within a block.
#[frb(non_opaque)]
#[derive(Clone, Debug)]
pub enum NodeLayout {
    /// A leaf node (symbol) — carries its rendered glyphs.
    Leaf {
        node_id: u32,
        glyphs: Vec<MathNode>,
        width: f64,
        height: f64,
        depth: f64,
    },
    /// A command node (frac, sqrt, etc.) — carries child blocks and decorations.
    Command {
        node_id: u32,
        kind: CommandLayoutKind,
        width: f64,
        height: f64,
        depth: f64,
        child_blocks: Vec<BlockLayout>,
        decorations: Vec<MathNode>,
    },
}

/// Identifies the type of command for layout delegation in Dart.
#[frb(non_opaque)]
#[derive(Clone, Debug)]
pub enum CommandLayoutKind {
    Frac,
    Sqrt,
    NthRoot,
    Sup,
    Sub,
    SupSub,
    Overline,
    Underline,
    LeftRight,
    SumLike,
    Matrix { rows: u32, cols: u32 },
    Text,
    Other,
}

impl From<&NodeKind> for CommandLayoutKind {
    fn from(kind: &NodeKind) -> Self {
        match kind {
            NodeKind::Frac => Self::Frac,
            NodeKind::Sqrt => Self::Sqrt,
            NodeKind::NthRoot => Self::NthRoot,
            NodeKind::Sup => Self::Sup,
            NodeKind::Sub => Self::Sub,
            NodeKind::SupSub => Self::SupSub,
            NodeKind::Overline => Self::Overline,
            NodeKind::Underline => Self::Underline,
            NodeKind::LeftRight { .. } => Self::LeftRight,
            NodeKind::SumLike { .. } => Self::SumLike,
            NodeKind::Matrix { rows, cols } => Self::Matrix {
                rows: *rows as u32,
                cols: *cols as u32,
            },
            NodeKind::Text => Self::Text,
            _ => Self::Other,
        }
    }
}

// ---------------------------------------------------------------------------
// Builder — walks Arena + flat MathLayout to produce EditorLayout
// ---------------------------------------------------------------------------

use crate::api::math_api::MathLayout;

/// Build a hierarchical EditorLayout from the arena tree and flat layout.
///
/// The flat `MathLayout` provides positioned glyphs/rules/paths with `node_id` tags.
/// We walk the arena tree to group these into their owning blocks and nodes.
pub(crate) fn build_editor_layout(
    state: &State,
    layout: &MathLayout,
) -> EditorLayout {
    let glyph_index = GlyphIndex::new(layout);
    let cursor_info = BlockCursorInfo::from_state(state);

    let root = build_block_layout(
        &state.arena,
        state.arena.root,
        &glyph_index,
        &cursor_info,
    );

    EditorLayout { root }
}

/// Build a hierarchical layout for read-only display (no cursor/selection).
pub(crate) fn build_readonly_layout(arena: &Arena, layout: &MathLayout) -> EditorLayout {
    let glyph_index = GlyphIndex::new(layout);
    let cursor_info = BlockCursorInfo::none();

    let root = build_block_layout(arena, arena.root, &glyph_index, &cursor_info);
    EditorLayout { root }
}

// ---------------------------------------------------------------------------
// Glyph index — groups flat MathNodes by their node_id
// ---------------------------------------------------------------------------

use std::collections::HashMap;

/// Groups MathNodes from the flat layout by their source node_id.
/// Also tracks "orphan" nodes (node_id = None) for decoration attribution.
struct GlyphIndex {
    /// node_id → list of MathNodes belonging to that arena node
    by_node: HashMap<u32, Vec<MathNode>>,
    /// MathNodes with no node_id (decorations like fraction bars, radical signs)
    orphans: Vec<MathNode>,
}

impl GlyphIndex {
    fn new(layout: &MathLayout) -> Self {
        let mut by_node: HashMap<u32, Vec<MathNode>> = HashMap::new();
        let mut orphans = Vec::new();

        for node in &layout.nodes {
            let nid = match node {
                MathNode::Glyph { node_id, .. } => *node_id,
                MathNode::Rule { node_id, .. } => *node_id,
                MathNode::SvgPath { node_id, .. } => *node_id,
            };

            if let Some(id) = nid {
                by_node.entry(id).or_default().push(node.clone());
            } else {
                orphans.push(node.clone());
            }
        }

        GlyphIndex { by_node, orphans }
    }

    fn glyphs_for(&self, node_id: u32) -> Vec<MathNode> {
        self.by_node.get(&node_id).cloned().unwrap_or_default()
    }

    /// Get all glyphs that belong to any descendant leaf of the given command node.
    fn glyphs_for_subtree(&self, arena: &Arena, node_id: NodeId) -> Vec<MathNode> {
        let mut result = Vec::new();
        self.collect_subtree_glyphs(arena, node_id, &mut result);
        result
    }

    fn collect_subtree_glyphs(&self, arena: &Arena, node_id: NodeId, out: &mut Vec<MathNode>) {
        let node = arena.node(node_id);
        if node.kind.is_leaf() {
            out.extend(self.glyphs_for(node_id.0));
        } else {
            // Also collect any glyphs directly tagged with this command node
            out.extend(self.glyphs_for(node_id.0));
            for &block_id in &node.blocks {
                let mut current = arena.block(block_id).first;
                while let Some(nid) = current {
                    self.collect_subtree_glyphs(arena, nid, out);
                    current = arena.node(nid).right;
                }
            }
        }
    }
}

// ---------------------------------------------------------------------------
// Cursor info — maps cursor/selection to per-block indices
// ---------------------------------------------------------------------------

struct BlockCursorInfo {
    /// Which block the cursor is in and its index (gap position)
    cursor_block: Option<BlockId>,
    cursor_left: Option<NodeId>,
    /// Selection anchor (anticursor) if active
    selection: Option<SelectionInfo>,
}

struct SelectionInfo {
    anticursor_block: BlockId,
    anticursor_left: Option<NodeId>,
}

impl BlockCursorInfo {
    fn from_state(state: &State) -> Self {
        BlockCursorInfo {
            cursor_block: Some(state.cursor.parent),
            cursor_left: state.cursor.left,
            selection: state.selection.as_ref().map(|s| SelectionInfo {
                anticursor_block: s.anticursor.parent,
                anticursor_left: s.anticursor.left,
            }),
        }
    }

    fn none() -> Self {
        BlockCursorInfo {
            cursor_block: None,
            cursor_left: None,
            selection: None,
        }
    }
}

// ---------------------------------------------------------------------------
// Block layout builder
// ---------------------------------------------------------------------------

fn build_block_layout(
    arena: &Arena,
    block_id: BlockId,
    glyphs: &GlyphIndex,
    cursor_info: &BlockCursorInfo,
) -> BlockLayout {
    let mut children = Vec::new();
    let mut block_width = 0.0;
    let mut block_height = 0.0;
    let mut block_depth = 0.0;

    let mut current = arena.block(block_id).first;
    while let Some(nid) = current {
        let node = arena.node(nid);
        let node_layout = build_node_layout(arena, nid, glyphs, cursor_info);

        // Track block extents
        match &node_layout {
            NodeLayout::Leaf { width, height, depth, .. } |
            NodeLayout::Command { width, height, depth, .. } => {
                block_width += width;
                if *height > block_height { block_height = *height; }
                if *depth > block_depth { block_depth = *depth; }
            }
        }

        children.push(node_layout);
        current = node.right;
    }

    // Compute cursor_index: count nodes to the left of cursor in this block
    let cursor_index = if cursor_info.cursor_block == Some(block_id) {
        Some(compute_cursor_index(arena, block_id, cursor_info.cursor_left))
    } else {
        None
    };

    // Compute selection range
    let selection = compute_block_selection(arena, block_id, cursor_info);

    BlockLayout {
        block_id: block_id.0,
        width: block_width,
        height: block_height,
        depth: block_depth,
        children,
        cursor_index,
        selection,
    }
}

fn build_node_layout(
    arena: &Arena,
    node_id: NodeId,
    glyphs: &GlyphIndex,
    cursor_info: &BlockCursorInfo,
) -> NodeLayout {
    let node = arena.node(node_id);

    if node.kind.is_leaf() {
        let node_glyphs = glyphs.glyphs_for(node_id.0);
        let (width, height, depth) = compute_glyph_extents(&node_glyphs);

        NodeLayout::Leaf {
            node_id: node_id.0,
            glyphs: node_glyphs,
            width,
            height,
            depth,
        }
    } else {
        // Command node — recurse into child blocks
        let child_blocks: Vec<BlockLayout> = node.blocks.iter()
            .map(|&bid| build_block_layout(arena, bid, glyphs, cursor_info))
            .collect();

        // Collect decorations: glyphs tagged with this command's node_id
        // (e.g. fraction bar rule tagged with the frac node)
        let decorations = glyphs.glyphs_for(node_id.0);

        // Compute extents from all subtree glyphs
        let all_glyphs = glyphs.glyphs_for_subtree(arena, node_id);
        let (width, height, depth) = compute_glyph_extents(&all_glyphs);

        NodeLayout::Command {
            node_id: node_id.0,
            kind: CommandLayoutKind::from(&node.kind),
            width,
            height,
            depth,
            child_blocks,
            decorations,
        }
    }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Compute (width, height, depth) from a set of positioned MathNodes.
/// height = max ascent above baseline, depth = max descent below.
fn compute_glyph_extents(nodes: &[MathNode]) -> (f64, f64, f64) {
    if nodes.is_empty() {
        return (0.0, 0.0, 0.0);
    }

    let mut min_x = f64::MAX;
    let mut max_x = f64::MIN;
    let mut max_height = 0.0_f64; // above baseline
    let mut max_depth = 0.0_f64;  // below baseline

    for node in nodes {
        match node {
            MathNode::Glyph { x, y, scale, .. } => {
                let glyph_width = 0.5 * scale; // approximate
                min_x = min_x.min(*x);
                max_x = max_x.max(*x + glyph_width);
                // y is baseline-relative (positive = above baseline)
                max_height = max_height.max(*y + *scale);
                max_depth = max_depth.max(-*y);
            }
            MathNode::Rule { x, y, width, height, .. } => {
                min_x = min_x.min(*x);
                max_x = max_x.max(*x + *width);
                max_height = max_height.max(*y + *height);
                max_depth = max_depth.max(-*y);
            }
            MathNode::SvgPath { x, y, width, height, .. } => {
                min_x = min_x.min(*x);
                max_x = max_x.max(*x + *width);
                max_height = max_height.max(*y + *height);
                max_depth = max_depth.max(-*y);
            }
        }
    }

    let width = if max_x > min_x { max_x - min_x } else { 0.0 };
    (width, max_height.max(0.0), max_depth.max(0.0))
}

/// Count nodes left of cursor position within a block → cursor gap index.
fn compute_cursor_index(arena: &Arena, block_id: BlockId, cursor_left: Option<NodeId>) -> u32 {
    match cursor_left {
        None => 0, // cursor at start of block
        Some(left_nid) => {
            let mut count = 0u32;
            let mut current = arena.block(block_id).first;
            while let Some(nid) = current {
                count += 1;
                if nid == left_nid {
                    return count;
                }
                current = arena.node(nid).right;
            }
            count // fallback: cursor at end
        }
    }
}

/// Compute selection range for a block, if cursor and anticursor are both in it.
fn compute_block_selection(
    arena: &Arena,
    block_id: BlockId,
    cursor_info: &BlockCursorInfo,
) -> Option<BlockSelection> {
    let sel = cursor_info.selection.as_ref()?;

    // Both cursor and anticursor must be in this block
    if cursor_info.cursor_block != Some(block_id) || sel.anticursor_block != block_id {
        return None;
    }

    let cursor_idx = compute_cursor_index(arena, block_id, cursor_info.cursor_left);
    let anti_idx = compute_cursor_index(arena, block_id, sel.anticursor_left);

    let start = cursor_idx.min(anti_idx);
    let end = cursor_idx.max(anti_idx);

    if start == end {
        return None;
    }

    Some(BlockSelection { start, end })
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

#[cfg(test)]
mod tests {
    use super::*;
    use crate::editor::convert::import_latex;

    #[test]
    fn test_build_simple_layout() {
        let state = import_latex("x+1").unwrap();
        let ctx = katex::KatexContext::default();
        let settings = katex::Settings::default();
        let leaf_ids = super::super::editor_api::collect_leaf_ids(&state.arena);
        let layout = katex::render_to_layout_tagged(&ctx, "x+1", &settings, leaf_ids)
            .map(MathLayout::from)
            .unwrap();

        let editor_layout = build_editor_layout(&state, &layout);
        assert_eq!(editor_layout.root.block_id, 0);
        assert_eq!(editor_layout.root.children.len(), 3); // x, +, 1
        // Cursor should be at end (index 3)
        assert_eq!(editor_layout.root.cursor_index, Some(3));
    }

    #[test]
    fn test_build_frac_layout() {
        let state = import_latex(r"\frac{a}{b}").unwrap();
        let ctx = katex::KatexContext::default();
        let settings = katex::Settings::default();
        let leaf_ids = super::super::editor_api::collect_leaf_ids(&state.arena);
        let layout = katex::render_to_layout_tagged(&ctx, r"\frac{a}{b}", &settings, leaf_ids)
            .map(MathLayout::from)
            .unwrap();

        let editor_layout = build_editor_layout(&state, &layout);
        assert_eq!(editor_layout.root.children.len(), 1); // one frac command

        match &editor_layout.root.children[0] {
            NodeLayout::Command { kind, child_blocks, .. } => {
                assert!(matches!(kind, CommandLayoutKind::Frac));
                assert_eq!(child_blocks.len(), 2); // numer + denom
                // Each child block should have one leaf
                assert_eq!(child_blocks[0].children.len(), 1); // 'a'
                assert_eq!(child_blocks[1].children.len(), 1); // 'b'
            }
            _ => panic!("Expected Command node for frac"),
        }
    }

    #[test]
    fn test_cursor_in_child_block() {
        // After import_latex, cursor is at end of root block
        // Move into frac numerator to test cursor_index in child block
        let mut state = import_latex(r"\frac{a}{b}").unwrap();
        // Manually place cursor in first child block of frac
        let frac_node = state.arena.block(state.arena.root).first.unwrap();
        let numer_block = state.arena.node(frac_node).blocks[0];
        let a_node = state.arena.block(numer_block).first;
        state.cursor = Cursor {
            parent: numer_block,
            left: a_node,
            right: None,
        };

        let ctx = katex::KatexContext::default();
        let settings = katex::Settings::default();
        let leaf_ids = super::super::editor_api::collect_leaf_ids(&state.arena);
        let layout = katex::render_to_layout_tagged(&ctx, r"\frac{a}{b}", &settings, leaf_ids)
            .map(MathLayout::from)
            .unwrap();

        let editor_layout = build_editor_layout(&state, &layout);

        // Root block should have no cursor
        assert_eq!(editor_layout.root.cursor_index, None);

        // Numerator block should have cursor at index 1 (after 'a')
        match &editor_layout.root.children[0] {
            NodeLayout::Command { child_blocks, .. } => {
                assert_eq!(child_blocks[0].cursor_index, Some(1));
                assert_eq!(child_blocks[1].cursor_index, None);
            }
            _ => panic!("Expected Command"),
        }
    }

    #[test]
    fn test_empty_editor_layout() {
        let state = State::new();
        let layout = MathLayout {
            width: 0.0,
            height: 0.0,
            depth: 0.0,
            nodes: Vec::new(),
        };

        let editor_layout = build_editor_layout(&state, &layout);
        assert_eq!(editor_layout.root.children.len(), 0);
        assert_eq!(editor_layout.root.cursor_index, Some(0));
    }
}
