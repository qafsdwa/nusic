import 'song.dart';

/// A lightweight playlist model used by the mock playlist page and by the
/// future Rust playlist API.
class Playlist {
  const Playlist({
    required this.id,
    required this.name,
    required this.description,
    required this.cover,
    required this.songs,
  });

  final String id;
  final String name;
  final String description;
  final String cover;
  final List<Song> songs;

  int get songCount => songs.length;
}
