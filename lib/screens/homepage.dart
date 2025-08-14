import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import '../services/jiosaavn_api_service.dart';
import '../widgets/animated_navbar.dart';
import '../widgets/mini_player.dart';
import '../widgets/music_loader.dart';
import '../screens/music_player.dart';
import '../screens/search_page.dart';
import '../screens/playlist_storage.dart'; // Make sure this import is correct!
import '../services/player_state_provider.dart';
import '../screens/settings_page.dart';
import 'package:swipe_cards/swipe_cards.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../widgets/artist_section.dart'; // <-- Import the new artist page widget
import '../widgets/masonry_song_section.dart';
import '../widgets/random_songs_section.dart';
import '../widgets/album_section.dart';
import '../services/pitch_black_theme_provider.dart'; // <-- Import pitch black provider
import '../services/custom_theme_provider.dart';

// Helper function: pick N random (non-repeating) songs from a list, skipping recently shown
Future<Set<String>> loadShownIdsFromStorage() async {
  // TODO: Implement persistent storage (SharedPreferences/Hive etc.)
  // For now, just return an empty set.
  return <String>{};
}

Future<void> saveShownIdsToStorage(Set<String> ids) async {
  // TODO: Implement persistent storage
}

List<Map<String, dynamic>> getUnseenRandomSongs(
  List<Map<String, dynamic>> songsList,
  int count,
  Set<String> shownSongIds,
) {
  final unseen = songsList
      .where((song) => !shownSongIds.contains(song['id']))
      .toList();
  unseen.shuffle(Random());
  final selected = unseen.take(count).toList();
  shownSongIds.addAll(selected.map((s) => s['id']));
  return selected;
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  final JioSaavnApiService _apiService = JioSaavnApiService();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final PageController _bannerController = PageController();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  late AnimationController _pageTransitionController;
  late Animation<Offset> _pageOffsetAnimation;

  late AnimationController _meteorsController;

  Timer? _bannerTimer;
  int _selectedNavIndex = 0;
  int _prevNavIndex = 0;

  List<Map<String, dynamic>> _trendingSongs = [];
  List<Map<String, dynamic>> _albums = [];
  List<Map<String, dynamic>> _artists = [];
  List<Map<String, dynamic>> _bannerSongs = [];
  List<Map<String, dynamic>> _randomSongs = [];

  bool _isLoading = true;
  String? _error;

  bool _isMusicPlayerPageOpen = false;
  bool _isAutoPlayTriggered = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _pageTransitionController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
    _pageOffsetAnimation = Tween<Offset>(begin: Offset.zero, end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _pageTransitionController,
            curve: Curves.easeOutCubic,
          ),
        );

    _meteorsController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();

    _loadData();
    _startBannerAutoScroll();

    // Listen to audio player state and update provider accordingly
    _audioPlayer.playingStream.listen((playing) {
      final playerState = Provider.of<PlayerStateProvider>(
        context,
        listen: false,
      );
      playerState.setPlaying(playing);
      if (playing) {
        playerState.setSongLoading(false);
      }
    });

    _audioPlayer.playerStateStream.listen((state) {
      if (!mounted) return; // Check if widget is still mounted

      final playerState = Provider.of<PlayerStateProvider>(
        context,
        listen: false,
      );

      print('Player state changed: ${state.processingState}');

      if (state.processingState == ProcessingState.ready) {
        playerState.setSongLoading(false);
      } else if (state.processingState == ProcessingState.completed) {
        // Song finished, play next song automatically
        print('Song completed, scheduling next song...');
        // Use post frame callback to ensure we're on the main thread
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _playNextSong();
          }
        });
      }
    });

    // Additional listener for position to detect near-end of song
    _audioPlayer.positionStream.listen((position) {
      if (!mounted) return;

      final duration = _audioPlayer.duration;
      if (duration != null) {
        final remaining = duration - position;
        // If less than 500ms remaining and was playing, trigger next song
        if (remaining.inMilliseconds < 500 &&
            remaining.inMilliseconds > 0 &&
            _audioPlayer.playing &&
            !_isAutoPlayTriggered) {
          print(
            'Song near completion: ${remaining.inMilliseconds}ms remaining - triggering next song',
          );
          _isAutoPlayTriggered = true;
          // Trigger next song when very close to end
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _playNextSong();
            }
          });
        }
      }
    });
  }

  void _startBannerAutoScroll() {
    _bannerTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_bannerController.hasClients && _bannerSongs.isNotEmpty) {
        final nextPage = (_bannerController.page?.round() ?? 0) + 1;
        if (nextPage >= _bannerSongs.length) {
          _bannerController.animateToPage(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        } else {
          _bannerController.nextPage(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      }
    });
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final List<String> songQueries = [
        'trending hindi songs',
        'bollywood hits',
        'latest punjabi songs',
        'romantic songs',
        'party songs',
        'english hits',
        'pop songs',
        'rock music',
        'hip hop',
        'electronic music',
        'indie songs',
        'classical music',
        'top hits',
        'billboard top',
        'viral songs',
        'spotify viral',
        'youtube trending',
        'folk music',
        'old hindi songs',
        'retro hits',
        'dance hits',
        'chill music',
        'instrumental hits',
        'workout songs',
        'study music',
        '90s hits',
        '2000s hits',
        'international hits',
        'regional hits',
        'desi pop',
        'love songs',
        'sad songs',
        'happy songs',
        'motivational songs',
        'indian rap',
        'ghazals',
        'sufi music',
        'devotional songs',
        'wedding songs',
        'festival songs',
        'summer hits',
        'winter hits',
        'road trip songs',
        'kids songs',
        'bollywood remixes',
        'cover songs',
        'mashup songs',
        'melancholic music',
      ];

      final List<String> albumQueries = [
        'latest albums',
        'bollywood albums',
        'punjabi albums',
        'hindi albums',
        'english albums',
        'pop albums',
        'rock albums',
        'hip hop albums',
        'electronic albums',
        'international albums',
        'regional albums',
        'indie albums',
        'remix albums',
        'soundtrack albums',
        'compilation albums',
        'award winning albums',
        'top albums',
        'classical albums',
        'romantic albums',
        'party albums',
        'folk albums',
        'devotional albums',
        'ghazal albums',
        'sufi albums',
      ];

      final List<String> bannerQueries = [
        'top hits 2024',
        'viral songs',
        'trending now',
        'popular music',
        'chart toppers',
        'global hits',
        'billboard top',
        'spotify viral',
        'youtube trending',
        'featured bollywood',
        'editor picks',
        'top charts',
        'playlist favorites',
        'international top charts',
        'festival special',
        'new music friday',
        'weekly top 20',
        'hot 100',
        'ultimate party mix',
        'best of 2023',
        'on repeat',
        'radio hits',
        'summer vibes',
        'winter anthems',
        'road trip playlist',
        'club bangers',
        'bollywood superhits',
      ];

      final random = Random();
      final songQuery = songQueries[random.nextInt(songQueries.length)];
      final albumQuery = albumQueries[random.nextInt(albumQueries.length)];
      final bannerQuery = bannerQueries[random.nextInt(bannerQueries.length)];

      // Fetch trending songs
      final songsResponse = await _apiService.searchSongs(songQuery, limit: 25);
      final albumsResponse = await _apiService.searchAlbums(
        albumQuery,
        limit: 5,
      );
      final bannerResponse = await _apiService.searchSongs(
        bannerQuery,
        limit: 5,
      );

      // Fetch random songs from multiple queries for true randomness and non-repeat
      Set<String> shownSongIds = await loadShownIdsFromStorage();
      List<Map<String, dynamic>> allSongs = [];
      final shuffledQueries = List<String>.from(songQueries)..shuffle();
      for (var q in shuffledQueries) {
        final response = await _apiService.searchSongs(q, limit: 15);
        if (response['success'] == true && response['data'] != null) {
          final songs = List<Map<String, dynamic>>.from(
            response['data']['results'] ?? [],
          );
          allSongs.addAll(songs);
        }
      }
      // Remove duplicates by song ID
      final uniqueSongs = {for (var s in allSongs) s['id']: s}.values.toList();
      final randomSongs = getUnseenRandomSongs(uniqueSongs, 20, shownSongIds);
      await saveShownIdsToStorage(shownSongIds);

      // Artists logic
      final List<String> famousArtists = [
        'arijit singh',
        'shreya ghoshal',
        'atif aslam',
        'neha kakkar',
        'armaan malik',
        'honey singh',
        'badshah',
        'guru randhawa',
        'taylor swift',
        'ed sheeran',
        'ariana grande',
        'justin bieber',
        'billie eilish',
        'the weeknd',
        'dua lipa',
        'bruno mars',
      ];
      List<Map<String, dynamic>> allArtists = [];
      final shuffledArtists = List<String>.from(famousArtists)..shuffle();
      for (int i = 0; i < 6 && i < shuffledArtists.length; i++) {
        try {
          final artistName = shuffledArtists[i];
          final artistResponse = await _apiService.searchArtists(
            artistName,
            limit: 1,
          );
          if (artistResponse['success'] == true &&
              artistResponse['data'] != null &&
              artistResponse['data']['results'] != null &&
              artistResponse['data']['results'].isNotEmpty) {
            allArtists.add(artistResponse['data']['results'][0]);
          }
        } catch (e) {
          print('Error fetching artist: $e');
        }
      }

      // Trending songs, albums, banners
      if (songsResponse['success'] == true && songsResponse['data'] != null) {
        final songsData = songsResponse['data'];
        if (songsData['results'] != null) {
          final songs = List<Map<String, dynamic>>.from(songsData['results']);
          setState(() {
            _trendingSongs = songs;
          });
        }
      }
      if (albumsResponse['success'] == true && albumsResponse['data'] != null) {
        final albumsData = albumsResponse['data'];
        if (albumsData['results'] != null) {
          final albums = List<Map<String, dynamic>>.from(albumsData['results']);
          setState(() {
            _albums = albums;
          });
        }
      }
      List<Map<String, dynamic>> bannerSongs = [];
      try {
        // Use random banner query instead of fixed "trending songs"
        final bannerSongsResponse = await _apiService.searchSongs(
          bannerQuery,
          limit: 6,
        );
        if (bannerSongsResponse['success'] == true &&
            bannerSongsResponse['data'] != null) {
          final bannerData = bannerSongsResponse['data'];
          if (bannerData['results'] != null) {
            final banners = List<Map<String, dynamic>>.from(
              bannerData['results'],
            );
            bannerSongs.addAll(banners);
          }
        }

        // If we don't have enough banners, add from a different random query
        if (bannerSongs.length < 5) {
          final fallbackQuery =
              bannerQueries[random.nextInt(bannerQueries.length)];
          final fallbackResponse = await _apiService.searchSongs(
            fallbackQuery,
            limit: 5,
          );
          if (fallbackResponse['success'] == true &&
              fallbackResponse['data'] != null) {
            final fallbackData = fallbackResponse['data'];
            if (fallbackData['results'] != null) {
              final fallbackBanners = List<Map<String, dynamic>>.from(
                fallbackData['results'],
              );
              bannerSongs.addAll(fallbackBanners);
            }
          }
        }

        // Remove duplicates and limit to 5
        final uniqueBanners = {
          for (var s in bannerSongs) s['id']: s,
        }.values.toList();
        bannerSongs = uniqueBanners.take(5).toList();
      } catch (e) {
        print('Banner query failed: $e');
        // Fallback to test song only if everything fails
      }

      setState(() {
        _bannerSongs = bannerSongs;
        _artists = allArtists;
        _randomSongs = randomSongs;
        _isLoading = false;
      });
      _animationController.forward();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _onNavTap(int index) {
    if (_selectedNavIndex == index) return;
    _prevNavIndex = _selectedNavIndex;

    _pageOffsetAnimation =
        Tween<Offset>(
          begin: Offset(index > _selectedNavIndex ? 1.0 : -1.0, 0),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: _pageTransitionController,
            curve: Curves.easeOutCubic,
          ),
        );

    setState(() {
      _selectedNavIndex = index;
    });

    _pageTransitionController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    final playerState = Provider.of<PlayerStateProvider>(context);
    final isPitchBlack = context
        .watch<PitchBlackThemeProvider>()
        .isPitchBlack; // <-- READ PROVIDER
    final customTheme = context.watch<CustomThemeProvider>();
    final customColorsEnabled = customTheme.customColorsEnabled;
    final primaryColor = customTheme.primaryColor;
    final secondaryColor = customTheme.secondaryColor;

    final List<Widget> pages = [
      _buildBody(
        customColorsEnabled: customColorsEnabled,
        primaryColor: primaryColor,
        secondaryColor: secondaryColor,
      ),
      SearchPage(
        onNavTap: _onNavTap,
        selectedNavIndex: _selectedNavIndex,
        audioPlayer: _audioPlayer,
        onPlayPause: () {
          if (_audioPlayer.playing) {
            _audioPlayer.pause();
          } else {
            _audioPlayer.play();
          }
        },
        onNext: _playNextSong,
        onPrevious: _playPreviousSong,
      ),
      LibraryScreen(onNavTap: _onNavTap, selectedNavIndex: _selectedNavIndex),
      SettingsPage(
        onLogout: () {
          // Implement your logout logic here
          // For example: Navigator.pushReplacementNamed(context, '/login');
        },
        onNavTap: _onNavTap,
        selectedNavIndex: _selectedNavIndex,
      ),
    ];

    return Scaffold(
      backgroundColor: isPitchBlack
          ? Colors.black
          : customColorsEnabled
          ? secondaryColor
          : Colors.black, // <-- USE PROVIDER AND CUSTOM THEME
      body: Stack(
        children: [
          _buildAnimatedBackground(
            isPitchBlack: isPitchBlack,
            customColorsEnabled: customColorsEnabled,
            primaryColor: primaryColor,
            secondaryColor: secondaryColor,
          ), // <-- USE PROVIDER
          SafeArea(
            child: Column(
              children: [
                if (_selectedNavIndex == 0)
                  _buildHeader(
                    customColorsEnabled: customColorsEnabled,
                    primaryColor: primaryColor,
                    secondaryColor: secondaryColor,
                  ),
                Expanded(
                  child: AnimatedBuilder(
                    animation: _pageTransitionController,
                    builder: (context, child) {
                      return SlideTransition(
                        position: _pageOffsetAnimation,
                        child: IndexedStack(
                          index: _selectedNavIndex,
                          children: pages,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          if (playerState.currentSong != null && !_isMusicPlayerPageOpen)
            Positioned(
              bottom: 70,
              left: 16,
              right: 16,
              child: MiniPlayer(
                currentSong: playerState.currentSong,
                audioPlayer: _audioPlayer,
                isSongLoading: playerState.isSongLoading,
                onPlayPause: () {
                  if (_audioPlayer.playing) {
                    _audioPlayer.pause();
                  } else {
                    _audioPlayer.play();
                  }
                },
                onClose: () {
                  _audioPlayer.stop();
                  playerState.clearSong();
                },
                onTap: () {
                  setState(() {
                    _isMusicPlayerPageOpen = true;
                  });
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => StreamBuilder<Duration>(
                        stream: _audioPlayer.positionStream,
                        builder: (context, positionSnapshot) {
                          return StreamBuilder<Duration?>(
                            stream: _audioPlayer.durationStream,
                            builder: (context, durationSnapshot) {
                              return StreamBuilder<bool>(
                                stream: _audioPlayer.playingStream,
                                builder: (context, playingSnapshot) {
                                  final song = playerState.currentSong;
                                  final songTitle =
                                      song?['name'] ??
                                      song?['title'] ??
                                      'Unknown';
                                  final artistName = song != null
                                      ? (song['artists'] != null
                                            ? (song['artists']['primary'] !=
                                                          null &&
                                                      song['artists']['primary']
                                                          .isNotEmpty
                                                  ? song['artists']['primary'][0]['name'] ??
                                                        'Unknown Artist'
                                                  : 'Unknown Artist')
                                            : (song['primaryArtists'] ??
                                                  song['subtitle'] ??
                                                  'Unknown Artist'))
                                      : 'Unknown Artist';
                                  final albumArtUrl = song?['image'] != null
                                      ? _getBestImageUrl(song!['image']) ?? ''
                                      : '';
                                  return MusicPlayerPage(
                                    songTitle: songTitle,
                                    artistName: artistName,
                                    albumArtUrl: albumArtUrl,
                                    songId: song?['id'],
                                    isPlaying: playingSnapshot.data ?? false,
                                    isLoading: playerState.isSongLoading,
                                    currentPosition:
                                        positionSnapshot.data ?? Duration.zero,
                                    totalDuration:
                                        durationSnapshot.data ?? Duration.zero,
                                    onPlayPause: () {
                                      if (_audioPlayer.playing) {
                                        _audioPlayer.pause();
                                      } else {
                                        _audioPlayer.play();
                                      }
                                    },
                                    onNext: _playNextSong,
                                    onPrevious: _playPreviousSong,
                                    onJumpToSong: (index) =>
                                        _jumpToSongAtIndex(index),
                                    onSeek: (value) {
                                      final position =
                                          (durationSnapshot.data ??
                                              Duration.zero) *
                                          value;
                                      _audioPlayer.seek(position);
                                    },
                                  );
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ).then((_) {
                    setState(() {
                      _isMusicPlayerPageOpen = false;
                    });
                  });
                },
              ),
            ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: AnimatedNavBar(
              selectedIndex: _selectedNavIndex,
              onNavTap: _onNavTap,
              navIcons: const [
                Icons.home,
                Icons.search,
                Icons.playlist_play,
                Icons.settings,
              ],
              navLabels: const ['Home', 'Search', 'Library', 'Settings'],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground({
    required bool isPitchBlack,
    required bool customColorsEnabled,
    required Color primaryColor,
    required Color secondaryColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: isPitchBlack
            ? null
            : customColorsEnabled
            ? RadialGradient(
                center: Alignment.topLeft,
                radius: 1.5,
                colors: [
                  secondaryColor,
                  secondaryColor.withOpacity(0.8),
                  Colors.black,
                ],
              )
            : const RadialGradient(
                center: Alignment.topLeft,
                radius: 1.5,
                colors: [Color(0xFF1a1a2e), Color(0xFF16213e), Colors.black],
              ),
        color: isPitchBlack ? Colors.black : null,
      ),
      child: Stack(
        children: List.generate(
          15,
          (index) => _buildMeteor(
            index,
            isPitchBlack: isPitchBlack,
            customColorsEnabled: customColorsEnabled,
            primaryColor: primaryColor,
          ),
        ),
      ),
    );
  }

  Widget _buildMeteor(
    int index, {
    required bool isPitchBlack,
    required bool customColorsEnabled,
    required Color primaryColor,
  }) {
    return AnimatedBuilder(
      animation: _meteorsController,
      builder: (context, child) {
        final double progress = _meteorsController.value;
        final double staggeredProgress = ((progress + (index * 0.1)) % 1.0)
            .clamp(0.0, 1.0);
        return Positioned(
          top: (index * 60.0) % MediaQuery.of(context).size.height,
          left: (index * 90.0) % MediaQuery.of(context).size.width,
          child: Transform.translate(
            offset: Offset(
              staggeredProgress * 100 - 50,
              staggeredProgress * 100 - 50,
            ),
            child: Opacity(
              opacity: isPitchBlack ? 0 : (1.0 - staggeredProgress) * 0.6,
              child: Container(
                width: 3,
                height: 3,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(1.5),
                  color: customColorsEnabled
                      ? primaryColor
                      : const Color(0xFFff7d78),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader({
    required bool customColorsEnabled,
    required Color primaryColor,
    required Color secondaryColor,
  }) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Good ${_getGreeting()}',
                style: TextStyle(color: Colors.grey[400], fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(
                'PlayWaves',
                style: TextStyle(
                  color: customColorsEnabled ? primaryColor : Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionCards({
    required bool customColorsEnabled,
    required Color primaryColor,
    required Color secondaryColor,
  }) {
    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 2,
      childAspectRatio: 2.5,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: [
        _buildActionCard(
          'Hot',
          'Trending',
          'Discover what\'s trending right now.',
          Colors.red,
          Icons.local_fire_department,
          () {},
          customColorsEnabled: customColorsEnabled,
          primaryColor: primaryColor,
          secondaryColor: secondaryColor,
        ),
        _buildActionCard(
          'Popular',
          'Most Played',
          'Check out the most played songs.',
          Colors.green,
          Icons.play_circle_filled,
          () {},
          customColorsEnabled: customColorsEnabled,
          primaryColor: primaryColor,
          secondaryColor: secondaryColor,
        ),
        _buildActionCard(
          'Collection',
          'Playlists',
          'Browse curated playlists for every mood.',
          Colors.purple,
          Icons.playlist_play,
          () {},
          customColorsEnabled: customColorsEnabled,
          primaryColor: primaryColor,
          secondaryColor: secondaryColor,
        ),
        _buildActionCard(
          'Stars',
          'Artists',
          'Explore your favorite artists.',
          Colors.blue,
          Icons.person,
          () {},
          customColorsEnabled: customColorsEnabled,
          primaryColor: primaryColor,
          secondaryColor: secondaryColor,
        ),
      ],
    );
  }

  Widget _buildActionCard(
    String tag,
    String title,
    String description,
    Color color,
    IconData icon,
    VoidCallback onTap, {
    required bool customColorsEnabled,
    required Color primaryColor,
    required Color secondaryColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white.withOpacity(0.05),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: customColorsEnabled
                    ? primaryColor.withOpacity(0.15)
                    : color.withOpacity(0.15),
              ),
              child: Text(
                tag.toUpperCase(),
                style: TextStyle(
                  color: customColorsEnabled ? primaryColor : color,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Row(
              children: [
                Icon(icon, color: Colors.white, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody({
    required bool customColorsEnabled,
    required Color primaryColor,
    required Color secondaryColor,
  }) {
    if (_isLoading) {
      return Center(
        child: SiriWaveLoader(
          colors: customColorsEnabled
              ? [
                  primaryColor,
                  primaryColor.withOpacity(0.7),
                  primaryColor.withOpacity(0.5),
                  primaryColor.withOpacity(0.3),
                ]
              : [Colors.purple, Colors.blue, Colors.pink, Colors.cyan],
          width: 80,
          height: 80,
        ),
      );
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              'Error: $_error',
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      color: customColorsEnabled ? primaryColor : const Color(0xFFff7d78),
      backgroundColor: Colors.black,
      displacement: 40.0,
      strokeWidth: 3.0,
      triggerMode: RefreshIndicatorTriggerMode.anywhere,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildActionCards(
                    customColorsEnabled: customColorsEnabled,
                    primaryColor: primaryColor,
                    secondaryColor: secondaryColor,
                  ),
                ),
                const SizedBox(height: 20),
                if (_bannerSongs.isNotEmpty)
                  _buildBannerSection(
                    customColorsEnabled: customColorsEnabled,
                    primaryColor: primaryColor,
                    secondaryColor: secondaryColor,
                  ),
                const SizedBox(height: 20),
                if (_albums.isNotEmpty) _buildAlbumsSection(),
                const SizedBox(height: 20),
                if (_artists.isNotEmpty) _buildArtistsSection(), // <-- updated!
                if (_randomSongs.isNotEmpty) _buildRandomSongsSection(),
                if (_trendingSongs.isNotEmpty) _buildSongsSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBannerSection({
    required bool customColorsEnabled,
    required Color primaryColor,
    required Color secondaryColor,
  }) {
    return SizedBox(
      height: 180,
      child: PageView.builder(
        controller: _bannerController,
        itemCount: _bannerSongs.length,
        itemBuilder: (context, index) {
          final song = _bannerSongs[index];
          return _buildBannerCard(
            song,
            customColorsEnabled: customColorsEnabled,
            primaryColor: primaryColor,
            secondaryColor: secondaryColor,
          );
        },
      ),
    );
  }

  Widget _buildBannerCard(
    Map<String, dynamic> song, {
    required bool customColorsEnabled,
    required Color primaryColor,
    required Color secondaryColor,
  }) {
    final imageUrl = _getBestImageUrl(song['image']);
    final title = song['name'] ?? song['title'] ?? 'Unknown Song';
    final songId = song['id'];
    final hasLyrics = songId == 'PIzj2ULl';

    String artist = 'Unknown Artist';
    if (song['artists'] != null) {
      final artists = song['artists'];
      if (artists['primary'] != null && artists['primary'].isNotEmpty) {
        artist = artists['primary'][0]['name'] ?? 'Unknown Artist';
      }
    } else if (song['subtitle'] != null) {
      artist = song['subtitle'];
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Stack(
        children: [
          if (imageUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                imageUrl,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: customColorsEnabled
                            ? [
                                primaryColor.withOpacity(0.3),
                                primaryColor.withOpacity(0.1),
                              ]
                            : [
                                const Color(0xFFff7d78).withOpacity(0.3),
                                const Color(0xFF9c27b0).withOpacity(0.3),
                              ],
                      ),
                    ),
                  );
                },
              ),
            ),
          if (hasLyrics)
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.lyrics, color: Colors.white, size: 12),
                    SizedBox(width: 4),
                    Text(
                      'Lyrics',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
              ),
            ),
          ),
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        artist,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: customColorsEnabled
                          ? [primaryColor, primaryColor.withOpacity(0.8)]
                          : [Color(0xFFff7d78), Color(0xFF9c27b0)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Consumer<PlayerStateProvider>(
                    builder: (context, playerState, child) {
                      final isCurrentSong =
                          playerState.currentSong != null &&
                          playerState.currentSong!['id'] == song['id'];
                      final isPlaying = playerState.isPlaying && isCurrentSong;
                      final isLoading =
                          playerState.isSongLoading && isCurrentSong;

                      return IconButton(
                        icon: isLoading
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Icon(
                                isPlaying ? Icons.pause : Icons.play_arrow,
                                color: Colors.white,
                              ),
                        onPressed: isLoading
                            ? null
                            : () async {
                                try {
                                  if (isCurrentSong && isPlaying) {
                                    // Pause current song
                                    await _audioPlayer.pause();
                                    playerState.setPlaying(false);
                                  } else if (isCurrentSong && !isPlaying) {
                                    // Resume current song
                                    await _audioPlayer.play();
                                    playerState.setPlaying(true);
                                  } else {
                                    // Play a different song
                                    _playSong(song, null, false);
                                  }
                                } catch (e) {
                                  print('Error in banner play/pause: $e');
                                  // Sync state with actual player state
                                  final actuallyPlaying = _audioPlayer.playing;
                                  playerState.setPlaying(actuallyPlaying);
                                }
                              },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlbumsSection() {
    return AlbumsSection(
      albums: _albums,
      onAlbumPlay: (album) => _playAlbum(album),
      getBestImageUrl: _getBestImageUrl,
      audioPlayer: _audioPlayer,
    );
  }

  Widget _buildArtistsSection() {
    return ArtistSection(
      artists: _artists,
      apiService: _apiService,
      audioPlayer: _audioPlayer,
    );
  }

  Widget _buildRandomSongsSection() {
    return RandomSongsSection(
      randomSongs: _randomSongs,
      onSongPlay: (song, index) => _playSong(song, index, true),
      getBestImageUrl: _getBestImageUrl,
      audioPlayer: _audioPlayer,
    );
  }

  Widget _buildSongsSection() {
    return MasonrySongSection(
      songs: _trendingSongs,
      onSongTap: (song, index) => _playSong(song, index, false),
      getBestImageUrl: _getBestImageUrl,
    );
  }

  Widget _buildSongTile(
    Map<String, dynamic> song,
    int index,
    bool useRandom, {
    required bool customColorsEnabled,
    required Color primaryColor,
    required Color secondaryColor,
  }) {
    final imageUrl = _getBestImageUrl(song['image']);
    final title = song['name'] ?? song['title'] ?? 'Unknown Song';
    String subtitle = 'Unknown Artist';
    if (song['artists'] != null) {
      final artists = song['artists'];
      if (artists['primary'] != null && artists['primary'].isNotEmpty) {
        subtitle = artists['primary'][0]['name'] ?? 'Unknown Artist';
      }
    } else if (song['subtitle'] != null) {
      subtitle = song['subtitle'];
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withOpacity(0.05),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Stack(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: LinearGradient(
                  colors: customColorsEnabled
                      ? [
                          primaryColor.withOpacity(0.3),
                          primaryColor.withOpacity(0.1),
                        ]
                      : [
                          const Color(0xFFff7d78).withOpacity(0.3),
                          const Color(0xFF9c27b0).withOpacity(0.3),
                        ],
                ),
              ),
              child: imageUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.music_note,
                            color: Colors.white,
                          );
                        },
                      ),
                    )
                  : const Icon(Icons.music_note, color: Colors.white),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Color(0xFFff7d78),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: Colors.white70),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: customColorsEnabled
                  ? [primaryColor, primaryColor.withOpacity(0.8)]
                  : [Color(0xFFff7d78), Color(0xFF9c27b0)],
            ),
            shape: BoxShape.circle,
          ),
          child: Consumer<PlayerStateProvider>(
            builder: (context, playerState, child) {
              final isCurrentSong =
                  playerState.currentSong != null &&
                  playerState.currentSong!['id'] == song['id'];
              final isPlaying = playerState.isPlaying && isCurrentSong;
              final isLoading = playerState.isSongLoading && isCurrentSong;

              return IconButton(
                icon: isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Icon(
                        isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                      ),
                onPressed: isLoading
                    ? null
                    : () async {
                        if (isCurrentSong && playerState.isPlaying) {
                          // Pause current song
                          playerState.setPlaying(false);
                          await _audioPlayer.pause();
                        } else if (isCurrentSong && !playerState.isPlaying) {
                          // Resume current song
                          playerState.setPlaying(true);
                          await _audioPlayer.play();
                        } else {
                          // Play a different song
                          _playSong(song, index, useRandom);
                        }
                      },
              );
            },
          ),
        ),
      ),
    );
  }

  String? _getBestImageUrl(dynamic images) {
    if (images is List && images.isNotEmpty) {
      for (var img in images.reversed) {
        if (img is Map && img['link'] != null) {
          return img['link'];
        }
        if (img is Map && img['url'] != null) {
          return img['url'];
        }
      }
    } else if (images is String) {
      return images;
    }
    return null;
  }

  Future<void> _playSong(
    Map<String, dynamic> song,
    int? index,
    bool useRandom,
  ) async {
    final playerState = Provider.of<PlayerStateProvider>(
      context,
      listen: false,
    );
    try {
      _isAutoPlayTriggered = false; // Reset auto-play flag for new song
      playerState.setSongLoading(true);
      await _audioPlayer.stop();
      await _audioPlayer.seek(Duration.zero);

      final playlist = useRandom
          ? List<Map<String, dynamic>>.from(_randomSongs)
          : List<Map<String, dynamic>>.from(_trendingSongs);

      if (playerState.currentPlaylist.isEmpty ||
          !ListEquality().equals(playerState.currentPlaylist, playlist)) {
        playerState.setPlaylist(playlist);
      }

      if (index != null) {
        playerState.setSongIndex(index);
      } else {
        final songIndex = playlist.indexWhere((s) => s['id'] == song['id']);
        playerState.setSongIndex(songIndex == -1 ? 0 : songIndex);
      }

      playerState.setSong(Map<String, dynamic>.from(song));

      final songId = song['id'];
      if (songId != null) {
        final songDetails = await _apiService.getSongById(songId);
        String? downloadUrl;
        final songData = songDetails['data']?[0];

        if (songData != null) {
          playerState.setSong(Map<String, dynamic>.from(songData));
          if (songData['downloadUrl'] != null &&
              songData['downloadUrl'] is List) {
            final downloadUrls = songData['downloadUrl'] as List;
            if (downloadUrls.isNotEmpty) {
              final urlData = downloadUrls.last;
              downloadUrl = urlData['url'] ?? urlData['link'];
            }
          }
          if (downloadUrl == null) {
            downloadUrl =
                songData['media_preview_url'] ??
                songData['media_url'] ??
                songData['preview_url'] ??
                songData['stream_url'];
          }
        }

        if (downloadUrl != null && downloadUrl.isNotEmpty) {
          if (downloadUrl.contains('preview.saavncdn.com') ||
              downloadUrl.contains('aac.saavncdn.com')) {
            await _audioPlayer.setUrl(downloadUrl);
            await _audioPlayer.play();
            playerState.setPlaying(true);
          } else {
            throw Exception('Invalid audio URL format');
          }
        } else {
          throw Exception('No download URL found in response');
        }
      } else {
        throw Exception('No song ID found');
      }
    } catch (e) {
      playerState.setSongLoading(false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error playing song: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _playAlbum(Map<String, dynamic> album) async {
    final playerState = Provider.of<PlayerStateProvider>(
      context,
      listen: false,
    );
    try {
      playerState.setSongLoading(true);
      await _audioPlayer.stop();
      await _audioPlayer.seek(Duration.zero);

      final albumId = album['id'];
      if (albumId != null) {
        final albumDetails = await _apiService.getAlbum(id: albumId);
        final songs = albumDetails['data']?['songs'];
        if (songs != null && songs.isNotEmpty) {
          final albumSongs = List<Map<String, dynamic>>.from(songs);
          final firstSong = albumSongs[0];

          playerState.setPlaylist(albumSongs);
          playerState.setSongIndex(0);
          playerState.setSong(Map<String, dynamic>.from(firstSong));

          final songId = firstSong['id'];
          if (songId != null) {
            final songDetails = await _apiService.getSongById(songId);
            String? downloadUrl;
            final songData = songDetails['data']?[0];

            if (songData != null) {
              playerState.setSong(Map<String, dynamic>.from(songData));
              if (songData['downloadUrl'] != null &&
                  songData['downloadUrl'] is List) {
                final downloadUrls = songData['downloadUrl'] as List;
                if (downloadUrls.isNotEmpty) {
                  final urlData = downloadUrls.last;
                  downloadUrl = urlData['url'] ?? urlData['link'];
                }
              }
              if (downloadUrl == null) {
                downloadUrl =
                    songData['media_preview_url'] ??
                    songData['media_url'] ??
                    songData['preview_url'] ??
                    songData['stream_url'];
              }
            }

            if (downloadUrl != null && downloadUrl.isNotEmpty) {
              if (downloadUrl.contains('preview.saavncdn.com') ||
                  downloadUrl.contains('aac.saavncdn.com')) {
                await _audioPlayer.setUrl(downloadUrl);
                await _audioPlayer.play();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Playing album: ${album['name']}'),
                    backgroundColor: const Color(0xFFff7d78),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              } else {
                throw Exception('Invalid audio URL format');
              }
            } else {
              throw Exception('No download URL found');
            }
          } else {
            throw Exception('No song ID found');
          }
        } else {
          throw Exception('No songs found in album');
        }
      } else {
        throw Exception('No album ID found');
      }
    } catch (e) {
      playerState.setSongLoading(false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error playing album: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _playNextSong() async {
    print('_playNextSong called');
    final playerState = Provider.of<PlayerStateProvider>(
      context,
      listen: false,
    );
    final playlist = playerState.currentPlaylist;
    final songIndex = playerState.currentSongIndex;

    print('Current playlist length: ${playlist.length}');
    print('Current song index: $songIndex');

    if (playlist.isNotEmpty && songIndex < playlist.length - 1) {
      // Play next song in playlist
      final nextSong = playlist[songIndex + 1];
      bool useRandom = ListEquality().equals(playlist, _randomSongs);
      print('Playing next song: ${nextSong['name'] ?? 'Unknown'}');
      await _playSong(nextSong, songIndex + 1, useRandom);
    } else {
      // End of playlist - stop playback and clear state
      print('End of playlist reached');
      playerState.setPlaying(false);
      playerState.setSongLoading(false);
      try {
        await _audioPlayer.stop();
      } catch (e) {
        print('Error stopping audio player: $e');
      }
    }
  }

  void _playPreviousSong() {
    final playerState = Provider.of<PlayerStateProvider>(
      context,
      listen: false,
    );
    final playlist = playerState.currentPlaylist;
    final songIndex = playerState.currentSongIndex;
    if (playlist.isNotEmpty && songIndex > 0) {
      final prevSong = playlist[songIndex - 1];
      bool useRandom = ListEquality().equals(playlist, _randomSongs);
      _playSong(prevSong, songIndex - 1, useRandom);
    }
  }

  void _jumpToSongAtIndex(int index) {
    final playerState = Provider.of<PlayerStateProvider>(
      context,
      listen: false,
    );
    final playlist = playerState.currentPlaylist;
    final song = playlist[index];
    bool useRandom = ListEquality().equals(playlist, _randomSongs);
    _playSong(song, index, useRandom);
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _bannerController.dispose();
    _animationController.dispose();
    _audioPlayer.dispose();
    _pageTransitionController.dispose();
    _meteorsController.dispose();
    super.dispose();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Morning';
    } else if (hour < 17) {
      return 'Afternoon';
    } else {
      return 'Evening';
    }
  }
}

class ListEquality {
  bool equals(List<Map<String, dynamic>> a, List<Map<String, dynamic>> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i]['id'] != b[i]['id']) return false;
    }
    return true;
  }
}
