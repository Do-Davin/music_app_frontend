import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:music_app_frontend/core/routing/navigation_provider.dart';
import 'package:music_app_frontend/features/home/screens/home_screen.dart';
import 'package:music_app_frontend/core/constants/app_colors.dart';

import 'package:music_app_frontend/features/search/screens/search_screen.dart';
import 'package:music_app_frontend/features/library/screens/library_screen.dart';
import 'package:music_app_frontend/features/profile/screens/profile_screen.dart';
import 'package:music_app_frontend/features/karaoke/presentation/screens/karaoke_home_screen.dart';

class MainScreen extends ConsumerWidget {
  const MainScreen({super.key});

  // static const _screens = [HomeScreen()];

  // static const _titles = ['Home'];
  // Each entry maps to a tab: [screen, label, icon]
  // When your team builds the real screens, swap the placeholders here
  static const _screens = [
    HomeScreen(),
    SearchScreen(),
    LibraryScreen(),
    KaraokeHomeScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(navigationIndexProvider);

    return Scaffold(
      // appBar: AppBar(title: Text(_titles[selectedIndex])),
      // No AppBar here — each individual screen manages its own header
      body: IndexedStack(
        // IndexedStack keeps all screens alive (no rebuild when switching tabs)
        index: selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: (index) =>
            ref.read(navigationIndexProvider.notifier).state = index,
        backgroundColor: AppColors.navBar,
        selectedItemColor: AppColors.navSelected, // orange
        unselectedItemColor: AppColors.navUnselected, // grey
        // 'fixed' ensures all 4 labels are always shown (not shifting layout)
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(
            // 'layers' matches the stacked-layers Library icon in Figma
            icon: Icon(Icons.layers_outlined),
            activeIcon: Icon(Icons.layers),
            label: 'Library',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.mic_outlined),        // ← Karaoke icon
            activeIcon: Icon(Icons.mic),          // ← Active karaoke icon
            label: 'Karaoke',                      // ← Karaoke label
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
