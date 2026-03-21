import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:music_app_frontend/models/user.dart';
import 'package:music_app_frontend/services/user_service.dart';

final userServiceProvider = Provider<UserService>((ref) => UserService());

final meProvider = FutureProvider<User>((ref) async {
  final service = ref.read(userServiceProvider);
  return service.fetchMe();
});
