use flutter_rust_bridge::frb;

/// Positioned math layout, ready for rendering.
/// All dimensions are in **em** units — multiply by font size in pixels for px coords.
#[frb(non_opaque)]
#[derive(Clone, Debug)]
pub struct MathLayout {
    /// Total width in em.
    pub width: f64,
    /// Ascent above the baseline in em.
    pub height: f64,
    /// Descent below the baseline in em.
    pub depth: f64,
    /// Positioned rendering nodes.
    pub nodes: Vec<MathNode>,
}

/// A single positioned rendering primitive.
#[frb(non_opaque)]
#[derive(Clone, Debug)]
pub enum MathNode {
    /// A text glyph — render with a KaTeX font at `(x, y)`.
    Glyph {
        codepoint: u32,
        x: f64,
        y: f64,
        font_name: String,
        scale: f64,
        color: Option<String>,
        /// Optional opaque ID for correlating with a source tree (e.g. editor arena).
        node_id: Option<u32>,
    },
    /// Fraction bar, overline, underline, etc.
    Rule {
        x: f64,
        y: f64,
        width: f64,
        height: f64,
        color: Option<String>,
        /// Optional opaque ID for correlating with a source tree.
        node_id: Option<u32>,
    },
    /// Stretchy SVG element (radical sign, large delimiters, wide accents).
    /// Path commands are pre-parsed — build a canvas Path directly from these.
    SvgPath {
        x: f64,
        y: f64,
        width: f64,
        height: f64,
        view_box_x: f64,
        view_box_y: f64,
        view_box_width: f64,
        view_box_height: f64,
        commands: Vec<PathCommand>,
        /// Optional opaque ID for correlating with a source tree.
        node_id: Option<u32>,
    },
}

/// A single path drawing command (absolute coordinates).
#[frb(non_opaque)]
#[derive(Clone, Debug)]
pub enum PathCommand {
    /// Move to (x, y).
    MoveTo { x: f64, y: f64 },
    /// Line to (x, y).
    LineTo { x: f64, y: f64 },
    /// Cubic Bézier to (x, y) with control points (x1, y1) and (x2, y2).
    CubicTo {
        x1: f64,
        y1: f64,
        x2: f64,
        y2: f64,
        x: f64,
        y: f64,
    },
    /// Quadratic Bézier to (x, y) with control point (x1, y1).
    QuadTo { x1: f64, y1: f64, x: f64, y: f64 },
    /// Close the current sub-path.
    Close,
}

impl From<katex::math_layout::MathLayout> for MathLayout {
    fn from(l: katex::math_layout::MathLayout) -> Self {
        Self {
            width: l.width,
            height: l.height,
            depth: l.depth,
            nodes: l.nodes.into_iter().map(MathNode::from).collect(),
        }
    }
}

impl From<katex::math_layout::MathNode> for MathNode {
    fn from(n: katex::math_layout::MathNode) -> Self {
        match n {
            katex::math_layout::MathNode::Glyph {
                codepoint,
                x,
                y,
                font_name,
                scale,
                color,
                node_id,
            } => Self::Glyph {
                codepoint,
                x,
                y,
                font_name,
                scale,
                color,
                node_id,
            },
            katex::math_layout::MathNode::Rule {
                x,
                y,
                width,
                height,
                color,
                node_id,
            } => Self::Rule {
                x,
                y,
                width,
                height,
                color,
                node_id,
            },
            katex::math_layout::MathNode::SvgPath {
                x,
                y,
                width,
                height,
                view_box_x,
                view_box_y,
                view_box_width,
                view_box_height,
                commands,
                node_id,
            } => Self::SvgPath {
                x,
                y,
                width,
                height,
                view_box_x,
                view_box_y,
                view_box_width,
                view_box_height,
                commands: commands.into_iter().map(PathCommand::from).collect(),
                node_id,
            },
        }
    }
}

impl From<katex::math_layout::PathCommand> for PathCommand {
    fn from(c: katex::math_layout::PathCommand) -> Self {
        match c {
            katex::math_layout::PathCommand::MoveTo { x, y } => Self::MoveTo { x, y },
            katex::math_layout::PathCommand::LineTo { x, y } => Self::LineTo { x, y },
            katex::math_layout::PathCommand::CubicTo {
                x1,
                y1,
                x2,
                y2,
                x,
                y,
            } => Self::CubicTo {
                x1,
                y1,
                x2,
                y2,
                x,
                y,
            },
            katex::math_layout::PathCommand::QuadTo { x1, y1, x, y } => {
                Self::QuadTo { x1, y1, x, y }
            }
            katex::math_layout::PathCommand::Close => Self::Close,
        }
    }
}

/// Layout a LaTeX expression, returning positioned nodes for rendering.
///
/// All coordinates in the returned [`MathLayout`] are in **em** units.
/// Multiply by the desired font size in logical pixels to get pixel coords.
///
/// Returns an empty layout on parse error.
#[frb(sync)]
pub fn layout_math(latex: String, display_mode: bool) -> MathLayout {
    let ctx = katex::KatexContext::default();
    let mut settings = katex::Settings::default();
    settings.display_mode = display_mode;
    katex::render_to_layout(&ctx, &latex, &settings)
        .map(MathLayout::from)
        .unwrap_or(MathLayout {
            width: 0.0,
            height: 0.0,
            depth: 0.0,
            nodes: Vec::new(),
        })
}

/// Layout a LaTeX expression as a hierarchical tree for widget-tree rendering.
///
/// Creates a temporary Arena via `import_latex`, builds the layout, and returns
/// a tree without cursor/selection. No editor registry involved.
///
/// This is used for `MathView(selectable: true)`.
#[frb(sync)]
pub fn layout_math_tree(latex: String, display_mode: bool) -> crate::api::editor_layout::EditorLayout {
    use crate::api::editor_layout::build_readonly_layout;
    use crate::editor::convert::import_latex;

    let state = match import_latex(&latex) {
        Ok(s) => s,
        Err(_) => {
            return crate::api::editor_layout::EditorLayout {
                root: crate::api::editor_layout::BlockLayout {
                    block_id: 0,
                    width: 0.0,
                    height: 0.0,
                    depth: 0.0,
                    children: Vec::new(),
                    cursor_index: None,
                    selection: None,
                },
                untagged: Vec::new(),
            };
        }
    };

    let ctx = katex::KatexContext::default();
    let mut settings = katex::Settings::default();
    settings.display_mode = display_mode;

    let leaf_ids = crate::api::editor_api::collect_leaf_ids(&state.arena);
    let layout = katex::render_to_layout_tagged(&ctx, &latex, &settings, leaf_ids)
        .map(MathLayout::from)
        .unwrap_or(MathLayout {
            width: 0.0,
            height: 0.0,
            depth: 0.0,
            nodes: Vec::new(),
        });

    build_readonly_layout(&state.arena, &layout)
}

#[frb(init)]
pub fn init_app() {
    flutter_rust_bridge::setup_default_user_utils();
}
