// lib/screens/main_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:music_app_frontend/constants/app_colors.dart';
import 'package:music_app_frontend/providers/navigation_provider.dart';
import 'package:music_app_frontend/screens/home_screen.dart';

// Placeholder screens for tabs not yet built
// Replace these with real screens as your team builds them
class _SearchScreen extends StatelessWidget {
  const _SearchScreen();
  @override
  Widget build(BuildContext context) =>
      const Center(child: Text('Search — coming soon'));
}

class _LibraryScreen extends StatelessWidget {
  const _LibraryScreen();
  @override
  Widget build(BuildContext context) =>
      const Center(child: Text('Library — coming soon'));
}

class _ProfileScreen extends StatelessWidget {
  const _ProfileScreen();
  @override
  Widget build(BuildContext context) =>
      const Center(child: Text('Profile — coming soon'));
}

class MainScreen extends ConsumerWidget {
  const MainScreen({super.key});

  // Each entry maps to a tab: [screen, label, icon]
  // When your team builds the real screens, swap the placeholders here
  static const _screens = [
    HomeScreen(),
    _SearchScreen(),
    _LibraryScreen(),
    _ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(navigationIndexProvider);

    return Scaffold(
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
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
