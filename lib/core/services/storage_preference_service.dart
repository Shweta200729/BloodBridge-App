import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences instance must be overridden in ProviderScope');
});

class StoragePreferenceService {
  final SharedPreferences _prefs;

  StoragePreferenceService(this._prefs);

  static const String _keyThemeMode = 'theme_mode';
  static const String _keyUserBloodGroup = 'user_blood_group';

  Future<bool> setDarkMode(bool isDark) async {
    return await _prefs.setBool(_keyThemeMode, isDark);
  }

  bool get isDarkMode {
    return _prefs.getBool(_keyThemeMode) ?? false;
  }

  Future<bool> setUserBloodGroup(String group) async {
    return await _prefs.setString(_keyUserBloodGroup, group);
  }

  String? get userBloodGroup {
    return _prefs.getString(_keyUserBloodGroup);
  }

  Future<void> clearAll() async {
    await _prefs.clear();
  }
}

final storagePreferenceServiceProvider = Provider<StoragePreferenceService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return StoragePreferenceService(prefs);
});
