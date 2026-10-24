import 'package:flutter/material.dart';

import '../database/app_database.dart';

class ThemeController extends ChangeNotifier {
  ThemeController(this._database, [ThemeMode initial = ThemeMode.system])
      : _themeMode = initial {
    if (initial == ThemeMode.system) {
      _load();
    }
  }

  final AppDatabase _database;
  ThemeMode _themeMode;

  ThemeMode get themeMode => _themeMode;

  /// Lee directamente de la base de datos el modo guardado antes de renderizar la app.
  static Future<ThemeMode> getSavedThemeMode(AppDatabase database) async {
    try {
      final rows = await database.db.query(
        'app_settings',
        where: 'key = ?',
        whereArgs: ['theme_mode'],
      );
      if (rows.isNotEmpty) {
        final val = rows.first['value'] as String?;
        if (val == 'light') return ThemeMode.light;
        if (val == 'dark') return ThemeMode.dark;
        if (val == 'system') return ThemeMode.system;
      }
    } catch (_) {}
    return ThemeMode.system;
  }

  Future<void> _load() async {
    try {
      final rows = await _database.db.query(
        'app_settings',
        where: 'key = ?',
        whereArgs: ['theme_mode'],
      );
      if (rows.isNotEmpty) {
        final val = rows.first['value'] as String?;
        if (val == 'light') _themeMode = ThemeMode.light;
        if (val == 'dark') _themeMode = ThemeMode.dark;
        if (val == 'system') _themeMode = ThemeMode.system;
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();

    try {
      final val = switch (mode) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'system',
      };
      await _database.db.insert('app_settings', {
        'key': 'theme_mode',
        'value': val,
      }, conflictAlgorithm: null);
    } catch (_) {
      try {
        final val = switch (mode) {
          ThemeMode.light => 'light',
          ThemeMode.dark => 'dark',
          ThemeMode.system => 'system',
        };
        await _database.db.rawInsert(
          'INSERT OR REPLACE INTO app_settings (key, value) VALUES (?, ?)',
          ['theme_mode', val],
        );
      } catch (_) {}
    }
  }
}
