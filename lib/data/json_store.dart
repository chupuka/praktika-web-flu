import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class JsonStore {
  final SharedPreferences _prefs;

  JsonStore(this._prefs);

  List<Map<String, dynamic>> read(String key) {
    final raw = _prefs.getString(key);
    if (raw == null) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return [
        for (final item in decoded)
          if (item is Map) Map<String, dynamic>.from(item),
      ];
    } catch (e) {
      return [];
    }
  }

  bool has(String key) => _prefs.containsKey(key);

  Future<void> write(String key, List<Map<String, dynamic>> rows) async {
    await _prefs.setString(
      key,
      jsonEncode([for (final row in rows) row]),
    );
  }

  Future<void> remove(String key) async {
    await _prefs.remove(key);
  }
}
