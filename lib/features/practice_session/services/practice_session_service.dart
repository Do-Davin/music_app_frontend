import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:music_app_frontend/core/network/graphql_config.dart';
import 'package:music_app_frontend/core/network/queries.dart';
import 'package:music_app_frontend/features/practice_session/models/practice_session.dart';

class PracticeSessionService {
  final GraphQLClient _client = GraphQLConfig.clientToQuery();

  Future<List<PracticeSession>> fetchAllSessions() async {
    final result = await _client.query(
      QueryOptions(
        document: gql(PracticeSessionQueries.getAllPracticeSessions),
      ),
    );

    if (result.hasException) {
      throw Exception(result.exception.toString());
    }

    final List<dynamic> data = result.data?['practiceSessions'] ?? [];
    return data.map((json) => PracticeSession.fromJson(json)).toList();
  }

  Future<PracticeSession> fetchSessionById(String id) async {
    final result = await _client.query(
      QueryOptions(
        document: gql(PracticeSessionQueries.getPracticeSessionById),
        variables: {'id': id},
      ),
    );

    if (result.hasException) {
      throw Exception(result.exception.toString());
    }

    return PracticeSession.fromJson(result.data!['practiceSession']);
  }

  Future<PracticeSession> createSession({
    required String title,
    required DateTime practiceDate,
    required int duration,
    required String focusArea,
    required int rating,
    String? notes,
  }) async {
    final input = {
      'title': title,
      'practiceDate': practiceDate.toIso8601String(),
      'duration': duration,
      'focusArea': focusArea,
      'rating': rating,
    };
    if (notes != null && notes.isNotEmpty) {
      input['notes'] = notes;
    }

    final result = await _client.mutate(
      MutationOptions(
        document: gql(PracticeSessionMutations.createPracticeSession),
        variables: {'input': input},
      ),
    );

    if (result.hasException) {
      throw Exception(result.exception.toString());
    }

    return PracticeSession.fromJson(result.data!['createPracticeSession']);
  }

  Future<PracticeSession> updateSession(
    String id, {
    String? title,
    DateTime? practiceDate,
    int? duration,
    String? focusArea,
    int? rating,
    String? notes,
  }) async {
    final input = <String, dynamic>{};
    if (title != null) {
      input['title'] = title;
    }
    if (practiceDate != null) {
      input['practiceDate'] = practiceDate.toIso8601String();
    }
    if (duration != null) {
      input['duration'] = duration;
    }
    if (focusArea != null) {
      input['focusArea'] = focusArea;
    }
    if (rating != null) {
      input['rating'] = rating;
    }
    if (notes != null) {
      input['notes'] = notes;
    }

    final result = await _client.mutate(
      MutationOptions(
        document: gql(PracticeSessionMutations.updatePracticeSession),
        variables: {'id': id, 'input': input},
      ),
    );

    if (result.hasException) {
      throw Exception(result.exception.toString());
    }

    return PracticeSession.fromJson(result.data!['updatePracticeSession']);
  }

  Future<bool> deleteSession(String id) async {
    final result = await _client.mutate(
      MutationOptions(
        document: gql(PracticeSessionMutations.deletePracticeSession),
        variables: {'id': id},
      ),
    );

    if (result.hasException) {
      throw Exception(result.exception.toString());
    }

    return result.data!['deletePracticeSession'] as bool;
  }
}
