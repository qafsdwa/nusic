import '../../models/album.dart';
import '../../models/song.dart';

/// Mock data for Phase 1 only.
///
/// All UI reads from here until the Rust backend is connected. The `cover`
/// values are intentionally mock keys; rendering falls back to generated
/// placeholder artwork instead of hitting the network.
abstract final class MockData {
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
      title: 'Flower Dance',
      artist: 'DJ Okawari',
      album: 'Compass',
      cover: 'mock://flower-dance',
      duration: Duration(minutes: 4, seconds: 41),
    ),
    Song(
      id: 'song_006',
      title: '夜曲',
      artist: '周杰伦',
      album: '十一月的萧邦',
      cover: 'mock://nocturne',
      duration: Duration(minutes: 3, seconds: 47),
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
  ];
}
