/// An album/playlist card model used by the mock library UI.
///
/// This is intentionally separate from [Song] so the future Rust playlist and
/// album endpoints have a clean mapping target.
class Album {
  const Album({
    required this.id,
    required this.title,
    required this.artist,
    required this.cover,
  });

  final String id;
  final String title;
  final String artist;

  /// Asset path or remote URL for the album cover.
  final String cover;

  @override
  bool operator ==(Object other) {
    return other is Album && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
