// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'editor_api.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$EditorIntent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EditorIntent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'EditorIntent()';
}


}

/// @nodoc
class $EditorIntentCopyWith<$Res>  {
$EditorIntentCopyWith(EditorIntent _, $Res Function(EditorIntent) __);
}


/// Adds pattern-matching-related methods to [EditorIntent].
extension EditorIntentPatterns on EditorIntent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( EditorIntent_InsertSymbol value)?  insertSymbol,TResult Function( EditorIntent_InsertFrac value)?  insertFrac,TResult Function( EditorIntent_InsertSqrt value)?  insertSqrt,TResult Function( EditorIntent_InsertNthRoot value)?  insertNthRoot,TResult Function( EditorIntent_InsertSup value)?  insertSup,TResult Function( EditorIntent_InsertSub value)?  insertSub,TResult Function( EditorIntent_InsertParentheses value)?  insertParentheses,TResult Function( EditorIntent_InsertBrackets value)?  insertBrackets,TResult Function( EditorIntent_InsertBraces value)?  insertBraces,TResult Function( EditorIntent_InsertAbs value)?  insertAbs,TResult Function( EditorIntent_InsertSum value)?  insertSum,TResult Function( EditorIntent_InsertProduct value)?  insertProduct,TResult Function( EditorIntent_InsertIntegral value)?  insertIntegral,TResult Function( EditorIntent_InsertLimit value)?  insertLimit,TResult Function( EditorIntent_InsertOverline value)?  insertOverline,TResult Function( EditorIntent_InsertUnderline value)?  insertUnderline,TResult Function( EditorIntent_InsertText value)?  insertText,TResult Function( EditorIntent_MoveLeft value)?  moveLeft,TResult Function( EditorIntent_MoveRight value)?  moveRight,TResult Function( EditorIntent_MoveUp value)?  moveUp,TResult Function( EditorIntent_MoveDown value)?  moveDown,TResult Function( EditorIntent_MoveToStart value)?  moveToStart,TResult Function( EditorIntent_MoveToEnd value)?  moveToEnd,TResult Function( EditorIntent_SelectLeft value)?  selectLeft,TResult Function( EditorIntent_SelectRight value)?  selectRight,TResult Function( EditorIntent_SelectAll value)?  selectAll,TResult Function( EditorIntent_DeleteBackward value)?  deleteBackward,TResult Function( EditorIntent_DeleteForward value)?  deleteForward,TResult Function( EditorIntent_SetLatex value)?  setLatex,TResult Function( EditorIntent_TapBlock value)?  tapBlock,required TResult orElse(),}){
final _that = this;
switch (_that) {
case EditorIntent_InsertSymbol() when insertSymbol != null:
return insertSymbol(_that);case EditorIntent_InsertFrac() when insertFrac != null:
return insertFrac(_that);case EditorIntent_InsertSqrt() when insertSqrt != null:
return insertSqrt(_that);case EditorIntent_InsertNthRoot() when insertNthRoot != null:
return insertNthRoot(_that);case EditorIntent_InsertSup() when insertSup != null:
return insertSup(_that);case EditorIntent_InsertSub() when insertSub != null:
return insertSub(_that);case EditorIntent_InsertParentheses() when insertParentheses != null:
return insertParentheses(_that);case EditorIntent_InsertBrackets() when insertBrackets != null:
return insertBrackets(_that);case EditorIntent_InsertBraces() when insertBraces != null:
return insertBraces(_that);case EditorIntent_InsertAbs() when insertAbs != null:
return insertAbs(_that);case EditorIntent_InsertSum() when insertSum != null:
return insertSum(_that);case EditorIntent_InsertProduct() when insertProduct != null:
return insertProduct(_that);case EditorIntent_InsertIntegral() when insertIntegral != null:
return insertIntegral(_that);case EditorIntent_InsertLimit() when insertLimit != null:
return insertLimit(_that);case EditorIntent_InsertOverline() when insertOverline != null:
return insertOverline(_that);case EditorIntent_InsertUnderline() when insertUnderline != null:
return insertUnderline(_that);case EditorIntent_InsertText() when insertText != null:
return insertText(_that);case EditorIntent_MoveLeft() when moveLeft != null:
return moveLeft(_that);case EditorIntent_MoveRight() when moveRight != null:
return moveRight(_that);case EditorIntent_MoveUp() when moveUp != null:
return moveUp(_that);case EditorIntent_MoveDown() when moveDown != null:
return moveDown(_that);case EditorIntent_MoveToStart() when moveToStart != null:
return moveToStart(_that);case EditorIntent_MoveToEnd() when moveToEnd != null:
return moveToEnd(_that);case EditorIntent_SelectLeft() when selectLeft != null:
return selectLeft(_that);case EditorIntent_SelectRight() when selectRight != null:
return selectRight(_that);case EditorIntent_SelectAll() when selectAll != null:
return selectAll(_that);case EditorIntent_DeleteBackward() when deleteBackward != null:
return deleteBackward(_that);case EditorIntent_DeleteForward() when deleteForward != null:
return deleteForward(_that);case EditorIntent_SetLatex() when setLatex != null:
return setLatex(_that);case EditorIntent_TapBlock() when tapBlock != null:
return tapBlock(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( EditorIntent_InsertSymbol value)  insertSymbol,required TResult Function( EditorIntent_InsertFrac value)  insertFrac,required TResult Function( EditorIntent_InsertSqrt value)  insertSqrt,required TResult Function( EditorIntent_InsertNthRoot value)  insertNthRoot,required TResult Function( EditorIntent_InsertSup value)  insertSup,required TResult Function( EditorIntent_InsertSub value)  insertSub,required TResult Function( EditorIntent_InsertParentheses value)  insertParentheses,required TResult Function( EditorIntent_InsertBrackets value)  insertBrackets,required TResult Function( EditorIntent_InsertBraces value)  insertBraces,required TResult Function( EditorIntent_InsertAbs value)  insertAbs,required TResult Function( EditorIntent_InsertSum value)  insertSum,required TResult Function( EditorIntent_InsertProduct value)  insertProduct,required TResult Function( EditorIntent_InsertIntegral value)  insertIntegral,required TResult Function( EditorIntent_InsertLimit value)  insertLimit,required TResult Function( EditorIntent_InsertOverline value)  insertOverline,required TResult Function( EditorIntent_InsertUnderline value)  insertUnderline,required TResult Function( EditorIntent_InsertText value)  insertText,required TResult Function( EditorIntent_MoveLeft value)  moveLeft,required TResult Function( EditorIntent_MoveRight value)  moveRight,required TResult Function( EditorIntent_MoveUp value)  moveUp,required TResult Function( EditorIntent_MoveDown value)  moveDown,required TResult Function( EditorIntent_MoveToStart value)  moveToStart,required TResult Function( EditorIntent_MoveToEnd value)  moveToEnd,required TResult Function( EditorIntent_SelectLeft value)  selectLeft,required TResult Function( EditorIntent_SelectRight value)  selectRight,required TResult Function( EditorIntent_SelectAll value)  selectAll,required TResult Function( EditorIntent_DeleteBackward value)  deleteBackward,required TResult Function( EditorIntent_DeleteForward value)  deleteForward,required TResult Function( EditorIntent_SetLatex value)  setLatex,required TResult Function( EditorIntent_TapBlock value)  tapBlock,}){
final _that = this;
switch (_that) {
case EditorIntent_InsertSymbol():
return insertSymbol(_that);case EditorIntent_InsertFrac():
return insertFrac(_that);case EditorIntent_InsertSqrt():
return insertSqrt(_that);case EditorIntent_InsertNthRoot():
return insertNthRoot(_that);case EditorIntent_InsertSup():
return insertSup(_that);case EditorIntent_InsertSub():
return insertSub(_that);case EditorIntent_InsertParentheses():
return insertParentheses(_that);case EditorIntent_InsertBrackets():
return insertBrackets(_that);case EditorIntent_InsertBraces():
return insertBraces(_that);case EditorIntent_InsertAbs():
return insertAbs(_that);case EditorIntent_InsertSum():
return insertSum(_that);case EditorIntent_InsertProduct():
return insertProduct(_that);case EditorIntent_InsertIntegral():
return insertIntegral(_that);case EditorIntent_InsertLimit():
return insertLimit(_that);case EditorIntent_InsertOverline():
return insertOverline(_that);case EditorIntent_InsertUnderline():
return insertUnderline(_that);case EditorIntent_InsertText():
return insertText(_that);case EditorIntent_MoveLeft():
return moveLeft(_that);case EditorIntent_MoveRight():
return moveRight(_that);case EditorIntent_MoveUp():
return moveUp(_that);case EditorIntent_MoveDown():
return moveDown(_that);case EditorIntent_MoveToStart():
return moveToStart(_that);case EditorIntent_MoveToEnd():
return moveToEnd(_that);case EditorIntent_SelectLeft():
return selectLeft(_that);case EditorIntent_SelectRight():
return selectRight(_that);case EditorIntent_SelectAll():
return selectAll(_that);case EditorIntent_DeleteBackward():
return deleteBackward(_that);case EditorIntent_DeleteForward():
return deleteForward(_that);case EditorIntent_SetLatex():
return setLatex(_that);case EditorIntent_TapBlock():
return tapBlock(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( EditorIntent_InsertSymbol value)?  insertSymbol,TResult? Function( EditorIntent_InsertFrac value)?  insertFrac,TResult? Function( EditorIntent_InsertSqrt value)?  insertSqrt,TResult? Function( EditorIntent_InsertNthRoot value)?  insertNthRoot,TResult? Function( EditorIntent_InsertSup value)?  insertSup,TResult? Function( EditorIntent_InsertSub value)?  insertSub,TResult? Function( EditorIntent_InsertParentheses value)?  insertParentheses,TResult? Function( EditorIntent_InsertBrackets value)?  insertBrackets,TResult? Function( EditorIntent_InsertBraces value)?  insertBraces,TResult? Function( EditorIntent_InsertAbs value)?  insertAbs,TResult? Function( EditorIntent_InsertSum value)?  insertSum,TResult? Function( EditorIntent_InsertProduct value)?  insertProduct,TResult? Function( EditorIntent_InsertIntegral value)?  insertIntegral,TResult? Function( EditorIntent_InsertLimit value)?  insertLimit,TResult? Function( EditorIntent_InsertOverline value)?  insertOverline,TResult? Function( EditorIntent_InsertUnderline value)?  insertUnderline,TResult? Function( EditorIntent_InsertText value)?  insertText,TResult? Function( EditorIntent_MoveLeft value)?  moveLeft,TResult? Function( EditorIntent_MoveRight value)?  moveRight,TResult? Function( EditorIntent_MoveUp value)?  moveUp,TResult? Function( EditorIntent_MoveDown value)?  moveDown,TResult? Function( EditorIntent_MoveToStart value)?  moveToStart,TResult? Function( EditorIntent_MoveToEnd value)?  moveToEnd,TResult? Function( EditorIntent_SelectLeft value)?  selectLeft,TResult? Function( EditorIntent_SelectRight value)?  selectRight,TResult? Function( EditorIntent_SelectAll value)?  selectAll,TResult? Function( EditorIntent_DeleteBackward value)?  deleteBackward,TResult? Function( EditorIntent_DeleteForward value)?  deleteForward,TResult? Function( EditorIntent_SetLatex value)?  setLatex,TResult? Function( EditorIntent_TapBlock value)?  tapBlock,}){
final _that = this;
switch (_that) {
case EditorIntent_InsertSymbol() when insertSymbol != null:
return insertSymbol(_that);case EditorIntent_InsertFrac() when insertFrac != null:
return insertFrac(_that);case EditorIntent_InsertSqrt() when insertSqrt != null:
return insertSqrt(_that);case EditorIntent_InsertNthRoot() when insertNthRoot != null:
return insertNthRoot(_that);case EditorIntent_InsertSup() when insertSup != null:
return insertSup(_that);case EditorIntent_InsertSub() when insertSub != null:
return insertSub(_that);case EditorIntent_InsertParentheses() when insertParentheses != null:
return insertParentheses(_that);case EditorIntent_InsertBrackets() when insertBrackets != null:
return insertBrackets(_that);case EditorIntent_InsertBraces() when insertBraces != null:
return insertBraces(_that);case EditorIntent_InsertAbs() when insertAbs != null:
return insertAbs(_that);case EditorIntent_InsertSum() when insertSum != null:
return insertSum(_that);case EditorIntent_InsertProduct() when insertProduct != null:
return insertProduct(_that);case EditorIntent_InsertIntegral() when insertIntegral != null:
return insertIntegral(_that);case EditorIntent_InsertLimit() when insertLimit != null:
return insertLimit(_that);case EditorIntent_InsertOverline() when insertOverline != null:
return insertOverline(_that);case EditorIntent_InsertUnderline() when insertUnderline != null:
return insertUnderline(_that);case EditorIntent_InsertText() when insertText != null:
return insertText(_that);case EditorIntent_MoveLeft() when moveLeft != null:
return moveLeft(_that);case EditorIntent_MoveRight() when moveRight != null:
return moveRight(_that);case EditorIntent_MoveUp() when moveUp != null:
return moveUp(_that);case EditorIntent_MoveDown() when moveDown != null:
return moveDown(_that);case EditorIntent_MoveToStart() when moveToStart != null:
return moveToStart(_that);case EditorIntent_MoveToEnd() when moveToEnd != null:
return moveToEnd(_that);case EditorIntent_SelectLeft() when selectLeft != null:
return selectLeft(_that);case EditorIntent_SelectRight() when selectRight != null:
return selectRight(_that);case EditorIntent_SelectAll() when selectAll != null:
return selectAll(_that);case EditorIntent_DeleteBackward() when deleteBackward != null:
return deleteBackward(_that);case EditorIntent_DeleteForward() when deleteForward != null:
return deleteForward(_that);case EditorIntent_SetLatex() when setLatex != null:
return setLatex(_that);case EditorIntent_TapBlock() when tapBlock != null:
return tapBlock(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String ch)?  insertSymbol,TResult Function()?  insertFrac,TResult Function()?  insertSqrt,TResult Function()?  insertNthRoot,TResult Function()?  insertSup,TResult Function()?  insertSub,TResult Function()?  insertParentheses,TResult Function()?  insertBrackets,TResult Function()?  insertBraces,TResult Function()?  insertAbs,TResult Function()?  insertSum,TResult Function()?  insertProduct,TResult Function()?  insertIntegral,TResult Function()?  insertLimit,TResult Function()?  insertOverline,TResult Function()?  insertUnderline,TResult Function()?  insertText,TResult Function()?  moveLeft,TResult Function()?  moveRight,TResult Function()?  moveUp,TResult Function()?  moveDown,TResult Function()?  moveToStart,TResult Function()?  moveToEnd,TResult Function()?  selectLeft,TResult Function()?  selectRight,TResult Function()?  selectAll,TResult Function()?  deleteBackward,TResult Function()?  deleteForward,TResult Function( String latex)?  setLatex,TResult Function( int blockId,  int caretIndex)?  tapBlock,required TResult orElse(),}) {final _that = this;
switch (_that) {
case EditorIntent_InsertSymbol() when insertSymbol != null:
return insertSymbol(_that.ch);case EditorIntent_InsertFrac() when insertFrac != null:
return insertFrac();case EditorIntent_InsertSqrt() when insertSqrt != null:
return insertSqrt();case EditorIntent_InsertNthRoot() when insertNthRoot != null:
return insertNthRoot();case EditorIntent_InsertSup() when insertSup != null:
return insertSup();case EditorIntent_InsertSub() when insertSub != null:
return insertSub();case EditorIntent_InsertParentheses() when insertParentheses != null:
return insertParentheses();case EditorIntent_InsertBrackets() when insertBrackets != null:
return insertBrackets();case EditorIntent_InsertBraces() when insertBraces != null:
return insertBraces();case EditorIntent_InsertAbs() when insertAbs != null:
return insertAbs();case EditorIntent_InsertSum() when insertSum != null:
return insertSum();case EditorIntent_InsertProduct() when insertProduct != null:
return insertProduct();case EditorIntent_InsertIntegral() when insertIntegral != null:
return insertIntegral();case EditorIntent_InsertLimit() when insertLimit != null:
return insertLimit();case EditorIntent_InsertOverline() when insertOverline != null:
return insertOverline();case EditorIntent_InsertUnderline() when insertUnderline != null:
return insertUnderline();case EditorIntent_InsertText() when insertText != null:
return insertText();case EditorIntent_MoveLeft() when moveLeft != null:
return moveLeft();case EditorIntent_MoveRight() when moveRight != null:
return moveRight();case EditorIntent_MoveUp() when moveUp != null:
return moveUp();case EditorIntent_MoveDown() when moveDown != null:
return moveDown();case EditorIntent_MoveToStart() when moveToStart != null:
return moveToStart();case EditorIntent_MoveToEnd() when moveToEnd != null:
return moveToEnd();case EditorIntent_SelectLeft() when selectLeft != null:
return selectLeft();case EditorIntent_SelectRight() when selectRight != null:
return selectRight();case EditorIntent_SelectAll() when selectAll != null:
return selectAll();case EditorIntent_DeleteBackward() when deleteBackward != null:
return deleteBackward();case EditorIntent_DeleteForward() when deleteForward != null:
return deleteForward();case EditorIntent_SetLatex() when setLatex != null:
return setLatex(_that.latex);case EditorIntent_TapBlock() when tapBlock != null:
return tapBlock(_that.blockId,_that.caretIndex);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String ch)  insertSymbol,required TResult Function()  insertFrac,required TResult Function()  insertSqrt,required TResult Function()  insertNthRoot,required TResult Function()  insertSup,required TResult Function()  insertSub,required TResult Function()  insertParentheses,required TResult Function()  insertBrackets,required TResult Function()  insertBraces,required TResult Function()  insertAbs,required TResult Function()  insertSum,required TResult Function()  insertProduct,required TResult Function()  insertIntegral,required TResult Function()  insertLimit,required TResult Function()  insertOverline,required TResult Function()  insertUnderline,required TResult Function()  insertText,required TResult Function()  moveLeft,required TResult Function()  moveRight,required TResult Function()  moveUp,required TResult Function()  moveDown,required TResult Function()  moveToStart,required TResult Function()  moveToEnd,required TResult Function()  selectLeft,required TResult Function()  selectRight,required TResult Function()  selectAll,required TResult Function()  deleteBackward,required TResult Function()  deleteForward,required TResult Function( String latex)  setLatex,required TResult Function( int blockId,  int caretIndex)  tapBlock,}) {final _that = this;
switch (_that) {
case EditorIntent_InsertSymbol():
return insertSymbol(_that.ch);case EditorIntent_InsertFrac():
return insertFrac();case EditorIntent_InsertSqrt():
return insertSqrt();case EditorIntent_InsertNthRoot():
return insertNthRoot();case EditorIntent_InsertSup():
return insertSup();case EditorIntent_InsertSub():
return insertSub();case EditorIntent_InsertParentheses():
return insertParentheses();case EditorIntent_InsertBrackets():
return insertBrackets();case EditorIntent_InsertBraces():
return insertBraces();case EditorIntent_InsertAbs():
return insertAbs();case EditorIntent_InsertSum():
return insertSum();case EditorIntent_InsertProduct():
return insertProduct();case EditorIntent_InsertIntegral():
return insertIntegral();case EditorIntent_InsertLimit():
return insertLimit();case EditorIntent_InsertOverline():
return insertOverline();case EditorIntent_InsertUnderline():
return insertUnderline();case EditorIntent_InsertText():
return insertText();case EditorIntent_MoveLeft():
return moveLeft();case EditorIntent_MoveRight():
return moveRight();case EditorIntent_MoveUp():
return moveUp();case EditorIntent_MoveDown():
return moveDown();case EditorIntent_MoveToStart():
return moveToStart();case EditorIntent_MoveToEnd():
return moveToEnd();case EditorIntent_SelectLeft():
return selectLeft();case EditorIntent_SelectRight():
return selectRight();case EditorIntent_SelectAll():
return selectAll();case EditorIntent_DeleteBackward():
return deleteBackward();case EditorIntent_DeleteForward():
return deleteForward();case EditorIntent_SetLatex():
return setLatex(_that.latex);case EditorIntent_TapBlock():
return tapBlock(_that.blockId,_that.caretIndex);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String ch)?  insertSymbol,TResult? Function()?  insertFrac,TResult? Function()?  insertSqrt,TResult? Function()?  insertNthRoot,TResult? Function()?  insertSup,TResult? Function()?  insertSub,TResult? Function()?  insertParentheses,TResult? Function()?  insertBrackets,TResult? Function()?  insertBraces,TResult? Function()?  insertAbs,TResult? Function()?  insertSum,TResult? Function()?  insertProduct,TResult? Function()?  insertIntegral,TResult? Function()?  insertLimit,TResult? Function()?  insertOverline,TResult? Function()?  insertUnderline,TResult? Function()?  insertText,TResult? Function()?  moveLeft,TResult? Function()?  moveRight,TResult? Function()?  moveUp,TResult? Function()?  moveDown,TResult? Function()?  moveToStart,TResult? Function()?  moveToEnd,TResult? Function()?  selectLeft,TResult? Function()?  selectRight,TResult? Function()?  selectAll,TResult? Function()?  deleteBackward,TResult? Function()?  deleteForward,TResult? Function( String latex)?  setLatex,TResult? Function( int blockId,  int caretIndex)?  tapBlock,}) {final _that = this;
switch (_that) {
case EditorIntent_InsertSymbol() when insertSymbol != null:
return insertSymbol(_that.ch);case EditorIntent_InsertFrac() when insertFrac != null:
return insertFrac();case EditorIntent_InsertSqrt() when insertSqrt != null:
return insertSqrt();case EditorIntent_InsertNthRoot() when insertNthRoot != null:
return insertNthRoot();case EditorIntent_InsertSup() when insertSup != null:
return insertSup();case EditorIntent_InsertSub() when insertSub != null:
return insertSub();case EditorIntent_InsertParentheses() when insertParentheses != null:
return insertParentheses();case EditorIntent_InsertBrackets() when insertBrackets != null:
return insertBrackets();case EditorIntent_InsertBraces() when insertBraces != null:
return insertBraces();case EditorIntent_InsertAbs() when insertAbs != null:
return insertAbs();case EditorIntent_InsertSum() when insertSum != null:
return insertSum();case EditorIntent_InsertProduct() when insertProduct != null:
return insertProduct();case EditorIntent_InsertIntegral() when insertIntegral != null:
return insertIntegral();case EditorIntent_InsertLimit() when insertLimit != null:
return insertLimit();case EditorIntent_InsertOverline() when insertOverline != null:
return insertOverline();case EditorIntent_InsertUnderline() when insertUnderline != null:
return insertUnderline();case EditorIntent_InsertText() when insertText != null:
return insertText();case EditorIntent_MoveLeft() when moveLeft != null:
return moveLeft();case EditorIntent_MoveRight() when moveRight != null:
return moveRight();case EditorIntent_MoveUp() when moveUp != null:
return moveUp();case EditorIntent_MoveDown() when moveDown != null:
return moveDown();case EditorIntent_MoveToStart() when moveToStart != null:
return moveToStart();case EditorIntent_MoveToEnd() when moveToEnd != null:
return moveToEnd();case EditorIntent_SelectLeft() when selectLeft != null:
return selectLeft();case EditorIntent_SelectRight() when selectRight != null:
return selectRight();case EditorIntent_SelectAll() when selectAll != null:
return selectAll();case EditorIntent_DeleteBackward() when deleteBackward != null:
return deleteBackward();case EditorIntent_DeleteForward() when deleteForward != null:
return deleteForward();case EditorIntent_SetLatex() when setLatex != null:
return setLatex(_that.latex);case EditorIntent_TapBlock() when tapBlock != null:
return tapBlock(_that.blockId,_that.caretIndex);case _:
  return null;

}
}

}

/// @nodoc


class EditorIntent_InsertSymbol extends EditorIntent {
  const EditorIntent_InsertSymbol({required this.ch}): super._();
  

 final  String ch;

/// Create a copy of EditorIntent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EditorIntent_InsertSymbolCopyWith<EditorIntent_InsertSymbol> get copyWith => _$EditorIntent_InsertSymbolCopyWithImpl<EditorIntent_InsertSymbol>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EditorIntent_InsertSymbol&&(identical(other.ch, ch) || other.ch == ch));
}


@override
int get hashCode => Object.hash(runtimeType,ch);

@override
String toString() {
  return 'EditorIntent.insertSymbol(ch: $ch)';
}


}

/// @nodoc
abstract mixin class $EditorIntent_InsertSymbolCopyWith<$Res> implements $EditorIntentCopyWith<$Res> {
  factory $EditorIntent_InsertSymbolCopyWith(EditorIntent_InsertSymbol value, $Res Function(EditorIntent_InsertSymbol) _then) = _$EditorIntent_InsertSymbolCopyWithImpl;
@useResult
$Res call({
 String ch
});




}
/// @nodoc
class _$EditorIntent_InsertSymbolCopyWithImpl<$Res>
    implements $EditorIntent_InsertSymbolCopyWith<$Res> {
  _$EditorIntent_InsertSymbolCopyWithImpl(this._self, this._then);

  final EditorIntent_InsertSymbol _self;
  final $Res Function(EditorIntent_InsertSymbol) _then;

/// Create a copy of EditorIntent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? ch = null,}) {
  return _then(EditorIntent_InsertSymbol(
ch: null == ch ? _self.ch : ch // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class EditorIntent_InsertFrac extends EditorIntent {
  const EditorIntent_InsertFrac(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EditorIntent_InsertFrac);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'EditorIntent.insertFrac()';
}


}




/// @nodoc


class EditorIntent_InsertSqrt extends EditorIntent {
  const EditorIntent_InsertSqrt(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EditorIntent_InsertSqrt);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'EditorIntent.insertSqrt()';
}


}




/// @nodoc


class EditorIntent_InsertNthRoot extends EditorIntent {
  const EditorIntent_InsertNthRoot(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EditorIntent_InsertNthRoot);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'EditorIntent.insertNthRoot()';
}


}




/// @nodoc


class EditorIntent_InsertSup extends EditorIntent {
  const EditorIntent_InsertSup(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EditorIntent_InsertSup);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'EditorIntent.insertSup()';
}


}




/// @nodoc


class EditorIntent_InsertSub extends EditorIntent {
  const EditorIntent_InsertSub(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EditorIntent_InsertSub);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'EditorIntent.insertSub()';
}


}




/// @nodoc


class EditorIntent_InsertParentheses extends EditorIntent {
  const EditorIntent_InsertParentheses(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EditorIntent_InsertParentheses);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'EditorIntent.insertParentheses()';
}


}




/// @nodoc


class EditorIntent_InsertBrackets extends EditorIntent {
  const EditorIntent_InsertBrackets(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EditorIntent_InsertBrackets);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'EditorIntent.insertBrackets()';
}


}




/// @nodoc


class EditorIntent_InsertBraces extends EditorIntent {
  const EditorIntent_InsertBraces(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EditorIntent_InsertBraces);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'EditorIntent.insertBraces()';
}


}




/// @nodoc


class EditorIntent_InsertAbs extends EditorIntent {
  const EditorIntent_InsertAbs(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EditorIntent_InsertAbs);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'EditorIntent.insertAbs()';
}


}




/// @nodoc


class EditorIntent_InsertSum extends EditorIntent {
  const EditorIntent_InsertSum(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EditorIntent_InsertSum);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'EditorIntent.insertSum()';
}


}




/// @nodoc


class EditorIntent_InsertProduct extends EditorIntent {
  const EditorIntent_InsertProduct(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EditorIntent_InsertProduct);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'EditorIntent.insertProduct()';
}


}




/// @nodoc


class EditorIntent_InsertIntegral extends EditorIntent {
  const EditorIntent_InsertIntegral(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EditorIntent_InsertIntegral);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'EditorIntent.insertIntegral()';
}


}




/// @nodoc


class EditorIntent_InsertLimit extends EditorIntent {
  const EditorIntent_InsertLimit(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EditorIntent_InsertLimit);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'EditorIntent.insertLimit()';
}


}




/// @nodoc


class EditorIntent_InsertOverline extends EditorIntent {
  const EditorIntent_InsertOverline(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EditorIntent_InsertOverline);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'EditorIntent.insertOverline()';
}


}




/// @nodoc


class EditorIntent_InsertUnderline extends EditorIntent {
  const EditorIntent_InsertUnderline(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EditorIntent_InsertUnderline);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'EditorIntent.insertUnderline()';
}


}




/// @nodoc


class EditorIntent_InsertText extends EditorIntent {
  const EditorIntent_InsertText(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EditorIntent_InsertText);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'EditorIntent.insertText()';
}


}




/// @nodoc


class EditorIntent_MoveLeft extends EditorIntent {
  const EditorIntent_MoveLeft(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EditorIntent_MoveLeft);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'EditorIntent.moveLeft()';
}


}




/// @nodoc


class EditorIntent_MoveRight extends EditorIntent {
  const EditorIntent_MoveRight(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EditorIntent_MoveRight);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'EditorIntent.moveRight()';
}


}




/// @nodoc


class EditorIntent_MoveUp extends EditorIntent {
  const EditorIntent_MoveUp(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EditorIntent_MoveUp);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'EditorIntent.moveUp()';
}


}




/// @nodoc


class EditorIntent_MoveDown extends EditorIntent {
  const EditorIntent_MoveDown(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EditorIntent_MoveDown);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'EditorIntent.moveDown()';
}


}




/// @nodoc


class EditorIntent_MoveToStart extends EditorIntent {
  const EditorIntent_MoveToStart(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EditorIntent_MoveToStart);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'EditorIntent.moveToStart()';
}


}




/// @nodoc


class EditorIntent_MoveToEnd extends EditorIntent {
  const EditorIntent_MoveToEnd(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EditorIntent_MoveToEnd);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'EditorIntent.moveToEnd()';
}


}




/// @nodoc


class EditorIntent_SelectLeft extends EditorIntent {
  const EditorIntent_SelectLeft(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EditorIntent_SelectLeft);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'EditorIntent.selectLeft()';
}


}




/// @nodoc


class EditorIntent_SelectRight extends EditorIntent {
  const EditorIntent_SelectRight(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EditorIntent_SelectRight);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'EditorIntent.selectRight()';
}


}




/// @nodoc


class EditorIntent_SelectAll extends EditorIntent {
  const EditorIntent_SelectAll(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EditorIntent_SelectAll);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'EditorIntent.selectAll()';
}


}




/// @nodoc


class EditorIntent_DeleteBackward extends EditorIntent {
  const EditorIntent_DeleteBackward(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EditorIntent_DeleteBackward);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'EditorIntent.deleteBackward()';
}


}




/// @nodoc


class EditorIntent_DeleteForward extends EditorIntent {
  const EditorIntent_DeleteForward(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EditorIntent_DeleteForward);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'EditorIntent.deleteForward()';
}


}




/// @nodoc


class EditorIntent_SetLatex extends EditorIntent {
  const EditorIntent_SetLatex({required this.latex}): super._();
  

 final  String latex;

/// Create a copy of EditorIntent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EditorIntent_SetLatexCopyWith<EditorIntent_SetLatex> get copyWith => _$EditorIntent_SetLatexCopyWithImpl<EditorIntent_SetLatex>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EditorIntent_SetLatex&&(identical(other.latex, latex) || other.latex == latex));
}


@override
int get hashCode => Object.hash(runtimeType,latex);

@override
String toString() {
  return 'EditorIntent.setLatex(latex: $latex)';
}


}

/// @nodoc
abstract mixin class $EditorIntent_SetLatexCopyWith<$Res> implements $EditorIntentCopyWith<$Res> {
  factory $EditorIntent_SetLatexCopyWith(EditorIntent_SetLatex value, $Res Function(EditorIntent_SetLatex) _then) = _$EditorIntent_SetLatexCopyWithImpl;
@useResult
$Res call({
 String latex
});




}
/// @nodoc
class _$EditorIntent_SetLatexCopyWithImpl<$Res>
    implements $EditorIntent_SetLatexCopyWith<$Res> {
  _$EditorIntent_SetLatexCopyWithImpl(this._self, this._then);

  final EditorIntent_SetLatex _self;
  final $Res Function(EditorIntent_SetLatex) _then;

/// Create a copy of EditorIntent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? latex = null,}) {
  return _then(EditorIntent_SetLatex(
latex: null == latex ? _self.latex : latex // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class EditorIntent_TapBlock extends EditorIntent {
  const EditorIntent_TapBlock({required this.blockId, required this.caretIndex}): super._();
  

 final  int blockId;
 final  int caretIndex;

/// Create a copy of EditorIntent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EditorIntent_TapBlockCopyWith<EditorIntent_TapBlock> get copyWith => _$EditorIntent_TapBlockCopyWithImpl<EditorIntent_TapBlock>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EditorIntent_TapBlock&&(identical(other.blockId, blockId) || other.blockId == blockId)&&(identical(other.caretIndex, caretIndex) || other.caretIndex == caretIndex));
}


@override
int get hashCode => Object.hash(runtimeType,blockId,caretIndex);

@override
String toString() {
  return 'EditorIntent.tapBlock(blockId: $blockId, caretIndex: $caretIndex)';
}


}

/// @nodoc
abstract mixin class $EditorIntent_TapBlockCopyWith<$Res> implements $EditorIntentCopyWith<$Res> {
  factory $EditorIntent_TapBlockCopyWith(EditorIntent_TapBlock value, $Res Function(EditorIntent_TapBlock) _then) = _$EditorIntent_TapBlockCopyWithImpl;
@useResult
$Res call({
 int blockId, int caretIndex
});




}
/// @nodoc
class _$EditorIntent_TapBlockCopyWithImpl<$Res>
    implements $EditorIntent_TapBlockCopyWith<$Res> {
  _$EditorIntent_TapBlockCopyWithImpl(this._self, this._then);

  final EditorIntent_TapBlock _self;
  final $Res Function(EditorIntent_TapBlock) _then;

/// Create a copy of EditorIntent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? blockId = null,Object? caretIndex = null,}) {
  return _then(EditorIntent_TapBlock(
blockId: null == blockId ? _self.blockId : blockId // ignore: cast_nullable_to_non_nullable
as int,caretIndex: null == caretIndex ? _self.caretIndex : caretIndex // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
