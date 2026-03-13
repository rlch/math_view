import 'package:flutter/material.dart';
import 'package:math_view/math_view.dart';

Future<void> main() async {
  await RustLib.init();
  runApp(const MathViewExample());
}

class MathViewExample extends StatelessWidget {
  const MathViewExample({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MathView Example',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue)),
      home: const MathShowcase(),
    );
  }
}

class MathShowcase extends StatelessWidget {
  const MathShowcase({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MathView')),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 32,
          children: [
            _Section(
              title: 'Inline',
              children: [
                _MathRow(label: 'Variable', latex: 'x'),
                _MathRow(label: 'Addition', latex: 'a + b'),
                _MathRow(label: 'Superscript', latex: 'E = mc^2'),
                _MathRow(label: 'Subscript', latex: 'x_i'),
              ],
            ),
            _Section(
              title: 'Display mode',
              children: [
                _MathBlock(
                  label: 'Quadratic formula',
                  latex: r'x = \frac{-b \pm \sqrt{b^2 - 4ac}}{2a}',
                ),
                _MathBlock(
                  label: 'Summation',
                  latex: r'\sum_{i=1}^{n} x_i',
                ),
                _MathBlock(
                  label: 'Integral',
                  latex: r'\int_{0}^{\infty} e^{-x^2} dx = \frac{\sqrt{\pi}}{2}',
                ),
                _MathBlock(
                  label: 'Matrix',
                  latex: r'\begin{pmatrix} a & b \\ c & d \end{pmatrix}',
                ),
                _MathBlock(
                  label: 'Nested fractions',
                  latex: r'\frac{1}{1 + \frac{1}{1 + \frac{1}{x}}}',
                ),
              ],
            ),
            _Section(
              title: 'Colors',
              children: [
                _MathBlock(
                  label: 'textcolor',
                  latex: r'\textcolor{red}{x} + \textcolor{blue}{y} = \textcolor{green}{z}',
                ),
                _MathBlock(
                  label: 'colorbox',
                  latex: r'\colorbox{yellow}{x^2 + y^2}',
                ),
              ],
            ),
            _Section(
              title: 'Operators & limits',
              children: [
                _MathBlock(
                  label: 'Limit',
                  latex: r'\lim_{x \to 0} \frac{\sin x}{x} = 1',
                ),
                _MathBlock(
                  label: 'Product',
                  latex: r'\prod_{k=1}^{n} k = n!',
                ),
                _MathBlock(
                  label: 'Binomial',
                  latex: r'\binom{n}{k} = \frac{n!}{k!(n-k)!}',
                ),
                _MathBlock(
                  label: 'Trig',
                  latex: r'\sin^2\theta + \cos^2\theta = 1',
                ),
              ],
            ),
            _Section(
              title: 'Environments',
              children: [
                _MathBlock(
                  label: 'Cases',
                  latex: r'f(x) = \begin{cases} x^2 & x \geq 0 \\ -x & x < 0 \end{cases}',
                ),
                _MathBlock(
                  label: 'Aligned',
                  latex: r'\begin{aligned} a &= b + c \\ d &= e + f + g \end{aligned}',
                ),
                _MathBlock(
                  label: '3x3 Matrix',
                  latex: r'\begin{bmatrix} 1 & 0 & 0 \\ 0 & 1 & 0 \\ 0 & 0 & 1 \end{bmatrix}',
                ),
              ],
            ),
            _Section(
              title: 'Accents & decorations',
              children: [
                _MathBlock(label: 'Hat', latex: r'\hat{x} + \bar{y} + \vec{z}'),
                _MathBlock(label: 'Overline', latex: r'\overline{a + b}'),
                _MathBlock(label: 'Underbrace', latex: r'\underbrace{a + b + c}_{n \text{ terms}}'),
                _MathBlock(label: 'Overbrace', latex: r'\overbrace{1 + 2 + \cdots + n}^{S_n}'),
              ],
            ),
            _Section(
              title: 'Inline with text (baseline)',
              children: [
                _InlineTextMath(
                  before: 'The equation ',
                  latex: r'E = mc^2',
                  after: ' is famous.',
                ),
                _InlineTextMath(
                  before: 'We know that ',
                  latex: r'\frac{a}{b} + \frac{c}{d}',
                  after: ' is a sum.',
                ),
                _InlineTextMath(
                  before: 'Consider ',
                  latex: r'\sqrt{x^2 + y^2}',
                  after: ' as distance.',
                ),
              ],
            ),
            _Section(
              title: 'Edge cases',
              children: [
                _MathBlock(label: 'Single number', latex: '42'),
                _MathBlock(label: 'Long expression', latex: r'a + b + c + d + e + f + g + h + i + j + k + l + m + n'),
                _MathBlock(label: 'Nested sqrt', latex: r'\sqrt{\sqrt{\sqrt{x}}}'),
                _MathBlock(label: 'Large delimiters', latex: r'\left( \frac{\frac{a}{b}}{\frac{c}{d}} \right)'),
              ],
            ),
            _Section(
              title: 'Font sizes',
              children: [
                _MathSized(latex: r'\alpha + \beta = \gamma', fontSize: 12),
                _MathSized(latex: r'\alpha + \beta = \gamma', fontSize: 20),
                _MathSized(latex: r'\alpha + \beta = \gamma', fontSize: 32),
              ],
            ),
            _Section(
              title: 'Editor',
              children: [
                _EditorDemo(
                  label: 'Empty editor',
                ),
                _EditorDemo(
                  label: 'Pre-populated',
                  initialLatex: r'\frac{x+1}{2}',
                ),
                _EditorDemo(
                  label: 'Quadratic',
                  initialLatex: r'x = \frac{-b \pm \sqrt{b^2 - 4ac}}{2a}',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 16,
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineSmall),
        ...children,
      ],
    );
  }
}

class _MathRow extends StatelessWidget {
  final String label;
  final String latex;

  const _MathRow({required this.label, required this.latex});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 120, child: Text(label)),
        MathView(latex: latex, fontSize: 20),
      ],
    );
  }
}

class _MathBlock extends StatelessWidget {
  final String label;
  final String latex;

  const _MathBlock({required this.label, required this.latex});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        Center(
          child: MathView(latex: latex, displayMode: true, fontSize: 24),
        ),
      ],
    );
  }
}

class _InlineTextMath extends StatelessWidget {
  final String before;
  final String latex;
  final String after;

  const _InlineTextMath({
    required this.before,
    required this.latex,
    required this.after,
  });

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        style: const TextStyle(fontSize: 16),
        children: [
          TextSpan(text: before),
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: MathView(latex: latex, fontSize: 16, debugBaseline: true),
          ),
          TextSpan(text: after),
        ],
      ),
    );
  }
}

class _EditorDemo extends StatefulWidget {
  final String label;
  final String? initialLatex;

  const _EditorDemo({required this.label, this.initialLatex});

  @override
  State<_EditorDemo> createState() => _EditorDemoState();
}

class _EditorDemoState extends State<_EditorDemo> {
  String _latex = '';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        Text(widget.label, style: Theme.of(context).textTheme.bodySmall),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: MathEditor(
            initialLatex: widget.initialLatex,
            fontSize: 24,
            autofocus: false,
            onChanged: (latex) => setState(() => _latex = latex),
          ),
        ),
        Text(
          'LaTeX: $_latex',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
                fontFamily: 'monospace',
              ),
        ),
      ],
    );
  }
}

class _MathSized extends StatelessWidget {
  final String latex;
  final double fontSize;

  const _MathSized({required this.latex, required this.fontSize});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 60, child: Text('${fontSize.toInt()}px')),
        MathView(latex: latex, fontSize: fontSize),
      ],
    );
  }
}
