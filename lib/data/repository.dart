import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

abstract class AppRepository {
  Future<Map<String, dynamic>?> load();
  Future<void> save(Map<String, dynamic> data);
  Future<void> clear();
}

/// Persistencia local (SharedPreferences).
///
/// En web guarda en localStorage y en Windows en un archivo de preferencias.
/// La separación entre persistencia local y sincronización se describe en `docs/SUPABASE.md`.
class LocalRepository implements AppRepository {
  static const String storageKey = 'casacomun.state.v1';

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _instance async =>
      _prefs ??= await SharedPreferences.getInstance();

  @override
  Future<Map<String, dynamic>?> load() async {
    final prefs = await _instance;
    final raw = prefs.getString(storageKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> save(Map<String, dynamic> data) async {
    final prefs = await _instance;
    await prefs.setString(storageKey, jsonEncode(data));
  }

  @override
  Future<void> clear() async {
    final prefs = await _instance;
    await prefs.remove(storageKey);
  }
}
