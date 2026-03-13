import 'dart:ui';

/// Maps a katex-rs font name (e.g. "Main-Regular") to Flutter font family,
/// weight, and style.
class KaTeXFontInfo {
  final String family;
  final FontWeight weight;
  final FontStyle style;

  const KaTeXFontInfo(this.family, this.weight, this.style);
}

const _normal = FontWeight.normal;
const _bold = FontWeight.bold;
const _upright = FontStyle.normal;
const _italic = FontStyle.italic;

/// Maps katex-rs `font_name` strings to Flutter font info.
///
/// katex-rs uses names like "Main-Regular", "Math-Italic", etc.
/// These map to the KaTeX_* font families declared in pubspec.yaml.
const Map<String, KaTeXFontInfo> katexFontMap = {
  'Main-Regular': KaTeXFontInfo('KaTeX_Main', _normal, _upright),
  'Main-Bold': KaTeXFontInfo('KaTeX_Main', _bold, _upright),
  'Main-Italic': KaTeXFontInfo('KaTeX_Main', _normal, _italic),
  'Main-BoldItalic': KaTeXFontInfo('KaTeX_Main', _bold, _italic),
  'Math-Italic': KaTeXFontInfo('KaTeX_Math', _normal, _italic),
  'Math-BoldItalic': KaTeXFontInfo('KaTeX_Math', _bold, _italic),
  'AMS-Regular': KaTeXFontInfo('KaTeX_AMS', _normal, _upright),
  'Size1-Regular': KaTeXFontInfo('KaTeX_Size1', _normal, _upright),
  'Size2-Regular': KaTeXFontInfo('KaTeX_Size2', _normal, _upright),
  'Size3-Regular': KaTeXFontInfo('KaTeX_Size3', _normal, _upright),
  'Size4-Regular': KaTeXFontInfo('KaTeX_Size4', _normal, _upright),
  'Caligraphic-Regular': KaTeXFontInfo('KaTeX_Caligraphic', _normal, _upright),
  'Caligraphic-Bold': KaTeXFontInfo('KaTeX_Caligraphic', _bold, _upright),
  'Fraktur-Regular': KaTeXFontInfo('KaTeX_Fraktur', _normal, _upright),
  'Fraktur-Bold': KaTeXFontInfo('KaTeX_Fraktur', _bold, _upright),
  'SansSerif-Regular': KaTeXFontInfo('KaTeX_SansSerif', _normal, _upright),
  'SansSerif-Bold': KaTeXFontInfo('KaTeX_SansSerif', _bold, _upright),
  'SansSerif-Italic': KaTeXFontInfo('KaTeX_SansSerif', _normal, _italic),
  'Script-Regular': KaTeXFontInfo('KaTeX_Script', _normal, _upright),
  'Typewriter-Regular': KaTeXFontInfo('KaTeX_Typewriter', _normal, _upright),
};
