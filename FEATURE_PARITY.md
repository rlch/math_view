# Feature Parity: MathQuill → math_view

## Legend
- ✅ Implemented
- ⚠️ Partial
- ❌ Missing
- 🟢 math_view has, MathQuill doesn't

## Math Constructs

| Feature | MQ | MV | Notes |
|---|---|---|---|
| Fractions (`\frac`) | ✅ | ✅ | LiveFraction (`/` key) missing in MV |
| Superscripts (`^`) | ✅ | ✅ | |
| Subscripts (`_`) | ✅ | ✅ | |
| Combined Sup/Sub | ✅ | ✅ | |
| Square root (`\sqrt`) | ✅ | ✅ | |
| Nth root (`\nthroot`) | ✅ | ✅ | |
| Parentheses/Brackets/Braces | ✅ | ✅ | MQ has ghost brackets, one-sided brackets |
| Absolute value | ✅ | ✅ | |
| Summation (`\sum`) | ✅ | ✅ | |
| Product (`\prod`) | ✅ | ✅ | |
| Integral (`\int`) | ✅ | ✅ | |
| Limit (`\lim`) | ✅ | ✅ | |
| Overline/Underline | ✅ | ✅ | |
| Accents (`\hat`, `\vec`, `\bar`) | ✅ | ✅ | |
| Over/Underbrace | ❌ | 🟢 | |
| Extensible arrows | ❌ | 🟢 | `\xleftarrow`, `\xrightarrow` |
| Matrices | ❌ | 🟢 | m×n |
| Text mode (`\text`) | ✅ | ✅ | |
| Colors (`\textcolor`) | ✅ | ✅ | |
| Fonts (`\mathbf`, `\mathrm`) | ✅ | ✅ | |
| Sizing (`\tiny`, `\large`) | ❌ | 🟢 | |
| Phantom | ❌ | 🟢 | |
| Binomial (`\binom`) | ✅ | ❌ | |
| Embedded objects (`\embed`) | ✅ | ❌ | Custom HTML embeds |
| Editable sub-fields | ✅ | ❌ | Nested editable regions |

## Symbols & Greek

| Feature | MQ | MV | Notes |
|---|---|---|---|
| Greek letters (full set) | ✅ | ⚠️ | LaTeX import works, no input shortcuts |
| Atom family spacing | ✅ | ✅ | `classify_char` in MV |
| Arrow symbols | ✅ | ⚠️ | Char insertion only, not named commands |
| Set theory symbols | ✅ | ⚠️ | Char insertion only |
| Logic symbols | ✅ | ⚠️ | Char insertion only |
| Dots (`\ldots`, `\cdots`) | ✅ | ⚠️ | LaTeX import only |

## Input & Keyboard

| # | Feature | MQ | MV | Notes |
|---|---|---|---|---|
| 1 | **`\` LaTeX command input** | ✅ | ❌ | Backslash opens command entry mode |
| 2 | **`/` LiveFraction** | ✅ | ❌ | Wraps preceding content into numerator |
| 7 | **Tab/Space to escape block** | ✅ | ❌ | Tab/Esc/Space exits current block |
| | Arrow key nav (L/R) | ✅ | ✅ | |
| | Arrow key nav (Up/Down) | ✅ | ✅ | Fracs, sup/sub, sums, matrices |
| | Home/End | ✅ | ✅ | |
| | Backspace (flatten command) | ✅ | ✅ | |
| | Delete forward | ✅ | ✅ | |
| | Ctrl+Backspace (word delete) | ✅ | ❌ | |
| | Select All (Ctrl+A) | ✅ | ✅ | |
| | Shift+Arrow selection | ✅ | ✅ | |
| 9 | **Auto-subscript numerals** | ✅ | ❌ | `x2` → `x_2` |
| | Smart unary/binary detection | ✅ | ❌ | |
| | Cmd+/ for fraction | ❌ | 🟢 | |

## Auto-Operator Recognition

| # | Feature | MQ | MV | Notes |
|---|---|---|---|---|
| 3 | **Auto-detect `sin`, `cos`, `log`** | ✅ | ❌ | 70+ auto-operators |
| 3 | **Auto-parenthesization** | ✅ | ❌ | `sin(` auto-trigger |
| 3 | **Configurable operator list** | ✅ | ❌ | |
| 3 | **Auto-unitalicize** | ✅ | ❌ | |

## Selection & Clipboard

| # | Feature | MQ | MV | Notes |
|---|---|---|---|---|
| | Shift+Arrow selection | ✅ | ✅ | |
| 6 | **Mouse drag selection** | ✅ | ❌ | |
| 4 | **Copy** (LaTeX to clipboard) | ✅ | ❌ | |
| 4 | **Cut** | ✅ | ❌ | |
| 4 | **Paste** (LaTeX from clipboard) | ✅ | ❌ | |
| 8 | **Cross-block selection** | ✅ | ❌ | MV limited to single block |
| | Selection wrapping into command | ✅ | ✅ | |

## Undo/Redo

| # | Feature | MQ | MV | Notes |
|---|---|---|---|---|
| 5 | **Undo** (Ctrl+Z) | ⚠️ | ❌ | |
| 5 | **Redo** (Ctrl+Shift+Z) | ⚠️ | ❌ | |

## Mouse Interaction

| Feature | MQ | MV | Notes |
|---|---|---|---|
| Click to position cursor | ✅ | ✅ | |
| Click+drag to select | ✅ | ❌ | |

## Accessibility

| Feature | MQ | MV | Notes |
|---|---|---|---|
| ARIA labels | ✅ | ❌ | |
| Mathspeak generation | ✅ | ❌ | |
| Screen reader navigation | ✅ | ❌ | |

## Rendering

| Feature | MQ | MV | Notes |
|---|---|---|---|
| Glyph rendering | ✅ (DOM) | ✅ (Canvas) | |
| Display vs inline mode | ✅ | ✅ | |
| Cursor blinking | ✅ | ✅ | |
| Selection highlight | ✅ | ✅ | |
| Selectable text mode | ❌ | 🟢 | Flutter SelectionArea |
| Digit grouping | ✅ | ❌ | |
| Scroll horizontal overflow | ✅ | ❌ | |

## Priority Gaps

1. **`\` LaTeX command input** — type `\frac`, `\alpha` via backslash
2. **`/` LiveFraction** — natural fraction entry `1/2`
3. **Auto-operator names** — `sin` → `\sin` recognition
4. **Copy/Paste** — clipboard support
5. **Undo/Redo** — history stack
6. **Mouse drag selection**
7. **Tab/Space block escape**
8. **Cross-block selection**
9. **Auto-subscript numerals** — `x2` → `x_2`
