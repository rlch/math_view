/// What kind of math construct a node represents.
///
/// Leaf variants (no child blocks) represent symbols and spacing.
/// Command variants have child blocks that the cursor can enter.
#[derive(Debug, Clone, PartialEq)]
pub enum NodeKind {
    // --- Leaf symbols (no child blocks) ---
    Symbol { text: String, atom_family: AtomFamily },

    // --- Commands with child blocks ---
    /// `\frac{numer}{denom}` — 2 blocks: [numer, denom]
    Frac,
    /// `\sqrt{body}` — 1 block: [body]
    Sqrt,
    /// `\sqrt[index]{body}` — 2 blocks: [index, body]
    NthRoot,
    /// `x^{sup}` — 1 block: [superscript]
    Sup,
    /// `x_{sub}` — 1 block: [subscript]
    Sub,
    /// `x^{sup}_{sub}` — 2 blocks: [sup, sub]
    SupSub,
    /// Accent above: `\hat`, `\bar`, `\vec`, etc. — 1 block: [body]
    Accent { label: String },
    /// `\overline{body}` — 1 block: [body]
    Overline,
    /// `\underline{body}` — 1 block: [body]
    Underline,
    /// `\left( ... \right)` — 1 block: [body]
    LeftRight { left_delim: String, right_delim: String },
    /// Matrix/array — rows*cols blocks
    Matrix { rows: usize, cols: usize },
    /// `\sum`, `\prod`, `\int`, `\lim`, etc. — 1-2 blocks: [below] or [below, above]
    SumLike { ctrl_seq: String },
    /// `\text{...}` — 1 block: [text content]
    Text,
    /// `\color{color}{body}` — 1 block: [body]
    Color(String),
    /// `\mathbf`, `\mathrm`, etc. — 1 block: [body]
    Font(String),
    /// `\scriptsize`, `\large`, etc. — 1 block: [body]
    Sizing(usize),
    /// `\phantom{body}` — 1 block: [body]
    Phantom,
    /// `\overbrace`, `\underbrace` — 1 block: [body]
    HorizBrace { label: String, is_over: bool },
    /// `\xleftarrow`, `\xrightarrow` — 1-2 blocks: [above] or [below, above]
    XArrow { label: String },
    /// `\operatorname{...}` — 1 block: [body]
    OperatorName,
    /// Transient command input node: user is typing `\commandname`.
    /// Stores the accumulated command name (e.g. "frac", "alpha").
    /// Cursor sits right after this node; letters are appended to `text`.
    /// Resolved on Space/Tab/Enter, cancelled on Escape.
    LatexCommandInput { text: String },
    /// Opaque LaTeX that we can't structurally edit.
    /// Rendered as a single unit, cursor skips over it.
    Raw(String),
}

impl NodeKind {
    /// Number of child blocks this node kind expects.
    pub fn expected_block_count(&self) -> usize {
        match self {
            NodeKind::Symbol { .. } | NodeKind::Raw(_) | NodeKind::LatexCommandInput { .. } => 0,
            NodeKind::Frac | NodeKind::SupSub => 2,
            NodeKind::NthRoot => 2,
            NodeKind::Sqrt
            | NodeKind::Sup
            | NodeKind::Sub
            | NodeKind::Overline
            | NodeKind::Underline
            | NodeKind::LeftRight { .. }
            | NodeKind::Text
            | NodeKind::Color(_)
            | NodeKind::Font(_)
            | NodeKind::Sizing(_)
            | NodeKind::Phantom
            | NodeKind::HorizBrace { .. }
            | NodeKind::OperatorName => 1,
            NodeKind::Accent { .. } => 1,
            NodeKind::SumLike { .. } => 2, // below + above (above may be empty)
            NodeKind::XArrow { .. } => 2,  // below + above
            NodeKind::Matrix { rows, cols } => rows * cols,
        }
    }

    /// Whether this is a leaf node (no child blocks).
    pub fn is_leaf(&self) -> bool {
        self.expected_block_count() == 0
    }
}

/// TeX atom families for spacing rules.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum AtomFamily {
    Ord,
    Bin,
    Rel,
    Op,
    Open,
    Close,
    Punct,
    Inner,
}
