use crate::editor::cursor::Cursor;
use crate::editor::node_kind::NodeKind;

/// All editing operations the math editor supports.
#[derive(Debug, Clone)]
pub enum Intent {
    // --- Symbol insertion ---
    InsertSymbol(char),
    InsertCommand(CommandKind),

    // --- Cursor movement ---
    MoveLeft,
    MoveRight,
    /// MathQuill-style "escape right": exit the current block to the right.
    /// If in root block, behaves like MoveRight.
    EscapeRight,
    MoveUp,
    MoveDown,
    MoveToStart,
    MoveToEnd,

    // --- Selection ---
    SelectLeft,
    SelectRight,
    SelectAll,

    // --- Deletion ---
    DeleteBackward,
    DeleteForward,

    // --- Structural ---
    /// Wrap current selection in a command (frac, sqrt, etc.)
    WrapInCommand(CommandKind),

    // --- LaTeX command input ---
    /// Begin command input mode: insert a LatexCommandInput node at cursor.
    InsertCommandInput,
    /// Append a character to the LatexCommandInput node to the left of cursor.
    CommandInputType(char),
    /// Remove last character from the LatexCommandInput, or remove it entirely if empty.
    CommandInputBackspace,
    /// Resolve the LatexCommandInput node to the left of cursor: extract text, remove node, insert result.
    ResolveCurrentCommandInput,
    /// Cancel command input: remove the LatexCommandInput node entirely.
    CancelCommandInput,
    /// Resolve a typed command name (e.g. "frac", "alpha") into the appropriate insertion.
    /// Used directly in tests; the FFI uses ResolveCurrentCommandInput instead.
    ResolveCommandInput(String),

    // --- Import ---
    /// Replace entire content with parsed LaTeX.
    SetLatex(String),

    // --- Hit test result ---
    /// Set cursor from a HitMap click resolution.
    SetCursor(Cursor),
}

/// Commands that can be inserted, each mapping to a NodeKind with child blocks.
#[derive(Debug, Clone)]
pub enum CommandKind {
    Frac,
    Sqrt,
    NthRoot,
    Sup,
    Sub,
    SupSub,
    Parentheses,
    Brackets,
    Braces,
    Abs,
    Sum,
    Product,
    Integral,
    Limit,
    Matrix(usize, usize),
    Accent(String),
    Overline,
    Underline,
    HorizBrace { label: String, is_over: bool },
    XArrow(String),
    OperatorName,
    Text,
}

impl CommandKind {
    /// Convert to the corresponding NodeKind.
    pub fn to_node_kind(&self) -> NodeKind {
        match self {
            CommandKind::Frac => NodeKind::Frac,
            CommandKind::Sqrt => NodeKind::Sqrt,
            CommandKind::NthRoot => NodeKind::NthRoot,
            CommandKind::Sup => NodeKind::Sup,
            CommandKind::Sub => NodeKind::Sub,
            CommandKind::SupSub => NodeKind::SupSub,
            CommandKind::Parentheses => NodeKind::LeftRight {
                left_delim: "(".to_string(),
                right_delim: ")".to_string(),
            },
            CommandKind::Brackets => NodeKind::LeftRight {
                left_delim: "[".to_string(),
                right_delim: "]".to_string(),
            },
            CommandKind::Braces => NodeKind::LeftRight {
                left_delim: "\\{".to_string(),
                right_delim: "\\}".to_string(),
            },
            CommandKind::Abs => NodeKind::LeftRight {
                left_delim: "|".to_string(),
                right_delim: "|".to_string(),
            },
            CommandKind::Sum => NodeKind::SumLike {
                ctrl_seq: "\\sum".to_string(),
            },
            CommandKind::Product => NodeKind::SumLike {
                ctrl_seq: "\\prod".to_string(),
            },
            CommandKind::Integral => NodeKind::SumLike {
                ctrl_seq: "\\int".to_string(),
            },
            CommandKind::Limit => NodeKind::SumLike {
                ctrl_seq: "\\lim".to_string(),
            },
            CommandKind::Matrix(r, c) => NodeKind::Matrix {
                rows: *r,
                cols: *c,
            },
            CommandKind::Accent(label) => NodeKind::Accent {
                label: label.clone(),
            },
            CommandKind::Overline => NodeKind::Overline,
            CommandKind::Underline => NodeKind::Underline,
            CommandKind::HorizBrace { label, is_over } => NodeKind::HorizBrace {
                label: label.clone(),
                is_over: *is_over,
            },
            CommandKind::XArrow(label) => NodeKind::XArrow {
                label: label.clone(),
            },
            CommandKind::OperatorName => NodeKind::OperatorName,
            CommandKind::Text => NodeKind::Text,
        }
    }
}
