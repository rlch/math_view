use crate::editor::arena::Arena;
use crate::editor::cursor::{Cursor, Selection};

/// Editor state: the arena tree, cursor position, and optional selection.
#[derive(Debug, Clone)]
pub struct State {
    pub arena: Arena,
    pub cursor: Cursor,
    pub selection: Option<Selection>,
}

impl State {
    /// Create a new empty editor state.
    pub fn new() -> Self {
        let arena = Arena::new();
        let root = arena.root;
        State {
            cursor: Cursor::at_block_start(root, None),
            arena,
            selection: None,
        }
    }
}

impl Default for State {
    fn default() -> Self {
        Self::new()
    }
}
