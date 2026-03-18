use crate::editor::arena::Arena;
use crate::editor::command_table;
use crate::editor::convert;
use crate::editor::cursor::{Cursor, Selection};
use crate::editor::intent::{CommandKind, Intent};
use crate::editor::node_kind::{AtomFamily, NodeKind};
use crate::editor::state::State;

/// Pure reducer: apply an intent to the editor state.
pub fn reduce(state: &mut State, intent: Intent) {
    match intent {
        Intent::InsertSymbol(ch) => {
            delete_selection(state);
            if ch.is_ascii_digit() && try_auto_subscript(state, ch) {
                // Auto-subscript handled the insertion
            } else {
                state.arena.insert_symbol_at_cursor(&mut state.cursor, ch);
                if ch.is_alphabetic() {
                    try_auto_operator(state);
                }
            }
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
        Intent::EscapeRight => {
            state.selection = None;
            state.cursor = state.arena.exit_block_right(state.cursor.parent)
                .unwrap_or_else(|| state.arena.move_right(&state.cursor));
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
        Intent::LiveFraction => {
            delete_selection(state);
            // Walk left from cursor, collecting nodes to wrap into the numerator.
            // Stop at block start or at a node with Bin/Rel/Open/Punct family.
            let mut to_wrap: Vec<crate::editor::arena::NodeId> = Vec::new();
            let mut current = state.cursor.left;
            while let Some(nid) = current {
                let node = state.arena.node(nid);
                if let NodeKind::Symbol { atom_family, .. } = &node.kind {
                    match atom_family {
                        AtomFamily::Bin | AtomFamily::Rel | AtomFamily::Open | AtomFamily::Punct => break,
                        _ => {}
                    }
                }
                to_wrap.push(nid);
                current = node.left;
            }
            // Reverse to get left-to-right order
            to_wrap.reverse();

            // Splice out the collected nodes
            if !to_wrap.is_empty() {
                let first = to_wrap[0];
                let before = state.arena.node(first).left;
                state.cursor.left = before;
                state.arena.splice_out(&to_wrap);
            }

            // Insert a Frac command at cursor
            let node_id = state.arena.insert_command(&mut state.cursor, CommandKind::Frac);

            // Splice the collected nodes into the numerator (first child block)
            let n = state.arena.node(node_id);
            let numer_block = n.blocks[0];
            let denom_block = n.blocks[1];
            if !to_wrap.is_empty() {
                state.arena.splice_into(numer_block, &to_wrap);
            }

            // Place cursor in denominator
            state.cursor = Cursor {
                parent: denom_block,
                left: None,
                right: None,
            };
        }
        Intent::SetLatex(latex) => {
            match convert::import_latex(&latex) {
                Ok(new_state) => *state = new_state,
                Err(_) => {} // Keep current state on parse error
            }
        }
        Intent::InsertCommandInput => {
            delete_selection(state);
            state.arena.insert_at_cursor(
                &mut state.cursor,
                NodeKind::LatexCommandInput { text: String::new() },
            );
        }
        Intent::CommandInputType(ch) => {
            if let Some(left_id) = state.cursor.left {
                let node = state.arena.node_mut(left_id);
                if let NodeKind::LatexCommandInput { ref mut text } = node.kind {
                    text.push(ch);
                }
            }
        }
        Intent::CommandInputBackspace => {
            if let Some(left_id) = state.cursor.left {
                let is_empty = matches!(
                    &state.arena.node(left_id).kind,
                    NodeKind::LatexCommandInput { text } if text.is_empty()
                );
                if is_empty {
                    let n = state.arena.node(left_id).clone();
                    state.arena.remove_node(left_id);
                    state.cursor.left = n.left;
                } else {
                    let node = state.arena.node_mut(left_id);
                    if let NodeKind::LatexCommandInput { ref mut text } = node.kind {
                        text.pop();
                    }
                }
            }
        }
        Intent::ResolveCurrentCommandInput => {
            if let Some(left_id) = state.cursor.left {
                let name = match &state.arena.node(left_id).kind {
                    NodeKind::LatexCommandInput { text } => text.clone(),
                    _ => return,
                };
                // Remove the LatexCommandInput node
                let n = state.arena.node(left_id).clone();
                state.arena.remove_node(left_id);
                state.cursor.left = n.left;
                // Resolve using existing logic
                resolve_command_name(state, name);
            }
        }
        Intent::CancelCommandInput => {
            if let Some(left_id) = state.cursor.left {
                if matches!(
                    &state.arena.node(left_id).kind,
                    NodeKind::LatexCommandInput { .. }
                ) {
                    let n = state.arena.node(left_id).clone();
                    state.arena.remove_node(left_id);
                    state.cursor.left = n.left;
                }
            }
        }
        Intent::ResolveCommandInput(name) => {
            delete_selection(state);
            resolve_command_name(state, name);
        }
        Intent::SetCursor(cursor) => {
            state.selection = None;
            state.cursor = cursor;
        }
        Intent::InsertLatex(latex) => {
            delete_selection(state);
            // Build the full LaTeX: existing content with pasted content spliced at cursor.
            // Serialize current state, find cursor position, inject paste, re-import.
            let before = {
                let mut out = String::new();
                // Serialize nodes before cursor
                let block = state.arena.block(state.cursor.parent);
                let mut cur = block.first;
                while cur != state.cursor.right && cur.is_some() {
                    let nid = cur.unwrap();
                    state.arena.serialize_node_inner(nid, &mut out, false);
                    cur = state.arena.node(nid).right;
                }
                out
            };
            let after = {
                let mut out = String::new();
                let mut cur = state.cursor.right;
                while let Some(nid) = cur {
                    state.arena.serialize_node_inner(nid, &mut out, false);
                    cur = state.arena.node(nid).right;
                }
                out
            };
            // Only works at root level for now. For nested pastes, fall back to
            // re-importing the entire expression.
            if state.cursor.parent == state.arena.root {
                let full = format!("{}{}{}", before, latex, after);
                if let Ok(new_state) = convert::import_latex(&full) {
                    state.arena = new_state.arena;
                    // Position cursor after pasted content
                    let target_len = before.len() + latex.len();
                    let mut cur_len = 0;
                    let mut cur = state.arena.block(state.arena.root).first;
                    let mut last = None;
                    while let Some(nid) = cur {
                        let node_latex = crate::editor::serialize::serialize_single_node(&state.arena, nid);
                        cur_len += node_latex.len();
                        last = Some(nid);
                        if cur_len >= target_len { break; }
                        cur = state.arena.node(nid).right;
                    }
                    state.cursor = Cursor {
                        parent: state.arena.root,
                        left: last,
                        right: last.and_then(|l| state.arena.node(l).right),
                    };
                    state.selection = None;
                }
            }
        }
        Intent::DragUpdate(cursor) => {
            // If no selection anchor, set one at current cursor position
            if state.selection.is_none() {
                state.selection = Some(Selection {
                    anticursor: state.cursor.clone(),
                });
            }
            // Only update cursor if same block as anchor (single-block selection)
            if let Some(ref sel) = state.selection {
                if sel.anticursor.parent == cursor.parent {
                    state.cursor = cursor;
                }
            }
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

/// Resolve a command name into the appropriate insertion at cursor.
fn resolve_command_name(state: &mut State, name: String) {
    match command_table::lookup(&name) {
        Some(command_table::Resolved::Command(cmd)) => {
            state.arena.insert_command(&mut state.cursor, cmd);
        }
        Some(command_table::Resolved::Symbol { text, family }) => {
            state.arena.insert_at_cursor(
                &mut state.cursor,
                NodeKind::Symbol {
                    text,
                    atom_family: family,
                },
            );
        }
        None => {
            // Not found in command table: insert letters as individual
            // symbols and then check if they form an auto-operator name
            // (e.g. \sin → s,i,n → \operatorname{sin}).
            for ch in name.chars() {
                state.arena.insert_symbol_at_cursor(&mut state.cursor, ch);
            }
            try_auto_operator(state);
        }
    }
}

/// Public version of order_cursors for use by editor_api.
pub fn order_cursors_pub<'a>(
    a: &'a Cursor,
    b: &'a Cursor,
    arena: &Arena,
) -> (&'a Cursor, &'a Cursor) {
    order_cursors(a, b, arena)
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

// ============================================================
// Auto-operator detection
// ============================================================

const AUTO_OPERATOR_NAMES: &[&str] = &[
    "arccos", "arcsin", "arctan",
    "arg", "cos", "cosh", "cot", "coth", "csc", "csch",
    "deg", "det", "dim", "exp",
    "gcd", "hom", "inf", "ker",
    "lcm", "lg", "lim", "ln", "log",
    "max", "min", "mod",
    "Pr",
    "sec", "sech", "sin", "sinh", "sup",
    "tan", "tanh",
];

/// After inserting a letter, check if the consecutive letters ending at cursor
/// form a known operator name. If so, replace them with an OperatorName node.
/// Also handles extending an existing OperatorName (e.g. sin + h → sinh).
fn try_auto_operator(state: &mut State) {
    use crate::editor::arena::NodeId;

    // Collect consecutive letter Symbol nodes ending at cursor.left,
    // walking leftward. We store (NodeId, char) in reverse order.
    let mut letters_rev: Vec<(NodeId, char)> = Vec::new();
    let mut preceding_op: Option<NodeId> = None;
    let mut current = state.cursor.left;
    while let Some(nid) = current {
        let node = state.arena.node(nid);
        match &node.kind {
            NodeKind::Symbol { text, .. } if text.len() == 1 => {
                let ch = text.chars().next().unwrap();
                if ch.is_alphabetic() {
                    letters_rev.push((nid, ch));
                    current = node.left;
                } else {
                    break;
                }
            }
            NodeKind::OperatorName => {
                // There's an existing OperatorName immediately before the loose letters.
                // We may need to extend it (e.g. \operatorname{sin} + h → \operatorname{sinh}).
                preceding_op = Some(nid);
                break;
            }
            _ => break,
        }
    }

    if letters_rev.is_empty() {
        return;
    }

    // If there's a preceding OperatorName, extract its letters and prepend them
    let mut op_letter_nodes: Vec<(NodeId, char)> = Vec::new();
    if let Some(op_nid) = preceding_op {
        let op_node = state.arena.node(op_nid);
        let child_block = op_node.blocks[0];
        let mut cur = state.arena.block(child_block).first;
        while let Some(nid) = cur {
            let node = state.arena.node(nid);
            if let NodeKind::Symbol { text, .. } = &node.kind {
                if text.len() == 1 {
                    let ch = text.chars().next().unwrap();
                    op_letter_nodes.push((nid, ch));
                }
            }
            cur = state.arena.node(nid).right;
        }
    }

    // Build the full string: op_letters (left-to-right) + loose letters (left-to-right)
    let mut full_letters: String = op_letter_nodes.iter().map(|(_, ch)| ch).collect();
    let loose_letters: String = letters_rev.iter().rev().map(|(_, ch)| ch).collect();
    full_letters.push_str(&loose_letters);

    // Find the longest suffix of full_letters that matches an operator name
    let mut best_len: usize = 0;
    for &name in AUTO_OPERATOR_NAMES {
        if name.len() <= full_letters.len() && name.len() > best_len && full_letters.ends_with(name) {
            best_len = name.len();
        }
    }

    if best_len == 0 {
        return;
    }

    // Determine how many of the loose letters vs op letters are consumed
    let loose_count = letters_rev.len();
    let block_id = state.cursor.parent;
    let cursor_right = state.cursor.right;

    if best_len <= loose_count {
        // Match is entirely within the loose letters (no need to touch preceding op)
        let matched_nodes: Vec<NodeId> = letters_rev[..best_len].iter().rev().map(|(nid, _)| *nid).collect();

        let before_match = state.arena.node(matched_nodes[0]).left;
        state.arena.splice_out(&matched_nodes);

        state.cursor = Cursor {
            parent: block_id,
            left: before_match,
            right: cursor_right,
        };

        let op_node_id = state.arena.insert_at_cursor(&mut state.cursor, NodeKind::OperatorName);
        let child_block = state.arena.alloc_block(Some(op_node_id));
        state.arena.node_mut(op_node_id).blocks = vec![child_block];
        state.arena.splice_into(child_block, &matched_nodes);

        state.cursor = Cursor {
            parent: block_id,
            left: Some(op_node_id),
            right: cursor_right,
        };
    } else if let Some(op_nid) = preceding_op {
        // Match extends into (or fully covers) the preceding OperatorName.
        // We need to unwrap the old OperatorName and re-wrap with the new longer match.

        // All loose letter nodes are part of the match
        let loose_nodes: Vec<NodeId> = letters_rev.iter().rev().map(|(nid, _)| *nid).collect();

        // Splice out the loose letters from the parent block
        state.arena.splice_out(&loose_nodes);

        // The old OperatorName's child block letters are already collected in op_letter_nodes.
        // We need to remove the old OperatorName node and take its letters.
        let old_child_block = state.arena.node(op_nid).blocks[0];
        let old_op_letters: Vec<NodeId> = state.arena.block_children(old_child_block);

        // Splice old letters out of the child block
        if !old_op_letters.is_empty() {
            state.arena.splice_out(&old_op_letters);
        }

        // Remove the old OperatorName node from the parent block
        let before_old_op = state.arena.node(op_nid).left;
        state.arena.remove_node(op_nid);

        // Build the combined node list: old op letters + loose letters
        let mut all_nodes = old_op_letters;
        all_nodes.extend(loose_nodes);

        // Position cursor where the old op was
        state.cursor = Cursor {
            parent: block_id,
            left: before_old_op,
            right: cursor_right,
        };

        // Create new OperatorName
        let new_op_id = state.arena.insert_at_cursor(&mut state.cursor, NodeKind::OperatorName);
        let child_block = state.arena.alloc_block(Some(new_op_id));
        state.arena.node_mut(new_op_id).blocks = vec![child_block];
        state.arena.splice_into(child_block, &all_nodes);

        state.cursor = Cursor {
            parent: block_id,
            left: Some(new_op_id),
            right: cursor_right,
        };
    }
}

/// MathQuill-style auto-subscript: typing a digit immediately after an italic
/// variable (or after a Sup/SupSub whose base is a variable) auto-wraps the
/// digit into a subscript. Returns true if auto-subscript was applied.
///
/// Examples:
///   x + 2 → x_{2}        (variable + digit)
///   x^{2} + 2 → x_{2}^{2}  (exponentiated variable + digit)
///
/// Does NOT trigger after operator names (\sin + 2 → \sin 2).
fn try_auto_subscript(state: &mut State, digit: char) -> bool {

    let cursor_left = match state.cursor.left {
        Some(nid) => nid,
        None => return false,
    };

    // Check what's at cursor.left (the node the digit would go after).
    // Case 1: cursor.left is an italic variable Symbol
    // Case 2: cursor.left is a Sup/SupSub whose left sibling is an italic variable
    let left_kind = &state.arena.node(cursor_left).kind;

    let (base_var, supsub_node) = match left_kind {
        NodeKind::Symbol { text, atom_family: AtomFamily::Ord } if text.len() == 1 => {
            let ch = text.chars().next().unwrap();
            if ch.is_alphabetic() {
                (cursor_left, None)
            } else {
                return false;
            }
        }
        NodeKind::Sup | NodeKind::Sub | NodeKind::SupSub => {
            // Check if the left sibling of this Sup/Sub is an italic variable
            let left_of_sup = state.arena.node(cursor_left).left;
            match left_of_sup {
                Some(var_id) => {
                    let var_kind = &state.arena.node(var_id).kind;
                    match var_kind {
                        NodeKind::Symbol { text, atom_family: AtomFamily::Ord }
                            if text.len() == 1 && text.chars().next().unwrap().is_alphabetic() =>
                        {
                            (var_id, Some(cursor_left))
                        }
                        _ => return false,
                    }
                }
                None => return false,
            }
        }
        _ => return false,
    };

    // Don't auto-subscript if we're already inside a subscript block
    let parent_block = state.cursor.parent;
    if let Some(parent_node) = state.arena.block(parent_block).parent {
        let parent_kind = &state.arena.node(parent_node).kind;
        if matches!(parent_kind, NodeKind::Sub | NodeKind::SupSub) {
            return false;
        }
    }

    let block_id = state.cursor.parent;
    let cursor_right = state.cursor.right;

    match supsub_node {
        None => {
            // Case 1: variable + digit → variable_{digit}
            // Insert a Sub command after the variable, put the digit inside
            state.cursor = Cursor {
                parent: block_id,
                left: Some(base_var),
                right: cursor_right,
            };

            let sub_id = state.arena.insert_at_cursor(&mut state.cursor, NodeKind::Sub);
            let child_block = state.arena.alloc_block(Some(sub_id));
            state.arena.node_mut(sub_id).blocks = vec![child_block];

            // Insert digit into the subscript block
            let mut inner_cursor = Cursor {
                parent: child_block,
                left: None,
                right: None,
            };
            state.arena.insert_symbol_at_cursor(&mut inner_cursor, digit);

            // Cursor goes after the Sub in the parent block (MathQuill behavior:
            // next digit typed goes into the subscript, not after it)
            state.cursor = Cursor {
                parent: block_id,
                left: Some(sub_id),
                right: cursor_right,
            };
        }
        Some(existing_sup_id) => {
            let existing_kind = state.arena.node(existing_sup_id).kind.clone();
            match existing_kind {
                NodeKind::Sup => {
                    // Case 2: variable + Sup{...} + digit → variable + SupSub{sup, sub=digit}
                    // Change the Sup to SupSub, add a sub block with the digit
                    let sup_block = state.arena.node(existing_sup_id).blocks[0];
                    let sub_block = state.arena.alloc_block(Some(existing_sup_id));

                    state.arena.node_mut(existing_sup_id).kind = NodeKind::SupSub;
                    state.arena.node_mut(existing_sup_id).blocks = vec![sup_block, sub_block];

                    // Insert digit into the new sub block
                    let mut inner_cursor = Cursor {
                        parent: sub_block,
                        left: None,
                        right: None,
                    };
                    state.arena.insert_symbol_at_cursor(&mut inner_cursor, digit);

                    // Cursor stays after the SupSub in parent block
                    state.cursor = Cursor {
                        parent: block_id,
                        left: Some(existing_sup_id),
                        right: cursor_right,
                    };
                }
                NodeKind::Sub => {
                    // Already has a subscript — append digit into it
                    let sub_block = state.arena.node(existing_sup_id).blocks[0];
                    let last = state.arena.block(sub_block).last;
                    let mut inner_cursor = Cursor {
                        parent: sub_block,
                        left: last,
                        right: None,
                    };
                    state.arena.insert_symbol_at_cursor(&mut inner_cursor, digit);

                    state.cursor = Cursor {
                        parent: block_id,
                        left: Some(existing_sup_id),
                        right: cursor_right,
                    };
                }
                NodeKind::SupSub => {
                    // Already has both — append digit into sub block (blocks[1])
                    let sub_block = state.arena.node(existing_sup_id).blocks[1];
                    let last = state.arena.block(sub_block).last;
                    let mut inner_cursor = Cursor {
                        parent: sub_block,
                        left: last,
                        right: None,
                    };
                    state.arena.insert_symbol_at_cursor(&mut inner_cursor, digit);

                    state.cursor = Cursor {
                        parent: block_id,
                        left: Some(existing_sup_id),
                        right: cursor_right,
                    };
                }
                _ => return false,
            }
        }
    }

    true
}
