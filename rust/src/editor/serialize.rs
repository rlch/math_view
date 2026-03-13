use crate::editor::arena::{Arena, BlockId, NodeId};
use crate::editor::node_kind::NodeKind;

/// Serialize a single node to LaTeX (standalone helper for convert module).
pub fn serialize_single_node(arena: &Arena, node_id: NodeId) -> String {
    let mut out = String::new();
    arena.serialize_node(node_id, &mut out);
    out
}

impl Arena {
    /// Serialize the entire arena to a LaTeX string.
    pub fn to_latex(&self) -> String {
        let mut out = String::new();
        self.serialize_block(self.root, &mut out);
        out
    }

    pub(crate) fn serialize_block(&self, block_id: BlockId, out: &mut String) {
        let mut current = self.block(block_id).first;
        while let Some(nid) = current {
            self.serialize_node(nid, out);
            current = self.node(nid).right;
        }
    }

    pub(crate) fn serialize_node(&self, node_id: NodeId, out: &mut String) {
        let n = self.node(node_id);
        match &n.kind {
            NodeKind::Symbol { text, .. } => {
                // Single-char symbols emit directly; multi-char get braces
                if text.len() == 1 {
                    let ch = text.chars().next().unwrap();
                    if needs_escape(ch) {
                        out.push('\\');
                    }
                    out.push(ch);
                } else {
                    out.push_str(text);
                }
            }
            NodeKind::Frac => {
                out.push_str("\\frac{");
                self.serialize_block(n.blocks[0], out);
                out.push_str("}{");
                self.serialize_block(n.blocks[1], out);
                out.push('}');
            }
            NodeKind::Sqrt => {
                out.push_str("\\sqrt{");
                self.serialize_block(n.blocks[0], out);
                out.push('}');
            }
            NodeKind::NthRoot => {
                out.push_str("\\sqrt[");
                self.serialize_block(n.blocks[0], out);
                out.push_str("]{");
                self.serialize_block(n.blocks[1], out);
                out.push('}');
            }
            NodeKind::Sup => {
                out.push_str("^{");
                self.serialize_block(n.blocks[0], out);
                out.push('}');
            }
            NodeKind::Sub => {
                out.push_str("_{");
                self.serialize_block(n.blocks[0], out);
                out.push('}');
            }
            NodeKind::SupSub => {
                out.push_str("^{");
                self.serialize_block(n.blocks[0], out);
                out.push_str("}_{");
                self.serialize_block(n.blocks[1], out);
                out.push('}');
            }
            NodeKind::Accent { label } => {
                out.push_str(label);
                out.push('{');
                self.serialize_block(n.blocks[0], out);
                out.push('}');
            }
            NodeKind::Overline => {
                out.push_str("\\overline{");
                self.serialize_block(n.blocks[0], out);
                out.push('}');
            }
            NodeKind::Underline => {
                out.push_str("\\underline{");
                self.serialize_block(n.blocks[0], out);
                out.push('}');
            }
            NodeKind::LeftRight {
                left_delim,
                right_delim,
            } => {
                out.push_str("\\left");
                out.push_str(left_delim);
                self.serialize_block(n.blocks[0], out);
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
                        self.serialize_block(n.blocks[r * cols + c], out);
                    }
                }
                out.push_str("\\end{matrix}");
            }
            NodeKind::SumLike { ctrl_seq } => {
                out.push_str(ctrl_seq);
                if n.blocks.len() >= 1 {
                    out.push_str("_{");
                    self.serialize_block(n.blocks[0], out);
                    out.push('}');
                }
                if n.blocks.len() >= 2 {
                    out.push_str("^{");
                    self.serialize_block(n.blocks[1], out);
                    out.push('}');
                }
            }
            NodeKind::Text => {
                out.push_str("\\text{");
                self.serialize_block(n.blocks[0], out);
                out.push('}');
            }
            NodeKind::Color(color) => {
                out.push_str("\\color{");
                out.push_str(color);
                out.push_str("}{");
                self.serialize_block(n.blocks[0], out);
                out.push('}');
            }
            NodeKind::Font(font) => {
                out.push_str(font);
                out.push('{');
                self.serialize_block(n.blocks[0], out);
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
                self.serialize_block(n.blocks[0], out);
                out.push('}');
            }
            NodeKind::Phantom => {
                out.push_str("\\phantom{");
                self.serialize_block(n.blocks[0], out);
                out.push('}');
            }
            NodeKind::HorizBrace { label, .. } => {
                out.push_str(label);
                out.push('{');
                self.serialize_block(n.blocks[0], out);
                out.push('}');
            }
            NodeKind::XArrow { label } => {
                out.push_str(label);
                if n.blocks.len() >= 1 && self.block(n.blocks[0]).first.is_some() {
                    out.push('[');
                    self.serialize_block(n.blocks[0], out);
                    out.push(']');
                }
                if n.blocks.len() >= 2 {
                    out.push('{');
                    self.serialize_block(n.blocks[1], out);
                    out.push('}');
                }
            }
            NodeKind::OperatorName => {
                out.push_str("\\operatorname{");
                self.serialize_block(n.blocks[0], out);
                out.push('}');
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
