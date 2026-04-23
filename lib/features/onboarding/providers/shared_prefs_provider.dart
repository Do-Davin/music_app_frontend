import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden');
});

class FirstLaunchNotifier extends Notifier<bool> {
  @override
  bool build() {
    final prefs = ref.read(sharedPreferencesProvider);
    return prefs.getBool('isFirstLaunch') ?? true;
  }

  Future<void> completeOnboarding() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool('isFirstLaunch', false);
    state = false;
  }
}

final isFirstLaunchProvider = NotifierProvider<FirstLaunchNotifier, bool>(
  FirstLaunchNotifier.new,
);
