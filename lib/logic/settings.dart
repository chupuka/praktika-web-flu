import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsStore extends ChangeNotifier {
  static const _themeKey = 'theme_mode';
  static const _fromKey = 'conv_from';
  static const _toKey = 'conv_to';

  ThemeMode _theme = ThemeMode.light;
  String _lastFrom = 'USD';
  String _lastTo = 'RUB';

  ThemeMode get theme => _theme;
  bool get isDark => _theme == ThemeMode.dark;
  String get lastFrom => _lastFrom;
  String get lastTo => _lastTo;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final t = prefs.getString(_themeKey);
    _theme = t == 'dark' ? ThemeMode.dark : ThemeMode.light;
    _lastFrom = prefs.getString(_fromKey) ?? 'USD';
    _lastTo = prefs.getString(_toKey) ?? 'RUB';
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _theme = isDark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, isDark ? 'dark' : 'light');
  }

  Future<void> savePair(String from, String to) async {
    _lastFrom = from;
    _lastTo = to;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_fromKey, from);
    await prefs.setString(_toKey, to);
  }
}
