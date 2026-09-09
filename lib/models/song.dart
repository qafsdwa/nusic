/// A music track displayed throughout the app.
///
/// In Phase 1 this model is fed only with mock data. When the Rust backend is
/// integrated, [cover] will hold a server-provided image URL and the other
/// fields can be mapped directly from REST JSON.
class Song {
  const Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.cover,
    required this.duration,
  });

  final String id;
  final String title;
  final String artist;
  final String album;

  /// Asset path or remote URL for the cover art.
  ///
  /// Mock items may use an empty value and are rendered as generated
  /// placeholder artwork by [CoverArtwork].
  final String cover;
  final Duration duration;

  Song copyWith({
    String? id,
    String? title,
    String? artist,
    String? album,
    String? cover,
    Duration? duration,
  }) {
    return Song(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      cover: cover ?? this.cover,
      duration: duration ?? this.duration,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is Song && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
