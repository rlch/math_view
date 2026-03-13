use katex::parser::parse_node::*;
use katex::symbols::Atom;
use katex::types::Mode;

use crate::editor::arena::{Arena, BlockId, NodeId};
use crate::editor::cursor::Cursor;
use crate::editor::node_kind::{AtomFamily, NodeKind};
use crate::editor::state::State;

/// Parse LaTeX and build an editor State from it.
pub fn import_latex(latex: &str) -> Result<State, String> {
    let ctx = katex::KatexContext::default();
    let settings = katex::Settings::default();
    let parse_tree =
        katex::parse(&ctx, latex, &settings).map_err(|e| format!("Parse error: {e}"))?;

    let mut arena = Arena::new();
    let root = arena.root;

    for node in &parse_tree {
        import_node(&mut arena, root, node);
    }

    let b = arena.block(root);
    let cursor = Cursor {
        parent: root,
        left: b.last,
        right: None,
    };

    Ok(State {
        arena,
        cursor,
        selection: None,
    })
}

/// Import a single AnyParseNode into a block, appending at end.
fn import_node(arena: &mut Arena, block_id: BlockId, node: &AnyParseNode) {
    match node {
        AnyParseNode::OrdGroup(group) => {
            for child in &group.body {
                import_node(arena, block_id, child);
            }
        }
        AnyParseNode::MathOrd(ord) => {
            insert_symbol_text(arena, block_id, ord.text.as_str(), AtomFamily::Ord);
        }
        AnyParseNode::TextOrd(ord) => {
            insert_symbol_text(arena, block_id, ord.text.as_str(), AtomFamily::Ord);
        }
        AnyParseNode::Atom(atom) => {
            let family = convert_atom_family(atom.family);
            insert_symbol_text(arena, block_id, atom.text.as_str(), family);
        }
        AnyParseNode::Spacing(sp) => {
            insert_symbol_text(arena, block_id, sp.text.as_str(), AtomFamily::Ord);
        }
        AnyParseNode::Genfrac(frac) => {
            let kind = NodeKind::Frac;
            let node_id = append_command(arena, block_id, kind, 2);

            let n = arena.node(node_id);
            let numer_block = n.blocks[0];
            let denom_block = n.blocks[1];

            import_node(arena, numer_block, &frac.numer);
            import_node(arena, denom_block, &frac.denom);
        }
        AnyParseNode::Sqrt(sqrt) => {
            if let Some(ref index) = sqrt.index {
                let kind = NodeKind::NthRoot;
                let node_id = append_command(arena, block_id, kind, 2);
                let n = arena.node(node_id);
                let index_block = n.blocks[0];
                let body_block = n.blocks[1];
                import_node(arena, index_block, index);
                import_node(arena, body_block, &sqrt.body);
            } else {
                let kind = NodeKind::Sqrt;
                let node_id = append_command(arena, block_id, kind, 1);
                let n = arena.node(node_id);
                let body_block = n.blocks[0];
                import_node(arena, body_block, &sqrt.body);
            }
        }
        AnyParseNode::SupSub(supsub) => {
            // Import the base first (as siblings in this block)
            if let Some(ref base) = supsub.base {
                import_node(arena, block_id, base);
            }

            match (&supsub.sup, &supsub.sub) {
                (Some(sup), Some(sub)) => {
                    let node_id = append_command(arena, block_id, NodeKind::SupSub, 2);
                    let n = arena.node(node_id);
                    let sup_block = n.blocks[0];
                    let sub_block = n.blocks[1];
                    import_node(arena, sup_block, sup);
                    import_node(arena, sub_block, sub);
                }
                (Some(sup), None) => {
                    let node_id = append_command(arena, block_id, NodeKind::Sup, 1);
                    let n = arena.node(node_id);
                    let sup_block = n.blocks[0];
                    import_node(arena, sup_block, sup);
                }
                (None, Some(sub)) => {
                    let node_id = append_command(arena, block_id, NodeKind::Sub, 1);
                    let n = arena.node(node_id);
                    let sub_block = n.blocks[0];
                    import_node(arena, sub_block, sub);
                }
                (None, None) => {}
            }
        }
        AnyParseNode::LeftRight(lr) => {
            let kind = NodeKind::LeftRight {
                left_delim: lr.left.clone(),
                right_delim: lr.right.clone(),
            };
            let node_id = append_command(arena, block_id, kind, 1);
            let n = arena.node(node_id);
            let body_block = n.blocks[0];
            for child in &lr.body {
                import_node(arena, body_block, child);
            }
        }
        AnyParseNode::Accent(acc) => {
            let kind = NodeKind::Accent {
                label: acc.label.clone(),
            };
            let node_id = append_command(arena, block_id, kind, 1);
            let n = arena.node(node_id);
            let body_block = n.blocks[0];
            import_node(arena, body_block, &acc.base);
        }
        AnyParseNode::Overline(ol) => {
            let node_id = append_command(arena, block_id, NodeKind::Overline, 1);
            let n = arena.node(node_id);
            let body_block = n.blocks[0];
            import_node(arena, body_block, &ol.body);
        }
        AnyParseNode::Underline(ul) => {
            let node_id = append_command(arena, block_id, NodeKind::Underline, 1);
            let n = arena.node(node_id);
            let body_block = n.blocks[0];
            import_node(arena, body_block, &ul.body);
        }
        AnyParseNode::Text(text) => {
            let node_id = append_command(arena, block_id, NodeKind::Text, 1);
            let n = arena.node(node_id);
            let body_block = n.blocks[0];
            for child in &text.body {
                import_node(arena, body_block, child);
            }
        }
        AnyParseNode::Color(color) => {
            let kind = NodeKind::Color(color.color.clone());
            let node_id = append_command(arena, block_id, kind, 1);
            let n = arena.node(node_id);
            let body_block = n.blocks[0];
            for child in &color.body {
                import_node(arena, body_block, child);
            }
        }
        AnyParseNode::Font(font) => {
            let kind = NodeKind::Font(font.font.clone());
            let node_id = append_command(arena, block_id, kind, 1);
            let n = arena.node(node_id);
            let body_block = n.blocks[0];
            import_node(arena, body_block, &font.body);
        }
        AnyParseNode::Sizing(sizing) => {
            let kind = NodeKind::Sizing(sizing.size);
            let node_id = append_command(arena, block_id, kind, 1);
            let n = arena.node(node_id);
            let body_block = n.blocks[0];
            for child in &sizing.body {
                import_node(arena, body_block, child);
            }
        }
        AnyParseNode::Phantom(ph) => {
            let node_id = append_command(arena, block_id, NodeKind::Phantom, 1);
            let n = arena.node(node_id);
            let body_block = n.blocks[0];
            for child in &ph.body {
                import_node(arena, body_block, child);
            }
        }
        AnyParseNode::Op(op) => {
            match op {
                ParseNodeOp::Symbol { name, .. } => {
                    // Large operators like \sum, \prod, \int
                    insert_symbol_text(arena, block_id, name, AtomFamily::Op);
                }
                ParseNodeOp::Body { body, .. } => {
                    // Operator with body (e.g. \operatorname)
                    for child in body {
                        import_node(arena, block_id, child);
                    }
                }
            }
        }
        AnyParseNode::Styling(styling) => {
            // Style wrapper: just import children
            for child in &styling.body {
                import_node(arena, block_id, child);
            }
        }
        AnyParseNode::Array(arr) => {
            let rows = arr.body.len();
            let cols = arr
                .body
                .iter()
                .map(|row| row.len())
                .max()
                .unwrap_or(1);
            let kind = NodeKind::Matrix { rows, cols };
            let node_id = append_command(arena, block_id, kind, rows * cols);
            let n = arena.node(node_id);
            let blocks: Vec<BlockId> = n.blocks.clone();

            for (r, row) in arr.body.iter().enumerate() {
                for (c, cell) in row.iter().enumerate() {
                    let idx = r * cols + c;
                    if idx < blocks.len() {
                        import_node(arena, blocks[idx], cell);
                    }
                }
            }
        }
        AnyParseNode::HorizBrace(hb) => {
            let kind = NodeKind::HorizBrace {
                label: hb.label.clone(),
                is_over: hb.is_over,
            };
            let node_id = append_command(arena, block_id, kind, 1);
            let n = arena.node(node_id);
            let body_block = n.blocks[0];
            import_node(arena, body_block, &hb.base);
        }
        AnyParseNode::XArrow(xa) => {
            let kind = NodeKind::XArrow {
                label: xa.label.clone(),
            };
            let node_id = append_command(arena, block_id, kind, 2);
            let n = arena.node(node_id);
            let below_block = n.blocks[0];
            let above_block = n.blocks[1];
            if let Some(ref below) = xa.below {
                import_node(arena, below_block, below);
            }
            if let Some(ref body) = xa.body {
                import_node(arena, above_block, body);
            }
        }
        AnyParseNode::OperatorName(opn) => {
            let node_id = append_command(arena, block_id, NodeKind::OperatorName, 1);
            let n = arena.node(node_id);
            let body_block = n.blocks[0];
            for child in &opn.body {
                import_node(arena, body_block, child);
            }
        }
        // Fallback: render opaque nodes as Raw
        _ => {
            // For unsupported node types, we store them as Raw LaTeX.
            // This is a lossy conversion — the user can't edit inside them.
            let raw = format_raw_node(node);
            if !raw.is_empty() {
                append_leaf(arena, block_id, NodeKind::Raw(raw));
            }
        }
    }
}

/// Append a leaf node (no child blocks) at the end of a block.
fn append_leaf(arena: &mut Arena, block_id: BlockId, kind: NodeKind) -> NodeId {
    let last = arena.block(block_id).last;
    let mut cursor = Cursor {
        parent: block_id,
        left: last,
        right: None,
    };
    arena.insert_at_cursor(&mut cursor, kind)
}

/// Append a command node (with child blocks) at the end of a block.
fn append_command(arena: &mut Arena, block_id: BlockId, kind: NodeKind, block_count: usize) -> NodeId {
    let last = arena.block(block_id).last;
    let mut cursor = Cursor {
        parent: block_id,
        left: last,
        right: None,
    };

    let node_id = arena.insert_at_cursor(&mut cursor, kind);

    let mut child_blocks = Vec::with_capacity(block_count);
    for _ in 0..block_count {
        let b = arena.alloc_block(Some(node_id));
        child_blocks.push(b);
    }
    arena.node_mut(node_id).blocks = child_blocks;

    node_id
}

/// Insert a symbol from text (may be multi-char like \alpha).
fn insert_symbol_text(arena: &mut Arena, block_id: BlockId, text: &str, family: AtomFamily) {
    if text.is_empty() {
        return;
    }
    // For single characters, insert directly
    if text.chars().count() == 1 {
        let ch = text.chars().next().unwrap();
        let actual_family = crate::editor::arena::classify_char(ch);
        // Use the provided family if it's more specific
        let family = if family == AtomFamily::Ord { actual_family } else { family };
        append_leaf(
            arena,
            block_id,
            NodeKind::Symbol {
                text: ch.to_string(),
                atom_family: family,
            },
        );
    } else {
        // Multi-char: likely a command like \alpha, \beta
        append_leaf(
            arena,
            block_id,
            NodeKind::Symbol {
                text: text.to_string(),
                atom_family: family,
            },
        );
    }
}

fn convert_atom_family(atom: Atom) -> AtomFamily {
    match atom {
        Atom::Bin => AtomFamily::Bin,
        Atom::Close => AtomFamily::Close,
        Atom::Inner => AtomFamily::Inner,
        Atom::Open => AtomFamily::Open,
        Atom::Punct => AtomFamily::Punct,
        Atom::Rel => AtomFamily::Rel,
    }
}

/// Best-effort LaTeX string for unsupported parse nodes.
fn format_raw_node(node: &AnyParseNode) -> String {
    match node {
        AnyParseNode::Raw(raw) => raw.string.as_str().to_string(),
        AnyParseNode::Kern(kern) => {
            format!("\\kern{{{}}}", format_measurement(&kern.dimension))
        }
        AnyParseNode::Rule(rule) => {
            let mut s = String::from("\\rule");
            if let Some(ref shift) = rule.shift {
                s.push_str(&format!("[{}]", format_measurement(shift)));
            }
            s.push_str(&format!(
                "{{{}}}{{{}}}",
                format_measurement(&rule.width),
                format_measurement(&rule.height)
            ));
            s
        }
        AnyParseNode::Verb(verb) => {
            format!("|{}|", verb.body.as_str())
        }
        _ => String::new(),
    }
}

fn format_measurement(m: &katex::spacing_data::MeasurementOwned) -> String {
    format!("{}{}", m.number, m.unit)
}

/// Export: convert Arena back to a Vec<AnyParseNode> for rendering.
/// This allows using katex-rs's render pipeline with the edited tree.
pub fn export_to_parse_nodes(arena: &Arena) -> Vec<AnyParseNode> {
    export_block(arena, arena.root)
}

fn export_block(arena: &Arena, block_id: BlockId) -> Vec<AnyParseNode> {
    let mut nodes = Vec::new();
    let mut current = arena.block(block_id).first;
    while let Some(nid) = current {
        if let Some(node) = export_node(arena, nid) {
            nodes.push(node);
        }
        current = arena.node(nid).right;
    }
    nodes
}

fn export_node(arena: &Arena, node_id: NodeId) -> Option<AnyParseNode> {
    let n = arena.node(node_id);
    match &n.kind {
        NodeKind::Symbol { text, atom_family } => {
            let mode = Mode::Math;
            match atom_family {
                AtomFamily::Bin | AtomFamily::Rel | AtomFamily::Open | AtomFamily::Close
                | AtomFamily::Punct | AtomFamily::Inner => Some(AnyParseNode::Atom(ParseNodeAtom {
                    family: export_atom_family(*atom_family),
                    mode,
                    loc: None,
                    text: text.to_string().into(),
                })),
                _ => Some(AnyParseNode::MathOrd(ParseNodeMathOrd {
                    mode,
                    loc: None,
                    text: text.to_string().into(),
                })),
            }
        }
        NodeKind::Frac => {
            let numer_nodes = export_block(arena, n.blocks[0]);
            let denom_nodes = export_block(arena, n.blocks[1]);
            Some(AnyParseNode::Genfrac(Box::new(ParseNodeGenfrac {
                mode: Mode::Math,
                loc: None,
                continued: false,
                numer: Box::new(wrap_group(numer_nodes)),
                denom: Box::new(wrap_group(denom_nodes)),
                has_bar_line: true,
                left_delim: None,
                right_delim: None,
                size: None,
                bar_size: None,
            })))
        }
        NodeKind::Sqrt => {
            let body_nodes = export_block(arena, n.blocks[0]);
            Some(AnyParseNode::Sqrt(Box::new(ParseNodeSqrt {
                mode: Mode::Math,
                loc: None,
                body: wrap_group(body_nodes),
                index: None,
            })))
        }
        NodeKind::NthRoot => {
            let index_nodes = export_block(arena, n.blocks[0]);
            let body_nodes = export_block(arena, n.blocks[1]);
            Some(AnyParseNode::Sqrt(Box::new(ParseNodeSqrt {
                mode: Mode::Math,
                loc: None,
                body: wrap_group(body_nodes),
                index: Some(wrap_group(index_nodes)),
            })))
        }
        NodeKind::Sup => {
            let sup_nodes = export_block(arena, n.blocks[0]);
            Some(AnyParseNode::SupSub(ParseNodeSupSub {
                mode: Mode::Math,
                loc: None,
                base: None,
                sup: Some(Box::new(wrap_group(sup_nodes))),
                sub: None,
            }))
        }
        NodeKind::Sub => {
            let sub_nodes = export_block(arena, n.blocks[0]);
            Some(AnyParseNode::SupSub(ParseNodeSupSub {
                mode: Mode::Math,
                loc: None,
                base: None,
                sup: None,
                sub: Some(Box::new(wrap_group(sub_nodes))),
            }))
        }
        NodeKind::SupSub => {
            let sup_nodes = export_block(arena, n.blocks[0]);
            let sub_nodes = export_block(arena, n.blocks[1]);
            Some(AnyParseNode::SupSub(ParseNodeSupSub {
                mode: Mode::Math,
                loc: None,
                base: None,
                sup: Some(Box::new(wrap_group(sup_nodes))),
                sub: Some(Box::new(wrap_group(sub_nodes))),
            }))
        }
        NodeKind::LeftRight {
            left_delim,
            right_delim,
        } => {
            let body_nodes = export_block(arena, n.blocks[0]);
            Some(AnyParseNode::LeftRight(ParseNodeLeftRight {
                mode: Mode::Math,
                loc: None,
                body: body_nodes,
                left: left_delim.clone(),
                right: right_delim.clone(),
                right_color: None,
            }))
        }
        NodeKind::Accent { label } => {
            let body_nodes = export_block(arena, n.blocks[0]);
            Some(AnyParseNode::Accent(Box::new(ParseNodeAccent {
                mode: Mode::Math,
                loc: None,
                label: label.clone(),
                is_stretchy: None,
                is_shifty: None,
                base: wrap_group(body_nodes),
            })))
        }
        NodeKind::Overline => {
            let body_nodes = export_block(arena, n.blocks[0]);
            Some(AnyParseNode::Overline(ParseNodeOverline {
                mode: Mode::Math,
                loc: None,
                body: Box::new(wrap_group(body_nodes)),
            }))
        }
        NodeKind::Underline => {
            let body_nodes = export_block(arena, n.blocks[0]);
            Some(AnyParseNode::Underline(ParseNodeUnderline {
                mode: Mode::Math,
                loc: None,
                body: Box::new(wrap_group(body_nodes)),
            }))
        }
        NodeKind::Text => {
            let body_nodes = export_block(arena, n.blocks[0]);
            Some(AnyParseNode::Text(ParseNodeText {
                mode: Mode::Text,
                loc: None,
                body: body_nodes,
                font: None,
            }))
        }
        NodeKind::Color(color) => {
            let body_nodes = export_block(arena, n.blocks[0]);
            Some(AnyParseNode::Color(ParseNodeColor {
                mode: Mode::Math,
                loc: None,
                color: color.clone(),
                body: body_nodes,
            }))
        }
        NodeKind::Font(font) => {
            let body_nodes = export_block(arena, n.blocks[0]);
            Some(AnyParseNode::Font(ParseNodeFont {
                mode: Mode::Math,
                loc: None,
                font: font.clone(),
                body: Box::new(wrap_group(body_nodes)),
            }))
        }
        NodeKind::Sizing(size) => {
            let body_nodes = export_block(arena, n.blocks[0]);
            Some(AnyParseNode::Sizing(ParseNodeSizing {
                mode: Mode::Math,
                loc: None,
                size: *size,
                body: body_nodes,
            }))
        }
        NodeKind::Phantom => {
            let body_nodes = export_block(arena, n.blocks[0]);
            Some(AnyParseNode::Phantom(ParseNodePhantom {
                mode: Mode::Math,
                loc: None,
                body: body_nodes,
            }))
        }
        NodeKind::Matrix { rows, cols } => {
            let mut body = Vec::new();
            for r in 0..*rows {
                let mut row = Vec::new();
                for c in 0..*cols {
                    let idx = r * cols + c;
                    let cell_nodes = export_block(arena, n.blocks[idx]);
                    row.push(wrap_group(cell_nodes));
                }
                body.push(row);
            }
            Some(AnyParseNode::Array(ParseNodeArray {
                mode: Mode::Math,
                loc: None,
                col_separation_type: None,
                hskip_before_and_after: None,
                add_jot: None,
                cols: None,
                arraystretch: 1.0,
                body,
                row_gaps: Vec::new(),
                h_lines_before_row: Vec::new(),
                tags: None,
                leqno: None,
                is_cd: None,
            }))
        }
        NodeKind::SumLike { ctrl_seq } => {
            // Export as Op with sup/sub
            Some(AnyParseNode::Op(ParseNodeOp::Symbol {
                mode: Mode::Math,
                loc: None,
                limits: true,
                always_handle_sup_sub: Some(true),
                suppress_base_shift: None,
                parent_is_sup_sub: false,
                name: ctrl_seq.clone(),
                symbol: true,
            }))
        }
        NodeKind::Raw(latex) => Some(AnyParseNode::Raw(ParseNodeRaw {
            mode: Mode::Math,
            loc: None,
            string: latex.to_string().into(),
        })),
        // For remaining types, serialize to LaTeX and re-parse via katex-rs
        _ => {
            let latex = crate::editor::serialize::serialize_single_node(arena, node_id);
            if latex.is_empty() {
                return None;
            }
            let ctx = katex::KatexContext::default();
            let settings = katex::Settings::default();
            katex::parse(&ctx, &latex, &settings)
                .ok()
                .and_then(|nodes| {
                    if nodes.len() == 1 {
                        Some(nodes.into_iter().next().unwrap())
                    } else if !nodes.is_empty() {
                        Some(AnyParseNode::OrdGroup(ParseNodeOrdGroup {
                            mode: Mode::Math,
                            loc: None,
                            body: nodes,
                            semisimple: None,
                        }))
                    } else {
                        None
                    }
                })
        }
    }
}

fn wrap_group(nodes: Vec<AnyParseNode>) -> AnyParseNode {
    if nodes.len() == 1 {
        nodes.into_iter().next().unwrap()
    } else {
        AnyParseNode::OrdGroup(ParseNodeOrdGroup {
            mode: Mode::Math,
            loc: None,
            body: nodes,
            semisimple: None,
        })
    }
}

fn export_atom_family(family: AtomFamily) -> Atom {
    match family {
        AtomFamily::Bin => Atom::Bin,
        AtomFamily::Close => Atom::Close,
        AtomFamily::Inner => Atom::Inner,
        AtomFamily::Open => Atom::Open,
        AtomFamily::Punct => Atom::Punct,
        AtomFamily::Rel => Atom::Rel,
        AtomFamily::Ord | AtomFamily::Op => Atom::Inner,
    }
}

