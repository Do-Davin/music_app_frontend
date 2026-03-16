import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:music_app_frontend/constants/app_colors.dart';
import 'package:music_app_frontend/constants/app_text_styles.dart';
import 'package:music_app_frontend/providers/navigation_provider.dart';
import 'package:music_app_frontend/screens/home_screen.dart';
import 'package:music_app_frontend/screens/test_screen.dart';

class MainScreen extends ConsumerWidget {
  const MainScreen({super.key});

  static const _screens = [HomeScreen(), TestScreen()];
  static const _titles = ['Home', 'Test'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(navigationIndexProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[selectedIndex], style: AppTextStyles.subtitle),
        backgroundColor: AppColors.background,
      ),
      body: IndexedStack(index: selectedIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: (index) =>
            ref.read(navigationIndexProvider.notifier).state = index,
        backgroundColor: const Color(0xFF1E1E1E),
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.science), label: 'Test'),
        ],
      ),
    );
  }
}
