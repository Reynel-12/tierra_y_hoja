import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tierra_y_hoja/core/database/app_database.dart';
import 'package:tierra_y_hoja/core/database/data_changes.dart';
import 'package:tierra_y_hoja/core/design/app_theme.dart';
import 'package:tierra_y_hoja/core/services/photo_storage_service.dart';
import 'package:tierra_y_hoja/core/state/theme_controller.dart';
import 'package:tierra_y_hoja/features/backup/models/backup_models.dart';
import 'package:tierra_y_hoja/features/backup/services/backup_service.dart';
import 'package:tierra_y_hoja/features/backup/views/backup_restore_view.dart';
import 'package:tierra_y_hoja/features/more/views/more_view.dart';

class FakePhotoStorageService implements PhotoStorageService {
  FakePhotoStorageService(this.mockDir);
  final Directory mockDir;

  @override
  Future<Directory> get photosDirectory async => mockDir;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('es', null);
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('BackupModels Tests', () {
    test('BackupManifest serializes and deserializes correctly', () {
      final now = DateTime(2026, 10, 25, 17, 30);
      const stats = BackupContentStats(
        plots: 2,
        cycles: 4,
        applications: 10,
        tasks: 6,
        incidents: 1,
        expenses: 8,
        sales: 3,
        photos: 12,
      );

      final manifest = BackupManifest(
        app: 'Tierra & Hoja',
        version: '1.1.4',
        dbVersion: 1,
        createdAt: now,
        stats: stats,
      );

      final json = manifest.toJson();
      expect(json['app'], 'Tierra & Hoja');
      expect(json['version'], '1.1.4');
      expect(json['db_version'], 1);
      expect(stats.totalRecords, 34);

      final fromJson = BackupManifest.fromJson(json);
      expect(fromJson.app, manifest.app);
      expect(fromJson.version, manifest.version);
      expect(fromJson.stats.plots, 2);
      expect(fromJson.stats.photos, 12);
    });

    test('BackupInspectionResult formats size and date properly', () {
      final result = BackupInspectionResult(
        isValid: true,
        filePath: 'mock/path/backup.tyh.zip',
        fileSizeBytes: 2048 * 1024, // 2 MB
        manifest: BackupManifest(
          app: 'Tierra & Hoja',
          version: '1.1.4',
          dbVersion: 1,
          createdAt: DateTime(2026, 10, 25, 12, 0),
          stats: const BackupContentStats(plots: 3, photos: 5),
        ),
      );

      expect(result.isValid, isTrue);
      expect(result.formattedSize, '2.0 MB');
      expect(result.formattedDate, contains('25'));
    });

    test('BackupService.resolveStoragePath resolves Android SAF content URIs correctly', () {
      // Primary internal storage
      expect(
        BackupService.resolveStoragePath(
          'content://com.android.externalstorage.documents/tree/primary%3ADownload',
        ),
        '/storage/emulated/0/Download',
      );
      expect(
        BackupService.resolveStoragePath(
          'content://com.android.externalstorage.documents/tree/primary%3ADocuments%2FRespaldos',
        ),
        '/storage/emulated/0/Documents/Respaldos',
      );
      expect(
        BackupService.resolveStoragePath(
          'content://com.android.externalstorage.documents/tree/primary%3A',
        ),
        '/storage/emulated/0',
      );

      // Raw download provider path
      expect(
        BackupService.resolveStoragePath(
          'content://com.android.providers.downloads.documents/tree/raw%3A%2Fstorage%2Femulated%2F0%2FDownload',
        ),
        '/storage/emulated/0/Download',
      );

      // External SD Card with UUID
      expect(
        BackupService.resolveStoragePath(
          'content://com.android.externalstorage.documents/tree/71B3-1510%3ABackups',
        ),
        '/storage/71B3-1510/Backups',
      );

      // File scheme
      expect(
        BackupService.resolveStoragePath('file:///storage/emulated/0/Download'),
        '/storage/emulated/0/Download',
      );

      // Regular path remains untouched
      expect(
        BackupService.resolveStoragePath('/storage/emulated/0/Download'),
        '/storage/emulated/0/Download',
      );
    });
  });

  group('BackupService Integration Tests', () {
    late Directory tempDir;
    late Directory photosDir;
    late Directory backupsDir;
    late AppDatabase db;
    late BackupService backupService;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('th_service_test_');
      photosDir = Directory('${tempDir.path}/photos')..createSync();
      backupsDir = Directory('${tempDir.path}/backups')..createSync();

      // Create a dummy photo file
      final photoFile = File('${photosDir.path}/sample_photo.jpg');
      await photoFile.writeAsString('fake_image_bytes');

      final dbPath = '${tempDir.path}/tierra_y_hoja_service.db';
      db = await AppDatabase.open(path: dbPath);

      // Insert dummy plot with photo
      await db.db.insert('plots', {
        'name': 'Lote El Roble',
        'area': 3.0,
        'area_unit': 'hectareas',
        'photo_path': photoFile.path,
        'created_at': DateTime.now().millisecondsSinceEpoch,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      });

      backupService = BackupService(
        db,
        FakePhotoStorageService(photosDir),
        packageInfo: PackageInfo(
          appName: 'Tierra & Hoja',
          packageName: 'com.tierrayhoja.app',
          version: '1.1.4',
          buildNumber: '6',
        ),
        defaultBackupDirectory: backupsDir,
      );
    });

    tearDown(() async {
      await db.close();
      try {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      } catch (_) {}
    });

    test('createBackup, inspectBackupFile, restoreBackup and deleteBackup work correctly', () async {
      // 1. Create backup
      final backupItem = await backupService.createBackup();
      expect(await backupItem.file.exists(), isTrue);
      expect(backupItem.manifest?.stats.plots, 1);
      expect(backupItem.manifest?.stats.photos, 1);

      // 2. Inspect backup
      final inspection = await backupService.inspectBackupFile(backupItem.file.path);
      expect(inspection.isValid, isTrue);
      expect(inspection.manifest?.app, 'Tierra & Hoja');
      expect(inspection.manifest?.stats.plots, 1);

      // 3. Modify current DB to prove restore replaces it
      await db.db.insert('plots', {
        'name': 'Lote Temporal',
        'area': 1.0,
        'area_unit': 'manzanas',
        'created_at': DateTime.now().millisecondsSinceEpoch,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      });
      final countBefore = Sqflite.firstIntValue(await db.db.rawQuery('SELECT COUNT(*) FROM plots'));
      expect(countBefore, 2);

      // 4. Restore backup
      final restoredManifest = await backupService.restoreBackup(backupItem.file.path);
      expect(restoredManifest.stats.plots, 1);

      final countAfter = Sqflite.firstIntValue(await db.db.rawQuery('SELECT COUNT(*) FROM plots'));
      expect(countAfter, 1); // Restored to 1 plot!

      final restoredPlot = (await db.db.query('plots')).first;
      expect(restoredPlot['name'], 'Lote El Roble');
      // Verify photo path was fixed to the device photos directory
      expect(restoredPlot['photo_path'], p.join(photosDir.path, 'sample_photo.jpg'));

      // 5. Delete backup
      await backupService.deleteBackup(backupItem.file.path);
      expect(await backupItem.file.exists(), isFalse);
    });
  });

  group('BackupRestoreView Widget Tests', () {
    late Directory tempDir;
    late Directory photosDir;
    late Directory backupsDir;
    late AppDatabase db;
    late BackupService backupService;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('th_backup_test_');
      photosDir = Directory('${tempDir.path}/photos')..createSync();
      backupsDir = Directory('${tempDir.path}/backups')..createSync();

      final dbPath = '${tempDir.path}/tierra_y_hoja_test.db';
      db = await AppDatabase.open(path: dbPath);

      // Insert dummy plot
      await db.db.insert('plots', {
        'name': 'Lote La Vega',
        'area': 1.5,
        'area_unit': 'manzanas',
        'created_at': DateTime.now().millisecondsSinceEpoch,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      });

      backupService = BackupService(
        db,
        FakePhotoStorageService(photosDir),
        packageInfo: PackageInfo(
          appName: 'Tierra & Hoja',
          packageName: 'com.tierrayhoja.app',
          version: '1.1.4',
          buildNumber: '6',
        ),
        defaultBackupDirectory: backupsDir,
      );

      // Configure backup directory to temp
      await backupService.setConfiguredBackupDirectory(backupsDir.path);
    });

    tearDown(() async {
      await db.close();
      try {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      } catch (_) {}
    });

    testWidgets('MoreView contains Copias de Seguridad y Restauración and navigates to it', (tester) async {
      await tester.runAsync(() async {
        tester.view.physicalSize = const Size(800, 1200);
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              Provider<AppDatabase>.value(value: db),
              ChangeNotifierProvider<ThemeController>(create: (_) => ThemeController(db)),
              Provider<PackageInfo>(
                create: (_) => PackageInfo(
                  appName: 'Tierra & Hoja',
                  packageName: 'com.tierrayhoja.app',
                  version: '1.1.4',
                  buildNumber: '6',
                ),
              ),
              Provider<BackupService>.value(value: backupService),
              Provider<DataChanges>.value(value: db.changes),
            ],
            child: MaterialApp(
              theme: AppTheme.light,
              home: const MoreView(),
            ),
          ),
        );

        await tester.pump();
        await Future<void>.delayed(const Duration(milliseconds: 300));
        await tester.pump();

        // Check section header and list row
        expect(find.text('COPIAS Y RESPALDO'), findsOneWidget);
        expect(find.text('Copias de Seguridad y Restauración'), findsOneWidget);
        expect(
          find.text('Respalde o restaure la base de datos y fotos completas'),
          findsOneWidget,
        );

        // Ensure visible and tap list row to navigate to BackupRestoreView
        await tester.ensureVisible(find.text('Copias de Seguridad y Restauración'));
        await tester.tap(find.text('Copias de Seguridad y Restauración'));
        await tester.pump();
        await Future<void>.delayed(const Duration(milliseconds: 600));
        await tester.pump();

        // Verify BackupRestoreView is shown
        expect(find.byType(BackupRestoreView), findsOneWidget);
        expect(find.text('UBICACIÓN DE ALMACENAMIENTO'), findsOneWidget);
        expect(find.text('CREAR COPIA DE SEGURIDAD'), findsOneWidget);
        expect(find.text('RESTAURAR COPIA DE SEGURIDAD'), findsOneWidget);
      });
    });

    testWidgets('BackupRestoreView renders sections and action buttons without layout overflow', (tester) async {
      await tester.runAsync(() async {
        // Test on narrow phone size (320x800)
        tester.view.physicalSize = const Size(320 * 2, 800 * 2);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              Provider<AppDatabase>.value(value: db),
              Provider<BackupService>.value(value: backupService),
              Provider<DataChanges>.value(value: db.changes),
            ],
            child: MaterialApp(
              theme: AppTheme.light,
              home: const BackupRestoreView(),
            ),
          ),
        );

        await tester.pump();
        await Future<void>.delayed(const Duration(milliseconds: 400));
        await tester.pump();

        // Verify titles and buttons
        expect(find.text('Carpeta de respaldos'), findsOneWidget);
        expect(find.text('Cambiar carpeta'), findsOneWidget);
        expect(find.text('Crear copia de seguridad ahora'), findsOneWidget);
        expect(find.text('Seleccionar archivo de respaldo...'), findsOneWidget);

        // Verify current stats are displayed (1 lote)
        expect(find.textContaining('1 lotes'), findsOneWidget);
      });
    });

    testWidgets('BackupRestoreView creates backup and lists it in detected backups', (tester) async {
      await tester.runAsync(() async {
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              Provider<AppDatabase>.value(value: db),
              Provider<BackupService>.value(value: backupService),
              Provider<DataChanges>.value(value: db.changes),
            ],
            child: MaterialApp(
              theme: AppTheme.light,
              home: const BackupRestoreView(),
            ),
          ),
        );

        await tester.pump();
        await Future<void>.delayed(const Duration(milliseconds: 400));
        await tester.pump();

        // Tap on Crear copia de seguridad ahora
        await tester.ensureVisible(find.text('Crear copia de seguridad ahora'));
        await tester.tap(find.text('Crear copia de seguridad ahora'));
        await tester.pump();
        await Future<void>.delayed(const Duration(milliseconds: 1000));
        await tester.pump();

        // Check success sheet appears
        expect(find.text('Copia creada exitosamente'), findsOneWidget);
        expect(find.text('Compartir copia ahora'), findsOneWidget);

        // Close success sheet
        await tester.tap(find.text('Cerrar'), warnIfMissed: false);
        await tester.pump();
        await Future<void>.delayed(const Duration(milliseconds: 400));
        await tester.pump();

        // Verify backup is listed in the list
        expect(find.textContaining('tierra_y_hoja_respaldo_'), findsWidgets);
        expect(find.text('Compartir'), findsOneWidget);
        expect(find.text('Restaurar'), findsOneWidget);
      });
    });
  });
}
