class Routes {
  Routes._();

  static const root = '/';
  static const splash = '/splash';
  static const onboarding = '/onboarding';
  static const main = '/main';
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const verifyAccount = '/verify-account';
  static const newPassword = '/new-password';
  static const status = '/status';
  static const noPlaylists = '/no-playlists';
  static const noResults = '/no-results';
  static const song = '/song/:id';
  static const playlistDetail = '/playlist/:id';

  static String songById(String id) => '/song/${Uri.encodeComponent(id)}';
  static String playlistById(String id) => '/playlist/${Uri.encodeComponent(id)}';
}
