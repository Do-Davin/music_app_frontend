import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:music_app_frontend/core/network/graphql_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/karaoke_song.dart';

class KaraokeRepository {
  static const String _storageKey = 'karaoke_songs';
  final GraphQLClient _client = GraphQLConfig.clientToQuery(
    authenticated: true,
  );

  Future<List<KaraokeSong>> getAllSongs() async {
    try {
      final result = await _client.query(
        QueryOptions(
          document: gql(_karaokeSongsQuery),
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      );

      if (result.hasException) {
        debugPrint(
          '❌ GraphQL Error fetching karaoke songs: ${result.exception}',
        );
        throw Exception(result.exception.toString());
      }

      final List<dynamic> data = result.data?['karaokeSongs'] ?? [];
      try {
        final songs = data
            .map((json) => KaraokeSong.fromJson(json as Map<String, dynamic>))
            .toList();

        await _saveLocalSongs(songs);
        debugPrint(
          '✅ Successfully loaded ${songs.length} karaoke songs from backend',
        );
        return songs;
      } catch (e) {
        debugPrint('❌ Error parsing karaoke songs: $e');
        rethrow;
      }
    } catch (e) {
      debugPrint('⚠️ Failed to fetch from backend, using local cache: $e');
      return _getLocalSongs();
    }
  }

  Future<void> saveSong(KaraokeSong song) async {
    await _saveLocalSong(song);

    try {
      final input = _toInput(song);

      final result = await _client.mutate(
        MutationOptions(
          document: gql(_createKaraokeSongMutation),
          variables: {'input': input},
        ),
      );

      if (result.hasException) {
        throw Exception('GraphQL Error: ${result.exception.toString()}');
      }

      if (result.data == null || result.data!['createKaraokeSong'] == null) {
        throw Exception('Backend did not return karaoke song data');
      }

      final saved = KaraokeSong.fromJson(
        result.data!['createKaraokeSong'] as Map<String, dynamic>,
      );
      await _saveLocalSong(saved);
    } catch (e) {
      // Log the error but keep the local song
      debugPrint('❌ Error saving to backend: $e');
      rethrow;
    }
  }

  Future<void> deleteSong(String id) async {
    final existing = await _getLocalSongs();
    existing.removeWhere((s) => s.id == id);
    await _saveLocalSongs(existing);

    try {
      final result = await _client.mutate(
        MutationOptions(
          document: gql(_removeKaraokeSongMutation),
          variables: {'id': id},
        ),
      );

      if (result.hasException) {
        throw Exception('GraphQL Error: ${result.exception.toString()}');
      }
    } catch (e) {
      debugPrint('❌ Error deleting from backend: $e');
      rethrow;
    }
  }

  Future<void> updateVisibility(String id, bool isPublic) async {
    final existing = await _getLocalSongs();
    final index = existing.indexWhere((s) => s.id == id);
    if (index >= 0) {
      existing[index] = existing[index].copyWith(isPublic: isPublic);
      await _saveLocalSongs(existing);
    }

    try {
      final result = await _client.mutate(
        MutationOptions(
          document: gql(_updateKaraokeSongVisibilityMutation),
          variables: {'id': id, 'isPublic': isPublic},
        ),
      );

      if (result.hasException) {
        throw Exception('GraphQL Error: ${result.exception.toString()}');
      }

      if (result.data != null && result.data!['updateKaraokeSongVisibility'] != null) {
        final updated = KaraokeSong.fromJson(
          result.data!['updateKaraokeSongVisibility'] as Map<String, dynamic>,
        );
        await _saveLocalSong(updated);
      }
    } catch (e) {
      debugPrint('❌ Error updating visibility on backend: $e');
      rethrow;
    }
  }


  Map<String, dynamic> _toInput(KaraokeSong song) {
    return {
      'title': song.title,
      'artist': song.artist,
      'source': song.source.name,
      'sourcePath': song.sourcePath,
      'lyrics': song.lyrics.map((line) {
        return {'timestamp': line.timestamp.inMilliseconds, 'text': line.text};
      }).toList(),
      'duration': song.duration?.inMilliseconds,
      'isPublic': song.isPublic,
    };
  }

  Future<List<KaraokeSong>> getPublicSongs() async {
    try {
      final result = await _client.query(
        QueryOptions(
          document: gql(_publicKaraokeSongsQuery),
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      );

      if (result.hasException) {
        throw Exception(result.exception.toString());
      }

      final List<dynamic> data = result.data?['publicKaraokeSongs'] ?? [];
      return data
          .map((json) => KaraokeSong.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('❌ Error fetching public karaoke songs: $e');
      return [];
    }
  }

  Future<List<KaraokeSong>> searchOwnSongs(String query) async {
    try {
      final result = await _client.query(
        QueryOptions(
          document: gql(_searchOwnKaraokeSongsQuery),
          variables: {'query': query},
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      );

      if (result.hasException) {
        throw Exception(result.exception.toString());
      }

      final List<dynamic> data = result.data?['searchOwnKaraokeSongs'] ?? [];
      return data
          .map((json) => KaraokeSong.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('❌ Error searching own karaoke songs: $e');
      return [];
    }
  }

  Future<List<KaraokeSong>> searchPublicSongs(String query) async {
    try {
      final result = await _client.query(
        QueryOptions(
          document: gql(_searchPublicKaraokeSongsQuery),
          variables: {'query': query},
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      );

      if (result.hasException) {
        throw Exception(result.exception.toString());
      }

      final List<dynamic> data = result.data?['searchPublicKaraokeSongs'] ?? [];
      return data
          .map((json) => KaraokeSong.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('❌ Error searching public karaoke songs: $e');
      return [];
    }
  }

  Future<List<KaraokeSong>> _getLocalSongs() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);

    if (jsonString == null) return [];

    final List<dynamic> decoded = jsonDecode(jsonString);
    return decoded.map((j) => KaraokeSong.fromJson(j)).toList();
  }

  Future<void> _saveLocalSong(KaraokeSong song) async {
    final existing = await _getLocalSongs();

    final index = existing.indexWhere((s) => s.id == song.id);
    if (index >= 0) {
      existing[index] = song;
    } else {
      existing.add(song);
    }

    await _saveLocalSongs(existing);
  }

  Future<void> _saveLocalSongs(List<KaraokeSong> songs) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(songs.map((s) => s.toJson()).toList());
    await prefs.setString(_storageKey, encoded);
  }

  static const String _karaokeSongsQuery = r'''
    query KaraokeSongs {
      karaokeSongs {
        _id
        userId
        title
        artist
        source
        sourcePath
        duration
        createdAt
        isPublic
        lyrics {
          timestamp
          text
        }
      }
    }
  ''';

  static const String _publicKaraokeSongsQuery = r'''
    query PublicKaraokeSongs {
      publicKaraokeSongs {
        _id
        userId
        title
        artist
        source
        sourcePath
        duration
        createdAt
        isPublic
        lyrics {
          timestamp
          text
        }
      }
    }
  ''';

  static const String _searchOwnKaraokeSongsQuery = r'''
    query SearchOwnKaraokeSongs($query: String!) {
      searchOwnKaraokeSongs(query: $query) {
        _id
        userId
        title
        artist
        source
        sourcePath
        duration
        createdAt
        isPublic
        lyrics {
          timestamp
          text
        }
      }
    }
  ''';

  static const String _searchPublicKaraokeSongsQuery = r'''
    query SearchPublicKaraokeSongs($query: String!) {
      searchPublicKaraokeSongs(query: $query) {
        _id
        userId
        title
        artist
        source
        sourcePath
        duration
        createdAt
        isPublic
        lyrics {
          timestamp
          text
        }
      }
    }
  ''';

  static const String _createKaraokeSongMutation = r'''
    mutation CreateKaraokeSong($input: CreateKaraokeSongInput!) {
      createKaraokeSong(input: $input) {
        _id
        userId
        title
        artist
        source
        sourcePath
        duration
        createdAt
        isPublic
        lyrics {
          timestamp
          text
        }
      }
    }
  ''';

  static const String _removeKaraokeSongMutation = r'''
    mutation RemoveKaraokeSong($id: ID!) {
      removeKaraokeSong(id: $id)
    }
  ''';

  static const String _updateKaraokeSongVisibilityMutation = r'''
    mutation UpdateKaraokeSongVisibility($id: ID!, $isPublic: Boolean!) {
      updateKaraokeSongVisibility(id: $id, isPublic: $isPublic) {
        _id
        userId
        title
        artist
        source
        sourcePath
        duration
        createdAt
        isPublic
        lyrics {
          timestamp
          text
        }
      }
    }
  ''';
}
