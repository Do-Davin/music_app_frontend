import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:music_app_frontend/features/auth/data/services/auth_service.dart';
import 'package:music_app_frontend/features/auth/domain/models/auth_state.dart';
import 'package:music_app_frontend/features/auth/domain/models/user.dart';

final authServiceProvider = Provider((ref) => AuthService());

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(AuthState(isLoading: true)) {
    _init();
  }

  Future<void> _init() async {
    state = state.copyWith(isLoading: true);
    final token = await _authService.getToken();
    if (token != null) {
      try {
        final user = await _authService.getMe(token);
        if (user != null) {
          state = AuthState(user: user, token: token, isLoading: false);
        } else {
          state = AuthState(isLoading: false); // Clear if token is invalid
        }
      } catch (e) {
        state = AuthState(isLoading: false); // Clear on error
      }
    } else {
      state = AuthState(isLoading: false);
    }
  }
  

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _authService.login(email, password);
      state = AuthState(
        user: result['user'] as User,
        token: result['token'] as String,
      );
    } catch (e) {
      state = AuthState(errorMessage: e.toString());
    }
  }

  Future<void> register(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _authService.register(email, password);
      state = AuthState(
        user: result['user'] as User,
        token: result['token'] as String,
      );
    } catch (e) {
      state = AuthState(errorMessage: e.toString());
    }
  }

  Future<void> logout() async {
    await _authService.clearToken();
    state = AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthNotifier(authService);
});
