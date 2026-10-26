import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sqflite/sqflite.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/db_schema.dart';
import '../../../core/services/photo_storage_service.dart';
import '../models/backup_models.dart';

/// Servicio encargado de crear, listar, inspeccionar, restaurar y compartir
/// copias de seguridad completas (base de datos SQLite + fotos) de forma offline.
class BackupService {
  BackupService(
    this._database,
    this._photoService, {
    PackageInfo? packageInfo,
    Directory? defaultBackupDirectory,
  })  : _packageInfo = packageInfo,
        _defaultBackupDirectory = defaultBackupDirectory;

  final AppDatabase _database;
  final PhotoStorageService _photoService;
  final PackageInfo? _packageInfo;
  final Directory? _defaultBackupDirectory;

  static const String customDirectorySettingKey = 'backup_custom_directory';
  static const String backupExtension = '.tyh.zip';

  /// Directorio predeterminado de respaldos dentro del espacio de documentos de la app.
  Future<Directory> getDefaultBackupDirectory() async {
    final defaultDir = _defaultBackupDirectory;
    if (defaultDir != null) {
      if (!await defaultDir.exists()) {
        await defaultDir.create(recursive: true);
      }
      return defaultDir;
    }
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, 'backups'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Convierte URIs de Android (content:// o file://) a una ruta del sistema de archivos real.
  static String resolveStoragePath(String path) {
    final raw = path.trim();
    if (raw.isEmpty) return raw;

    // Si viene con esquema file://
    if (raw.startsWith('file://')) {
      final stripped = raw.substring(7);
      return stripped.startsWith('/') ? stripped : '/$stripped';
    }

    // Si no es un URI con esquema content:, retornar directo
    if (!raw.startsWith('content:')) {
      return raw;
    }

    try {
      // Decodificar percent-encoding (ej. %3A -> :, %2F -> /)
      final decoded = Uri.decodeFull(raw);

      // Caso 1: Rutas directas "raw:" (típico en Descargas)
      if (decoded.contains('raw:')) {
        var rawPart = decoded.substring(decoded.indexOf('raw:') + 4);
        if (rawPart.contains('?')) {
          rawPart = rawPart.substring(0, rawPart.indexOf('?'));
        }
        return rawPart.trim();
      }

      // Caso 2: Almacenamiento interno principal "primary:"
      if (decoded.contains('primary:')) {
        var subPath = decoded.substring(decoded.indexOf('primary:') + 8);
        if (subPath.contains('?')) {
          subPath = subPath.substring(0, subPath.indexOf('?'));
        }
        if (subPath.contains('/document/')) {
          subPath = subPath.substring(0, subPath.indexOf('/document/'));
        }
        final cleanSub = subPath.trim().replaceFirst(RegExp(r'^/+'), '');
        if (cleanSub.isEmpty) {
          return '/storage/emulated/0';
        }
        return '/storage/emulated/0/$cleanSub';
      }

      // Caso 3: Tarjetas SD externas con UUID (ej. 1234-ABCD:Backups)
      final sdMatch = RegExp(r'([0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}):([^?&]*)').firstMatch(decoded);
      if (sdMatch != null) {
        final uuid = sdMatch.group(1);
        final subPath = sdMatch.group(2) ?? '';
        final cleanSub = subPath.trim().replaceFirst(RegExp(r'^/+'), '');
        if (cleanSub.isEmpty) {
          return '/storage/$uuid';
        }
        return '/storage/$uuid/$cleanSub';
      }

      // Caso 4: Descargas / Documentos estándar por palabras clave
      if (decoded.toLowerCase().contains('downloads') || decoded.toLowerCase().contains('download')) {
        return '/storage/emulated/0/Download';
      }
      if (decoded.toLowerCase().contains('documents') || decoded.toLowerCase().contains('document')) {
        return '/storage/emulated/0/Documents';
      }
    } catch (_) {}

    return raw;
  }

  /// Retorna el directorio configurado para respaldos (personalizado o predeterminado).
  Future<Directory> getConfiguredBackupDirectory() async {
    try {
      final rows = await _database.db.query(
        'app_settings',
        where: 'key = ?',
        whereArgs: [customDirectorySettingKey],
      );
      if (rows.isNotEmpty) {
        final customPath = rows.first['value'] as String?;
        if (customPath != null && customPath.trim().isNotEmpty) {
          final cleanPath = resolveStoragePath(customPath.trim());
          if (!cleanPath.startsWith('content:')) {
            final customDir = Directory(cleanPath);
            if (await customDir.exists()) {
              return customDir;
            }
          }
        }
      }
    } catch (_) {}

    return getDefaultBackupDirectory();
  }

  /// Indica si la ruta configurada es personalizada o predeterminada.
  Future<bool> isCustomDirectoryConfigured() async {
    try {
      final rows = await _database.db.query(
        'app_settings',
        where: 'key = ?',
        whereArgs: [customDirectorySettingKey],
      );
      if (rows.isNotEmpty) {
        final val = rows.first['value'] as String?;
        return val != null && val.trim().isNotEmpty;
      }
    } catch (_) {}
    return false;
  }

  /// Guarda o restablece la ruta de respaldos.
  Future<void> setConfiguredBackupDirectory(String? customPath) async {
    if (customPath == null || customPath.trim().isEmpty) {
      await _database.db.delete(
        'app_settings',
        where: 'key = ?',
        whereArgs: [customDirectorySettingKey],
      );
      return;
    }

    final cleanPath = resolveStoragePath(customPath.trim());

    if (cleanPath.startsWith('content:')) {
      throw const FileSystemException(
        'No se pudo convertir el URI del proveedor de archivos a una ruta válida del dispositivo. Por favor seleccione una carpeta de Almacenamiento Interno o Descargas.',
      );
    }

    final dir = Directory(cleanPath);
    if (!await dir.exists()) {
      try {
        await dir.create(recursive: true);
      } catch (e) {
        if (!await dir.exists()) {
          throw FileSystemException(
            'No se tienen permisos para acceder o crear la carpeta seleccionada: $cleanPath',
            cleanPath,
          );
        }
      }
    }

    await _database.db.rawInsert(
      'INSERT OR REPLACE INTO app_settings (key, value) VALUES (?, ?)',
      [customDirectorySettingKey, cleanPath],
    );
  }

  /// Obtiene las estadísticas de los datos actuales en el dispositivo.
  Future<BackupContentStats> getCurrentStats() async {
    int plotsCount = 0;
    int cyclesCount = 0;
    int appsCount = 0;
    int tasksCount = 0;
    int incidentsCount = 0;
    int expensesCount = 0;
    int salesCount = 0;
    int photosCount = 0;

    try {
      plotsCount = Sqflite.firstIntValue(
            await _database.db.rawQuery('SELECT COUNT(*) FROM plots'),
          ) ??
          0;
      cyclesCount = Sqflite.firstIntValue(
            await _database.db.rawQuery('SELECT COUNT(*) FROM crop_cycles'),
          ) ??
          0;
      appsCount = Sqflite.firstIntValue(
            await _database.db.rawQuery('SELECT COUNT(*) FROM input_applications'),
          ) ??
          0;
      tasksCount = Sqflite.firstIntValue(
            await _database.db.rawQuery('SELECT COUNT(*) FROM cultural_tasks'),
          ) ??
          0;
      incidentsCount = Sqflite.firstIntValue(
            await _database.db.rawQuery('SELECT COUNT(*) FROM incidents'),
          ) ??
          0;
      expensesCount = Sqflite.firstIntValue(
            await _database.db.rawQuery('SELECT COUNT(*) FROM expenses'),
          ) ??
          0;
      salesCount = Sqflite.firstIntValue(
            await _database.db.rawQuery('SELECT COUNT(*) FROM sales'),
          ) ??
          0;
    } catch (_) {}

    try {
      final photosDir = await _photoService.photosDirectory;
      if (await photosDir.exists()) {
        photosCount = photosDir
            .listSync()
            .whereType<File>()
            .where((f) => !p.basename(f.path).startsWith('.'))
            .length;
      }
    } catch (_) {}

    return BackupContentStats(
      plots: plotsCount,
      cycles: cyclesCount,
      applications: appsCount,
      tasks: tasksCount,
      incidents: incidentsCount,
      expenses: expensesCount,
      sales: salesCount,
      photos: photosCount,
    );
  }

  /// Crea una copia de seguridad completa y la guarda en el directorio destino.
  Future<BackupFileItem> createBackup({
    Directory? destinationDir,
    String? customFileName,
    void Function(String message)? onProgress,
  }) async {
    onProgress?.call('Preparando base de datos...');
    await _database.checkpoint();

    final targetDir = destinationDir ?? await getConfiguredBackupDirectory();
    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }

    final stats = await getCurrentStats();
    final appVersion = _packageInfo?.version ?? '1.1.4';
    final now = DateTime.now();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(now);
    final fileName = customFileName ?? 'tierra_y_hoja_respaldo_$timestamp$backupExtension';
    final targetFilePath = p.join(targetDir.path, fileName);

    final manifest = BackupManifest(
      app: 'Tierra & Hoja',
      version: appVersion,
      dbVersion: DbSchema.version,
      createdAt: now,
      stats: stats,
    );

    final sessionDir = Directory(
      p.join(Directory.systemTemp.path, 'th_backup_${now.millisecondsSinceEpoch}'),
    );
    await sessionDir.create(recursive: true);

    try {
      // 1. Guardar manifest.json
      onProgress?.call('Empaquetando metadatos...');
      final manifestFile = File(p.join(sessionDir.path, 'manifest.json'));
      await manifestFile.writeAsString(manifest.toJsonString());

      // 2. Copiar archivo de base de datos
      onProgress?.call('Comprimiendo base de datos...');
      final dbPath = await _database.getDatabasePath();
      final dbFile = File(dbPath);

      // 3. Empaquetar todo en ZIP usando ZipFileEncoder (streaming directo a disco)
      final encoder = ZipFileEncoder();
      encoder.create(targetFilePath);

      await encoder.addFile(manifestFile, 'manifest.json');
      if (await dbFile.exists()) {
        await encoder.addFile(dbFile, 'database/tierra_y_hoja.db');
      }

      // 4. Agregar fotografías
      onProgress?.call('Comprimiendo fotografías...');
      final photosDir = await _photoService.photosDirectory;
      if (await photosDir.exists()) {
        final photoEntities = photosDir.listSync().whereType<File>();
        for (final photo in photoEntities) {
          final bName = p.basename(photo.path);
          if (!bName.startsWith('.')) {
            await encoder.addFile(photo, 'photos/$bName');
          }
        }
      }

      await encoder.close();
      onProgress?.call('Copia finalizada.');

      final backupFile = File(targetFilePath);
      final size = await backupFile.length();

      return BackupFileItem(
        file: backupFile,
        name: fileName,
        sizeBytes: size,
        modifiedAt: now,
        manifest: manifest,
      );
    } finally {
      try {
        if (await sessionDir.exists()) {
          await sessionDir.delete(recursive: true);
        }
      } catch (_) {}
    }
  }

  /// Lista las copias de seguridad detectadas en el directorio configurado.
  Future<List<BackupFileItem>> listBackups() async {
    final dir = await getConfiguredBackupDirectory();
    if (!await dir.exists()) return [];

    final files = dir.listSync().whereType<File>().where((file) {
      final name = p.basename(file.path).toLowerCase();
      return name.endsWith('.zip') || name.endsWith('.tyh');
    }).toList();

    final List<BackupFileItem> results = [];
    for (final file in files) {
      try {
        final stat = file.statSync();
        BackupManifest? manifest;

        // Intentar leer de forma ligera el manifest del zip
        try {
          final bytes = await file.readAsBytes();
          final archive = ZipDecoder().decodeBytes(bytes);
          final manifestEntry = archive.findFile('manifest.json');
          if (manifestEntry != null) {
            final content = manifestEntry.content as List<int>;
            final json = jsonDecode(utf8.decode(content)) as Map<String, dynamic>;
            manifest = BackupManifest.fromJson(json);
          }
        } catch (_) {}

        results.add(
          BackupFileItem(
            file: file,
            name: p.basename(file.path),
            sizeBytes: stat.size,
            modifiedAt: stat.modified,
            manifest: manifest,
          ),
        );
      } catch (_) {}
    }

    results.sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));
    return results;
  }

  /// Inspecciona y valida un archivo de respaldo antes de confirmar su restauración.
  Future<BackupInspectionResult> inspectBackupFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      return BackupInspectionResult(
        isValid: false,
        filePath: filePath,
        fileSizeBytes: 0,
        errorMessage: 'El archivo seleccionado no existe o no se puede leer.',
      );
    }

    final fileSize = await file.length();
    if (fileSize < 100) {
      return BackupInspectionResult(
        isValid: false,
        filePath: filePath,
        fileSizeBytes: fileSize,
        errorMessage: 'El archivo está vacío o dañado.',
      );
    }

    try {
      final bytes = await file.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      // 1. Verificar si contiene la base de datos de SQLite
      final hasDb = archive.findFile('database/tierra_y_hoja.db') != null ||
          archive.findFile('tierra_y_hoja.db') != null;

      if (!hasDb) {
        return BackupInspectionResult(
          isValid: false,
          filePath: filePath,
          fileSizeBytes: fileSize,
          errorMessage:
              'El archivo no contiene una base de datos válida de Tierra & Hoja.',
        );
      }

      // 2. Contar fotos empaquetadas
      var photoCount = 0;
      for (final f in archive.files) {
        if (f.isFile && f.name.startsWith('photos/')) {
          photoCount++;
        }
      }

      // 3. Leer manifest si existe
      BackupManifest? manifest;
      final manifestEntry = archive.findFile('manifest.json');
      if (manifestEntry != null) {
        try {
          final content = manifestEntry.content as List<int>;
          final json = jsonDecode(utf8.decode(content)) as Map<String, dynamic>;
          manifest = BackupManifest.fromJson(json);
        } catch (_) {}
      }

      // Si no hay manifest, construimos uno aproximado con las fotos detectadas
      manifest ??= BackupManifest(
        app: 'Tierra & Hoja',
        version: '1.0.0',
        dbVersion: DbSchema.version,
        createdAt: file.statSync().modified,
        stats: BackupContentStats(photos: photoCount),
      );

      return BackupInspectionResult(
        isValid: true,
        filePath: filePath,
        fileSizeBytes: fileSize,
        manifest: manifest,
        detectedPhotos: photoCount,
      );
    } catch (e) {
      return BackupInspectionResult(
        isValid: false,
        filePath: filePath,
        fileSizeBytes: fileSize,
        errorMessage: 'No se pudo leer el archivo de respaldo: $e',
      );
    }
  }

  /// Restaura completamente la base de datos y fotografías desde un archivo de respaldo.
  Future<BackupManifest> restoreBackup(
    String filePath, {
    void Function(String message)? onProgress,
  }) async {
    onProgress?.call('Verificando archivo de respaldo...');
    final inspection = await inspectBackupFile(filePath);
    if (!inspection.isValid) {
      throw Exception(
        inspection.errorMessage ?? 'Archivo de respaldo no válido.',
      );
    }

    final extractDir = Directory(
      p.join(Directory.systemTemp.path, 'th_restore_${DateTime.now().millisecondsSinceEpoch}'),
    );
    await extractDir.create(recursive: true);

    try {
      onProgress?.call('Descomprimiendo archivos...');
      await extractFileToDisk(filePath, extractDir.path);

      // Localizar la base de datos SQLite extraída
      File? extractedDbFile;
      final candidate1 = File(
        p.join(extractDir.path, 'database', 'tierra_y_hoja.db'),
      );
      final candidate2 = File(p.join(extractDir.path, 'tierra_y_hoja.db'));

      if (await candidate1.exists()) {
        extractedDbFile = candidate1;
      } else if (await candidate2.exists()) {
        extractedDbFile = candidate2;
      }

      if (extractedDbFile == null) {
        throw Exception('No se encontró el archivo de base de datos dentro del respaldo.');
      }

      // Restaurar fotografías en el almacenamiento local
      onProgress?.call('Restaurando fotografías...');
      final targetPhotosDir = await _photoService.photosDirectory;
      final extractedPhotosDir = Directory(p.join(extractDir.path, 'photos'));

      if (await extractedPhotosDir.exists()) {
        final photos = extractedPhotosDir.listSync().whereType<File>();
        for (final photo in photos) {
          final targetPhotoPath = p.join(
            targetPhotosDir.path,
            p.basename(photo.path),
          );
          await photo.copy(targetPhotoPath);
        }
      }

      // Reemplazar y reabrir la base de datos SQLite
      onProgress?.call('Restaurando registros y tablas...');
      await _database.restoreFromFile(extractedDbFile.path);

      // Corregir rutas de fotos para este dispositivo
      onProgress?.call('Actualizando rutas de fotografías...');
      await _database.fixPhotoPaths(targetPhotosDir.path);

      onProgress?.call('Restauración completada.');
      return inspection.manifest ??
          BackupManifest(
            app: 'Tierra & Hoja',
            version: '1.1.0',
            dbVersion: DbSchema.version,
            createdAt: DateTime.now(),
            stats: const BackupContentStats(),
          );
    } finally {
      try {
        if (await extractDir.exists()) {
          await extractDir.delete(recursive: true);
        }
      } catch (_) {}
    }
  }

  /// Comparte el archivo de respaldo mediante share_plus.
  Future<void> shareBackup(String filePath, {String? subject}) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('El archivo de respaldo no existe.');
    }

    final name = p.basename(filePath);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(filePath)],
        subject: subject ?? 'Copia de seguridad Tierra & Hoja ($name)',
      ),
    );
  }

  /// Elimina una copia de seguridad del disco.
  Future<void> deleteBackup(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
