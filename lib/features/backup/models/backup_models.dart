import 'dart:convert';
import 'dart:io';

import 'package:intl/intl.dart';

/// Metadatos y estadísticas del contenido empaquetado en una copia de seguridad.
class BackupManifest {
  const BackupManifest({
    required this.app,
    required this.version,
    required this.dbVersion,
    required this.createdAt,
    required this.stats,
    this.notes,
  });

  final String app;
  final String version;
  final int dbVersion;
  final DateTime createdAt;
  final BackupContentStats stats;
  final String? notes;

  Map<String, dynamic> toJson() => {
        'app': app,
        'version': version,
        'db_version': dbVersion,
        'created_at': createdAt.toIso8601String(),
        'stats': stats.toJson(),
        if (notes != null) 'notes': notes,
      };

  factory BackupManifest.fromJson(Map<String, dynamic> json) {
    return BackupManifest(
      app: json['app'] as String? ?? 'Tierra & Hoja',
      version: json['version'] as String? ?? '1.1.0',
      dbVersion: json['db_version'] as int? ?? 1,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      stats: json['stats'] is Map<String, dynamic>
          ? BackupContentStats.fromJson(json['stats'] as Map<String, dynamic>)
          : const BackupContentStats(),
      notes: json['notes'] as String?,
    );
  }

  String toJsonString() => const JsonEncoder.withIndent('  ').convert(toJson());
}

/// Conteos de elementos almacenados en la copia de seguridad.
class BackupContentStats {
  const BackupContentStats({
    this.plots = 0,
    this.cycles = 0,
    this.applications = 0,
    this.tasks = 0,
    this.incidents = 0,
    this.expenses = 0,
    this.sales = 0,
    this.photos = 0,
  });

  final int plots;
  final int cycles;
  final int applications;
  final int tasks;
  final int incidents;
  final int expenses;
  final int sales;
  final int photos;

  int get totalRecords =>
      plots + cycles + applications + tasks + incidents + expenses + sales;

  Map<String, dynamic> toJson() => {
        'plots': plots,
        'cycles': cycles,
        'applications': applications,
        'tasks': tasks,
        'incidents': incidents,
        'expenses': expenses,
        'sales': sales,
        'photos': photos,
      };

  factory BackupContentStats.fromJson(Map<String, dynamic> json) {
    return BackupContentStats(
      plots: json['plots'] as int? ?? 0,
      cycles: json['cycles'] as int? ?? 0,
      applications: json['applications'] as int? ?? 0,
      tasks: json['tasks'] as int? ?? 0,
      incidents: json['incidents'] as int? ?? 0,
      expenses: json['expenses'] as int? ?? 0,
      sales: json['sales'] as int? ?? 0,
      photos: json['photos'] as int? ?? 0,
    );
  }
}

/// Representa un archivo de respaldo detectado en el almacenamiento.
class BackupFileItem {
  const BackupFileItem({
    required this.file,
    required this.name,
    required this.sizeBytes,
    required this.modifiedAt,
    this.manifest,
  });

  final File file;
  final String name;
  final int sizeBytes;
  final DateTime modifiedAt;
  final BackupManifest? manifest;

  String get path => file.path;

  String get formattedSize {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) {
      return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String get formattedDate {
    return DateFormat('d MMM yyyy, HH:mm', 'es').format(modifiedAt);
  }
}

/// Resultado de la inspección y validación de un archivo de respaldo antes de restaurar.
class BackupInspectionResult {
  const BackupInspectionResult({
    required this.isValid,
    required this.filePath,
    required this.fileSizeBytes,
    this.manifest,
    this.errorMessage,
    this.detectedPhotos = 0,
  });

  final bool isValid;
  final String filePath;
  final int fileSizeBytes;
  final BackupManifest? manifest;
  final String? errorMessage;
  final int detectedPhotos;

  String get formattedSize {
    if (fileSizeBytes < 1024) return '$fileSizeBytes B';
    if (fileSizeBytes < 1024 * 1024) {
      return '${(fileSizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  DateTime get date => manifest?.createdAt ?? DateTime.now();

  String get formattedDate {
    return DateFormat('d MMM yyyy, HH:mm', 'es').format(date);
  }
}
