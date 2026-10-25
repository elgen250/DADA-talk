import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsState {
  final ThemeMode themeMode;
  final Locale locale;
  final bool autoPlayTts;
  final bool hasCompletedOnboarding;

  const SettingsState({
    this.themeMode = ThemeMode.system,
    this.locale = const Locale('ar'),
    this.autoPlayTts = true,
    this.hasCompletedOnboarding = false,
  });

  SettingsState copyWith({
    ThemeMode? themeMode,
    Locale? locale,
    bool? autoPlayTts,
    bool? hasCompletedOnboarding,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      locale: locale ?? this.locale,
      autoPlayTts: autoPlayTts ?? this.autoPlayTts,
      hasCompletedOnboarding:
          hasCompletedOnboarding ?? this.hasCompletedOnboarding,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(const SettingsState()) {
    _loadSettings();
  }

  static const String _themeKey = 'vava_theme_mode';
  static const String _langKey = 'vava_app_lang';
  static const String _autoTtsKey = 'vava_auto_tts';
  static const String _onboardingKey = 'vava_has_onboarded';

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeStr = prefs.getString(_themeKey);
      final langStr = prefs.getString(_langKey) ?? 'ar';
      final autoTts = prefs.getBool(_autoTtsKey) ?? true;
      final onboarded = prefs.getBool(_onboardingKey) ?? false;

      ThemeMode mode = ThemeMode.system;
      if (themeStr == 'dark') mode = ThemeMode.dark;
      if (themeStr == 'light') mode = ThemeMode.light;

      state = state.copyWith(
        themeMode: mode,
        locale: Locale(langStr),
        autoPlayTts: autoTts,
        hasCompletedOnboarding: onboarded,
      );
    } catch (_) {}
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    String val = 'system';
    if (mode == ThemeMode.dark) val = 'dark';
    if (mode == ThemeMode.light) val = 'light';
    await prefs.setString(_themeKey, val);
    state = state.copyWith(themeMode: mode);
  }

  Future<void> setLocale(Locale loc) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_langKey, loc.languageCode);
    state = state.copyWith(locale: loc);
  }

  Future<void> setAutoPlayTts(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoTtsKey, enabled);
    state = state.copyWith(autoPlayTts: enabled);
  }

  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, true);
    state = state.copyWith(hasCompletedOnboarding: true);
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});
