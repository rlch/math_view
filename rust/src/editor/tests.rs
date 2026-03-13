use crate::editor::*;

// ============================================================
// Arena construction from LaTeX and serialization back
// ============================================================

#[test]
fn test_import_simple_symbols() {
    let state = convert::import_latex("x+1").unwrap();
    let children = state.arena.block_children(state.arena.root);
    assert_eq!(children.len(), 3);
    assert!(matches!(
        &state.arena.node(children[0]).kind,
        NodeKind::Symbol { text, .. } if text == "x"
    ));
    assert!(matches!(
        &state.arena.node(children[1]).kind,
        NodeKind::Symbol { text, atom_family: AtomFamily::Bin } if text == "+"
    ));
    assert!(matches!(
        &state.arena.node(children[2]).kind,
        NodeKind::Symbol { text, .. } if text == "1"
    ));
}

#[test]
fn test_import_frac() {
    let state = convert::import_latex("\\frac{x+1}{2}").unwrap();
    let children = state.arena.block_children(state.arena.root);
    assert_eq!(children.len(), 1);

    let frac = &state.arena.node(children[0]);
    assert!(matches!(&frac.kind, NodeKind::Frac));
    assert_eq!(frac.blocks.len(), 2);

    // Numerator: x+1 (3 nodes)
    let numer = state.arena.block_children(frac.blocks[0]);
    assert_eq!(numer.len(), 3);

    // Denominator: 2 (1 node)
    let denom = state.arena.block_children(frac.blocks[1]);
    assert_eq!(denom.len(), 1);
}

#[test]
fn test_latex_roundtrip_simple() {
    let state = convert::import_latex("x+1").unwrap();
    let latex = state.arena.to_latex();
    assert_eq!(latex, "x+1");
}

#[test]
fn test_latex_roundtrip_frac() {
    let state = convert::import_latex("\\frac{x+1}{2}").unwrap();
    let latex = state.arena.to_latex();
    assert_eq!(latex, "\\frac{x+1}{2}");
}

#[test]
fn test_latex_roundtrip_sqrt() {
    let state = convert::import_latex("\\sqrt{x}").unwrap();
    let latex = state.arena.to_latex();
    assert_eq!(latex, "\\sqrt{x}");
}

#[test]
fn test_latex_roundtrip_sup() {
    let state = convert::import_latex("x^{2}").unwrap();
    let latex = state.arena.to_latex();
    assert_eq!(latex, "x^{2}");
}

#[test]
fn test_latex_roundtrip_sub() {
    let state = convert::import_latex("x_{i}").unwrap();
    let latex = state.arena.to_latex();
    assert_eq!(latex, "x_{i}");
}

#[test]
fn test_latex_roundtrip_leftright() {
    let state = convert::import_latex("\\left(x+1\\right)").unwrap();
    let latex = state.arena.to_latex();
    assert_eq!(latex, "\\left(x+1\\right)");
}

// ============================================================
// Cursor navigation — right through frac numer → denom → exit
// ============================================================

#[test]
fn test_navigate_right_through_frac() {
    let state = convert::import_latex("\\frac{a}{b}").unwrap();
    // Start at beginning
    let start = state.arena.move_to_start();
    assert_eq!(start.parent, state.arena.root);
    assert!(start.left.is_none());

    // Move right: enter frac numerator
    let c1 = state.arena.move_right(&start);
    let frac_node = start.right.unwrap();
    let frac = state.arena.node(frac_node);
    assert_eq!(c1.parent, frac.blocks[0]); // In numerator
    assert!(c1.left.is_none()); // At start of numerator

    // Move right: past 'a' in numerator
    let c2 = state.arena.move_right(&c1);
    assert_eq!(c2.parent, frac.blocks[0]); // Still in numerator
    assert!(c2.left.is_some()); // Past 'a'
    assert!(c2.right.is_none()); // At end of numerator

    // Move right: exit numer → enter denom
    let c3 = state.arena.move_right(&c2);
    assert_eq!(c3.parent, frac.blocks[1]); // In denominator
    assert!(c3.left.is_none()); // At start of denominator

    // Move right: past 'b' in denom
    let c4 = state.arena.move_right(&c3);
    assert_eq!(c4.parent, frac.blocks[1]);
    assert!(c4.right.is_none());

    // Move right: exit denom → exit frac → after frac in root
    let c5 = state.arena.move_right(&c4);
    assert_eq!(c5.parent, state.arena.root);
    assert_eq!(c5.left, Some(frac_node));
    assert!(c5.right.is_none());
}

#[test]
fn test_navigate_left_through_frac() {
    let state = convert::import_latex("\\frac{a}{b}").unwrap();
    let end = state.arena.move_to_end();

    // Move left: enter frac from right → enter denom at end
    let c1 = state.arena.move_left(&end);
    let frac_node = end.left.unwrap();
    let frac = state.arena.node(frac_node);
    assert_eq!(c1.parent, frac.blocks[1]); // In denominator
    assert!(c1.right.is_none()); // At end of denom

    // Move left: before 'b' in denom
    let c2 = state.arena.move_left(&c1);
    assert_eq!(c2.parent, frac.blocks[1]);
    assert!(c2.left.is_none());

    // Move left: exit denom → enter numer at end
    let c3 = state.arena.move_left(&c2);
    assert_eq!(c3.parent, frac.blocks[0]);
    assert!(c3.right.is_none());
}

// ============================================================
// InsertCommand(Frac) wraps selection into fraction
// ============================================================

#[test]
fn test_insert_frac_wraps_selection() {
    let mut state = convert::import_latex("x+1").unwrap();

    // Select "x+1" (all)
    reduce::reduce(&mut state, Intent::SelectAll);

    // Wrap in frac
    reduce::reduce(&mut state, Intent::InsertCommand(CommandKind::Frac));

    // Result should be \frac{x+1}{} — cursor in numerator
    let latex = state.arena.to_latex();
    assert_eq!(latex, "\\frac{x+1}{}");
}

// ============================================================
// DeleteBackward at start of denominator flattens fraction
// ============================================================

#[test]
fn test_delete_backward_flattens_frac() {
    let mut state = convert::import_latex("\\frac{a}{b}").unwrap();

    // Navigate to start of denominator
    let start = state.arena.move_to_start();
    state.cursor = start;

    // Right into frac → numer start
    reduce::reduce(&mut state, Intent::MoveRight);
    // Right past 'a'
    reduce::reduce(&mut state, Intent::MoveRight);
    // Right → numer end → denom start
    reduce::reduce(&mut state, Intent::MoveRight);

    // Now at start of denominator. Delete backward should flatten.
    reduce::reduce(&mut state, Intent::DeleteBackward);

    // After flattening, frac is gone, content is "ab"
    let latex = state.arena.to_latex();
    assert_eq!(latex, "ab");
}

// ============================================================
// Vertical navigation in fractions
// ============================================================

#[test]
fn test_vertical_navigation_frac() {
    let state = convert::import_latex("\\frac{a}{b}").unwrap();

    // Navigate into numerator
    let start = state.arena.move_to_start();
    let in_numer = state.arena.move_right(&start);
    let frac_node = start.right.unwrap();
    let frac = state.arena.node(frac_node);
    assert_eq!(in_numer.parent, frac.blocks[0]);

    // Move down from numerator → denominator
    let in_denom = state.arena.move_down(&in_numer);
    assert_eq!(in_denom.parent, frac.blocks[1]);

    // Move up from denominator → numerator
    let back_numer = state.arena.move_up(&in_denom);
    assert_eq!(back_numer.parent, frac.blocks[0]);
}

// ============================================================
// Symbol insertion
// ============================================================

#[test]
fn test_insert_symbols() {
    let mut state = State::new();
    reduce::reduce(&mut state, Intent::InsertSymbol('x'));
    reduce::reduce(&mut state, Intent::InsertSymbol('+'));
    reduce::reduce(&mut state, Intent::InsertSymbol('1'));
    assert_eq!(state.arena.to_latex(), "x+1");
}

// ============================================================
// Delete forward
// ============================================================

#[test]
fn test_delete_forward() {
    let mut state = convert::import_latex("abc").unwrap();
    state.cursor = state.arena.move_to_start();
    reduce::reduce(&mut state, Intent::DeleteForward);
    assert_eq!(state.arena.to_latex(), "bc");
}

// ============================================================
// SetLatex replaces content
// ============================================================

#[test]
fn test_set_latex() {
    let mut state = State::new();
    reduce::reduce(&mut state, Intent::InsertSymbol('x'));
    reduce::reduce(&mut state, Intent::SetLatex("y+z".to_string()));
    assert_eq!(state.arena.to_latex(), "y+z");
}

// ============================================================
// Integration test: programmatic intent sequence producing expected LaTeX
// ============================================================

#[test]
fn test_intent_sequence_builds_expression() {
    let mut state = State::new();

    // Build: \frac{x}{y} + 1
    reduce::reduce(&mut state, Intent::InsertCommand(CommandKind::Frac));
    // Cursor is now in numerator
    reduce::reduce(&mut state, Intent::InsertSymbol('x'));
    // Move to denominator
    reduce::reduce(&mut state, Intent::MoveRight); // exit numer → enter denom
    reduce::reduce(&mut state, Intent::InsertSymbol('y'));
    // Move out of frac
    reduce::reduce(&mut state, Intent::MoveRight); // past y to end of denom
    reduce::reduce(&mut state, Intent::MoveRight); // exit denom → exit frac → root
    // Continue in root
    reduce::reduce(&mut state, Intent::InsertSymbol('+'));
    reduce::reduce(&mut state, Intent::InsertSymbol('1'));

    assert_eq!(state.arena.to_latex(), "\\frac{x}{y}+1");
}

#[test]
fn test_build_quadratic_formula() {
    let mut state = State::new();

    // Build: \frac{-b}{2a}
    reduce::reduce(&mut state, Intent::InsertCommand(CommandKind::Frac));
    // In numerator
    reduce::reduce(&mut state, Intent::InsertSymbol('-'));
    reduce::reduce(&mut state, Intent::InsertSymbol('b'));
    // Move to denom
    reduce::reduce(&mut state, Intent::MoveRight);
    reduce::reduce(&mut state, Intent::InsertSymbol('2'));
    reduce::reduce(&mut state, Intent::InsertSymbol('a'));
    // Exit frac
    reduce::reduce(&mut state, Intent::MoveRight);
    reduce::reduce(&mut state, Intent::MoveRight);

    assert_eq!(state.arena.to_latex(), "\\frac{-b}{2a}");
}

// ============================================================
// Empty blocks
// ============================================================

#[test]
fn test_empty_blocks() {
    let mut state = State::new();
    reduce::reduce(&mut state, Intent::InsertCommand(CommandKind::Frac));
    // Both numer and denom are empty, plus the root block cursor is past frac
    let empty = state.arena.empty_blocks();
    // The frac's numer and denom are empty (cursor is in numer but it's still empty)
    // Actually cursor is IN the numer block, and we haven't inserted anything yet
    // Numer is empty, denom is empty
    assert!(empty.len() >= 1); // At least the denom is empty
}

// ============================================================
// Arena operations
// ============================================================

#[test]
fn test_block_children_order() {
    let state = convert::import_latex("abc").unwrap();
    let children = state.arena.block_children(state.arena.root);
    assert_eq!(children.len(), 3);

    // Check doubly-linked list integrity
    for i in 0..children.len() {
        let n = state.arena.node(children[i]);
        if i > 0 {
            assert_eq!(n.left, Some(children[i - 1]));
        } else {
            assert!(n.left.is_none());
        }
        if i < children.len() - 1 {
            assert_eq!(n.right, Some(children[i + 1]));
        } else {
            assert!(n.right.is_none());
        }
    }
}

#[test]
fn test_move_to_start_end() {
    let state = convert::import_latex("abc").unwrap();
    let start = state.arena.move_to_start();
    assert!(start.left.is_none());
    assert!(start.right.is_some());

    let end = state.arena.move_to_end();
    assert!(end.left.is_some());
    assert!(end.right.is_none());
}

// ============================================================
// Overline, underline
// ============================================================

#[test]
fn test_latex_roundtrip_overline() {
    let state = convert::import_latex("\\overline{x}").unwrap();
    assert_eq!(state.arena.to_latex(), "\\overline{x}");
}

#[test]
fn test_latex_roundtrip_underline() {
    let state = convert::import_latex("\\underline{x}").unwrap();
    assert_eq!(state.arena.to_latex(), "\\underline{x}");
}

// ============================================================
// Nested structures
// ============================================================

#[test]
fn test_nested_frac() {
    let state = convert::import_latex("\\frac{\\frac{a}{b}}{c}").unwrap();
    let latex = state.arena.to_latex();
    assert_eq!(latex, "\\frac{\\frac{a}{b}}{c}");
}
