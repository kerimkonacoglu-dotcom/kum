import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/device.dart';

/// Kayıtlı cihazları cihaz hafızasında (SharedPreferences) saklar.
class DeviceStore {
  static const _key = 'devices_v1';

  Future<List<Device>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    final list = (jsonDecode(raw) as List)
        .map((e) => Device.fromJson(e as Map<String, dynamic>))
        .toList();
    return list;
  }

  Future<void> _saveAll(List<Device> devices) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _key, jsonEncode(devices.map((d) => d.toJson()).toList()));
  }

  Future<void> upsert(Device device) async {
    final list = await load();
    final i = list.indexWhere((d) => d.id == device.id);
    if (i >= 0) {
      list[i] = device;
    } else {
      list.add(device);
    }
    await _saveAll(list);
  }

  Future<void> delete(String id) async {
    final list = await load();
    list.removeWhere((d) => d.id == id);
    await _saveAll(list);
  }
}
