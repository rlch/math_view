use crate::editor::intent::CommandKind;
use crate::editor::node_kind::AtomFamily;

/// Result of looking up a command name in the table.
pub enum Resolved {
    /// A structural command (frac, sqrt, etc.)
    Command(CommandKind),
    /// A symbol (α, ∞, ±, etc.) with its atom family and LaTeX text.
    Symbol { text: String, family: AtomFamily },
}

/// Look up a command name (without the leading backslash).
pub fn lookup(name: &str) -> Option<Resolved> {
    // Structural commands
    match name {
        "frac" => return Some(Resolved::Command(CommandKind::Frac)),
        "sqrt" => return Some(Resolved::Command(CommandKind::Sqrt)),
        "nthroot" => return Some(Resolved::Command(CommandKind::NthRoot)),
        "text" => return Some(Resolved::Command(CommandKind::Text)),
        "overline" => return Some(Resolved::Command(CommandKind::Overline)),
        "underline" => return Some(Resolved::Command(CommandKind::Underline)),
        "sum" => return Some(Resolved::Command(CommandKind::Sum)),
        "prod" => return Some(Resolved::Command(CommandKind::Product)),
        "int" => return Some(Resolved::Command(CommandKind::Integral)),
        "lim" => return Some(Resolved::Command(CommandKind::Limit)),
        "operatorname" => return Some(Resolved::Command(CommandKind::OperatorName)),
        "hat" => return Some(Resolved::Command(CommandKind::Accent("\\hat".into()))),
        "vec" => return Some(Resolved::Command(CommandKind::Accent("\\vec".into()))),
        "bar" => return Some(Resolved::Command(CommandKind::Accent("\\bar".into()))),
        "dot" => return Some(Resolved::Command(CommandKind::Accent("\\dot".into()))),
        "ddot" => return Some(Resolved::Command(CommandKind::Accent("\\ddot".into()))),
        "tilde" => return Some(Resolved::Command(CommandKind::Accent("\\tilde".into()))),
        "overrightarrow" => {
            return Some(Resolved::Command(CommandKind::Accent(
                "\\overrightarrow".into(),
            )))
        }
        "overbrace" => {
            return Some(Resolved::Command(CommandKind::HorizBrace {
                label: "\\overbrace".into(),
                is_over: true,
            }))
        }
        "underbrace" => {
            return Some(Resolved::Command(CommandKind::HorizBrace {
                label: "\\underbrace".into(),
                is_over: false,
            }))
        }
        "xleftarrow" => return Some(Resolved::Command(CommandKind::XArrow("\\xleftarrow".into()))),
        "xrightarrow" => {
            return Some(Resolved::Command(CommandKind::XArrow(
                "\\xrightarrow".into(),
            )))
        }
        _ => {}
    }

    // Delimiter commands
    match name {
        "left" | "right" => return None, // These aren't standalone
        "langle" => return Some(sym("\\langle", AtomFamily::Open)),
        "rangle" => return Some(sym("\\rangle", AtomFamily::Close)),
        "lfloor" => return Some(sym("\\lfloor", AtomFamily::Open)),
        "rfloor" => return Some(sym("\\rfloor", AtomFamily::Close)),
        "lceil" => return Some(sym("\\lceil", AtomFamily::Open)),
        "rceil" => return Some(sym("\\rceil", AtomFamily::Close)),
        _ => {}
    }

    // Greek lowercase
    match name {
        "alpha" => return Some(sym("\\alpha", AtomFamily::Ord)),
        "beta" => return Some(sym("\\beta", AtomFamily::Ord)),
        "gamma" => return Some(sym("\\gamma", AtomFamily::Ord)),
        "delta" => return Some(sym("\\delta", AtomFamily::Ord)),
        "epsilon" => return Some(sym("\\epsilon", AtomFamily::Ord)),
        "varepsilon" => return Some(sym("\\varepsilon", AtomFamily::Ord)),
        "zeta" => return Some(sym("\\zeta", AtomFamily::Ord)),
        "eta" => return Some(sym("\\eta", AtomFamily::Ord)),
        "theta" => return Some(sym("\\theta", AtomFamily::Ord)),
        "vartheta" => return Some(sym("\\vartheta", AtomFamily::Ord)),
        "iota" => return Some(sym("\\iota", AtomFamily::Ord)),
        "kappa" => return Some(sym("\\kappa", AtomFamily::Ord)),
        "lambda" => return Some(sym("\\lambda", AtomFamily::Ord)),
        "mu" => return Some(sym("\\mu", AtomFamily::Ord)),
        "nu" => return Some(sym("\\nu", AtomFamily::Ord)),
        "xi" => return Some(sym("\\xi", AtomFamily::Ord)),
        "pi" => return Some(sym("\\pi", AtomFamily::Ord)),
        "varpi" => return Some(sym("\\varpi", AtomFamily::Ord)),
        "rho" => return Some(sym("\\rho", AtomFamily::Ord)),
        "varrho" => return Some(sym("\\varrho", AtomFamily::Ord)),
        "sigma" => return Some(sym("\\sigma", AtomFamily::Ord)),
        "varsigma" => return Some(sym("\\varsigma", AtomFamily::Ord)),
        "tau" => return Some(sym("\\tau", AtomFamily::Ord)),
        "upsilon" => return Some(sym("\\upsilon", AtomFamily::Ord)),
        "phi" => return Some(sym("\\phi", AtomFamily::Ord)),
        "varphi" => return Some(sym("\\varphi", AtomFamily::Ord)),
        "chi" => return Some(sym("\\chi", AtomFamily::Ord)),
        "psi" => return Some(sym("\\psi", AtomFamily::Ord)),
        "omega" => return Some(sym("\\omega", AtomFamily::Ord)),
        _ => {}
    }

    // Greek uppercase
    match name {
        "Gamma" => return Some(sym("\\Gamma", AtomFamily::Ord)),
        "Delta" => return Some(sym("\\Delta", AtomFamily::Ord)),
        "Theta" => return Some(sym("\\Theta", AtomFamily::Ord)),
        "Lambda" => return Some(sym("\\Lambda", AtomFamily::Ord)),
        "Xi" => return Some(sym("\\Xi", AtomFamily::Ord)),
        "Pi" => return Some(sym("\\Pi", AtomFamily::Ord)),
        "Sigma" => return Some(sym("\\Sigma", AtomFamily::Ord)),
        "Upsilon" => return Some(sym("\\Upsilon", AtomFamily::Ord)),
        "Phi" => return Some(sym("\\Phi", AtomFamily::Ord)),
        "Psi" => return Some(sym("\\Psi", AtomFamily::Ord)),
        "Omega" => return Some(sym("\\Omega", AtomFamily::Ord)),
        _ => {}
    }

    // Common symbols
    match name {
        "infty" => return Some(sym("\\infty", AtomFamily::Ord)),
        "pm" => return Some(sym("\\pm", AtomFamily::Bin)),
        "mp" => return Some(sym("\\mp", AtomFamily::Bin)),
        "times" => return Some(sym("\\times", AtomFamily::Bin)),
        "div" => return Some(sym("\\div", AtomFamily::Bin)),
        "cdot" => return Some(sym("\\cdot", AtomFamily::Bin)),
        "star" => return Some(sym("\\star", AtomFamily::Bin)),
        "circ" => return Some(sym("\\circ", AtomFamily::Bin)),
        "bullet" => return Some(sym("\\bullet", AtomFamily::Bin)),
        "oplus" => return Some(sym("\\oplus", AtomFamily::Bin)),
        "otimes" => return Some(sym("\\otimes", AtomFamily::Bin)),
        "ldots" => return Some(sym("\\ldots", AtomFamily::Inner)),
        "cdots" => return Some(sym("\\cdots", AtomFamily::Inner)),
        "vdots" => return Some(sym("\\vdots", AtomFamily::Ord)),
        "ddots" => return Some(sym("\\ddots", AtomFamily::Inner)),
        "to" | "rightarrow" => return Some(sym("\\to", AtomFamily::Rel)),
        "leftarrow" => return Some(sym("\\leftarrow", AtomFamily::Rel)),
        "leftrightarrow" => return Some(sym("\\leftrightarrow", AtomFamily::Rel)),
        "Rightarrow" => return Some(sym("\\Rightarrow", AtomFamily::Rel)),
        "Leftarrow" => return Some(sym("\\Leftarrow", AtomFamily::Rel)),
        "Leftrightarrow" => return Some(sym("\\Leftrightarrow", AtomFamily::Rel)),
        "implies" => return Some(sym("\\implies", AtomFamily::Rel)),
        "iff" => return Some(sym("\\iff", AtomFamily::Rel)),
        "mapsto" => return Some(sym("\\mapsto", AtomFamily::Rel)),
        "forall" => return Some(sym("\\forall", AtomFamily::Ord)),
        "exists" => return Some(sym("\\exists", AtomFamily::Ord)),
        "nexists" => return Some(sym("\\nexists", AtomFamily::Ord)),
        "in" => return Some(sym("\\in", AtomFamily::Rel)),
        "notin" => return Some(sym("\\notin", AtomFamily::Rel)),
        "ni" => return Some(sym("\\ni", AtomFamily::Rel)),
        "subset" => return Some(sym("\\subset", AtomFamily::Rel)),
        "supset" => return Some(sym("\\supset", AtomFamily::Rel)),
        "subseteq" => return Some(sym("\\subseteq", AtomFamily::Rel)),
        "supseteq" => return Some(sym("\\supseteq", AtomFamily::Rel)),
        "cup" => return Some(sym("\\cup", AtomFamily::Bin)),
        "cap" => return Some(sym("\\cap", AtomFamily::Bin)),
        "setminus" => return Some(sym("\\setminus", AtomFamily::Bin)),
        "emptyset" | "varnothing" => return Some(sym("\\emptyset", AtomFamily::Ord)),
        "neg" | "lnot" => return Some(sym("\\neg", AtomFamily::Ord)),
        "wedge" | "land" => return Some(sym("\\wedge", AtomFamily::Bin)),
        "vee" | "lor" => return Some(sym("\\vee", AtomFamily::Bin)),
        "partial" => return Some(sym("\\partial", AtomFamily::Ord)),
        "nabla" => return Some(sym("\\nabla", AtomFamily::Ord)),
        "ell" => return Some(sym("\\ell", AtomFamily::Ord)),
        "hbar" => return Some(sym("\\hbar", AtomFamily::Ord)),
        "Re" => return Some(sym("\\Re", AtomFamily::Ord)),
        "Im" => return Some(sym("\\Im", AtomFamily::Ord)),
        "aleph" => return Some(sym("\\aleph", AtomFamily::Ord)),
        // Relations
        "leq" | "le" => return Some(sym("\\leq", AtomFamily::Rel)),
        "geq" | "ge" => return Some(sym("\\geq", AtomFamily::Rel)),
        "neq" | "ne" => return Some(sym("\\neq", AtomFamily::Rel)),
        "approx" => return Some(sym("\\approx", AtomFamily::Rel)),
        "equiv" => return Some(sym("\\equiv", AtomFamily::Rel)),
        "sim" => return Some(sym("\\sim", AtomFamily::Rel)),
        "simeq" => return Some(sym("\\simeq", AtomFamily::Rel)),
        "cong" => return Some(sym("\\cong", AtomFamily::Rel)),
        "propto" => return Some(sym("\\propto", AtomFamily::Rel)),
        "perp" => return Some(sym("\\perp", AtomFamily::Rel)),
        "parallel" => return Some(sym("\\parallel", AtomFamily::Rel)),
        "ll" => return Some(sym("\\ll", AtomFamily::Rel)),
        "gg" => return Some(sym("\\gg", AtomFamily::Rel)),
        "prec" => return Some(sym("\\prec", AtomFamily::Rel)),
        "succ" => return Some(sym("\\succ", AtomFamily::Rel)),
        // Misc
        "angle" => return Some(sym("\\angle", AtomFamily::Ord)),
        "triangle" => return Some(sym("\\triangle", AtomFamily::Ord)),
        "diamond" => return Some(sym("\\diamond", AtomFamily::Ord)),
        "square" => return Some(sym("\\square", AtomFamily::Ord)),
        "checkmark" => return Some(sym("\\checkmark", AtomFamily::Ord)),
        "degree" => return Some(sym("\\degree", AtomFamily::Ord)),
        _ => None,
    }
}

fn sym(text: &str, family: AtomFamily) -> Resolved {
    Resolved::Symbol {
        text: text.to_string(),
        family,
    }
}
