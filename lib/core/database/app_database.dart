import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'data_changes.dart';
import 'db_schema.dart';

/// Punto único de acceso a SQLite.
///
/// Abre la base, activa claves foráneas, crea el esquema y aplica migraciones.
class AppDatabase {
  AppDatabase._(
    this._db,
    this.changes, {
    DatabaseFactory? factory,
    String? path,
  }) : _factory = factory ?? databaseFactory,
       _customPath = path;

  Database _db;
  Database get db => _db;
  final DataChanges changes;
  final DatabaseFactory _factory;
  final String? _customPath;

  /// Obtiene la ruta física del archivo de base de datos.
  Future<String> getDatabasePath() async {
    return _customPath ??
        p.join(await _factory.getDatabasesPath(), DbSchema.fileName);
  }

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
    return AppDatabase._(database, DataChanges(), factory: factory, path: path);
  }

  /// Vuelca los cambios pendientes del registro WAL al archivo principal
  /// para asegurar que la copia de respaldo contenga todos los datos.
  Future<void> checkpoint() async {
    try {
      await _db.rawQuery('PRAGMA wal_checkpoint(TRUNCATE)');
    } catch (_) {}
  }

  /// Cierra la base actual, reemplaza el archivo SQLite con [sourceDbPath]
  /// y reabre la base de datos, notificando a todos los escuchas.
  Future<void> restoreFromFile(String sourceDbPath) async {
    final targetPath = await getDatabasePath();

    // 1. Cerrar la conexión actual de SQLite
    await _db.close();

    // 2. Limpiar archivos temporales de WAL / SHM si existen
    final walFile = File('$targetPath-wal');
    if (await walFile.exists()) {
      try {
        await walFile.delete();
      } catch (_) {}
    }
    final shmFile = File('$targetPath-shm');
    if (await shmFile.exists()) {
      try {
        await shmFile.delete();
      } catch (_) {}
    }

    // 3. Reemplazar el archivo SQLite principal
    final targetFile = File(targetPath);
    if (await targetFile.exists()) {
      await targetFile.delete();
    }
    await File(sourceDbPath).copy(targetPath);

    // 4. Reabrir la base de datos
    _db = await _factory.openDatabase(
      targetPath,
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

    // 5. Notificar a todas las tablas para que los controladores recarguen datos
    changes.notify(DbTable.values.toSet());
  }

  /// Corrige las rutas absolutas de fotos en la base de datos tras una restauración
  /// para que apunten al directorio local del dispositivo actual.
  Future<void> fixPhotoPaths(String newPhotosDirPath) async {
    // 1. plots (photo_path)
    try {
      final plots = await _db.rawQuery(
        'SELECT id, photo_path FROM plots WHERE photo_path IS NOT NULL',
      );
      for (final row in plots) {
        final oldPath = row['photo_path'] as String?;
        if (oldPath != null && oldPath.isNotEmpty) {
          final candidate = p.join(newPhotosDirPath, p.basename(oldPath));
          if (File(candidate).existsSync()) {
            await _db.rawUpdate(
              'UPDATE plots SET photo_path = ? WHERE id = ?',
              [candidate, row['id']],
            );
          }
        }
      }
    } catch (_) {}

    // 2. input_applications (photo_before, photo_after)
    try {
      final apps = await _db.rawQuery(
        'SELECT id, photo_before, photo_after FROM input_applications '
        'WHERE photo_before IS NOT NULL OR photo_after IS NOT NULL',
      );
      for (final row in apps) {
        final id = row['id'];
        final before = row['photo_before'] as String?;
        final after = row['photo_after'] as String?;
        String? newBefore = before;
        String? newAfter = after;

        if (before != null && before.isNotEmpty) {
          final candidate = p.join(newPhotosDirPath, p.basename(before));
          if (File(candidate).existsSync()) newBefore = candidate;
        }
        if (after != null && after.isNotEmpty) {
          final candidate = p.join(newPhotosDirPath, p.basename(after));
          if (File(candidate).existsSync()) newAfter = candidate;
        }

        if (newBefore != before || newAfter != after) {
          await _db.rawUpdate(
            'UPDATE input_applications SET photo_before = ?, photo_after = ? WHERE id = ?',
            [newBefore, newAfter, id],
          );
        }
      }
    } catch (_) {}

    // 3. cultural_tasks (photo_path)
    try {
      final tasks = await _db.rawQuery(
        'SELECT id, photo_path FROM cultural_tasks WHERE photo_path IS NOT NULL',
      );
      for (final row in tasks) {
        final oldPath = row['photo_path'] as String?;
        if (oldPath != null && oldPath.isNotEmpty) {
          final candidate = p.join(newPhotosDirPath, p.basename(oldPath));
          if (File(candidate).existsSync()) {
            await _db.rawUpdate(
              'UPDATE cultural_tasks SET photo_path = ? WHERE id = ?',
              [candidate, row['id']],
            );
          }
        }
      }
    } catch (_) {}

    // 4. incidents (photo_path)
    try {
      final incidents = await _db.rawQuery(
        'SELECT id, photo_path FROM incidents WHERE photo_path IS NOT NULL',
      );
      for (final row in incidents) {
        final oldPath = row['photo_path'] as String?;
        if (oldPath != null && oldPath.isNotEmpty) {
          final candidate = p.join(newPhotosDirPath, p.basename(oldPath));
          if (File(candidate).existsSync()) {
            await _db.rawUpdate(
              'UPDATE incidents SET photo_path = ? WHERE id = ?',
              [candidate, row['id']],
            );
          }
        }
      }
    } catch (_) {}
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
    await _db.close();
  }
}
