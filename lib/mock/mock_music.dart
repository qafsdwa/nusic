import '../models/album.dart';
import '../models/playlist.dart';
import '../models/song.dart';

/// Mock data for Phase 1 only.
///
/// All UI reads from here until the Rust backend is connected. The `cover`
/// values are intentionally mock keys; rendering falls back to generated
/// placeholder artwork instead of hitting the network.
abstract final class MockMusic {
  static const List<Song> songs = <Song>[
    Song(
      id: 'song_001',
      title: 'Midnight Drive',
      artist: 'Google Material Orchestra',
      album: 'Synthetic Waves',
      cover: 'mock://midnight-drive',
      duration: Duration(minutes: 4, seconds: 12),
    ),
    Song(
      id: 'song_002',
      title: '冬日挽歌',
      artist: 'Cytus II',
      album: 'Cytus II Original Soundtrack',
      cover: 'mock://winter-elegy',
      duration: Duration(minutes: 5, seconds: 8),
    ),
    Song(
      id: 'song_003',
      title: 'Lemon',
      artist: '米津玄師',
      album: 'Lemon',
      cover: 'mock://lemon',
      duration: Duration(minutes: 4, seconds: 16),
    ),
    Song(
      id: 'song_004',
      title: '晴天',
      artist: '周杰伦',
      album: '叶惠美',
      cover: 'mock://sunny-day',
      duration: Duration(minutes: 4, seconds: 29),
    ),
    Song(
      id: 'song_005',
      title: 'The Nights',
      artist: 'Avicii',
      album: 'The Days / Nights',
      cover: 'mock://the-nights',
      duration: Duration(minutes: 2, seconds: 56),
    ),
    Song(
      id: 'song_006',
      title: 'Fix You',
      artist: 'Coldplay',
      album: 'X&Y',
      cover: 'mock://fix-you',
      duration: Duration(minutes: 4, seconds: 54),
    ),
  ];

  static const List<Album> albums = <Album>[
    Album(
      id: 'album_001',
      title: 'Synthetic Waves',
      artist: 'Google Material Orchestra',
      cover: 'mock://album-synthetic-waves',
    ),
    Album(
      id: 'album_002',
      title: 'Cytus II Original Soundtrack',
      artist: 'Cytus II',
      cover: 'mock://album-cytus2',
    ),
    Album(
      id: 'album_003',
      title: 'Lemon',
      artist: '米津玄師',
      cover: 'mock://album-lemon',
    ),
    Album(
      id: 'album_004',
      title: '叶惠美',
      artist: '周杰伦',
      cover: 'mock://album-yehui-mei',
    ),
    Album(
      id: 'album_005',
      title: 'The Days / Nights',
      artist: 'Avicii',
      cover: 'mock://album-the-days-nights',
    ),
    Album(
      id: 'album_006',
      title: 'X&Y',
      artist: 'Coldplay',
      cover: 'mock://album-xy',
    ),
  ];

  static const List<Playlist> playlists = <Playlist>[
    Playlist(
      id: 'playlist_001',
      name: '深夜驾驶',
      description: '适合夜间公路的冷静节拍',
      cover: 'mock://playlist-midnight-drive',
      songs: <Song>[
        Song(
          id: 'song_001',
          title: 'Midnight Drive',
          artist: 'Google Material Orchestra',
          album: 'Synthetic Waves',
          cover: 'mock://midnight-drive',
          duration: Duration(minutes: 4, seconds: 12),
        ),
        Song(
          id: 'song_005',
          title: 'The Nights',
          artist: 'Avicii',
          album: 'The Days / Nights',
          cover: 'mock://the-nights',
          duration: Duration(minutes: 2, seconds: 56),
        ),
        Song(
          id: 'song_006',
          title: 'Fix You',
          artist: 'Coldplay',
          album: 'X&Y',
          cover: 'mock://fix-you',
          duration: Duration(minutes: 4, seconds: 54),
        ),
      ],
    ),
    Playlist(
      id: 'playlist_002',
      name: '华语精选',
      description: '周杰伦与米津玄師的精选时刻',
      cover: 'mock://playlist-chinese',
      songs: <Song>[
        Song(
          id: 'song_003',
          title: 'Lemon',
          artist: '米津玄師',
          album: 'Lemon',
          cover: 'mock://lemon',
          duration: Duration(minutes: 4, seconds: 16),
        ),
        Song(
          id: 'song_004',
          title: '晴天',
          artist: '周杰伦',
          album: '叶惠美',
          cover: 'mock://sunny-day',
          duration: Duration(minutes: 4, seconds: 29),
        ),
      ],
    ),
  ];

  /// Used by the Home page "recently played" horizontal rail.
  static const List<Song> recentlyPlayed = <Song>[
    Song(
      id: 'song_004',
      title: '晴天',
      artist: '周杰伦',
      album: '叶惠美',
      cover: 'mock://sunny-day',
      duration: Duration(minutes: 4, seconds: 29),
    ),
    Song(
      id: 'song_003',
      title: 'Lemon',
      artist: '米津玄師',
      album: 'Lemon',
      cover: 'mock://lemon',
      duration: Duration(minutes: 4, seconds: 16),
    ),
    Song(
      id: 'song_001',
      title: 'Midnight Drive',
      artist: 'Google Material Orchestra',
      album: 'Synthetic Waves',
      cover: 'mock://midnight-drive',
      duration: Duration(minutes: 4, seconds: 12),
    ),
    Song(
      id: 'song_005',
      title: 'The Nights',
      artist: 'Avicii',
      album: 'The Days / Nights',
      cover: 'mock://the-nights',
      duration: Duration(minutes: 2, seconds: 56),
    ),
    Song(
      id: 'song_006',
      title: 'Fix You',
      artist: 'Coldplay',
      album: 'X&Y',
      cover: 'mock://fix-you',
      duration: Duration(minutes: 4, seconds: 54),
    ),
  ];
}
