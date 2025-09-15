import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

class Repo {
  static const _kClientes = 'clientes_v1';
  static const _kPixKey = 'pix_key';
  static const _kPixNome = 'pix_nome';
  static const _kThemeMode = 'theme_mode';

  final SharedPreferences prefs;
  Repo(this.prefs);

  List<Cliente> loadClientes() {
    final raw = prefs.getString(_kClientes);
    if (raw == null) return [];
    final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    return list.map((m) => Cliente.fromMap(Map<String, dynamic>.from(m))).toList();
  }

  Future<void> saveClientes(List<Cliente> clientes) async {
    final raw = jsonEncode(clientes.map((c) => c.toMap()).toList());
    await prefs.setString(_kClientes, raw);
  }

  String get pixKey => prefs.getString(_kPixKey) ?? '';
  String get pixNome => prefs.getString(_kPixNome) ?? '';
  ThemeMode get themeMode =>
      ThemeMode.values[prefs.getInt(_kThemeMode) ?? ThemeMode.light.index];

  Future<void> setPix({required String key, required String nome}) async {
    await prefs.setString(_kPixKey, key);
    await prefs.setString(_kPixNome, nome);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await prefs.setInt(_kThemeMode, mode.index);
  }
}
