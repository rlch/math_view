use crate::editor::arena::Arena;
use crate::editor::convert;
use crate::editor::cursor::{Cursor, Selection};
use crate::editor::intent::Intent;
use crate::editor::state::State;

/// Pure reducer: apply an intent to the editor state.
pub fn reduce(state: &mut State, intent: Intent) {
    match intent {
        Intent::InsertSymbol(ch) => {
            delete_selection(state);
            state.arena.insert_symbol_at_cursor(&mut state.cursor, ch);
        }
        Intent::InsertCommand(cmd) => {
            let selected = take_selection_nodes(state);
            let node_id = state.arena.insert_command(&mut state.cursor, cmd);
            // If there were selected nodes, put them in the first child block
            if !selected.is_empty() {
                let n = state.arena.node(node_id);
                if let Some(&first_block) = n.blocks.first() {
                    state.arena.splice_into(first_block, &selected);
                    // Cursor should be at end of first block
                    let bl = state.arena.block(first_block);
                    state.cursor = Cursor {
                        parent: first_block,
                        left: bl.last,
                        right: None,
                    };
                }
            }
        }
        Intent::MoveLeft => {
            state.selection = None;
            state.cursor = state.arena.move_left(&state.cursor);
        }
        Intent::MoveRight => {
            state.selection = None;
            state.cursor = state.arena.move_right(&state.cursor);
        }
        Intent::MoveUp => {
            state.selection = None;
            state.cursor = state.arena.move_up(&state.cursor);
        }
        Intent::MoveDown => {
            state.selection = None;
            state.cursor = state.arena.move_down(&state.cursor);
        }
        Intent::MoveToStart => {
            state.selection = None;
            state.cursor = state.arena.move_to_start();
        }
        Intent::MoveToEnd => {
            state.selection = None;
            state.cursor = state.arena.move_to_end();
        }
        Intent::SelectLeft => {
            if state.selection.is_none() {
                state.selection = Some(Selection {
                    anticursor: state.cursor.clone(),
                });
            }
            state.cursor = state.arena.move_left(&state.cursor);
        }
        Intent::SelectRight => {
            if state.selection.is_none() {
                state.selection = Some(Selection {
                    anticursor: state.cursor.clone(),
                });
            }
            state.cursor = state.arena.move_right(&state.cursor);
        }
        Intent::SelectAll => {
            let start = state.arena.move_to_start();
            let end = state.arena.move_to_end();
            state.selection = Some(Selection {
                anticursor: start,
            });
            state.cursor = end;
        }
        Intent::DeleteBackward => {
            if state.selection.is_some() {
                delete_selection(state);
            } else {
                state.arena.delete_backward(&mut state.cursor);
            }
        }
        Intent::DeleteForward => {
            if state.selection.is_some() {
                delete_selection(state);
            } else {
                state.arena.delete_forward(&mut state.cursor);
            }
        }
        Intent::WrapInCommand(cmd) => {
            let selected = take_selection_nodes(state);
            let node_id = state.arena.insert_command(&mut state.cursor, cmd);
            if !selected.is_empty() {
                let n = state.arena.node(node_id);
                if let Some(&first_block) = n.blocks.first() {
                    state.arena.splice_into(first_block, &selected);
                    let bl = state.arena.block(first_block);
                    state.cursor = Cursor {
                        parent: first_block,
                        left: bl.last,
                        right: None,
                    };
                }
            }
        }
        Intent::SetLatex(latex) => {
            match convert::import_latex(&latex) {
                Ok(new_state) => *state = new_state,
                Err(_) => {} // Keep current state on parse error
            }
        }
        Intent::SetCursor(cursor) => {
            state.selection = None;
            state.cursor = cursor;
        }
    }
}

/// Delete selected nodes, leaving cursor at the selection start.
fn delete_selection(state: &mut State) {
    if let Some(sel) = state.selection.take() {
        let (left, right) = order_cursors(&sel.anticursor, &state.cursor, &state.arena);
        if left.parent == right.parent {
            let nodes = state.arena.selected_nodes(&left, &right);
            if !nodes.is_empty() {
                let block_id = left.parent;
                let new_right = right.right;
                state.arena.splice_out(&nodes);
                state.cursor = Cursor {
                    parent: block_id,
                    left: left.left,
                    right: new_right,
                };
                return;
            }
        }
        state.cursor = left.clone();
    }
}

/// Take selected nodes out of the arena, returning them.
/// Leaves cursor at selection start. Clears selection.
fn take_selection_nodes(state: &mut State) -> Vec<crate::editor::arena::NodeId> {
    if let Some(sel) = state.selection.take() {
        let (left, right) = order_cursors(&sel.anticursor, &state.cursor, &state.arena);
        if left.parent == right.parent {
            let nodes = state.arena.selected_nodes(&left, &right);
            if !nodes.is_empty() {
                let block_id = left.parent;
                state.arena.splice_out(&nodes);
                // After splicing, cursor sits between left.left and right.right
                // (which is the gap where the nodes were).
                let new_right = right.right;
                state.cursor = Cursor {
                    parent: block_id,
                    left: left.left,
                    right: new_right,
                };
                return nodes;
            }
        }
        state.cursor = left.clone();
    }
    Vec::new()
}

/// Order two cursors in the same block: returns (left, right).
fn order_cursors<'a>(
    a: &'a Cursor,
    b: &'a Cursor,
    arena: &Arena,
) -> (&'a Cursor, &'a Cursor) {
    if a.parent != b.parent {
        return (a, b);
    }
    // If a is at block start, a is leftmost
    if a.left.is_none() {
        return (a, b);
    }
    if b.left.is_none() {
        return (b, a);
    }
    // Walk right from a.left to see if we reach b.left
    // If we do, a is to the left of b.
    let mut current = a.left;
    while let Some(nid) = current {
        if Some(nid) == b.left {
            // a's left is before b's left → b is to the right
            return (a, b);
        }
        current = arena.node(nid).right;
    }
    // Didn't find b after a → b is to the left
    (b, a)
}
