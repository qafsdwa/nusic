/// Where a track's audio comes from.
///
/// Only [remote] changes how playback works: those tracks belong to the online
/// catalog and have to be downloaded before the engine can play them. Hand
/// written mock data keeps the [local] default, because it never takes that
/// path; tracks that cross the Rust bridge carry the exact source.
enum SongSource {
  /// A file owned by the local library.
  local,

  /// A Bilibili video's audio track, cached on first play.
  remote,

  /// Phase 1 mock data.
  mock,

  /// The backend reported a source this build does not know.
  unknown,
}

/// A music track displayed throughout the app.
class Song {
  const Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.cover,
    required this.duration,
    this.source = SongSource.local,
  });

  final String id;
  final String title;
  final String artist;
  final String album;

  /// Asset path or remote URL for the cover art.
  ///
  /// Mock items use a `mock://` key and are rendered as generated placeholder
  /// artwork by [CoverArtwork].
  final String cover;
  final Duration duration;
  final SongSource source;

  /// Whether playback has to prepare this track before the engine can load it.
  bool get isRemote => source == SongSource.remote;

  Song copyWith({
    String? id,
    String? title,
    String? artist,
    String? album,
    String? cover,
    Duration? duration,
    SongSource? source,
  }) {
    return Song(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      cover: cover ?? this.cover,
      duration: duration ?? this.duration,
      source: source ?? this.source,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is Song && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
