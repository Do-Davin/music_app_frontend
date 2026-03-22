import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:music_app_frontend/features/auth/domain/models/user.dart';
import 'package:music_app_frontend/features/auth/data/services/user_service.dart';

final userServiceProvider = Provider<UserService>((ref) => UserService());

final meProvider = FutureProvider<User>((ref) async {
  final service = ref.watch(userServiceProvider);
  return service.fetchMe();
});
