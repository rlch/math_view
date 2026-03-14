// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'math_api.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$MathNode {

 double get x; double get y;/// Advance width in em (actual glyph width from font metrics, scaled).
 double get width;/// Optional opaque ID for correlating with a source tree (e.g. editor arena).
 int? get nodeId;
/// Create a copy of MathNode
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MathNodeCopyWith<MathNode> get copyWith => _$MathNodeCopyWithImpl<MathNode>(this as MathNode, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MathNode&&(identical(other.x, x) || other.x == x)&&(identical(other.y, y) || other.y == y)&&(identical(other.width, width) || other.width == width)&&(identical(other.nodeId, nodeId) || other.nodeId == nodeId));
}


@override
int get hashCode => Object.hash(runtimeType,x,y,width,nodeId);

@override
String toString() {
  return 'MathNode(x: $x, y: $y, width: $width, nodeId: $nodeId)';
}


}

/// @nodoc
abstract mixin class $MathNodeCopyWith<$Res>  {
  factory $MathNodeCopyWith(MathNode value, $Res Function(MathNode) _then) = _$MathNodeCopyWithImpl;
@useResult
$Res call({
 double x, double y, double width, int? nodeId
});




}
/// @nodoc
class _$MathNodeCopyWithImpl<$Res>
    implements $MathNodeCopyWith<$Res> {
  _$MathNodeCopyWithImpl(this._self, this._then);

  final MathNode _self;
  final $Res Function(MathNode) _then;

/// Create a copy of MathNode
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? x = null,Object? y = null,Object? width = null,Object? nodeId = freezed,}) {
  return _then(_self.copyWith(
x: null == x ? _self.x : x // ignore: cast_nullable_to_non_nullable
as double,y: null == y ? _self.y : y // ignore: cast_nullable_to_non_nullable
as double,width: null == width ? _self.width : width // ignore: cast_nullable_to_non_nullable
as double,nodeId: freezed == nodeId ? _self.nodeId : nodeId // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [MathNode].
extension MathNodePatterns on MathNode {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( MathNode_Glyph value)?  glyph,TResult Function( MathNode_Rule value)?  rule,TResult Function( MathNode_SvgPath value)?  svgPath,required TResult orElse(),}){
final _that = this;
switch (_that) {
case MathNode_Glyph() when glyph != null:
return glyph(_that);case MathNode_Rule() when rule != null:
return rule(_that);case MathNode_SvgPath() when svgPath != null:
return svgPath(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( MathNode_Glyph value)  glyph,required TResult Function( MathNode_Rule value)  rule,required TResult Function( MathNode_SvgPath value)  svgPath,}){
final _that = this;
switch (_that) {
case MathNode_Glyph():
return glyph(_that);case MathNode_Rule():
return rule(_that);case MathNode_SvgPath():
return svgPath(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( MathNode_Glyph value)?  glyph,TResult? Function( MathNode_Rule value)?  rule,TResult? Function( MathNode_SvgPath value)?  svgPath,}){
final _that = this;
switch (_that) {
case MathNode_Glyph() when glyph != null:
return glyph(_that);case MathNode_Rule() when rule != null:
return rule(_that);case MathNode_SvgPath() when svgPath != null:
return svgPath(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( int codepoint,  double x,  double y,  String fontName,  double scale,  double width,  String? color,  int? nodeId)?  glyph,TResult Function( double x,  double y,  double width,  double height,  String? color,  int? nodeId)?  rule,TResult Function( double x,  double y,  double width,  double height,  double viewBoxX,  double viewBoxY,  double viewBoxWidth,  double viewBoxHeight,  List<PathCommand> commands,  int? nodeId)?  svgPath,required TResult orElse(),}) {final _that = this;
switch (_that) {
case MathNode_Glyph() when glyph != null:
return glyph(_that.codepoint,_that.x,_that.y,_that.fontName,_that.scale,_that.width,_that.color,_that.nodeId);case MathNode_Rule() when rule != null:
return rule(_that.x,_that.y,_that.width,_that.height,_that.color,_that.nodeId);case MathNode_SvgPath() when svgPath != null:
return svgPath(_that.x,_that.y,_that.width,_that.height,_that.viewBoxX,_that.viewBoxY,_that.viewBoxWidth,_that.viewBoxHeight,_that.commands,_that.nodeId);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( int codepoint,  double x,  double y,  String fontName,  double scale,  double width,  String? color,  int? nodeId)  glyph,required TResult Function( double x,  double y,  double width,  double height,  String? color,  int? nodeId)  rule,required TResult Function( double x,  double y,  double width,  double height,  double viewBoxX,  double viewBoxY,  double viewBoxWidth,  double viewBoxHeight,  List<PathCommand> commands,  int? nodeId)  svgPath,}) {final _that = this;
switch (_that) {
case MathNode_Glyph():
return glyph(_that.codepoint,_that.x,_that.y,_that.fontName,_that.scale,_that.width,_that.color,_that.nodeId);case MathNode_Rule():
return rule(_that.x,_that.y,_that.width,_that.height,_that.color,_that.nodeId);case MathNode_SvgPath():
return svgPath(_that.x,_that.y,_that.width,_that.height,_that.viewBoxX,_that.viewBoxY,_that.viewBoxWidth,_that.viewBoxHeight,_that.commands,_that.nodeId);}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( int codepoint,  double x,  double y,  String fontName,  double scale,  double width,  String? color,  int? nodeId)?  glyph,TResult? Function( double x,  double y,  double width,  double height,  String? color,  int? nodeId)?  rule,TResult? Function( double x,  double y,  double width,  double height,  double viewBoxX,  double viewBoxY,  double viewBoxWidth,  double viewBoxHeight,  List<PathCommand> commands,  int? nodeId)?  svgPath,}) {final _that = this;
switch (_that) {
case MathNode_Glyph() when glyph != null:
return glyph(_that.codepoint,_that.x,_that.y,_that.fontName,_that.scale,_that.width,_that.color,_that.nodeId);case MathNode_Rule() when rule != null:
return rule(_that.x,_that.y,_that.width,_that.height,_that.color,_that.nodeId);case MathNode_SvgPath() when svgPath != null:
return svgPath(_that.x,_that.y,_that.width,_that.height,_that.viewBoxX,_that.viewBoxY,_that.viewBoxWidth,_that.viewBoxHeight,_that.commands,_that.nodeId);case _:
  return null;

}
}

}

/// @nodoc


class MathNode_Glyph extends MathNode {
  const MathNode_Glyph({required this.codepoint, required this.x, required this.y, required this.fontName, required this.scale, required this.width, this.color, this.nodeId}): super._();
  

 final  int codepoint;
@override final  double x;
@override final  double y;
 final  String fontName;
 final  double scale;
/// Advance width in em (actual glyph width from font metrics, scaled).
@override final  double width;
 final  String? color;
/// Optional opaque ID for correlating with a source tree (e.g. editor arena).
@override final  int? nodeId;

/// Create a copy of MathNode
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MathNode_GlyphCopyWith<MathNode_Glyph> get copyWith => _$MathNode_GlyphCopyWithImpl<MathNode_Glyph>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MathNode_Glyph&&(identical(other.codepoint, codepoint) || other.codepoint == codepoint)&&(identical(other.x, x) || other.x == x)&&(identical(other.y, y) || other.y == y)&&(identical(other.fontName, fontName) || other.fontName == fontName)&&(identical(other.scale, scale) || other.scale == scale)&&(identical(other.width, width) || other.width == width)&&(identical(other.color, color) || other.color == color)&&(identical(other.nodeId, nodeId) || other.nodeId == nodeId));
}


@override
int get hashCode => Object.hash(runtimeType,codepoint,x,y,fontName,scale,width,color,nodeId);

@override
String toString() {
  return 'MathNode.glyph(codepoint: $codepoint, x: $x, y: $y, fontName: $fontName, scale: $scale, width: $width, color: $color, nodeId: $nodeId)';
}


}

/// @nodoc
abstract mixin class $MathNode_GlyphCopyWith<$Res> implements $MathNodeCopyWith<$Res> {
  factory $MathNode_GlyphCopyWith(MathNode_Glyph value, $Res Function(MathNode_Glyph) _then) = _$MathNode_GlyphCopyWithImpl;
@override @useResult
$Res call({
 int codepoint, double x, double y, String fontName, double scale, double width, String? color, int? nodeId
});




}
/// @nodoc
class _$MathNode_GlyphCopyWithImpl<$Res>
    implements $MathNode_GlyphCopyWith<$Res> {
  _$MathNode_GlyphCopyWithImpl(this._self, this._then);

  final MathNode_Glyph _self;
  final $Res Function(MathNode_Glyph) _then;

/// Create a copy of MathNode
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? codepoint = null,Object? x = null,Object? y = null,Object? fontName = null,Object? scale = null,Object? width = null,Object? color = freezed,Object? nodeId = freezed,}) {
  return _then(MathNode_Glyph(
codepoint: null == codepoint ? _self.codepoint : codepoint // ignore: cast_nullable_to_non_nullable
as int,x: null == x ? _self.x : x // ignore: cast_nullable_to_non_nullable
as double,y: null == y ? _self.y : y // ignore: cast_nullable_to_non_nullable
as double,fontName: null == fontName ? _self.fontName : fontName // ignore: cast_nullable_to_non_nullable
as String,scale: null == scale ? _self.scale : scale // ignore: cast_nullable_to_non_nullable
as double,width: null == width ? _self.width : width // ignore: cast_nullable_to_non_nullable
as double,color: freezed == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String?,nodeId: freezed == nodeId ? _self.nodeId : nodeId // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

/// @nodoc


class MathNode_Rule extends MathNode {
  const MathNode_Rule({required this.x, required this.y, required this.width, required this.height, this.color, this.nodeId}): super._();
  

@override final  double x;
@override final  double y;
@override final  double width;
 final  double height;
 final  String? color;
/// Optional opaque ID for correlating with a source tree.
@override final  int? nodeId;

/// Create a copy of MathNode
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MathNode_RuleCopyWith<MathNode_Rule> get copyWith => _$MathNode_RuleCopyWithImpl<MathNode_Rule>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MathNode_Rule&&(identical(other.x, x) || other.x == x)&&(identical(other.y, y) || other.y == y)&&(identical(other.width, width) || other.width == width)&&(identical(other.height, height) || other.height == height)&&(identical(other.color, color) || other.color == color)&&(identical(other.nodeId, nodeId) || other.nodeId == nodeId));
}


@override
int get hashCode => Object.hash(runtimeType,x,y,width,height,color,nodeId);

@override
String toString() {
  return 'MathNode.rule(x: $x, y: $y, width: $width, height: $height, color: $color, nodeId: $nodeId)';
}


}

/// @nodoc
abstract mixin class $MathNode_RuleCopyWith<$Res> implements $MathNodeCopyWith<$Res> {
  factory $MathNode_RuleCopyWith(MathNode_Rule value, $Res Function(MathNode_Rule) _then) = _$MathNode_RuleCopyWithImpl;
@override @useResult
$Res call({
 double x, double y, double width, double height, String? color, int? nodeId
});




}
/// @nodoc
class _$MathNode_RuleCopyWithImpl<$Res>
    implements $MathNode_RuleCopyWith<$Res> {
  _$MathNode_RuleCopyWithImpl(this._self, this._then);

  final MathNode_Rule _self;
  final $Res Function(MathNode_Rule) _then;

/// Create a copy of MathNode
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? x = null,Object? y = null,Object? width = null,Object? height = null,Object? color = freezed,Object? nodeId = freezed,}) {
  return _then(MathNode_Rule(
x: null == x ? _self.x : x // ignore: cast_nullable_to_non_nullable
as double,y: null == y ? _self.y : y // ignore: cast_nullable_to_non_nullable
as double,width: null == width ? _self.width : width // ignore: cast_nullable_to_non_nullable
as double,height: null == height ? _self.height : height // ignore: cast_nullable_to_non_nullable
as double,color: freezed == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String?,nodeId: freezed == nodeId ? _self.nodeId : nodeId // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

/// @nodoc


class MathNode_SvgPath extends MathNode {
  const MathNode_SvgPath({required this.x, required this.y, required this.width, required this.height, required this.viewBoxX, required this.viewBoxY, required this.viewBoxWidth, required this.viewBoxHeight, required final  List<PathCommand> commands, this.nodeId}): _commands = commands,super._();
  

@override final  double x;
@override final  double y;
@override final  double width;
 final  double height;
 final  double viewBoxX;
 final  double viewBoxY;
 final  double viewBoxWidth;
 final  double viewBoxHeight;
 final  List<PathCommand> _commands;
 List<PathCommand> get commands {
  if (_commands is EqualUnmodifiableListView) return _commands;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_commands);
}

/// Optional opaque ID for correlating with a source tree.
@override final  int? nodeId;

/// Create a copy of MathNode
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MathNode_SvgPathCopyWith<MathNode_SvgPath> get copyWith => _$MathNode_SvgPathCopyWithImpl<MathNode_SvgPath>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MathNode_SvgPath&&(identical(other.x, x) || other.x == x)&&(identical(other.y, y) || other.y == y)&&(identical(other.width, width) || other.width == width)&&(identical(other.height, height) || other.height == height)&&(identical(other.viewBoxX, viewBoxX) || other.viewBoxX == viewBoxX)&&(identical(other.viewBoxY, viewBoxY) || other.viewBoxY == viewBoxY)&&(identical(other.viewBoxWidth, viewBoxWidth) || other.viewBoxWidth == viewBoxWidth)&&(identical(other.viewBoxHeight, viewBoxHeight) || other.viewBoxHeight == viewBoxHeight)&&const DeepCollectionEquality().equals(other._commands, _commands)&&(identical(other.nodeId, nodeId) || other.nodeId == nodeId));
}


@override
int get hashCode => Object.hash(runtimeType,x,y,width,height,viewBoxX,viewBoxY,viewBoxWidth,viewBoxHeight,const DeepCollectionEquality().hash(_commands),nodeId);

@override
String toString() {
  return 'MathNode.svgPath(x: $x, y: $y, width: $width, height: $height, viewBoxX: $viewBoxX, viewBoxY: $viewBoxY, viewBoxWidth: $viewBoxWidth, viewBoxHeight: $viewBoxHeight, commands: $commands, nodeId: $nodeId)';
}


}

/// @nodoc
abstract mixin class $MathNode_SvgPathCopyWith<$Res> implements $MathNodeCopyWith<$Res> {
  factory $MathNode_SvgPathCopyWith(MathNode_SvgPath value, $Res Function(MathNode_SvgPath) _then) = _$MathNode_SvgPathCopyWithImpl;
@override @useResult
$Res call({
 double x, double y, double width, double height, double viewBoxX, double viewBoxY, double viewBoxWidth, double viewBoxHeight, List<PathCommand> commands, int? nodeId
});




}
/// @nodoc
class _$MathNode_SvgPathCopyWithImpl<$Res>
    implements $MathNode_SvgPathCopyWith<$Res> {
  _$MathNode_SvgPathCopyWithImpl(this._self, this._then);

  final MathNode_SvgPath _self;
  final $Res Function(MathNode_SvgPath) _then;

/// Create a copy of MathNode
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? x = null,Object? y = null,Object? width = null,Object? height = null,Object? viewBoxX = null,Object? viewBoxY = null,Object? viewBoxWidth = null,Object? viewBoxHeight = null,Object? commands = null,Object? nodeId = freezed,}) {
  return _then(MathNode_SvgPath(
x: null == x ? _self.x : x // ignore: cast_nullable_to_non_nullable
as double,y: null == y ? _self.y : y // ignore: cast_nullable_to_non_nullable
as double,width: null == width ? _self.width : width // ignore: cast_nullable_to_non_nullable
as double,height: null == height ? _self.height : height // ignore: cast_nullable_to_non_nullable
as double,viewBoxX: null == viewBoxX ? _self.viewBoxX : viewBoxX // ignore: cast_nullable_to_non_nullable
as double,viewBoxY: null == viewBoxY ? _self.viewBoxY : viewBoxY // ignore: cast_nullable_to_non_nullable
as double,viewBoxWidth: null == viewBoxWidth ? _self.viewBoxWidth : viewBoxWidth // ignore: cast_nullable_to_non_nullable
as double,viewBoxHeight: null == viewBoxHeight ? _self.viewBoxHeight : viewBoxHeight // ignore: cast_nullable_to_non_nullable
as double,commands: null == commands ? _self._commands : commands // ignore: cast_nullable_to_non_nullable
as List<PathCommand>,nodeId: freezed == nodeId ? _self.nodeId : nodeId // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

/// @nodoc
mixin _$PathCommand {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PathCommand);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PathCommand()';
}


}

/// @nodoc
class $PathCommandCopyWith<$Res>  {
$PathCommandCopyWith(PathCommand _, $Res Function(PathCommand) __);
}


/// Adds pattern-matching-related methods to [PathCommand].
extension PathCommandPatterns on PathCommand {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( PathCommand_MoveTo value)?  moveTo,TResult Function( PathCommand_LineTo value)?  lineTo,TResult Function( PathCommand_CubicTo value)?  cubicTo,TResult Function( PathCommand_QuadTo value)?  quadTo,TResult Function( PathCommand_Close value)?  close,required TResult orElse(),}){
final _that = this;
switch (_that) {
case PathCommand_MoveTo() when moveTo != null:
return moveTo(_that);case PathCommand_LineTo() when lineTo != null:
return lineTo(_that);case PathCommand_CubicTo() when cubicTo != null:
return cubicTo(_that);case PathCommand_QuadTo() when quadTo != null:
return quadTo(_that);case PathCommand_Close() when close != null:
return close(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( PathCommand_MoveTo value)  moveTo,required TResult Function( PathCommand_LineTo value)  lineTo,required TResult Function( PathCommand_CubicTo value)  cubicTo,required TResult Function( PathCommand_QuadTo value)  quadTo,required TResult Function( PathCommand_Close value)  close,}){
final _that = this;
switch (_that) {
case PathCommand_MoveTo():
return moveTo(_that);case PathCommand_LineTo():
return lineTo(_that);case PathCommand_CubicTo():
return cubicTo(_that);case PathCommand_QuadTo():
return quadTo(_that);case PathCommand_Close():
return close(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( PathCommand_MoveTo value)?  moveTo,TResult? Function( PathCommand_LineTo value)?  lineTo,TResult? Function( PathCommand_CubicTo value)?  cubicTo,TResult? Function( PathCommand_QuadTo value)?  quadTo,TResult? Function( PathCommand_Close value)?  close,}){
final _that = this;
switch (_that) {
case PathCommand_MoveTo() when moveTo != null:
return moveTo(_that);case PathCommand_LineTo() when lineTo != null:
return lineTo(_that);case PathCommand_CubicTo() when cubicTo != null:
return cubicTo(_that);case PathCommand_QuadTo() when quadTo != null:
return quadTo(_that);case PathCommand_Close() when close != null:
return close(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( double x,  double y)?  moveTo,TResult Function( double x,  double y)?  lineTo,TResult Function( double x1,  double y1,  double x2,  double y2,  double x,  double y)?  cubicTo,TResult Function( double x1,  double y1,  double x,  double y)?  quadTo,TResult Function()?  close,required TResult orElse(),}) {final _that = this;
switch (_that) {
case PathCommand_MoveTo() when moveTo != null:
return moveTo(_that.x,_that.y);case PathCommand_LineTo() when lineTo != null:
return lineTo(_that.x,_that.y);case PathCommand_CubicTo() when cubicTo != null:
return cubicTo(_that.x1,_that.y1,_that.x2,_that.y2,_that.x,_that.y);case PathCommand_QuadTo() when quadTo != null:
return quadTo(_that.x1,_that.y1,_that.x,_that.y);case PathCommand_Close() when close != null:
return close();case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( double x,  double y)  moveTo,required TResult Function( double x,  double y)  lineTo,required TResult Function( double x1,  double y1,  double x2,  double y2,  double x,  double y)  cubicTo,required TResult Function( double x1,  double y1,  double x,  double y)  quadTo,required TResult Function()  close,}) {final _that = this;
switch (_that) {
case PathCommand_MoveTo():
return moveTo(_that.x,_that.y);case PathCommand_LineTo():
return lineTo(_that.x,_that.y);case PathCommand_CubicTo():
return cubicTo(_that.x1,_that.y1,_that.x2,_that.y2,_that.x,_that.y);case PathCommand_QuadTo():
return quadTo(_that.x1,_that.y1,_that.x,_that.y);case PathCommand_Close():
return close();}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( double x,  double y)?  moveTo,TResult? Function( double x,  double y)?  lineTo,TResult? Function( double x1,  double y1,  double x2,  double y2,  double x,  double y)?  cubicTo,TResult? Function( double x1,  double y1,  double x,  double y)?  quadTo,TResult? Function()?  close,}) {final _that = this;
switch (_that) {
case PathCommand_MoveTo() when moveTo != null:
return moveTo(_that.x,_that.y);case PathCommand_LineTo() when lineTo != null:
return lineTo(_that.x,_that.y);case PathCommand_CubicTo() when cubicTo != null:
return cubicTo(_that.x1,_that.y1,_that.x2,_that.y2,_that.x,_that.y);case PathCommand_QuadTo() when quadTo != null:
return quadTo(_that.x1,_that.y1,_that.x,_that.y);case PathCommand_Close() when close != null:
return close();case _:
  return null;

}
}

}

/// @nodoc


class PathCommand_MoveTo extends PathCommand {
  const PathCommand_MoveTo({required this.x, required this.y}): super._();
  

 final  double x;
 final  double y;

/// Create a copy of PathCommand
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PathCommand_MoveToCopyWith<PathCommand_MoveTo> get copyWith => _$PathCommand_MoveToCopyWithImpl<PathCommand_MoveTo>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PathCommand_MoveTo&&(identical(other.x, x) || other.x == x)&&(identical(other.y, y) || other.y == y));
}


@override
int get hashCode => Object.hash(runtimeType,x,y);

@override
String toString() {
  return 'PathCommand.moveTo(x: $x, y: $y)';
}


}

/// @nodoc
abstract mixin class $PathCommand_MoveToCopyWith<$Res> implements $PathCommandCopyWith<$Res> {
  factory $PathCommand_MoveToCopyWith(PathCommand_MoveTo value, $Res Function(PathCommand_MoveTo) _then) = _$PathCommand_MoveToCopyWithImpl;
@useResult
$Res call({
 double x, double y
});




}
/// @nodoc
class _$PathCommand_MoveToCopyWithImpl<$Res>
    implements $PathCommand_MoveToCopyWith<$Res> {
  _$PathCommand_MoveToCopyWithImpl(this._self, this._then);

  final PathCommand_MoveTo _self;
  final $Res Function(PathCommand_MoveTo) _then;

/// Create a copy of PathCommand
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? x = null,Object? y = null,}) {
  return _then(PathCommand_MoveTo(
x: null == x ? _self.x : x // ignore: cast_nullable_to_non_nullable
as double,y: null == y ? _self.y : y // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

/// @nodoc


class PathCommand_LineTo extends PathCommand {
  const PathCommand_LineTo({required this.x, required this.y}): super._();
  

 final  double x;
 final  double y;

/// Create a copy of PathCommand
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PathCommand_LineToCopyWith<PathCommand_LineTo> get copyWith => _$PathCommand_LineToCopyWithImpl<PathCommand_LineTo>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PathCommand_LineTo&&(identical(other.x, x) || other.x == x)&&(identical(other.y, y) || other.y == y));
}


@override
int get hashCode => Object.hash(runtimeType,x,y);

@override
String toString() {
  return 'PathCommand.lineTo(x: $x, y: $y)';
}


}

/// @nodoc
abstract mixin class $PathCommand_LineToCopyWith<$Res> implements $PathCommandCopyWith<$Res> {
  factory $PathCommand_LineToCopyWith(PathCommand_LineTo value, $Res Function(PathCommand_LineTo) _then) = _$PathCommand_LineToCopyWithImpl;
@useResult
$Res call({
 double x, double y
});




}
/// @nodoc
class _$PathCommand_LineToCopyWithImpl<$Res>
    implements $PathCommand_LineToCopyWith<$Res> {
  _$PathCommand_LineToCopyWithImpl(this._self, this._then);

  final PathCommand_LineTo _self;
  final $Res Function(PathCommand_LineTo) _then;

/// Create a copy of PathCommand
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? x = null,Object? y = null,}) {
  return _then(PathCommand_LineTo(
x: null == x ? _self.x : x // ignore: cast_nullable_to_non_nullable
as double,y: null == y ? _self.y : y // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

/// @nodoc


class PathCommand_CubicTo extends PathCommand {
  const PathCommand_CubicTo({required this.x1, required this.y1, required this.x2, required this.y2, required this.x, required this.y}): super._();
  

 final  double x1;
 final  double y1;
 final  double x2;
 final  double y2;
 final  double x;
 final  double y;

/// Create a copy of PathCommand
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PathCommand_CubicToCopyWith<PathCommand_CubicTo> get copyWith => _$PathCommand_CubicToCopyWithImpl<PathCommand_CubicTo>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PathCommand_CubicTo&&(identical(other.x1, x1) || other.x1 == x1)&&(identical(other.y1, y1) || other.y1 == y1)&&(identical(other.x2, x2) || other.x2 == x2)&&(identical(other.y2, y2) || other.y2 == y2)&&(identical(other.x, x) || other.x == x)&&(identical(other.y, y) || other.y == y));
}


@override
int get hashCode => Object.hash(runtimeType,x1,y1,x2,y2,x,y);

@override
String toString() {
  return 'PathCommand.cubicTo(x1: $x1, y1: $y1, x2: $x2, y2: $y2, x: $x, y: $y)';
}


}

/// @nodoc
abstract mixin class $PathCommand_CubicToCopyWith<$Res> implements $PathCommandCopyWith<$Res> {
  factory $PathCommand_CubicToCopyWith(PathCommand_CubicTo value, $Res Function(PathCommand_CubicTo) _then) = _$PathCommand_CubicToCopyWithImpl;
@useResult
$Res call({
 double x1, double y1, double x2, double y2, double x, double y
});




}
/// @nodoc
class _$PathCommand_CubicToCopyWithImpl<$Res>
    implements $PathCommand_CubicToCopyWith<$Res> {
  _$PathCommand_CubicToCopyWithImpl(this._self, this._then);

  final PathCommand_CubicTo _self;
  final $Res Function(PathCommand_CubicTo) _then;

/// Create a copy of PathCommand
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? x1 = null,Object? y1 = null,Object? x2 = null,Object? y2 = null,Object? x = null,Object? y = null,}) {
  return _then(PathCommand_CubicTo(
x1: null == x1 ? _self.x1 : x1 // ignore: cast_nullable_to_non_nullable
as double,y1: null == y1 ? _self.y1 : y1 // ignore: cast_nullable_to_non_nullable
as double,x2: null == x2 ? _self.x2 : x2 // ignore: cast_nullable_to_non_nullable
as double,y2: null == y2 ? _self.y2 : y2 // ignore: cast_nullable_to_non_nullable
as double,x: null == x ? _self.x : x // ignore: cast_nullable_to_non_nullable
as double,y: null == y ? _self.y : y // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

/// @nodoc


class PathCommand_QuadTo extends PathCommand {
  const PathCommand_QuadTo({required this.x1, required this.y1, required this.x, required this.y}): super._();
  

 final  double x1;
 final  double y1;
 final  double x;
 final  double y;

/// Create a copy of PathCommand
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PathCommand_QuadToCopyWith<PathCommand_QuadTo> get copyWith => _$PathCommand_QuadToCopyWithImpl<PathCommand_QuadTo>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PathCommand_QuadTo&&(identical(other.x1, x1) || other.x1 == x1)&&(identical(other.y1, y1) || other.y1 == y1)&&(identical(other.x, x) || other.x == x)&&(identical(other.y, y) || other.y == y));
}


@override
int get hashCode => Object.hash(runtimeType,x1,y1,x,y);

@override
String toString() {
  return 'PathCommand.quadTo(x1: $x1, y1: $y1, x: $x, y: $y)';
}


}

/// @nodoc
abstract mixin class $PathCommand_QuadToCopyWith<$Res> implements $PathCommandCopyWith<$Res> {
  factory $PathCommand_QuadToCopyWith(PathCommand_QuadTo value, $Res Function(PathCommand_QuadTo) _then) = _$PathCommand_QuadToCopyWithImpl;
@useResult
$Res call({
 double x1, double y1, double x, double y
});




}
/// @nodoc
class _$PathCommand_QuadToCopyWithImpl<$Res>
    implements $PathCommand_QuadToCopyWith<$Res> {
  _$PathCommand_QuadToCopyWithImpl(this._self, this._then);

  final PathCommand_QuadTo _self;
  final $Res Function(PathCommand_QuadTo) _then;

/// Create a copy of PathCommand
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? x1 = null,Object? y1 = null,Object? x = null,Object? y = null,}) {
  return _then(PathCommand_QuadTo(
x1: null == x1 ? _self.x1 : x1 // ignore: cast_nullable_to_non_nullable
as double,y1: null == y1 ? _self.y1 : y1 // ignore: cast_nullable_to_non_nullable
as double,x: null == x ? _self.x : x // ignore: cast_nullable_to_non_nullable
as double,y: null == y ? _self.y : y // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

/// @nodoc


class PathCommand_Close extends PathCommand {
  const PathCommand_Close(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PathCommand_Close);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PathCommand.close()';
}


}




// dart format on
