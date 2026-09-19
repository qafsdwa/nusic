// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'bridge_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$BridgePlayerCommand {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BridgePlayerCommand);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'BridgePlayerCommand()';
}


}

/// @nodoc
class $BridgePlayerCommandCopyWith<$Res>  {
$BridgePlayerCommandCopyWith(BridgePlayerCommand _, $Res Function(BridgePlayerCommand) __);
}


/// Adds pattern-matching-related methods to [BridgePlayerCommand].
extension BridgePlayerCommandPatterns on BridgePlayerCommand {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( BridgePlayerCommand_Play value)?  play,TResult Function( BridgePlayerCommand_PlayTrack value)?  playTrack,TResult Function( BridgePlayerCommand_PlayQueue value)?  playQueue,TResult Function( BridgePlayerCommand_Pause value)?  pause,TResult Function( BridgePlayerCommand_Resume value)?  resume,TResult Function( BridgePlayerCommand_Toggle value)?  toggle,TResult Function( BridgePlayerCommand_Next value)?  next,TResult Function( BridgePlayerCommand_Previous value)?  previous,TResult Function( BridgePlayerCommand_Seek value)?  seek,TResult Function( BridgePlayerCommand_SetVolume value)?  setVolume,TResult Function( BridgePlayerCommand_SetShuffle value)?  setShuffle,TResult Function( BridgePlayerCommand_SetRepeat value)?  setRepeat,TResult Function( BridgePlayerCommand_ClearQueue value)?  clearQueue,TResult Function( BridgePlayerCommand_RequestSnapshot value)?  requestSnapshot,required TResult orElse(),}){
final _that = this;
switch (_that) {
case BridgePlayerCommand_Play() when play != null:
return play(_that);case BridgePlayerCommand_PlayTrack() when playTrack != null:
return playTrack(_that);case BridgePlayerCommand_PlayQueue() when playQueue != null:
return playQueue(_that);case BridgePlayerCommand_Pause() when pause != null:
return pause(_that);case BridgePlayerCommand_Resume() when resume != null:
return resume(_that);case BridgePlayerCommand_Toggle() when toggle != null:
return toggle(_that);case BridgePlayerCommand_Next() when next != null:
return next(_that);case BridgePlayerCommand_Previous() when previous != null:
return previous(_that);case BridgePlayerCommand_Seek() when seek != null:
return seek(_that);case BridgePlayerCommand_SetVolume() when setVolume != null:
return setVolume(_that);case BridgePlayerCommand_SetShuffle() when setShuffle != null:
return setShuffle(_that);case BridgePlayerCommand_SetRepeat() when setRepeat != null:
return setRepeat(_that);case BridgePlayerCommand_ClearQueue() when clearQueue != null:
return clearQueue(_that);case BridgePlayerCommand_RequestSnapshot() when requestSnapshot != null:
return requestSnapshot(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( BridgePlayerCommand_Play value)  play,required TResult Function( BridgePlayerCommand_PlayTrack value)  playTrack,required TResult Function( BridgePlayerCommand_PlayQueue value)  playQueue,required TResult Function( BridgePlayerCommand_Pause value)  pause,required TResult Function( BridgePlayerCommand_Resume value)  resume,required TResult Function( BridgePlayerCommand_Toggle value)  toggle,required TResult Function( BridgePlayerCommand_Next value)  next,required TResult Function( BridgePlayerCommand_Previous value)  previous,required TResult Function( BridgePlayerCommand_Seek value)  seek,required TResult Function( BridgePlayerCommand_SetVolume value)  setVolume,required TResult Function( BridgePlayerCommand_SetShuffle value)  setShuffle,required TResult Function( BridgePlayerCommand_SetRepeat value)  setRepeat,required TResult Function( BridgePlayerCommand_ClearQueue value)  clearQueue,required TResult Function( BridgePlayerCommand_RequestSnapshot value)  requestSnapshot,}){
final _that = this;
switch (_that) {
case BridgePlayerCommand_Play():
return play(_that);case BridgePlayerCommand_PlayTrack():
return playTrack(_that);case BridgePlayerCommand_PlayQueue():
return playQueue(_that);case BridgePlayerCommand_Pause():
return pause(_that);case BridgePlayerCommand_Resume():
return resume(_that);case BridgePlayerCommand_Toggle():
return toggle(_that);case BridgePlayerCommand_Next():
return next(_that);case BridgePlayerCommand_Previous():
return previous(_that);case BridgePlayerCommand_Seek():
return seek(_that);case BridgePlayerCommand_SetVolume():
return setVolume(_that);case BridgePlayerCommand_SetShuffle():
return setShuffle(_that);case BridgePlayerCommand_SetRepeat():
return setRepeat(_that);case BridgePlayerCommand_ClearQueue():
return clearQueue(_that);case BridgePlayerCommand_RequestSnapshot():
return requestSnapshot(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( BridgePlayerCommand_Play value)?  play,TResult? Function( BridgePlayerCommand_PlayTrack value)?  playTrack,TResult? Function( BridgePlayerCommand_PlayQueue value)?  playQueue,TResult? Function( BridgePlayerCommand_Pause value)?  pause,TResult? Function( BridgePlayerCommand_Resume value)?  resume,TResult? Function( BridgePlayerCommand_Toggle value)?  toggle,TResult? Function( BridgePlayerCommand_Next value)?  next,TResult? Function( BridgePlayerCommand_Previous value)?  previous,TResult? Function( BridgePlayerCommand_Seek value)?  seek,TResult? Function( BridgePlayerCommand_SetVolume value)?  setVolume,TResult? Function( BridgePlayerCommand_SetShuffle value)?  setShuffle,TResult? Function( BridgePlayerCommand_SetRepeat value)?  setRepeat,TResult? Function( BridgePlayerCommand_ClearQueue value)?  clearQueue,TResult? Function( BridgePlayerCommand_RequestSnapshot value)?  requestSnapshot,}){
final _that = this;
switch (_that) {
case BridgePlayerCommand_Play() when play != null:
return play(_that);case BridgePlayerCommand_PlayTrack() when playTrack != null:
return playTrack(_that);case BridgePlayerCommand_PlayQueue() when playQueue != null:
return playQueue(_that);case BridgePlayerCommand_Pause() when pause != null:
return pause(_that);case BridgePlayerCommand_Resume() when resume != null:
return resume(_that);case BridgePlayerCommand_Toggle() when toggle != null:
return toggle(_that);case BridgePlayerCommand_Next() when next != null:
return next(_that);case BridgePlayerCommand_Previous() when previous != null:
return previous(_that);case BridgePlayerCommand_Seek() when seek != null:
return seek(_that);case BridgePlayerCommand_SetVolume() when setVolume != null:
return setVolume(_that);case BridgePlayerCommand_SetShuffle() when setShuffle != null:
return setShuffle(_that);case BridgePlayerCommand_SetRepeat() when setRepeat != null:
return setRepeat(_that);case BridgePlayerCommand_ClearQueue() when clearQueue != null:
return clearQueue(_that);case BridgePlayerCommand_RequestSnapshot() when requestSnapshot != null:
return requestSnapshot(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String trackId)?  play,TResult Function( BridgeTrack track)?  playTrack,TResult Function( List<BridgeTrack> tracks,  int startIndex)?  playQueue,TResult Function()?  pause,TResult Function()?  resume,TResult Function()?  toggle,TResult Function()?  next,TResult Function()?  previous,TResult Function( PlatformInt64 positionMs)?  seek,TResult Function( double volume)?  setVolume,TResult Function( bool enabled)?  setShuffle,TResult Function( BridgeRepeatMode mode)?  setRepeat,TResult Function()?  clearQueue,TResult Function()?  requestSnapshot,required TResult orElse(),}) {final _that = this;
switch (_that) {
case BridgePlayerCommand_Play() when play != null:
return play(_that.trackId);case BridgePlayerCommand_PlayTrack() when playTrack != null:
return playTrack(_that.track);case BridgePlayerCommand_PlayQueue() when playQueue != null:
return playQueue(_that.tracks,_that.startIndex);case BridgePlayerCommand_Pause() when pause != null:
return pause();case BridgePlayerCommand_Resume() when resume != null:
return resume();case BridgePlayerCommand_Toggle() when toggle != null:
return toggle();case BridgePlayerCommand_Next() when next != null:
return next();case BridgePlayerCommand_Previous() when previous != null:
return previous();case BridgePlayerCommand_Seek() when seek != null:
return seek(_that.positionMs);case BridgePlayerCommand_SetVolume() when setVolume != null:
return setVolume(_that.volume);case BridgePlayerCommand_SetShuffle() when setShuffle != null:
return setShuffle(_that.enabled);case BridgePlayerCommand_SetRepeat() when setRepeat != null:
return setRepeat(_that.mode);case BridgePlayerCommand_ClearQueue() when clearQueue != null:
return clearQueue();case BridgePlayerCommand_RequestSnapshot() when requestSnapshot != null:
return requestSnapshot();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String trackId)  play,required TResult Function( BridgeTrack track)  playTrack,required TResult Function( List<BridgeTrack> tracks,  int startIndex)  playQueue,required TResult Function()  pause,required TResult Function()  resume,required TResult Function()  toggle,required TResult Function()  next,required TResult Function()  previous,required TResult Function( PlatformInt64 positionMs)  seek,required TResult Function( double volume)  setVolume,required TResult Function( bool enabled)  setShuffle,required TResult Function( BridgeRepeatMode mode)  setRepeat,required TResult Function()  clearQueue,required TResult Function()  requestSnapshot,}) {final _that = this;
switch (_that) {
case BridgePlayerCommand_Play():
return play(_that.trackId);case BridgePlayerCommand_PlayTrack():
return playTrack(_that.track);case BridgePlayerCommand_PlayQueue():
return playQueue(_that.tracks,_that.startIndex);case BridgePlayerCommand_Pause():
return pause();case BridgePlayerCommand_Resume():
return resume();case BridgePlayerCommand_Toggle():
return toggle();case BridgePlayerCommand_Next():
return next();case BridgePlayerCommand_Previous():
return previous();case BridgePlayerCommand_Seek():
return seek(_that.positionMs);case BridgePlayerCommand_SetVolume():
return setVolume(_that.volume);case BridgePlayerCommand_SetShuffle():
return setShuffle(_that.enabled);case BridgePlayerCommand_SetRepeat():
return setRepeat(_that.mode);case BridgePlayerCommand_ClearQueue():
return clearQueue();case BridgePlayerCommand_RequestSnapshot():
return requestSnapshot();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String trackId)?  play,TResult? Function( BridgeTrack track)?  playTrack,TResult? Function( List<BridgeTrack> tracks,  int startIndex)?  playQueue,TResult? Function()?  pause,TResult? Function()?  resume,TResult? Function()?  toggle,TResult? Function()?  next,TResult? Function()?  previous,TResult? Function( PlatformInt64 positionMs)?  seek,TResult? Function( double volume)?  setVolume,TResult? Function( bool enabled)?  setShuffle,TResult? Function( BridgeRepeatMode mode)?  setRepeat,TResult? Function()?  clearQueue,TResult? Function()?  requestSnapshot,}) {final _that = this;
switch (_that) {
case BridgePlayerCommand_Play() when play != null:
return play(_that.trackId);case BridgePlayerCommand_PlayTrack() when playTrack != null:
return playTrack(_that.track);case BridgePlayerCommand_PlayQueue() when playQueue != null:
return playQueue(_that.tracks,_that.startIndex);case BridgePlayerCommand_Pause() when pause != null:
return pause();case BridgePlayerCommand_Resume() when resume != null:
return resume();case BridgePlayerCommand_Toggle() when toggle != null:
return toggle();case BridgePlayerCommand_Next() when next != null:
return next();case BridgePlayerCommand_Previous() when previous != null:
return previous();case BridgePlayerCommand_Seek() when seek != null:
return seek(_that.positionMs);case BridgePlayerCommand_SetVolume() when setVolume != null:
return setVolume(_that.volume);case BridgePlayerCommand_SetShuffle() when setShuffle != null:
return setShuffle(_that.enabled);case BridgePlayerCommand_SetRepeat() when setRepeat != null:
return setRepeat(_that.mode);case BridgePlayerCommand_ClearQueue() when clearQueue != null:
return clearQueue();case BridgePlayerCommand_RequestSnapshot() when requestSnapshot != null:
return requestSnapshot();case _:
  return null;

}
}

}

/// @nodoc


class BridgePlayerCommand_Play extends BridgePlayerCommand {
  const BridgePlayerCommand_Play({required this.trackId}): super._();
  

 final  String trackId;

/// Create a copy of BridgePlayerCommand
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BridgePlayerCommand_PlayCopyWith<BridgePlayerCommand_Play> get copyWith => _$BridgePlayerCommand_PlayCopyWithImpl<BridgePlayerCommand_Play>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BridgePlayerCommand_Play&&(identical(other.trackId, trackId) || other.trackId == trackId));
}


@override
int get hashCode => Object.hash(runtimeType,trackId);

@override
String toString() {
  return 'BridgePlayerCommand.play(trackId: $trackId)';
}


}

/// @nodoc
abstract mixin class $BridgePlayerCommand_PlayCopyWith<$Res> implements $BridgePlayerCommandCopyWith<$Res> {
  factory $BridgePlayerCommand_PlayCopyWith(BridgePlayerCommand_Play value, $Res Function(BridgePlayerCommand_Play) _then) = _$BridgePlayerCommand_PlayCopyWithImpl;
@useResult
$Res call({
 String trackId
});




}
/// @nodoc
class _$BridgePlayerCommand_PlayCopyWithImpl<$Res>
    implements $BridgePlayerCommand_PlayCopyWith<$Res> {
  _$BridgePlayerCommand_PlayCopyWithImpl(this._self, this._then);

  final BridgePlayerCommand_Play _self;
  final $Res Function(BridgePlayerCommand_Play) _then;

/// Create a copy of BridgePlayerCommand
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? trackId = null,}) {
  return _then(BridgePlayerCommand_Play(
trackId: null == trackId ? _self.trackId : trackId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class BridgePlayerCommand_PlayTrack extends BridgePlayerCommand {
  const BridgePlayerCommand_PlayTrack({required this.track}): super._();
  

 final  BridgeTrack track;

/// Create a copy of BridgePlayerCommand
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BridgePlayerCommand_PlayTrackCopyWith<BridgePlayerCommand_PlayTrack> get copyWith => _$BridgePlayerCommand_PlayTrackCopyWithImpl<BridgePlayerCommand_PlayTrack>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BridgePlayerCommand_PlayTrack&&(identical(other.track, track) || other.track == track));
}


@override
int get hashCode => Object.hash(runtimeType,track);

@override
String toString() {
  return 'BridgePlayerCommand.playTrack(track: $track)';
}


}

/// @nodoc
abstract mixin class $BridgePlayerCommand_PlayTrackCopyWith<$Res> implements $BridgePlayerCommandCopyWith<$Res> {
  factory $BridgePlayerCommand_PlayTrackCopyWith(BridgePlayerCommand_PlayTrack value, $Res Function(BridgePlayerCommand_PlayTrack) _then) = _$BridgePlayerCommand_PlayTrackCopyWithImpl;
@useResult
$Res call({
 BridgeTrack track
});




}
/// @nodoc
class _$BridgePlayerCommand_PlayTrackCopyWithImpl<$Res>
    implements $BridgePlayerCommand_PlayTrackCopyWith<$Res> {
  _$BridgePlayerCommand_PlayTrackCopyWithImpl(this._self, this._then);

  final BridgePlayerCommand_PlayTrack _self;
  final $Res Function(BridgePlayerCommand_PlayTrack) _then;

/// Create a copy of BridgePlayerCommand
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? track = null,}) {
  return _then(BridgePlayerCommand_PlayTrack(
track: null == track ? _self.track : track // ignore: cast_nullable_to_non_nullable
as BridgeTrack,
  ));
}


}

/// @nodoc


class BridgePlayerCommand_PlayQueue extends BridgePlayerCommand {
  const BridgePlayerCommand_PlayQueue({required  List<BridgeTrack> tracks, required this.startIndex}): _tracks = tracks,super._();
  

 final  List<BridgeTrack> _tracks;
 List<BridgeTrack> get tracks {
  if (_tracks is EqualUnmodifiableListView) return _tracks;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tracks);
}

 final  int startIndex;

/// Create a copy of BridgePlayerCommand
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BridgePlayerCommand_PlayQueueCopyWith<BridgePlayerCommand_PlayQueue> get copyWith => _$BridgePlayerCommand_PlayQueueCopyWithImpl<BridgePlayerCommand_PlayQueue>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BridgePlayerCommand_PlayQueue&&const DeepCollectionEquality().equals(other._tracks, _tracks)&&(identical(other.startIndex, startIndex) || other.startIndex == startIndex));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_tracks),startIndex);

@override
String toString() {
  return 'BridgePlayerCommand.playQueue(tracks: $tracks, startIndex: $startIndex)';
}


}

/// @nodoc
abstract mixin class $BridgePlayerCommand_PlayQueueCopyWith<$Res> implements $BridgePlayerCommandCopyWith<$Res> {
  factory $BridgePlayerCommand_PlayQueueCopyWith(BridgePlayerCommand_PlayQueue value, $Res Function(BridgePlayerCommand_PlayQueue) _then) = _$BridgePlayerCommand_PlayQueueCopyWithImpl;
@useResult
$Res call({
 List<BridgeTrack> tracks, int startIndex
});




}
/// @nodoc
class _$BridgePlayerCommand_PlayQueueCopyWithImpl<$Res>
    implements $BridgePlayerCommand_PlayQueueCopyWith<$Res> {
  _$BridgePlayerCommand_PlayQueueCopyWithImpl(this._self, this._then);

  final BridgePlayerCommand_PlayQueue _self;
  final $Res Function(BridgePlayerCommand_PlayQueue) _then;

/// Create a copy of BridgePlayerCommand
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? tracks = null,Object? startIndex = null,}) {
  return _then(BridgePlayerCommand_PlayQueue(
tracks: null == tracks ? _self._tracks : tracks // ignore: cast_nullable_to_non_nullable
as List<BridgeTrack>,startIndex: null == startIndex ? _self.startIndex : startIndex // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class BridgePlayerCommand_Pause extends BridgePlayerCommand {
  const BridgePlayerCommand_Pause(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BridgePlayerCommand_Pause);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'BridgePlayerCommand.pause()';
}


}




/// @nodoc


class BridgePlayerCommand_Resume extends BridgePlayerCommand {
  const BridgePlayerCommand_Resume(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BridgePlayerCommand_Resume);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'BridgePlayerCommand.resume()';
}


}




/// @nodoc


class BridgePlayerCommand_Toggle extends BridgePlayerCommand {
  const BridgePlayerCommand_Toggle(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BridgePlayerCommand_Toggle);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'BridgePlayerCommand.toggle()';
}


}




/// @nodoc


class BridgePlayerCommand_Next extends BridgePlayerCommand {
  const BridgePlayerCommand_Next(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BridgePlayerCommand_Next);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'BridgePlayerCommand.next()';
}


}




/// @nodoc


class BridgePlayerCommand_Previous extends BridgePlayerCommand {
  const BridgePlayerCommand_Previous(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BridgePlayerCommand_Previous);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'BridgePlayerCommand.previous()';
}


}




/// @nodoc


class BridgePlayerCommand_Seek extends BridgePlayerCommand {
  const BridgePlayerCommand_Seek({required this.positionMs}): super._();
  

 final  PlatformInt64 positionMs;

/// Create a copy of BridgePlayerCommand
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BridgePlayerCommand_SeekCopyWith<BridgePlayerCommand_Seek> get copyWith => _$BridgePlayerCommand_SeekCopyWithImpl<BridgePlayerCommand_Seek>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BridgePlayerCommand_Seek&&(identical(other.positionMs, positionMs) || other.positionMs == positionMs));
}


@override
int get hashCode => Object.hash(runtimeType,positionMs);

@override
String toString() {
  return 'BridgePlayerCommand.seek(positionMs: $positionMs)';
}


}

/// @nodoc
abstract mixin class $BridgePlayerCommand_SeekCopyWith<$Res> implements $BridgePlayerCommandCopyWith<$Res> {
  factory $BridgePlayerCommand_SeekCopyWith(BridgePlayerCommand_Seek value, $Res Function(BridgePlayerCommand_Seek) _then) = _$BridgePlayerCommand_SeekCopyWithImpl;
@useResult
$Res call({
 PlatformInt64 positionMs
});




}
/// @nodoc
class _$BridgePlayerCommand_SeekCopyWithImpl<$Res>
    implements $BridgePlayerCommand_SeekCopyWith<$Res> {
  _$BridgePlayerCommand_SeekCopyWithImpl(this._self, this._then);

  final BridgePlayerCommand_Seek _self;
  final $Res Function(BridgePlayerCommand_Seek) _then;

/// Create a copy of BridgePlayerCommand
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? positionMs = null,}) {
  return _then(BridgePlayerCommand_Seek(
positionMs: null == positionMs ? _self.positionMs : positionMs // ignore: cast_nullable_to_non_nullable
as PlatformInt64,
  ));
}


}

/// @nodoc


class BridgePlayerCommand_SetVolume extends BridgePlayerCommand {
  const BridgePlayerCommand_SetVolume({required this.volume}): super._();
  

 final  double volume;

/// Create a copy of BridgePlayerCommand
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BridgePlayerCommand_SetVolumeCopyWith<BridgePlayerCommand_SetVolume> get copyWith => _$BridgePlayerCommand_SetVolumeCopyWithImpl<BridgePlayerCommand_SetVolume>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BridgePlayerCommand_SetVolume&&(identical(other.volume, volume) || other.volume == volume));
}


@override
int get hashCode => Object.hash(runtimeType,volume);

@override
String toString() {
  return 'BridgePlayerCommand.setVolume(volume: $volume)';
}


}

/// @nodoc
abstract mixin class $BridgePlayerCommand_SetVolumeCopyWith<$Res> implements $BridgePlayerCommandCopyWith<$Res> {
  factory $BridgePlayerCommand_SetVolumeCopyWith(BridgePlayerCommand_SetVolume value, $Res Function(BridgePlayerCommand_SetVolume) _then) = _$BridgePlayerCommand_SetVolumeCopyWithImpl;
@useResult
$Res call({
 double volume
});




}
/// @nodoc
class _$BridgePlayerCommand_SetVolumeCopyWithImpl<$Res>
    implements $BridgePlayerCommand_SetVolumeCopyWith<$Res> {
  _$BridgePlayerCommand_SetVolumeCopyWithImpl(this._self, this._then);

  final BridgePlayerCommand_SetVolume _self;
  final $Res Function(BridgePlayerCommand_SetVolume) _then;

/// Create a copy of BridgePlayerCommand
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? volume = null,}) {
  return _then(BridgePlayerCommand_SetVolume(
volume: null == volume ? _self.volume : volume // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

/// @nodoc


class BridgePlayerCommand_SetShuffle extends BridgePlayerCommand {
  const BridgePlayerCommand_SetShuffle({required this.enabled}): super._();
  

 final  bool enabled;

/// Create a copy of BridgePlayerCommand
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BridgePlayerCommand_SetShuffleCopyWith<BridgePlayerCommand_SetShuffle> get copyWith => _$BridgePlayerCommand_SetShuffleCopyWithImpl<BridgePlayerCommand_SetShuffle>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BridgePlayerCommand_SetShuffle&&(identical(other.enabled, enabled) || other.enabled == enabled));
}


@override
int get hashCode => Object.hash(runtimeType,enabled);

@override
String toString() {
  return 'BridgePlayerCommand.setShuffle(enabled: $enabled)';
}


}

/// @nodoc
abstract mixin class $BridgePlayerCommand_SetShuffleCopyWith<$Res> implements $BridgePlayerCommandCopyWith<$Res> {
  factory $BridgePlayerCommand_SetShuffleCopyWith(BridgePlayerCommand_SetShuffle value, $Res Function(BridgePlayerCommand_SetShuffle) _then) = _$BridgePlayerCommand_SetShuffleCopyWithImpl;
@useResult
$Res call({
 bool enabled
});




}
/// @nodoc
class _$BridgePlayerCommand_SetShuffleCopyWithImpl<$Res>
    implements $BridgePlayerCommand_SetShuffleCopyWith<$Res> {
  _$BridgePlayerCommand_SetShuffleCopyWithImpl(this._self, this._then);

  final BridgePlayerCommand_SetShuffle _self;
  final $Res Function(BridgePlayerCommand_SetShuffle) _then;

/// Create a copy of BridgePlayerCommand
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? enabled = null,}) {
  return _then(BridgePlayerCommand_SetShuffle(
enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc


class BridgePlayerCommand_SetRepeat extends BridgePlayerCommand {
  const BridgePlayerCommand_SetRepeat({required this.mode}): super._();
  

 final  BridgeRepeatMode mode;

/// Create a copy of BridgePlayerCommand
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BridgePlayerCommand_SetRepeatCopyWith<BridgePlayerCommand_SetRepeat> get copyWith => _$BridgePlayerCommand_SetRepeatCopyWithImpl<BridgePlayerCommand_SetRepeat>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BridgePlayerCommand_SetRepeat&&(identical(other.mode, mode) || other.mode == mode));
}


@override
int get hashCode => Object.hash(runtimeType,mode);

@override
String toString() {
  return 'BridgePlayerCommand.setRepeat(mode: $mode)';
}


}

/// @nodoc
abstract mixin class $BridgePlayerCommand_SetRepeatCopyWith<$Res> implements $BridgePlayerCommandCopyWith<$Res> {
  factory $BridgePlayerCommand_SetRepeatCopyWith(BridgePlayerCommand_SetRepeat value, $Res Function(BridgePlayerCommand_SetRepeat) _then) = _$BridgePlayerCommand_SetRepeatCopyWithImpl;
@useResult
$Res call({
 BridgeRepeatMode mode
});




}
/// @nodoc
class _$BridgePlayerCommand_SetRepeatCopyWithImpl<$Res>
    implements $BridgePlayerCommand_SetRepeatCopyWith<$Res> {
  _$BridgePlayerCommand_SetRepeatCopyWithImpl(this._self, this._then);

  final BridgePlayerCommand_SetRepeat _self;
  final $Res Function(BridgePlayerCommand_SetRepeat) _then;

/// Create a copy of BridgePlayerCommand
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? mode = null,}) {
  return _then(BridgePlayerCommand_SetRepeat(
mode: null == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as BridgeRepeatMode,
  ));
}


}

/// @nodoc


class BridgePlayerCommand_ClearQueue extends BridgePlayerCommand {
  const BridgePlayerCommand_ClearQueue(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BridgePlayerCommand_ClearQueue);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'BridgePlayerCommand.clearQueue()';
}


}




/// @nodoc


class BridgePlayerCommand_RequestSnapshot extends BridgePlayerCommand {
  const BridgePlayerCommand_RequestSnapshot(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BridgePlayerCommand_RequestSnapshot);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'BridgePlayerCommand.requestSnapshot()';
}


}




// dart format on
