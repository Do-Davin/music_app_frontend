import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:music_app_frontend/core/network/graphql_config.dart';
import 'package:music_app_frontend/core/network/queries/index.dart';
import 'package:music_app_frontend/features/playlist/models/playlist.dart';
import 'package:music_app_frontend/features/song/models/song.dart';

class LikedSongsPlaylistResponse {
  final Playlist playlist;
  final List<Song> songs;

  LikedSongsPlaylistResponse({required this.playlist, required this.songs});
}

class LikedSongsService {
  final GraphQLClient _client = GraphQLConfig.clientToQuery(
    authenticated: true,
  );

  Future<List<Song>> fetchLikedSongs() async {
    final result = await _client.query(
      QueryOptions(
        document: gql(UserQueries.likedSongs),
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );

    if (result.hasException) {
      throw Exception(result.exception.toString());
    }

    final List<dynamic> data = result.data?['likedSongs'] ?? [];
    return data.map((json) => Song.fromJson(json)).toList();
  }

  Future<LikedSongsPlaylistResponse> fetchLikedSongsPlaylist() async {
    final result = await _client.query(
      QueryOptions(
        document: gql(PlaylistQueries.likedSongsPlaylist),
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );

    if (result.hasException) {
      throw Exception(result.exception.toString());
    }

    final Map<String, dynamic> raw = result.data?['likedSongsPlaylist'] ?? {};
    final playlist = Playlist.fromJson(raw);
    final List<dynamic> rawSongs = raw['songs'] ?? [];
    final songs = rawSongs.map((s) => Song.fromJson(s)).toList();

    return LikedSongsPlaylistResponse(playlist: playlist, songs: songs);
  }

  Future<void> toggleLikeSong(String songId) async {
    final result = await _client.mutate(
      MutationOptions(
        document: gql(UserMutations.toggleLikeSong),
        variables: {'songId': songId},
      ),
    );

    if (result.hasException) {
      throw Exception(result.exception.toString());
    }
  }
}
