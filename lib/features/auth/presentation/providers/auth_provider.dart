import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:music_app_frontend/features/auth/data/models/user.dart';
import 'package:music_app_frontend/features/auth/data/services/auth_service.dart';
import 'package:music_app_frontend/features/auth/data/services/token_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final tokenStorageServiceProvider = Provider<TokenStorageService>(
  (ref) => const TokenStorageService(),
);

class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final bool isSuccess;
  final String? errorMessage;
  final User? user;

  const AuthState({
    this.isAuthenticated = false,
    this.isLoading = false,
    this.isSuccess = false,
    this.errorMessage,
    this.user,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    bool? isSuccess,
    String? errorMessage,
    User? user,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      isSuccess: isSuccess ?? this.isSuccess,
      errorMessage: errorMessage,
      user: user ?? this.user,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._service, this._tokenStorage) : super(const AuthState()) {
    _restoreSession();
  }

  final AuthService _service;
  final TokenStorageService _tokenStorage;

  Future<void> _restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    if (state.isAuthenticated == isLoggedIn) {
      return;
    }

    state = state.copyWith(isAuthenticated: isLoggedIn);
  }

  Future<void> login({required String email, required String password}) async {
    state = state.copyWith(
      isLoading: true,
      isSuccess: false,
      errorMessage: null,
    );

    try {
      final session = await _service.login(email: email, password: password);
      await _persistSession(
        accessToken: session.accessToken,
        refreshToken: session.refreshToken,
      );

      state = state.copyWith(
        isAuthenticated: true,
        isLoading: false,
        isSuccess: true,
        errorMessage: null,
        user: session.user,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        isSuccess: false,
        errorMessage: _normalizeError(error),
      );
    }
  }

  Future<void> register({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(
      isLoading: true,
      isSuccess: false,
      errorMessage: null,
    );

    try {
      final session = await _service.register(
        username: _usernameFromEmail(email),
        email: email,
        password: password,
      );
      await _persistSession(
        accessToken: session.accessToken,
        refreshToken: session.refreshToken,
      );

      state = state.copyWith(
        isAuthenticated: true,
        isLoading: false,
        isSuccess: true,
        errorMessage: null,
        user: session.user,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        isSuccess: false,
        errorMessage: _normalizeError(error),
      );
    }
  }

  Future<void> logout() async {
    await _tokenStorage.clearTokens();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    state = const AuthState();
  }

  void clearFeedback() {
    state = state.copyWith(
      isSuccess: false,
      errorMessage: null,
      user: state.user,
      isAuthenticated: state.isAuthenticated,
      isLoading: state.isLoading,
    );
  }

  Future<void> _persistSession({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _tokenStorage.saveTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
  }

  String _normalizeError(Object error) {
    final message = error.toString();
    return message.startsWith('Exception: ') ? message.substring(11) : message;
  }

  String _usernameFromEmail(String email) {
    final localPart = email.split('@').first.trim().toLowerCase();
    final sanitized = localPart.replaceAll(RegExp(r'[^a-z0-9_]'), '_');
    final base = sanitized.length >= 3 ? sanitized : '${sanitized}user';
    final suffix = email.hashCode
        .abs()
        .toString()
        .padLeft(4, '0')
        .substring(0, 4);
    return '${base}_$suffix';
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(
    ref.read(authServiceProvider),
    ref.read(tokenStorageServiceProvider),
  ),
);
