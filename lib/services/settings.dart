import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Uygulama geneli ayarlar (tema modu ve titreşim), cihaz hafızasında saklanır.
class Settings {
  static final ValueNotifier<ThemeMode> themeMode =
      ValueNotifier(ThemeMode.dark);
  static bool haptics = true;

  static Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    final t = p.getString('themeMode') ?? 'dark';
    themeMode.value = t == 'light'
        ? ThemeMode.light
        : t == 'system'
            ? ThemeMode.system
            : ThemeMode.dark;
    haptics = p.getBool('haptics') ?? true;
  }

  static Future<void> setTheme(ThemeMode m) async {
    themeMode.value = m;
    final p = await SharedPreferences.getInstance();
    await p.setString(
        'themeMode',
        m == ThemeMode.light
            ? 'light'
            : m == ThemeMode.system
                ? 'system'
                : 'dark');
  }

  static Future<void> setHaptics(bool v) async {
    haptics = v;
    final p = await SharedPreferences.getInstance();
    await p.setBool('haptics', v);
  }
}
