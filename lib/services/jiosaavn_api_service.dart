import 'dart:convert';
import 'package:http/http.dart' as http;

class JioSaavnApiService {
  static const String baseUrl = 'https://saavn.dev/api';

  // ---- GLOBAL SEARCH (songs, albums, artists, playlists, topQuery) ----
  Future<Map<String, dynamic>> globalSearch(String query) async {
    final url = Uri.parse('$baseUrl/search?query=$query');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Global search failed');
    }
  }

  // ---- SONG SEARCH ----
  Future<Map<String, dynamic>> searchSongs(
    String query, {
    int page = 0,
    int limit = 10,
  }) async {
    final url = Uri.parse(
      '$baseUrl/search/songs?query=$query&page=$page&limit=$limit',
    );
    final response = await http.get(url);
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Song search failed');
    }
  }

  // ---- ALBUM SEARCH ----
  Future<Map<String, dynamic>> searchAlbums(
    String query, {
    int page = 0,
    int limit = 10,
  }) async {
    final url = Uri.parse(
      '$baseUrl/search/albums?query=$query&page=$page&limit=$limit',
    );
    final response = await http.get(url);
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Album search failed');
    }
  }

  // ---- ARTIST SEARCH ----
  Future<Map<String, dynamic>> searchArtists(
    String query, {
    int page = 0,
    int limit = 10,
  }) async {
    final url = Uri.parse(
      '$baseUrl/search/artists?query=$query&page=$page&limit=$limit',
    );
    final response = await http.get(url);
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Artist search failed');
    }
  }

  // ---- PLAYLIST SEARCH ----
  Future<Map<String, dynamic>> searchPlaylists(
    String query, {
    int page = 0,
    int limit = 10,
  }) async {
    final url = Uri.parse(
      '$baseUrl/search/playlists?query=$query&page=$page&limit=$limit',
    );
    final response = await http.get(url);
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Playlist search failed');
    }
  }

  // ---- GET SONG(S) BY ID OR LINK ----
  Future<Map<String, dynamic>> getSongs({
    List<String>? ids,
    String? link,
  }) async {
    String params = '';
    if (ids != null && ids.isNotEmpty) {
      params += 'ids=${ids.join(',')}';
    }
    if (link != null && link.isNotEmpty) {
      if (params.isNotEmpty) params += '&';
      params += 'link=${Uri.encodeComponent(link)}';
    }
    final url = Uri.parse('$baseUrl/songs?$params');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Fetching song(s) failed');
    }
  }

  // ---- GET SONG BY ID (with optional lyrics) ----
  Future<Map<String, dynamic>> getSongById(
    String songId, {
    bool lyrics = false,
  }) async {
    final url = Uri.parse('$baseUrl/songs/$songId?lyrics=$lyrics');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Fetching song by ID failed');
    }
  }

  // ---- GET SONG LYRICS ----
  Future<Map<String, dynamic>> getSongLyrics(String songId) async {
    final url = Uri.parse('$baseUrl/songs/$songId/lyrics');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Fetching lyrics failed');
    }
  }

  // ---- GET SONG SUGGESTIONS ----
  Future<Map<String, dynamic>> getSongSuggestions(
    String songId, {
    int limit = 10,
  }) async {
    final url = Uri.parse('$baseUrl/songs/$songId/suggestions?limit=$limit');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Fetching suggestions failed');
    }
  }

  // ---- GET ALBUM BY ID OR LINK ----
  Future<Map<String, dynamic>> getAlbum({String? id, String? link}) async {
    String params = '';
    if (id != null && id.isNotEmpty) {
      params += 'id=$id';
    }
    if (link != null && link.isNotEmpty) {
      if (params.isNotEmpty) params += '&';
      params += 'link=${Uri.encodeComponent(link)}';
    }
    final url = Uri.parse('$baseUrl/albums?$params');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Fetching album failed');
    }
  }

  // ---- GET ARTIST BY ID OR LINK ----
  Future<Map<String, dynamic>> getArtist({
    String? id,
    String? link,
    int page = 0,
    int songCount = 10,
    int albumCount = 10,
    String? sortBy,
    String sortOrder = 'desc',
  }) async {
    String params = '';
    if (id != null && id.isNotEmpty) params += 'id=$id';
    if (link != null && link.isNotEmpty)
      params +=
          '${params.isNotEmpty ? '&' : ''}link=${Uri.encodeComponent(link)}';
    params +=
        '${params.isNotEmpty ? '&' : ''}page=$page&songCount=$songCount&albumCount=$albumCount';
    if (sortBy != null && sortBy.isNotEmpty) params += '&sortBy=$sortBy';
    params += '&sortOrder=$sortOrder';
    final url = Uri.parse('$baseUrl/artists?$params');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Fetching artist failed');
    }
  }

  // ---- GET ARTIST BY ID (detailed) ----
  Future<Map<String, dynamic>> getArtistById(
    String artistId, {
    int page = 0,
    int songCount = 10,
    int albumCount = 10,
    String? sortBy,
    String sortOrder = 'desc',
  }) async {
    String params = 'page=$page&songCount=$songCount&albumCount=$albumCount';
    if (sortBy != null && sortBy.isNotEmpty) params += '&sortBy=$sortBy';
    params += '&sortOrder=$sortOrder';
    final url = Uri.parse('$baseUrl/artists/$artistId?$params');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Fetching artist by ID failed');
    }
  }

  // ---- GET ARTIST'S SONGS ----
  Future<Map<String, dynamic>> getArtistSongs(
    String artistId, {
    int page = 0,
    String sortBy = 'popularity',
    String sortOrder = 'desc',
  }) async {
    final url = Uri.parse(
      '$baseUrl/artists/$artistId/songs?page=$page&sortBy=$sortBy&sortOrder=$sortOrder',
    );
    final response = await http.get(url);
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Fetching artist songs failed');
    }
  }

  // ---- GET ARTIST'S ALBUMS ----
  Future<Map<String, dynamic>> getArtistAlbums(
    String artistId, {
    int page = 0,
    String sortBy = 'popularity',
    String sortOrder = 'desc',
  }) async {
    final url = Uri.parse(
      '$baseUrl/artists/$artistId/albums?page=$page&sortBy=$sortBy&sortOrder=$sortOrder',
    );
    final response = await http.get(url);
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Fetching artist albums failed');
    }
  }

  // ---- GET PLAYLIST BY ID OR LINK ----
  Future<Map<String, dynamic>> getPlaylist({
    String? id,
    String? link,
    int page = 0,
    int limit = 10,
  }) async {
    String params = '';
    if (id != null && id.isNotEmpty) params += 'id=$id';
    if (link != null && link.isNotEmpty)
      params +=
          '${params.isNotEmpty ? '&' : ''}link=${Uri.encodeComponent(link)}';
    params += '${params.isNotEmpty ? '&' : ''}page=$page&limit=$limit';
    final url = Uri.parse('$baseUrl/playlists?$params');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Fetching playlist failed');
    }
  }

  // ---- UTILITY: Get best cover art url ----
  /// Picks the highest quality cover art available.
  /// Prefers "default", "high", "500x500", then largest dimension ("500x500", "150x150", etc.)
  String? getBestCoverArt(dynamic images) {
    if (images is List && images.isNotEmpty) {
      // Prefer "default", "high", or "500x500" quality
      for (var img in images) {
        final quality = (img['quality'] ?? '').toString().toLowerCase();
        if (quality == 'default' || quality == 'high' || quality == '500x500') {
          return img['url'];
        }
      }
      // Fallback: sort by largest dimensions (e.g., "500x500" > "150x150")
      images.sort((a, b) {
        int getPixels(String q) {
          final match = RegExp(r'(\d+)x(\d+)').firstMatch(q);
          if (match != null) {
            return int.parse(match.group(1)!) * int.parse(match.group(2)!);
          }
          return 0;
        }

        return getPixels(
          (b['quality'] ?? '').toString(),
        ).compareTo(getPixels((a['quality'] ?? '').toString()));
      });
      return images.first['url'];
    }
    return null;
  }
}
