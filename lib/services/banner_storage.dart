import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/led_banner_config.dart';

class BannerStorage {
  static const String _lastConfigKey = 'led_banner_last_config_v1';
  static const String _favoritesKey = 'led_banner_favorites_v1';
  static const String _historyKey = 'led_banner_history_v1';
  static const int _maxHistory = 15;

  Future<LedBannerConfig> loadLastConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_lastConfigKey);
      if (raw == null || raw.isEmpty) return LedBannerConfig.defaults();
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return LedBannerConfig.fromJson(decoded);
      }
    } catch (_) {
      // Fallback to defaults if stored JSON is malformed or plugin unavailable.
    }
    return LedBannerConfig.defaults();
  }

  Future<void> saveLastConfig(LedBannerConfig config) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastConfigKey, jsonEncode(config.toJson()));
    } catch (_) {}
  }

  Future<List<BannerPreset>> loadFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_favoritesKey);
      if (raw == null || raw.isEmpty) return [];
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded
            .whereType<Map<String, dynamic>>()
            .map(BannerPreset.fromJson)
            .toList();
      }
    } catch (_) {}
    return [];
  }

  Future<void> saveFavorites(List<BannerPreset> favorites) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(favorites.map((e) => e.toJson()).toList());
      await prefs.setString(_favoritesKey, encoded);
    } catch (_) {}
  }

  Future<List<BannerPreset>> loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_historyKey);
      if (raw == null || raw.isEmpty) return [];
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded
            .whereType<Map<String, dynamic>>()
            .map(BannerPreset.fromJson)
            .toList();
      }
    } catch (_) {}
    return [];
  }

  Future<List<BannerPreset>> recordHistory(LedBannerConfig config) async {
    final current = await loadHistory();
    final trimmed = config.text.trim();
    if (trimmed.isEmpty) return current;

    final filtered = current.where((item) => item.config != config).toList();
    final now = DateTime.now();
    final entry = BannerPreset(
      id: 'hist_${now.microsecondsSinceEpoch}',
      name: trimmed.length > 18 ? '${trimmed.substring(0, 18)}…' : trimmed,
      category: '最近使用',
      config: config,
      isBuiltIn: false,
      savedAt: now,
    );
    final updated = [entry, ...filtered].take(_maxHistory).toList();
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(updated.map((e) => e.toJson()).toList());
      await prefs.setString(_historyKey, encoded);
    } catch (_) {}
    return updated;
  }
}
