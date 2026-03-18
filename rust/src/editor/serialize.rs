use std::fmt::Write;

use crate::editor::arena::{Arena, BlockId, NodeId};
use crate::editor::node_kind::NodeKind;

/// Serialize a single node to LaTeX (standalone helper for convert module).
pub fn serialize_single_node(arena: &Arena, node_id: NodeId) -> String {
    let mut out = String::new();
    arena.serialize_node_inner(node_id, &mut out, false);
    out
}

/// Serialize a list of nodes to LaTeX (for copy/clipboard).
pub fn serialize_nodes(arena: &Arena, nodes: &[NodeId]) -> String {
    let mut out = String::new();
    for &nid in nodes {
        arena.serialize_node_inner(nid, &mut out, false);
    }
    out
}

/// Approximate width of one character in the command input box (em units).
const COMMAND_INPUT_CHAR_WIDTH: f64 = 0.56;

impl Arena {
    /// Serialize the entire arena to a LaTeX string (for export).
    /// LatexCommandInput nodes are omitted.
    pub fn to_latex(&self) -> String {
        let mut out = String::new();
        self.serialize_block_inner(self.root, &mut out, false);
        out
    }

    /// Serialize the entire arena to a LaTeX string (for KaTeX rendering).
    /// LatexCommandInput nodes emit `\kern{Nem}` to reserve horizontal space.
    pub fn to_render_latex(&self) -> String {
        let mut out = String::new();
        self.serialize_block_inner(self.root, &mut out, true);
        out
    }

    fn serialize_block_inner(&self, block_id: BlockId, out: &mut String, for_render: bool) {
        let block = self.block(block_id);
        // Empty child blocks need a \kern to force KaTeX to produce structural
        // elements (fraction bars, radical signs, etc.) instead of zero output.
        if for_render && block.first.is_none() && block_id != self.root {
            out.push_str(r"\kern{0.5em}");
            return;
        }
        let mut current = block.first;
        while let Some(nid) = current {
            self.serialize_node_inner(nid, out, for_render);
            current = self.node(nid).right;
        }
    }

    pub(crate) fn serialize_node_inner(&self, node_id: NodeId, out: &mut String, for_render: bool) {
        let n = self.node(node_id);
        match &n.kind {
            NodeKind::Symbol { text, .. } => {
                if text.len() == 1 {
                    let ch = text.chars().next().unwrap();
                    if needs_escape(ch) {
                        out.push('\\');
                    }
                    out.push(ch);
                } else {
                    out.push_str(text);
                    // LaTeX commands like \pm need a trailing space to avoid
                    // merging with the next token (e.g. \pmb ≠ \pm b).
                    if text.starts_with('\\') {
                        out.push(' ');
                    }
                }
            }
            NodeKind::LatexCommandInput { text } => {
                if for_render {
                    // Reserve horizontal space for Flutter to render the command input widget.
                    // +1 for the backslash prefix character.
                    let width_em = (text.len() as f64 + 1.0) * COMMAND_INPUT_CHAR_WIDTH;
                    let _ = write!(out, "\\kern{{{:.2}em}}", width_em);
                }
                // For export: omit entirely (transient editing state)
            }
            NodeKind::Frac => {
                out.push_str("\\frac{");
                self.serialize_block_inner(n.blocks[0], out, for_render);
                out.push_str("}{");
                self.serialize_block_inner(n.blocks[1], out, for_render);
                out.push('}');
            }
            NodeKind::Sqrt => {
                out.push_str("\\sqrt{");
                self.serialize_block_inner(n.blocks[0], out, for_render);
                out.push('}');
            }
            NodeKind::NthRoot => {
                out.push_str("\\sqrt[");
                self.serialize_block_inner(n.blocks[0], out, for_render);
                out.push_str("]{");
                self.serialize_block_inner(n.blocks[1], out, for_render);
                out.push('}');
            }
            NodeKind::Sup => {
                out.push_str("^{");
                self.serialize_block_inner(n.blocks[0], out, for_render);
                out.push('}');
            }
            NodeKind::Sub => {
                out.push_str("_{");
                self.serialize_block_inner(n.blocks[0], out, for_render);
                out.push('}');
            }
            NodeKind::SupSub => {
                out.push_str("^{");
                self.serialize_block_inner(n.blocks[0], out, for_render);
                out.push_str("}_{");
                self.serialize_block_inner(n.blocks[1], out, for_render);
                out.push('}');
            }
            NodeKind::Accent { label } => {
                out.push_str(label);
                out.push('{');
                self.serialize_block_inner(n.blocks[0], out, for_render);
                out.push('}');
            }
            NodeKind::Overline => {
                out.push_str("\\overline{");
                self.serialize_block_inner(n.blocks[0], out, for_render);
                out.push('}');
            }
            NodeKind::Underline => {
                out.push_str("\\underline{");
                self.serialize_block_inner(n.blocks[0], out, for_render);
                out.push('}');
            }
            NodeKind::LeftRight {
                left_delim,
                right_delim,
            } => {
                out.push_str("\\left");
                out.push_str(left_delim);
                self.serialize_block_inner(n.blocks[0], out, for_render);
                out.push_str("\\right");
                out.push_str(right_delim);
            }
            NodeKind::Matrix { rows, cols } => {
                out.push_str("\\begin{matrix}");
                for r in 0..*rows {
                    if r > 0 {
                        out.push_str(" \\\\ ");
                    }
                    for c in 0..*cols {
                        if c > 0 {
                            out.push_str(" & ");
                        }
                        self.serialize_block_inner(n.blocks[r * cols + c], out, for_render);
                    }
                }
                out.push_str("\\end{matrix}");
            }
            NodeKind::SumLike { ctrl_seq } => {
                out.push_str(ctrl_seq);
                if n.blocks.len() >= 1 {
                    out.push_str("_{");
                    self.serialize_block_inner(n.blocks[0], out, for_render);
                    out.push('}');
                }
                if n.blocks.len() >= 2 {
                    out.push_str("^{");
                    self.serialize_block_inner(n.blocks[1], out, for_render);
                    out.push('}');
                }
            }
            NodeKind::Text => {
                out.push_str("\\text{");
                self.serialize_block_inner(n.blocks[0], out, for_render);
                out.push('}');
            }
            NodeKind::Color(color) => {
                out.push_str("\\color{");
                out.push_str(color);
                out.push_str("}{");
                self.serialize_block_inner(n.blocks[0], out, for_render);
                out.push('}');
            }
            NodeKind::Font(font) => {
                out.push_str(font);
                out.push('{');
                self.serialize_block_inner(n.blocks[0], out, for_render);
                out.push('}');
            }
            NodeKind::Sizing(size) => {
                let cmd = match size {
                    1 => "\\tiny",
                    2 => "\\scriptsize",
                    3 => "\\footnotesize",
                    4 => "\\small",
                    5 => "\\normalsize",
                    6 => "\\large",
                    7 => "\\Large",
                    8 => "\\LARGE",
                    9 => "\\huge",
                    10 => "\\Huge",
                    _ => "\\normalsize",
                };
                out.push_str(cmd);
                out.push('{');
                self.serialize_block_inner(n.blocks[0], out, for_render);
                out.push('}');
            }
            NodeKind::Phantom => {
                out.push_str("\\phantom{");
                self.serialize_block_inner(n.blocks[0], out, for_render);
                out.push('}');
            }
            NodeKind::HorizBrace { label, .. } => {
                out.push_str(label);
                out.push('{');
                self.serialize_block_inner(n.blocks[0], out, for_render);
                out.push('}');
            }
            NodeKind::XArrow { label } => {
                out.push_str(label);
                if n.blocks.len() >= 1 && self.block(n.blocks[0]).first.is_some() {
                    out.push('[');
                    self.serialize_block_inner(n.blocks[0], out, for_render);
                    out.push(']');
                }
                if n.blocks.len() >= 2 {
                    out.push('{');
                    self.serialize_block_inner(n.blocks[1], out, for_render);
                    out.push('}');
                }
            }
            NodeKind::OperatorName => {
                // Collect the body text to check for built-in shorthand
                let mut body = String::new();
                self.serialize_block_inner(n.blocks[0], &mut body, for_render);
                // Built-in operator names that have \name shorthand in LaTeX
                const BUILTIN_OPS: &[&str] = &[
                    "arccos", "arcsin", "arctan", "arg", "cos", "cosh",
                    "cot", "coth", "csc", "csch", "deg", "det", "dim",
                    "exp", "gcd", "hom", "inf", "ker", "lg", "lim",
                    "liminf", "limsup", "ln", "log", "max", "min",
                    "mod", "Pr", "sec", "sech", "sin", "sinh", "sup",
                    "tan", "tanh",
                ];
                if BUILTIN_OPS.contains(&body.as_str()) {
                    out.push('\\');
                    out.push_str(&body);
                    out.push(' ');
                } else {
                    out.push_str("\\operatorname{");
                    out.push_str(&body);
                    out.push('}');
                }
            }
            NodeKind::Raw(latex) => {
                out.push_str(latex);
            }
        }
    }
}

fn needs_escape(ch: char) -> bool {
    matches!(ch, '#' | '$' | '%' | '&' | '~' | '_' | '^' | '{' | '}' | '\\')
}
