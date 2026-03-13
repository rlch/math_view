use crate::editor::cursor::Cursor;
use crate::editor::intent::CommandKind;
use crate::editor::node_kind::{AtomFamily, NodeKind};

/// Index into `Arena::nodes`.
#[derive(Debug, Copy, Clone, Eq, PartialEq, Hash)]
pub struct NodeId(pub u32);

/// Index into `Arena::blocks`.
#[derive(Debug, Copy, Clone, Eq, PartialEq, Hash)]
pub struct BlockId(pub u32);

/// Arena-based math tree. Blocks contain sequences of Nodes, Nodes contain
/// child Blocks. Mirrors MathQuill's doubly-linked tree structure.
#[derive(Debug, Clone)]
pub struct Arena {
    pub(crate) nodes: Vec<Node>,
    pub(crate) blocks: Vec<Block>,
    /// Root block (top-level expression).
    pub root: BlockId,
}

/// A node (command or symbol) in the math tree.
#[derive(Debug, Clone)]
pub struct Node {
    pub kind: NodeKind,
    /// Parent block this node lives in.
    pub parent: BlockId,
    /// Left sibling (None if first in block).
    pub left: Option<NodeId>,
    /// Right sibling (None if last in block).
    pub right: Option<NodeId>,
    /// Child blocks (e.g. frac has 2, sqrt has 1, symbol has 0).
    pub blocks: Vec<BlockId>,
}

/// A block is a sequence of nodes. The cursor always lives in a block.
#[derive(Debug, Clone)]
pub struct Block {
    /// First child node (None if empty).
    pub first: Option<NodeId>,
    /// Last child node (None if empty).
    pub last: Option<NodeId>,
    /// Parent node that owns this block (None for root block).
    pub parent: Option<NodeId>,
}

impl Arena {
    /// Create a new arena with an empty root block.
    pub fn new() -> Self {
        let root_block = Block {
            first: None,
            last: None,
            parent: None,
        };
        Arena {
            nodes: Vec::new(),
            blocks: vec![root_block],
            root: BlockId(0),
        }
    }

    pub fn node(&self, id: NodeId) -> &Node {
        &self.nodes[id.0 as usize]
    }

    pub fn node_mut(&mut self, id: NodeId) -> &mut Node {
        &mut self.nodes[id.0 as usize]
    }

    pub fn block(&self, id: BlockId) -> &Block {
        &self.blocks[id.0 as usize]
    }

    pub fn block_mut(&mut self, id: BlockId) -> &mut Block {
        &mut self.blocks[id.0 as usize]
    }

    /// Allocate a new node (not linked into any block yet).
    fn alloc_node(&mut self, kind: NodeKind, parent: BlockId) -> NodeId {
        let id = NodeId(self.nodes.len() as u32);
        self.nodes.push(Node {
            kind,
            parent,
            left: None,
            right: None,
            blocks: Vec::new(),
        });
        id
    }

    /// Allocate a new empty block owned by the given parent node.
    pub(crate) fn alloc_block(&mut self, parent: Option<NodeId>) -> BlockId {
        let id = BlockId(self.blocks.len() as u32);
        self.blocks.push(Block {
            first: None,
            last: None,
            parent,
        });
        id
    }

    /// Insert a node to the left of the cursor position, updating the cursor
    /// to sit after the new node.
    pub fn insert_at_cursor(&mut self, cursor: &mut Cursor, kind: NodeKind) -> NodeId {
        let block_id = cursor.parent;
        let node_id = self.alloc_node(kind, block_id);

        // Wire sibling links
        if let Some(left_id) = cursor.left {
            self.node_mut(left_id).right = Some(node_id);
            self.node_mut(node_id).left = Some(left_id);
        } else {
            // Inserting at block start
            self.block_mut(block_id).first = Some(node_id);
        }

        if let Some(right_id) = cursor.right {
            self.node_mut(right_id).left = Some(node_id);
            self.node_mut(node_id).right = Some(right_id);
        } else {
            // Inserting at block end
            self.block_mut(block_id).last = Some(node_id);
        }

        // Advance cursor past the new node
        cursor.left = Some(node_id);

        node_id
    }

    /// Insert a command node at the cursor, creating child blocks.
    /// If there's a selection, the selected content goes into the first block.
    pub fn insert_command(
        &mut self,
        cursor: &mut Cursor,
        command: CommandKind,
    ) -> NodeId {
        let kind = command.to_node_kind();
        let block_count = kind.expected_block_count();
        let node_id = self.insert_at_cursor(cursor, kind);

        // Create child blocks
        let mut child_blocks = Vec::with_capacity(block_count);
        for _ in 0..block_count {
            let block = self.alloc_block(Some(node_id));
            child_blocks.push(block);
        }
        self.node_mut(node_id).blocks = child_blocks.clone();

        // Move cursor into first child block
        if let Some(&first_block) = child_blocks.first() {
            *cursor = Cursor {
                parent: first_block,
                left: None,
                right: None,
            };
        }

        node_id
    }

    /// Remove a node from its parent block, re-linking siblings.
    pub fn remove_node(&mut self, id: NodeId) {
        let node = self.node(id).clone();
        let block_id = node.parent;

        // Re-link siblings
        if let Some(left_id) = node.left {
            self.node_mut(left_id).right = node.right;
        } else {
            self.block_mut(block_id).first = node.right;
        }

        if let Some(right_id) = node.right {
            self.node_mut(right_id).left = node.left;
        } else {
            self.block_mut(block_id).last = node.left;
        }
    }

    /// Move all children from `src_block` into `dst_block` at the cursor position.
    pub fn adopt_children(&mut self, src_block: BlockId, dst_block: BlockId, at: &Cursor) {
        let src = self.block(src_block).clone();

        // Nothing to move
        if src.first.is_none() {
            return;
        }

        let src_first = src.first.unwrap();
        let src_last = src.last.unwrap();

        // Re-parent all nodes in src
        let mut current = Some(src_first);
        while let Some(nid) = current {
            self.node_mut(nid).parent = dst_block;
            current = self.node(nid).right;
        }

        // Link src chain into dst at cursor position
        if let Some(left_id) = at.left {
            self.node_mut(left_id).right = Some(src_first);
            self.node_mut(src_first).left = Some(left_id);
        } else {
            self.block_mut(dst_block).first = Some(src_first);
            self.node_mut(src_first).left = None;
        }

        if let Some(right_id) = at.right {
            self.node_mut(right_id).left = Some(src_last);
            self.node_mut(src_last).right = Some(right_id);
        } else {
            self.block_mut(dst_block).last = Some(src_last);
            self.node_mut(src_last).right = None;
        }

        // Clear src block
        self.block_mut(src_block).first = None;
        self.block_mut(src_block).last = None;
    }

    /// Collect nodes in a block as a Vec, left to right.
    pub fn block_children(&self, block_id: BlockId) -> Vec<NodeId> {
        let mut result = Vec::new();
        let mut current = self.block(block_id).first;
        while let Some(nid) = current {
            result.push(nid);
            current = self.node(nid).right;
        }
        result
    }

    /// Collect all BlockIds that are currently empty.
    pub fn empty_blocks(&self) -> Vec<BlockId> {
        self.blocks
            .iter()
            .enumerate()
            .filter(|(_, b)| b.first.is_none())
            .map(|(i, _)| BlockId(i as u32))
            .collect()
    }

    /// Insert a symbol node for a character, with default Ord family.
    pub fn insert_symbol_at_cursor(&mut self, cursor: &mut Cursor, ch: char) -> NodeId {
        let family = classify_char(ch);
        self.insert_at_cursor(
            cursor,
            NodeKind::Symbol {
                text: ch.to_string(),
                atom_family: family,
            },
        )
    }

    /// Collect selected nodes between anticursor and cursor.
    /// Returns nodes in left-to-right order if both are in the same block.
    pub fn selected_nodes(&self, left: &Cursor, right: &Cursor) -> Vec<NodeId> {
        if left.parent != right.parent {
            return Vec::new();
        }
        let mut result = Vec::new();
        let mut current = left.right;
        while current != right.right {
            if let Some(nid) = current {
                result.push(nid);
                current = self.node(nid).right;
            } else {
                break;
            }
        }
        result
    }

    /// Remove a range of sibling nodes from their block and return them.
    /// Updates the block's first/last pointers.
    pub fn splice_out(&mut self, nodes: &[NodeId]) -> Vec<NodeId> {
        if nodes.is_empty() {
            return Vec::new();
        }
        let first = nodes[0];
        let last = *nodes.last().unwrap();
        let block_id = self.node(first).parent;

        let before = self.node(first).left;
        let after = self.node(last).right;

        if let Some(b) = before {
            self.node_mut(b).right = after;
        } else {
            self.block_mut(block_id).first = after;
        }

        if let Some(a) = after {
            self.node_mut(a).left = before;
        } else {
            self.block_mut(block_id).last = before;
        }

        // Disconnect the spliced range
        self.node_mut(first).left = None;
        self.node_mut(last).right = None;

        nodes.to_vec()
    }

    /// Move a list of previously-spliced nodes into a block, appending at end.
    pub fn splice_into(&mut self, block_id: BlockId, nodes: &[NodeId]) {
        for &nid in nodes {
            self.node_mut(nid).parent = block_id;
        }
        if nodes.is_empty() {
            return;
        }

        // Link the chain
        for i in 0..nodes.len() - 1 {
            self.node_mut(nodes[i]).right = Some(nodes[i + 1]);
            self.node_mut(nodes[i + 1]).left = Some(nodes[i]);
        }
        self.node_mut(nodes[0]).left = None;
        self.node_mut(*nodes.last().unwrap()).right = None;

        let existing_last = self.block(block_id).last;
        if let Some(el) = existing_last {
            self.node_mut(el).right = Some(nodes[0]);
            self.node_mut(nodes[0]).left = Some(el);
        } else {
            self.block_mut(block_id).first = Some(nodes[0]);
        }
        self.block_mut(block_id).last = Some(*nodes.last().unwrap());
    }
}

impl Default for Arena {
    fn default() -> Self {
        Self::new()
    }
}

/// Classify a character into an atom family for spacing.
pub fn classify_char(ch: char) -> AtomFamily {
    match ch {
        '+' | '-' | '*' | '/' | '×' | '÷' | '±' | '∓' | '∧' | '∨' | '⊕' | '⊗' => {
            AtomFamily::Bin
        }
        '=' | '<' | '>' | '≤' | '≥' | '≠' | '≈' | '∼' | '≡' | '∈' | '⊂' | '⊃' | '⊆'
        | '⊇' => AtomFamily::Rel,
        '(' | '[' | '{' | '⟨' => AtomFamily::Open,
        ')' | ']' | '}' | '⟩' => AtomFamily::Close,
        ',' | ';' => AtomFamily::Punct,
        _ => AtomFamily::Ord,
    }
}
