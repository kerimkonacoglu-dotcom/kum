import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Favori kanalları (servis referansı -> ad) cihaz hafızasında saklar.
class FavoritesStore {
  static const _key = 'favorites_v2';

  Future<Map<String, String>> load() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_key);
    if (raw == null || raw.isEmpty) return {};
    final m = jsonDecode(raw) as Map<String, dynamic>;
    return m.map((k, v) => MapEntry(k, v.toString()));
  }

  Future<Map<String, String>> toggle(String ref, String name) async {
    final map = await load();
    if (map.containsKey(ref)) {
      map.remove(ref);
    } else {
      map[ref] = name;
    }
    final p = await SharedPreferences.getInstance();
    await p.setString(_key, jsonEncode(map));
    return map;
  }
}
