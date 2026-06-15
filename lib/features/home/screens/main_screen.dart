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

  static const _screens = [
    HomeScreen(),
    SearchScreen(),
    LibraryScreen(),
    KaraokeHomeScreen(),
    ProfileScreen(),
  ];

  static const _navItems = [
    BottomNavigationBarItem(
      icon: Icon(Icons.home_outlined),
      activeIcon: Icon(Icons.home),
      label: 'Home',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.search),
      label: 'Search',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.layers_outlined),
      activeIcon: Icon(Icons.layers),
      label: 'Library',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.mic_outlined),
      activeIcon: Icon(Icons.mic),
      label: 'Karaoke',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.person_outline),
      activeIcon: Icon(Icons.person),
      label: 'Profile',
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(navigationIndexProvider);
    final index = selectedIndex < _screens.length ? selectedIndex : 0;

    return Scaffold(
      body: IndexedStack(
        index: index,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,
        onTap: (newIndex) =>
            ref.read(navigationIndexProvider.notifier).state = newIndex,
        backgroundColor: AppColors.navBar,
        selectedItemColor: AppColors.navSelected,
        unselectedItemColor: AppColors.navUnselected,
        type: BottomNavigationBarType.fixed,
        items: _navItems,
      ),
    );
  }
}
