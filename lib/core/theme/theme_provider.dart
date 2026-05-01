import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/app_icon_service.dart';
import 'accent_palette.dart';

const int _defaultAccentValue = AccentPalette.defaultAccentValue;

int _encodeColor(Color color) {
  final a = (color.a * 255).round() & 0xff;
  final r = (color.r * 255).round() & 0xff;
  final g = (color.g * 255).round() & 0xff;
  final b = (color.b * 255).round() & 0xff;
  return (a << 24) | (r << 16) | (g << 8) | b;
}

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden');
});

final themeProvider =
    StateNotifierProvider<ThemeNotifier, ThemeSettings>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ThemeNotifier(prefs);
});

enum VerseLayout { poetic, centered }

class ThemeSettings {
  final ThemeMode themeMode;
  final double fontScale;
  final VerseLayout verseLayout;
  final bool playSectionTitles;
  final bool removeParentheses;
  final bool useArabicNumerals;
  final int reciter;
  final Color accentColor;

  const ThemeSettings({
    this.themeMode = ThemeMode.light,
    this.fontScale = 1.0,
    this.verseLayout = VerseLayout.poetic,
    this.playSectionTitles = false,
    this.removeParentheses = true,
    this.useArabicNumerals = true,
    this.reciter = 1,
    this.accentColor = const Color(_defaultAccentValue),
  });

  ThemeSettings copyWith({
    ThemeMode? themeMode,
    double? fontScale,
    VerseLayout? verseLayout,
    bool? playSectionTitles,
    bool? removeParentheses,
    bool? useArabicNumerals,
    int? reciter,
    Color? accentColor,
  }) {
    return ThemeSettings(
      themeMode: themeMode ?? this.themeMode,
      fontScale: fontScale ?? this.fontScale,
      verseLayout: verseLayout ?? this.verseLayout,
      playSectionTitles: playSectionTitles ?? this.playSectionTitles,
      removeParentheses: removeParentheses ?? this.removeParentheses,
      useArabicNumerals: useArabicNumerals ?? this.useArabicNumerals,
      reciter: reciter ?? this.reciter,
      accentColor: accentColor ?? this.accentColor,
    );
  }
}

class ThemeNotifier extends StateNotifier<ThemeSettings> {
  final SharedPreferences _prefs;

  ThemeNotifier(this._prefs) : super(_loadPreferences(_prefs)) {
    Future<void>.microtask(
        () => AppIconService.syncWithAccent(state.accentColor));
  }

  static ThemeSettings _loadPreferences(SharedPreferences prefs) {
    final layoutIndex = prefs.getInt('verseLayout') ?? 0;

    ThemeMode themeMode;
    if (prefs.containsKey('themeMode')) {
      themeMode = ThemeMode.values[prefs.getInt('themeMode')!];
    } else {
      final isDark = prefs.getBool('isDark') ?? false;
      themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    }

    return ThemeSettings(
      themeMode: themeMode,
      fontScale: prefs.getDouble('fontScale') ?? 1.0,
      verseLayout: VerseLayout.values[layoutIndex],
      playSectionTitles: prefs.getBool('playSectionTitles') ?? false,
      removeParentheses: prefs.getBool('removeParentheses') ?? true,
      useArabicNumerals: prefs.getBool('useArabicNumerals') ?? true,
      reciter: prefs.getInt('reciter') ?? 1,
      accentColor: Color(
        prefs.getInt('accentColor') ?? _defaultAccentValue,
      ),
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await _prefs.setInt('themeMode', mode.index);
  }

  Future<void> setFontScale(double scale) async {
    state = state.copyWith(fontScale: scale);
    await _prefs.setDouble('fontScale', scale);
  }

  Future<void> setVerseLayout(VerseLayout layout) async {
    state = state.copyWith(verseLayout: layout);
    await _prefs.setInt('verseLayout', layout.index);
  }

  Future<void> setPlaySectionTitles(bool value) async {
    state = state.copyWith(playSectionTitles: value);
    await _prefs.setBool('playSectionTitles', value);
  }

  Future<void> setRemoveParentheses(bool value) async {
    state = state.copyWith(removeParentheses: value);
    await _prefs.setBool('removeParentheses', value);
  }

  Future<void> setUseArabicNumerals(bool value) async {
    state = state.copyWith(useArabicNumerals: value);
    await _prefs.setBool('useArabicNumerals', value);
  }

  Future<void> setReciter(int value) async {
    state = state.copyWith(reciter: value);
    await _prefs.setInt('reciter', value);
  }

  Future<void> setAccentColor(Color color) async {
    if (_encodeColor(state.accentColor) == _encodeColor(color)) {
      return;
    }
    state = state.copyWith(accentColor: color);
    await _prefs.setInt('accentColor', _encodeColor(color));
    Future<void>.microtask(
      () => AppIconService.syncWithAccent(color, closeAfterSync: true),
    );
  }

  Future<void> resetAccentColor() async {
    await setAccentColor(const Color(_defaultAccentValue));
  }
}
