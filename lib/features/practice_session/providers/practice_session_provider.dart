import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:music_app_frontend/features/practice_session/models/practice_session.dart';
import 'package:music_app_frontend/features/practice_session/services/practice_session_service.dart';

final practiceSessionServiceProvider = Provider<PracticeSessionService>(
  (ref) => PracticeSessionService(),
);

class PracticeSessionsController extends AsyncNotifier<List<PracticeSession>> {
  @override
  Future<List<PracticeSession>> build() async {
    final service = ref.watch(practiceSessionServiceProvider);
    return service.fetchAllSessions();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final service = ref.read(practiceSessionServiceProvider);
      return service.fetchAllSessions();
    });
  }

  Future<void> create({
    required String title,
    required DateTime practiceDate,
    required int duration,
    required String focusArea,
    required int rating,
    String? notes,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final service = ref.read(practiceSessionServiceProvider);
      await service.createSession(
        title: title,
        practiceDate: practiceDate,
        duration: duration,
        focusArea: focusArea,
        rating: rating,
        notes: notes,
      );
      return service.fetchAllSessions();
    });
  }

  Future<void> updateSession(
    String id, {
    String? title,
    DateTime? practiceDate,
    int? duration,
    String? focusArea,
    int? rating,
    String? notes,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final service = ref.read(practiceSessionServiceProvider);
      await service.updateSession(
        id,
        title: title,
        practiceDate: practiceDate,
        duration: duration,
        focusArea: focusArea,
        rating: rating,
        notes: notes,
      );
      return service.fetchAllSessions();
    });
  }

  Future<void> deleteSession(String id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final service = ref.read(practiceSessionServiceProvider);
      await service.deleteSession(id);
      return service.fetchAllSessions();
    });
  }
}

final practiceSessionsProvider =
    AsyncNotifierProvider<PracticeSessionsController, List<PracticeSession>>(
  PracticeSessionsController.new,
);

final practiceSessionByIdProvider =
    FutureProvider.family<PracticeSession, String>((ref, id) async {
      final service = ref.watch(practiceSessionServiceProvider);
      return service.fetchSessionById(id);
    });
