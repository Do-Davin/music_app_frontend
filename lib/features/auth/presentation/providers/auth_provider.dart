import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:music_app_frontend/features/auth/data/services/auth_service.dart';
import 'package:music_app_frontend/features/auth/data/services/token_storage_service.dart';
import 'package:music_app_frontend/features/auth/presentation/providers/user_provider.dart';
import 'package:music_app_frontend/features/friends/providers/friend_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final tokenStorageServiceProvider = Provider<TokenStorageService>(
  (ref) => const TokenStorageService(),
);

class AuthState {
  final bool isAuthenticated;
  final bool isValidatingSession;
  final bool isLoading;
  final bool isSuccess;
  final String? errorMessage;

  const AuthState({
    this.isAuthenticated = false,
    this.isValidatingSession = true,
    this.isLoading = false,
    this.isSuccess = false,
    this.errorMessage,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isValidatingSession,
    bool? isLoading,
    bool? isSuccess,
    String? errorMessage,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isValidatingSession: isValidatingSession ?? this.isValidatingSession,
      isLoading: isLoading ?? this.isLoading,
      isSuccess: isSuccess ?? this.isSuccess,
      errorMessage: errorMessage,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._ref, this._service, this._tokenStorage)
    : super(const AuthState()) {
    _validateStoredSession();
  }

  final Ref _ref;
  final AuthService _service;
  final TokenStorageService _tokenStorage;

  Future<void> _validateStoredSession() async {
    final accessToken = await _tokenStorage.readAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      await _clearStoredSession();
      _resetUserScopedProviders();
      state = const AuthState(isValidatingSession: false);
      return;
    }

    try {
      await _ref.read(meProvider.future);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      state = state.copyWith(
        isAuthenticated: true,
        isValidatingSession: false,
        errorMessage: null,
      );
    } catch (_) {
      await _clearStoredSession();
      _resetUserScopedProviders();
      state = const AuthState(isValidatingSession: false);
    }
  }

  Future<void> login({required String email, required String password}) async {
    state = state.copyWith(
      isAuthenticated: false,
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
      _resetUserScopedProviders();
      await _ref.read(meProvider.future);

      state = state.copyWith(
        isAuthenticated: true,
        isValidatingSession: false,
        isLoading: false,
        isSuccess: true,
        errorMessage: null,
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
      isAuthenticated: false,
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
      _resetUserScopedProviders();
      await _ref.read(meProvider.future);

      state = state.copyWith(
        isAuthenticated: true,
        isValidatingSession: false,
        isLoading: false,
        isSuccess: true,
        errorMessage: null,
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
    await _clearStoredSession();
    state = const AuthState(isValidatingSession: false);
    _resetUserScopedProviders();
  }

  void clearFeedback() {
    state = state.copyWith(
      isSuccess: false,
      errorMessage: null,
      isAuthenticated: state.isAuthenticated,
      isValidatingSession: state.isValidatingSession,
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

  Future<void> _clearStoredSession() async {
    await _tokenStorage.clearTokens();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
  }

  void _resetUserScopedProviders() {
    _ref.invalidate(userServiceProvider);
    _ref.invalidate(friendServiceProvider);
    _ref.invalidate(meProvider);
    _ref.invalidate(usernameUpdateProvider);
    _ref.invalidate(myFriendsProvider);
    _ref.invalidate(incomingFriendRequestsProvider);
    _ref.invalidate(outgoingFriendRequestsProvider);
    _ref.invalidate(userSearchProvider);
    _ref.invalidate(friendSearchQueryProvider);
    _ref.invalidate(friendActionsProvider);
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
    ref,
    ref.read(authServiceProvider),
    ref.read(tokenStorageServiceProvider),
  ),
);
