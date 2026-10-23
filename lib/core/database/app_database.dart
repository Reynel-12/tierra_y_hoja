import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'data_changes.dart';
import 'db_schema.dart';

/// Punto único de acceso a SQLite.
///
/// Abre la base, activa claves foráneas, crea el esquema y aplica migraciones.
class AppDatabase {
  AppDatabase._(this.db, this.changes);

  final Database db;
  final DataChanges changes;

  /// Abre (o crea) la base de datos del dispositivo.
  ///
  /// [factory] y [path] permiten usar una base en memoria en las pruebas.
  static Future<AppDatabase> open({
    DatabaseFactory? factory,
    String? path,
  }) async {
    final dbFactory = factory ?? databaseFactory;
    final dbPath =
        path ?? p.join(await dbFactory.getDatabasesPath(), DbSchema.fileName);

    final database = await dbFactory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: DbSchema.version,
        onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
        onCreate: (db, version) async {
          final batch = db.batch();
          for (final statement in DbSchema.createV1) {
            batch.execute(statement);
          }
          await batch.commit(noResult: true);
          await _migrate(db, from: 1, to: version);
        },
        onUpgrade: (db, oldVersion, newVersion) =>
            _migrate(db, from: oldVersion, to: newVersion),
      ),
    );
    return AppDatabase._(database, DataChanges());
  }

  static Future<void> _migrate(
    Database db, {
    required int from,
    required int to,
  }) async {
    for (var v = from + 1; v <= to; v++) {
      final statements = DbSchema.migrations[v];
      if (statements == null) continue;
      final batch = db.batch();
      for (final statement in statements) {
        batch.execute(statement);
      }
      await batch.commit(noResult: true);
    }
  }

  Future<void> close() async {
    await changes.dispose();
    await db.close();
  }
}
