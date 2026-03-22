import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:music_app_frontend/providers/auth_provider.dart';
import 'package:music_app_frontend/screens/auth/login/login_screen.dart';
import 'package:music_app_frontend/screens/main/main_screen.dart';

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoggedIn = ref.watch(authProvider);

    return isLoggedIn ? const MainScreen() : const LoginScreen();
  }
}
