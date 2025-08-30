import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';
import 'package:playwaves/services/player_state_provider.dart';
import 'package:playwaves/services/jiosaavn_api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class RecentlyPlayedScreen extends StatefulWidget {
  const RecentlyPlayedScreen({Key? key}) : super(key: key);

  @override
  State<RecentlyPlayedScreen> createState() => _RecentlyPlayedScreenState();
}

class _RecentlyPlayedScreenState extends State<RecentlyPlayedScreen> {
  List<Map<String, dynamic>> _recentlyPlayed = [];
  bool _isLoading = true;
  final JioSaavnApiService _apiService = JioSaavnApiService();

  @override
  void initState() {
    super.initState();
    _loadRecentlyPlayed();
  }

  Future<void> _loadRecentlyPlayed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? recentlyPlayedJson = prefs.getString('recently_played');
      if (recentlyPlayedJson != null) {
        final List<dynamic> decoded = json.decode(recentlyPlayedJson);
        setState(() {
          _recentlyPlayed = decoded.cast<Map<String, dynamic>>();
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading recently played: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _playSong(Map<String, dynamic> song, [int? index]) async {
    final playerState = Provider.of<PlayerStateProvider>(context, listen: false);
    try {
      playerState.setSongLoading(true);

      final audioPlayer = Provider.of<AudioPlayer>(context, listen: false);
      await audioPlayer.stop();
      await audioPlayer.seek(Duration.zero);

      // Set playlist to recently played songs
      playerState.setPlaylist(_recentlyPlayed);
      
      // Set song index
      if (index != null) {
        playerState.setSongIndex(index);
      } else {
        final songIndex = _recentlyPlayed.indexWhere((s) => s['id'] == song['id']);
        playerState.setSongIndex(songIndex == -1 ? 0 : songIndex);
      }

      // Set current context
      playerState.setCurrentContext('recently_played');
      playerState.setSong(Map<String, dynamic>.from(song));

      final songId = song['id'];
      if (songId != null) {
        final songDetails = await _apiService.getSongById(songId);
        final songData = songDetails['data']?[0];

        if (songData != null) {
          playerState.setSong(Map<String, dynamic>.from(songData));
          
          // Use PlayerStateProvider's quality-aware URL selection
          final downloadUrl = playerState.getPlayableUrlForSong(songData);

          if (downloadUrl != null && downloadUrl.isNotEmpty) {
            if (downloadUrl.contains('preview.saavncdn.com') ||
                downloadUrl.contains('aac.saavncdn.com')) {
              await audioPlayer.setAudioSource(
                AudioSource.uri(
                  Uri.parse(downloadUrl),
                  tag: MediaItem(
                    id: songId ?? '',
                    album: songData['album']?['name'] ?? songData['album'] ?? '',
                    title: songData['title'] ?? songData['name'] ?? '',
                    artist: _getArtistName(songData),
                    artUri: _getArtUri(songData),
                  ),
                ),
              );
              await audioPlayer.play();
              playerState.setPlaying(true);
              
              // Add quality feedback
              final quality = playerState.audioQuality ?? 'High (320 kbps)';
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Playing in $quality quality'),
                  duration: const Duration(seconds: 2),
                  backgroundColor: Colors.green,
                ),
              );
            } else {
              throw Exception('Invalid audio URL format');
            }
          } else {
            throw Exception('No download URL found');
          }
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error playing song: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      playerState.setSongLoading(false);
    }
  }

  String _getArtistName(Map<String, dynamic> songData) {
    if (songData['artists'] != null &&
        songData['artists'] is Map &&
        songData['artists']['primary'] is List &&
        (songData['artists']['primary'] as List).isNotEmpty) {
      return songData['artists']['primary'][0]['name'] ?? '';
    } else if (songData['primaryArtists'] != null) {
      return songData['primaryArtists'].toString();
    } else if (songData['subtitle'] != null) {
      return songData['subtitle'].toString();
    }
    return 'Unknown Artist';
  }

  Uri? _getArtUri(Map<String, dynamic> songData) {
    final imageField = songData['image'];
    if (imageField is List && imageField.isNotEmpty) {
      final img = imageField.last ?? imageField.first;
      if (img is String) {
        return Uri.parse(img);
      } else if (img is Map && img['url'] != null) {
        return Uri.parse(img['url']);
      } else if (img is Map && img['link'] != null) {
        return Uri.parse(img['link']);
      }
    } else if (imageField is String) {
      return Uri.parse(imageField);
    }
    return null;
  }

  String _getBestImageUrl(dynamic images) {
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
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerStateProvider>(
      builder: (context, playerState, child) {
        return Scaffold(
          backgroundColor: const Color(0xFF1a1a1a),
          appBar: AppBar(
            backgroundColor: const Color(0xFF1a1a1a),
            elevation: 0,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Recently Played',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Quality: ${playerState.audioQuality ?? "High (320 kbps)"}',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFFff7d78),
                  ),
                )
              : _recentlyPlayed.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.history,
                            color: Colors.grey[400],
                            size: 64,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No recently played songs',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Start playing some music to see your history here',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _recentlyPlayed.length,
                      itemBuilder: (context, index) {
                        final song = _recentlyPlayed[index];
                        final isCurrentSong = playerState.currentSong?['id'] == song['id'];
                        
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: isCurrentSong 
                                ? const Color(0xFFff7d78).withOpacity(0.1)
                                : Colors.grey[900],
                            borderRadius: BorderRadius.circular(12),
                            border: isCurrentSong 
                                ? Border.all(color: const Color(0xFFff7d78), width: 1)
                                : null,
                          ),
                          child: ListTile(
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                _getBestImageUrl(song['image']) ,
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  width: 50,
                                  height: 50,
                                  color: Colors.grey[800],
                                  child: const Icon(
                                    Icons.music_note,
                                    color: Colors.white54,
                                  ),
                                ),
                              ),
                            ),
                            title: Text(
                              song['title'] ?? song['name'] ?? 'Unknown Song',
                              style: TextStyle(
                                color: isCurrentSong ? const Color(0xFFff7d78) : Colors.white,
                                fontWeight: isCurrentSong ? FontWeight.w600 : FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              _getArtistName(song),
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: isCurrentSong && playerState.isPlaying
                                ? const Icon(
                                    Icons.equalizer,
                                    color: Color(0xFFff7d78),
                                  )
                                : const Icon(
                                    Icons.play_arrow,
                                    color: Colors.white54,
                                  ),
                            onTap: () => _playSong(song, index),
                          ),
                        );
                      },
                    ),
        );
      },
    );
  }
}