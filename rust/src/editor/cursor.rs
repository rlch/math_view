use crate::editor::arena::{BlockId, NodeId};

/// Position between nodes in a block. Equivalent to MathQuill's Point type.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Cursor {
    /// The block the cursor is in.
    pub parent: BlockId,
    /// Node to the left of cursor (None = at start of block).
    pub left: Option<NodeId>,
    /// Node to the right of cursor (None = at end of block).
    pub right: Option<NodeId>,
}

/// Represents a selected range of nodes. The anticursor is the anchor
/// and the main cursor is the focus (moving end).
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Selection {
    /// Where selection started (anchor).
    pub anticursor: Cursor,
}

impl Cursor {
    /// Create a cursor at the start of a block.
    pub fn at_block_start(block: BlockId, first: Option<NodeId>) -> Self {
        Cursor {
            parent: block,
            left: None,
            right: first,
        }
    }

    /// Create a cursor at the end of a block.
    pub fn at_block_end(block: BlockId, last: Option<NodeId>) -> Self {
        Cursor {
            parent: block,
            left: last,
            right: None,
        }
    }
}
