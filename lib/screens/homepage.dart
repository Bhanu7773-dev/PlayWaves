import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:just_audio/just_audio.dart';
import 'package:marquee/marquee.dart';
import 'package:playwaves/widgets/animated_navbar_player.dart';
import 'package:playwaves/widgets/music_player.dart';

// Album Card Model (for future API use)
class AlbumCardData {
  final String title;
  final String artist;
  final String coverUrl;
  AlbumCardData({
    required this.title,
    required this.artist,
    required this.coverUrl,
  });
}

// Artist Card Model (for future API use)
class ArtistCardData {
  final String name;
  final String imageUrl;
  ArtistCardData({required this.name, required this.imageUrl});
}

// Genre Model
class GenreData {
  final String name;
  final IconData icon;
  final Color color;
  GenreData({required this.name, required this.icon, required this.color});
}

class HomePage extends StatefulWidget {
  final String username;
  const HomePage({super.key, this.username = "User Name"});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  final List<AlbumCardData> albums = [
    AlbumCardData(
      title: "Midnight Memories",
      artist: "One Direction",
      coverUrl:
          "https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?auto=format&fit=crop&w=400&q=80",
    ),
    AlbumCardData(
      title: "Evermore",
      artist: "Taylor Swift",
      coverUrl:
          "https://images.unsplash.com/photo-1465101046530-73398c7f28ca?auto=format&fit=crop&w=400&q=80",
    ),
    AlbumCardData(
      title: "Divide",
      artist: "Ed Sheeran",
      coverUrl:
          "https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=400&q=80",
    ),
    AlbumCardData(
      title: "After Hours",
      artist: "The Weeknd",
      coverUrl:
          "https://images.unsplash.com/photo-1465101178521-c1a9136a03d4?auto=format&fit=crop&w=400&q=80",
    ),
  ];

  final List<ArtistCardData> artists = [
    ArtistCardData(
      name: "Taylor Swift",
      imageUrl: "https://randomuser.me/api/portraits/women/44.jpg",
    ),
    ArtistCardData(
      name: "Ed Sheeran",
      imageUrl: "https://randomuser.me/api/portraits/men/36.jpg",
    ),
    ArtistCardData(
      name: "The Weeknd",
      imageUrl: "https://randomuser.me/api/portraits/men/65.jpg",
    ),
    ArtistCardData(
      name: "Ariana Grande",
      imageUrl: "https://randomuser.me/api/portraits/women/68.jpg",
    ),
    ArtistCardData(
      name: "Billie Eilish",
      imageUrl: "https://randomuser.me/api/portraits/women/79.jpg",
    ),
    ArtistCardData(
      name: "Drake",
      imageUrl: "https://randomuser.me/api/portraits/men/41.jpg",
    ),
    ArtistCardData(
      name: "Shawn Mendes",
      imageUrl: "https://randomuser.me/api/portraits/men/29.jpg",
    ),
    ArtistCardData(
      name: "Dua Lipa",
      imageUrl: "https://randomuser.me/api/portraits/women/53.jpg",
    ),
  ];

  final List<GenreData> genres = [
    GenreData(name: "Pop", icon: Icons.music_note, color: Colors.pinkAccent),
    GenreData(name: "Rock", icon: Icons.rocket_launch, color: Colors.redAccent),
    GenreData(name: "Hip-Hop", icon: Icons.headphones, color: Colors.orange),
    GenreData(name: "Jazz", icon: Icons.spa, color: Colors.teal),
    GenreData(name: "EDM", icon: Icons.graphic_eq, color: Colors.indigoAccent),
    GenreData(
      name: "Classical",
      icon: Icons.library_music,
      color: Colors.green,
    ),
    GenreData(name: "Indie", icon: Icons.star_border, color: Colors.deepPurple),
    GenreData(name: "Country", icon: Icons.landscape, color: Colors.brown),
    GenreData(name: "Reggae", icon: Icons.sunny, color: Colors.yellow[800]!),
    GenreData(name: "Metal", icon: Icons.flash_on, color: Colors.grey),
  ];

  final PageController _albumPageController = PageController(
    viewportFraction: 0.89,
    initialPage: 0,
  );
  int _currentAlbumPage = 0;
  late AnimationController _autoScrollController;

  final List<AlbumCardData> trendingAlbums = [
    AlbumCardData(
      title: "Happier Than Ever",
      artist: "Billie Eilish",
      coverUrl:
          "https://images.unsplash.com/photo-1453090927415-5f45085b65c0?auto=format&fit=crop&w=400&q=80",
    ),
    AlbumCardData(
      title: "Future Nostalgia",
      artist: "Dua Lipa",
      coverUrl:
          "https://images.unsplash.com/photo-1465101178521-c1a9136a03d4?auto=format&fit=crop&w=400&q=80",
    ),
    AlbumCardData(
      title: "No.6 Collaborations Project",
      artist: "Ed Sheeran",
      coverUrl:
          "https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=400&q=80",
    ),
    AlbumCardData(
      title: "Positions",
      artist: "Ariana Grande",
      coverUrl:
          "https://images.unsplash.com/photo-1465101046530-73398c7f28ca?auto=format&fit=crop&w=400&q=80",
    ),
  ];

  // --------- MUSIC PLAYER STATE & LOGIC FOR DEMO ---------
  bool isPlaying = true;
  String songTitle = "Midnight Memories";
  String artistName = "One Direction";
  String albumArtUrl =
      "https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?auto=format&fit=crop&w=400&q=80";
  Duration currentPosition = Duration(seconds: 0);
  Duration totalDuration = Duration(minutes: 3, seconds: 32);

  int _selectedNavIndex = 0;

  @override
  void initState() {
    super.initState();
    _albumPageController.addListener(() {
      int page = _albumPageController.page?.round() ?? 0;
      if (_currentAlbumPage != page) {
        setState(() {
          _currentAlbumPage = page;
        });
      }
    });

    _autoScrollController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 3),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAutoScrollAlbums();
    });
  }

  void _startAutoScrollAlbums() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 3));
      if (!mounted) return false;
      int nextPage = (_currentAlbumPage + 1) % albums.length;
      if (_albumPageController.hasClients) {
        _albumPageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeIn,
        );
      }
      return mounted;
    });
  }

  @override
  void dispose() {
    _albumPageController.dispose();
    _autoScrollController.dispose();
    super.dispose();
  }

  // --- MUSIC PLAYER CALLBACKS ---
  void onPlayPause() => setState(() => isPlaying = !isPlaying);
  void onNext() {
    setState(() {
      int nextIndex =
          (albums.indexWhere((a) => a.title == songTitle) + 1) % albums.length;
      songTitle = albums[nextIndex].title;
      artistName = albums[nextIndex].artist;
      albumArtUrl = albums[nextIndex].coverUrl;
      currentPosition = Duration(seconds: 0);
    });
  }

  void onPrevious() {
    setState(() {
      int prevIndex = (albums.indexWhere((a) => a.title == songTitle) - 1);
      if (prevIndex < 0) prevIndex = albums.length - 1;
      songTitle = albums[prevIndex].title;
      artistName = albums[prevIndex].artist;
      albumArtUrl = albums[prevIndex].coverUrl;
      currentPosition = Duration(seconds: 0);
    });
  }

  void onSeek(double value) {
    setState(() {
      currentPosition = Duration(
        seconds: (totalDuration.inSeconds * value).round(),
      );
    });
  }

  // --- OPEN FULL PLAYER PAGE ---
  void openFullPlayer() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MusicPlayerPage(
          songTitle: songTitle,
          artistName: artistName,
          albumArtUrl: albumArtUrl,
          isPlaying: isPlaying,
          currentPosition: currentPosition,
          totalDuration: totalDuration,
          onPlayPause: onPlayPause,
          onNext: onNext,
          onPrevious: onPrevious,
          onSeek: onSeek,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<_FeatureCardData> featureCards = [
      _FeatureCardData(
        title: "Most played",
        icon: Clarity.play_line,
        color: Colors.orangeAccent,
      ),
      _FeatureCardData(
        title: "History",
        icon: Clarity.history_line,
        color: Colors.grey[400]!,
      ),
      _FeatureCardData(
        title: "Favourite",
        icon: Clarity.favorite_line,
        color: Colors.pinkAccent,
      ),
      _FeatureCardData(
        title: "Playlists",
        icon: Clarity.folder_line,
        color: Colors.blueAccent,
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Clarity.search_line, color: Colors.white),
          onPressed: () {},
        ),
        title: RichText(
          text: TextSpan(
            children: [
              const TextSpan(
                text: 'Play',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 22,
                ),
              ),
              TextSpan(
                text: 'Waves',
                style: TextStyle(
                  color: Colors.blueAccent,
                  fontWeight: FontWeight.w600,
                  fontSize: 22,
                ),
              ),
            ],
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Clarity.devices_line, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Clarity.settings_line, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: Stack(
        children: [
          // Main Home Page Content
          ListView(
            children: [
              Padding(
                padding: const EdgeInsets.only(
                  left: 22.0,
                  top: 18.0,
                  bottom: 8.0,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.account_circle_outlined,
                      color: Colors.blueAccent,
                      size: 45,
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Welcome,",
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            height: 1.0,
                          ),
                        ),
                        Text(
                          widget.username,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 270,
                child: Column(
                  children: [
                    SizedBox(
                      height: 210,
                      child: PageView.builder(
                        controller: _albumPageController,
                        itemCount: albums.length,
                        itemBuilder: (context, index) {
                          final album = albums[index];
                          final isCurrent = index == _currentAlbumPage;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOut,
                            margin: EdgeInsets.symmetric(
                              horizontal: isCurrent ? 7 : 13,
                              vertical: isCurrent ? 0 : 18,
                            ),
                            child: Material(
                              elevation: isCurrent ? 9 : 0,
                              borderRadius: BorderRadius.circular(28),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(28),
                                  image: DecorationImage(
                                    image: NetworkImage(album.coverUrl),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                child: Stack(
                                  children: [
                                    Positioned(
                                      bottom: 0,
                                      left: 0,
                                      right: 0,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.vertical(
                                            bottom: Radius.circular(28),
                                          ),
                                          color: Colors.black.withOpacity(0.55),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                          horizontal: 18,
                                        ),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    album.title,
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 18,
                                                      letterSpacing: 1,
                                                    ),
                                                  ),
                                                  Text(
                                                    album.artist,
                                                    style: TextStyle(
                                                      color: Colors.white
                                                          .withOpacity(0.88),
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            // Play Button
                                            IconButton(
                                              icon: Container(
                                                decoration: BoxDecoration(
                                                  color: Colors.blueAccent,
                                                  shape: BoxShape.circle,
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.blueAccent
                                                          .withOpacity(0.3),
                                                      blurRadius: 8,
                                                    ),
                                                  ],
                                                ),
                                                child: const Icon(
                                                  Icons.play_arrow_rounded,
                                                  color: Colors.white,
                                                  size: 38,
                                                ),
                                              ),
                                              onPressed: () {
                                                setState(() {
                                                  isPlaying = true;
                                                  songTitle = album.title;
                                                  artistName = album.artist;
                                                  albumArtUrl = album.coverUrl;
                                                  currentPosition = Duration(
                                                    seconds: 0,
                                                  );
                                                });
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                    AlbumSliderDots(
                      count: albums.length,
                      current: _currentAlbumPage,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18.0,
                  vertical: 1.0,
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: _FeatureCard(data: featureCards[0])),
                        const SizedBox(width: 12),
                        Expanded(child: _FeatureCard(data: featureCards[1])),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _FeatureCard(data: featureCards[2])),
                        const SizedBox(width: 12),
                        Expanded(child: _FeatureCard(data: featureCards[3])),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 6.0,
                ),
                child: Row(
                  children: [
                    const Text(
                      "Suggestions",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(
                        Clarity.refresh_line,
                        color: Colors.white,
                        size: 25,
                      ),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 18.0, vertical: 0.0),
                child: CustomSuggestionsGrid(),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.only(left: 20.0, top: 0, bottom: 0),
                child: const Text(
                  "Top artists",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 120,
                child: ListView.separated(
                  padding: const EdgeInsets.only(left: 20, top: 0, bottom: 0),
                  scrollDirection: Axis.horizontal,
                  itemCount: artists.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 22),
                  itemBuilder: (context, index) {
                    final artist = artists[index];
                    return Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.blueAccent.withOpacity(0.7),
                              width: 2.5,
                            ),
                            image: DecorationImage(
                              image: NetworkImage(artist.imageUrl),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(height: 9),
                        SizedBox(
                          width: 80,
                          child: Text(
                            artist.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.only(left: 20.0, bottom: 6.0),
                child: const Text(
                  "Genres",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(
                height: 52,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(left: 20.0, right: 10.0),
                  itemCount: genres.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 15),
                  itemBuilder: (context, index) {
                    final genre = genres[index];
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: genre.color.withOpacity(0.13),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: genre.color.withOpacity(0.34),
                          width: 1.3,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(genre.icon, color: genre.color, size: 22),
                          const SizedBox(width: 8),
                          Text(
                            genre.name,
                            style: TextStyle(
                              color: genre.color,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 28),
              Padding(
                padding: const EdgeInsets.only(left: 20.0, bottom: 8.0),
                child: const Text(
                  "Trending Albums",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(
                height: 188,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(left: 20, right: 10, top: 10),
                  itemCount: trendingAlbums.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 16),
                  itemBuilder: (context, index) {
                    final album = trendingAlbums[index];
                    return Container(
                      width: 145,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        image: DecorationImage(
                          image: NetworkImage(album.coverUrl),
                          fit: BoxFit.cover,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.18),
                            blurRadius: 18,
                            offset: const Offset(2, 10),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            height: 60,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.vertical(
                                  bottom: Radius.circular(20),
                                ),
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.black.withOpacity(0.85),
                                    Colors.black.withOpacity(0.0),
                                  ],
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            left: 12,
                            bottom: 20,
                            right: 12,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        album.title,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          height: 1.1,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        album.artist,
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.82),
                                          fontSize: 13,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  margin: const EdgeInsets.only(bottom: 2),
                                  child: IconButton(
                                    icon: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.blueAccent,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.blueAccent
                                                .withOpacity(0.36),
                                            blurRadius: 7,
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.play_arrow_rounded,
                                        color: Colors.white,
                                        size: 26,
                                      ),
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        isPlaying = true;
                                        songTitle = album.title;
                                        artistName = album.artist;
                                        albumArtUrl = album.coverUrl;
                                        currentPosition = Duration(seconds: 0);
                                      });
                                    },
                                    padding: EdgeInsets.zero,
                                    constraints: BoxConstraints(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 28),
            ],
          ),
          // Floating Nav Bar At Bottom (transparent below)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AnimatedPlayerNavBar(
              isPlaying: isPlaying,
              songTitle: songTitle,
              albumArtUrl: albumArtUrl,
              onPlayPause: onPlayPause,
              selectedIndex: _selectedNavIndex,
              onNavTap: (i) => setState(() => _selectedNavIndex = i),
              onMiniPlayerTap: openFullPlayer,
              navIcons: [
                Icons.home,
                Icons.search,
                Icons.playlist_play,
                Icons.bar_chart,
                Icons.person_outline,
              ],
              navLabels: ["Home", "Search", "Playlist", "Usage", "Profile"],
            ),
          ),
        ],
      ),
    );
  }
}

class AlbumSliderDots extends StatelessWidget {
  final int count;
  final int current;
  const AlbumSliderDots({
    super.key,
    required this.count,
    required this.current,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: i == current ? 20 : 9,
          height: 9,
          decoration: BoxDecoration(
            color: i == current ? Colors.blueAccent : Colors.white24,
            borderRadius: BorderRadius.circular(9),
          ),
        );
      }),
    );
  }
}

class _FeatureCardData {
  final String title;
  final IconData icon;
  final Color color;
  _FeatureCardData({
    required this.title,
    required this.icon,
    required this.color,
  });
}

class _FeatureCard extends StatelessWidget {
  final _FeatureCardData data;
  const _FeatureCard({required this.data});
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
        child: Row(
          children: [
            Icon(data.icon, color: data.color, size: 22),
            const SizedBox(width: 10),
            Text(
              data.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CustomSuggestionsGrid extends StatelessWidget {
  const CustomSuggestionsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final double panelWidth = MediaQuery.of(context).size.width - 2 * 18;
    const double gap = 12;
    final double x = (panelWidth - 4 * gap) / 5.1;
    final double small = x;
    final double big = 2 * x + gap;
    final double rectW = 2 * x + gap;
    final double rectH = x;
    final double circle = 1.1 * x;

    final double bottomRowTop = big + gap;
    final double bottomRectBottom = bottomRowTop + rectH;
    final double circleBottom = big + gap + (rectH / 2) + (circle / 2);

    final double gridHeight = circleBottom > bottomRectBottom
        ? circleBottom
        : bottomRectBottom;

    return SizedBox(
      width: panelWidth,
      height: gridHeight,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            width: big,
            height: big,
            child: _SuggestionCover(
              borderRadius: BorderRadius.circular(18),
              gradient: [Colors.blueGrey[900]!, Colors.blue[800]!],
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Text(
                  "New\nMusic\nMix",
                  style: TextStyle(
                    color: Colors.lightBlue[100],
                    fontWeight: FontWeight.bold,
                    fontSize: 19,
                    height: 1.1,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: big + gap,
            top: 0,
            width: small,
            height: small,
            child: _SuggestionCover(
              image:
                  "https://images.unsplash.com/photo-1465101046530-73398c7f28ca?auto=format&fit=crop&w=400&q=80",
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          Positioned(
            left: big + gap + small + gap,
            top: 0,
            width: rectW,
            height: rectH,
            child: _SuggestionCover(
              image:
                  "https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?auto=format&fit=crop&w=400&q=80",
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          Positioned(
            left: big + gap,
            top: small + gap,
            width: small,
            height: small,
            child: _SuggestionCover(
              image:
                  "https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=400&q=80",
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          Positioned(
            left: big + gap + small + gap,
            top: small + gap,
            width: small,
            height: small,
            child: _SuggestionCover(
              image:
                  "https://images.unsplash.com/photo-1465101178521-c1a9136a03d4?auto=format&fit=crop&w=400&q=80",
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          Positioned(
            left: big + gap + 2 * (small + gap),
            top: rectH + gap,
            width: small,
            height: small,
            child: _SuggestionCover(
              image:
                  "https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?auto=format&fit=crop&w=400&q=80",
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          Positioned(
            left: 0,
            top: big + gap,
            width: small,
            height: small,
            child: _SuggestionCover(
              image:
                  "https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=400&q=80",
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          Positioned(
            left: small + gap,
            top: big + gap,
            width: small,
            height: small,
            child: _SuggestionCover(
              image:
                  "https://images.unsplash.com/photo-1465101178521-c1a9136a03d4?auto=format&fit=crop&w=400&q=80",
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          Positioned(
            left: 2 * (small + gap),
            top: big + gap,
            width: rectW,
            height: rectH,
            child: _SuggestionCover(
              image:
                  "https://images.unsplash.com/photo-1465101046530-73398c7f28ca?auto=format&fit=crop&w=400&q=80",
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          Positioned(
            left: 2 * (small + gap) + rectW + gap,
            top: big + gap + (rectH / 2) - (circle / 2),
            width: circle,
            height: circle,
            child: _SuggestionCover(
              isCircle: true,
              image:
                  "https://images.unsplash.com/photo-1465101178521-c1a9136a03d4?auto=format&fit=crop&w=400&q=80",
            ),
          ),
        ],
      ),
    );
  }
}

class _SuggestionCover extends StatelessWidget {
  final double? width;
  final double? height;
  final Widget? child;
  final List<Color>? gradient;
  final String? image;
  final bool isCircle;
  final BorderRadius? borderRadius;

  const _SuggestionCover({
    this.width,
    this.height,
    this.child,
    this.gradient,
    this.image,
    this.isCircle = false,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasImage = image != null && image!.isNotEmpty;
    final bool hasGradient = gradient != null && gradient!.isNotEmpty;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: isCircle
            ? null
            : (borderRadius ?? BorderRadius.circular(13)),
        gradient: hasGradient
            ? LinearGradient(
                colors: gradient!,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        image: hasImage
            ? DecorationImage(image: NetworkImage(image!), fit: BoxFit.cover)
            : null,
      ),
      child: child,
    );
  }
}
