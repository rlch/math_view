use crate::editor::arena::{Arena, BlockId, NodeId};
use crate::editor::cursor::Cursor;
use crate::editor::node_kind::NodeKind;

impl Arena {
    /// Move cursor right: if there's a node to the right, enter it or skip it.
    pub fn move_right(&self, cursor: &Cursor) -> Cursor {
        if let Some(right_id) = cursor.right {
            self.enter_from_left(right_id)
        } else {
            // At end of block — try to exit
            self.exit_block_right(cursor.parent)
                .unwrap_or_else(|| cursor.clone())
        }
    }

    /// Move cursor left: if there's a node to the left, enter it or skip it.
    pub fn move_left(&self, cursor: &Cursor) -> Cursor {
        if let Some(left_id) = cursor.left {
            self.enter_from_right(left_id)
        } else {
            // At start of block — try to exit
            self.exit_block_left(cursor.parent)
                .unwrap_or_else(|| cursor.clone())
        }
    }

    /// Called when cursor moves right and hits a node.
    /// Leaf nodes: skip past. Commands: enter first block.
    pub fn enter_from_left(&self, node_id: NodeId) -> Cursor {
        let n = self.node(node_id);
        if n.blocks.is_empty() {
            // Leaf: skip past
            Cursor {
                parent: n.parent,
                left: Some(node_id),
                right: n.right,
            }
        } else {
            // Command: enter first block at start
            let block = n.blocks[0];
            let b = self.block(block);
            Cursor {
                parent: block,
                left: None,
                right: b.first,
            }
        }
    }

    /// Called when cursor moves left and hits a node.
    /// Leaf nodes: skip past. Commands: enter last block at end.
    pub fn enter_from_right(&self, node_id: NodeId) -> Cursor {
        let n = self.node(node_id);
        if n.blocks.is_empty() {
            // Leaf: skip past
            Cursor {
                parent: n.parent,
                left: n.left,
                right: Some(node_id),
            }
        } else {
            // Command: enter last block at end
            let block = *n.blocks.last().unwrap();
            let b = self.block(block);
            Cursor {
                parent: block,
                left: b.last,
                right: None,
            }
        }
    }

    /// When cursor is at end of a block and moves right: exit to next sibling
    /// block or out of the parent node entirely.
    pub fn exit_block_right(&self, block_id: BlockId) -> Option<Cursor> {
        let b = self.block(block_id);
        let parent_node_id = b.parent?;
        let n = self.node(parent_node_id);
        let idx = n.blocks.iter().position(|&bid| bid == block_id)?;

        if idx + 1 < n.blocks.len() {
            // Enter next sibling block at start
            let next_block = n.blocks[idx + 1];
            let nb = self.block(next_block);
            Some(Cursor {
                parent: next_block,
                left: None,
                right: nb.first,
            })
        } else {
            // Exit parent node entirely — cursor lands after it
            Some(Cursor {
                parent: n.parent,
                left: Some(parent_node_id),
                right: n.right,
            })
        }
    }

    /// When cursor is at start of a block and moves left: exit to prev sibling
    /// block or out of the parent node entirely.
    pub fn exit_block_left(&self, block_id: BlockId) -> Option<Cursor> {
        let b = self.block(block_id);
        let parent_node_id = b.parent?;
        let n = self.node(parent_node_id);
        let idx = n.blocks.iter().position(|&bid| bid == block_id)?;

        if idx > 0 {
            // Enter previous sibling block at end
            let prev_block = n.blocks[idx - 1];
            let pb = self.block(prev_block);
            Some(Cursor {
                parent: prev_block,
                left: pb.last,
                right: None,
            })
        } else {
            // Exit parent node entirely — cursor lands before it
            Some(Cursor {
                parent: n.parent,
                left: n.left,
                right: Some(parent_node_id),
            })
        }
    }

    /// Vertical navigation: which block to enter when pressing Up from cursor.
    pub fn up_into(&self, node_id: NodeId) -> Option<BlockId> {
        let n = self.node(node_id);
        match &n.kind {
            // Frac: denom → numer (up goes to numerator)
            NodeKind::Frac if n.blocks.len() == 2 => Some(n.blocks[0]),
            // SupSub: sub → sup
            NodeKind::SupSub if n.blocks.len() == 2 => Some(n.blocks[0]),
            // SumLike: below → above (if has above block)
            NodeKind::SumLike { .. } if n.blocks.len() == 2 => Some(n.blocks[1]),
            // Matrix: navigate up by row
            NodeKind::Matrix { cols, .. } if n.blocks.len() > *cols => {
                // Not directly possible without knowing current cell
                None
            }
            _ => None,
        }
    }

    /// Vertical navigation: which block to enter when pressing Down from cursor.
    pub fn down_into(&self, node_id: NodeId) -> Option<BlockId> {
        let n = self.node(node_id);
        match &n.kind {
            // Frac: numer → denom
            NodeKind::Frac if n.blocks.len() == 2 => Some(n.blocks[1]),
            // SupSub: sup → sub
            NodeKind::SupSub if n.blocks.len() == 2 => Some(n.blocks[1]),
            // SumLike: above → below
            NodeKind::SumLike { .. } if n.blocks.len() >= 1 => Some(n.blocks[0]),
            _ => None,
        }
    }

    /// Move cursor up: find the enclosing command and navigate vertically.
    pub fn move_up(&self, cursor: &Cursor) -> Cursor {
        // Walk up to find a node with up_into
        let mut block_id = cursor.parent;
        loop {
            let b = self.block(block_id);
            if let Some(parent_node_id) = b.parent {
                let n = self.node(parent_node_id);
                // Check if this node's current block can go up
                if let Some(idx) = n.blocks.iter().position(|&bid| bid == block_id) {
                    let target = match &n.kind {
                        NodeKind::Frac if n.blocks.len() == 2 && idx == 1 => Some(n.blocks[0]),
                        NodeKind::SupSub if n.blocks.len() == 2 && idx == 1 => Some(n.blocks[0]),
                        NodeKind::SumLike { .. } if n.blocks.len() == 2 && idx == 0 => {
                            Some(n.blocks[1])
                        }
                        NodeKind::Matrix { cols, .. } => {
                            let row = idx / cols;
                            if row > 0 {
                                Some(n.blocks[idx - cols])
                            } else {
                                None
                            }
                        }
                        _ => None,
                    };
                    if let Some(target_block) = target {
                        let tb = self.block(target_block);
                        return Cursor {
                            parent: target_block,
                            left: tb.last,
                            right: None,
                        };
                    }
                }
                // Keep searching upward
                block_id = n.parent;
            } else {
                // At root, can't go up
                return cursor.clone();
            }
        }
    }

    /// Move cursor down: find the enclosing command and navigate vertically.
    pub fn move_down(&self, cursor: &Cursor) -> Cursor {
        let mut block_id = cursor.parent;
        loop {
            let b = self.block(block_id);
            if let Some(parent_node_id) = b.parent {
                let n = self.node(parent_node_id);
                if let Some(idx) = n.blocks.iter().position(|&bid| bid == block_id) {
                    let target = match &n.kind {
                        NodeKind::Frac if n.blocks.len() == 2 && idx == 0 => Some(n.blocks[1]),
                        NodeKind::SupSub if n.blocks.len() == 2 && idx == 0 => Some(n.blocks[1]),
                        NodeKind::SumLike { .. } if n.blocks.len() == 2 && idx == 1 => {
                            Some(n.blocks[0])
                        }
                        NodeKind::Matrix { cols, rows } => {
                            let row = idx / cols;
                            if row + 1 < *rows {
                                Some(n.blocks[idx + cols])
                            } else {
                                None
                            }
                        }
                        _ => None,
                    };
                    if let Some(target_block) = target {
                        let tb = self.block(target_block);
                        return Cursor {
                            parent: target_block,
                            left: None,
                            right: tb.first,
                        };
                    }
                }
                block_id = n.parent;
            } else {
                return cursor.clone();
            }
        }
    }

    /// Move cursor to the very start of the root block.
    pub fn move_to_start(&self) -> Cursor {
        let b = self.block(self.root);
        Cursor {
            parent: self.root,
            left: None,
            right: b.first,
        }
    }

    /// Move cursor to the very end of the root block.
    pub fn move_to_end(&self) -> Cursor {
        let b = self.block(self.root);
        Cursor {
            parent: self.root,
            left: b.last,
            right: None,
        }
    }

    /// Delete backward: remove node to the left of cursor, or exit block.
    /// MathQuill-style per-command deletion behavior.
    pub fn delete_backward(&mut self, cursor: &mut Cursor) {
        if let Some(left_id) = cursor.left {
            let n = self.node(left_id).clone();
            if n.blocks.is_empty() {
                // Leaf: just remove
                self.remove_node(left_id);
                cursor.left = n.left;
            } else {
                // Command: flatten — unwrap contents into parent
                self.flatten_command(left_id, cursor);
            }
        } else {
            // At start of block: try to delete out of parent command
            self.delete_out_of(cursor);
        }
    }

    /// Delete forward: remove node to the right of cursor.
    pub fn delete_forward(&mut self, cursor: &mut Cursor) {
        if let Some(right_id) = cursor.right {
            let n = self.node(right_id).clone();
            if n.blocks.is_empty() {
                self.remove_node(right_id);
                cursor.right = n.right;
            } else {
                self.flatten_command(right_id, cursor);
            }
        }
        // At end of block: nothing (or could merge with parent — left as no-op)
    }

    /// Flatten a command node: remove the command, dump its children's contents
    /// into the parent block at the cursor position.
    fn flatten_command(&mut self, node_id: NodeId, cursor: &mut Cursor) {
        let n = self.node(node_id).clone();
        let parent_block = n.parent;

        // Save what was after this node before removing
        let after = n.right;

        // Remove the command node from its parent block
        self.remove_node(node_id);
        cursor.left = n.left;
        cursor.right = after;
        cursor.parent = parent_block;

        // Adopt children from each child block into parent block
        for &child_block in &n.blocks {
            let adopt_cursor = Cursor {
                parent: parent_block,
                left: cursor.left,
                right: cursor.right,
            };
            let block_last = self.block(child_block).last;
            self.adopt_children(child_block, parent_block, &adopt_cursor);
            // Advance cursor past adopted content
            if let Some(last) = block_last {
                cursor.left = Some(last);
                // right stays the same (the original after-node)
            }
        }

        // Ensure cursor.right is consistent
        if let Some(left) = cursor.left {
            cursor.right = self.node(left).right;
        } else {
            cursor.right = self.block(parent_block).first;
        }
    }

    /// Backspace at the start of a child block: flatten the parent command.
    fn delete_out_of(&mut self, cursor: &mut Cursor) {
        let b = self.block(cursor.parent);
        if let Some(parent_node_id) = b.parent {
            // Place cursor before parent node, then flatten
            let n = self.node(parent_node_id).clone();
            *cursor = Cursor {
                parent: n.parent,
                left: n.left,
                right: Some(parent_node_id),
            };
            self.flatten_command(parent_node_id, cursor);
        }
    }
}
