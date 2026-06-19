import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:music_app_frontend/core/network/graphql_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:music_app_frontend/features/auth/data/services/user_service.dart';
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
    };
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
        title
        artist
        source
        sourcePath
        duration
        createdAt
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
        title
        artist
        source
        sourcePath
        duration
        createdAt
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
}
