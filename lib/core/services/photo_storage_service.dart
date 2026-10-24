import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

enum PhotoSource { camera, gallery }

/// Error de fotos con un mensaje listo para mostrar al usuario.
class PhotoException implements Exception {
  const PhotoException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Toma, comprime y guarda fotos fuera de la base de datos.
///
/// - La foto se comprime (máx. 1600 px, calidad 70) para no llenar la memoria.
/// - Se guarda en la carpeta privada de la app; la base de datos solo guarda
///   la ruta del archivo.
/// - Las fotos tomadas con la cámara se copian además al álbum
///   "Tierra y Hoja" de la galería del teléfono.
class PhotoStorageService {
  PhotoStorageService({ImagePicker? picker})
    : _picker = picker ?? ImagePicker();

  static const albumName = 'Tierra y Hoja';
  static const _maxSide = 1600.0;
  static const _quality = 70;

  final ImagePicker _picker;
  Directory? _photosDir;

  /// Abre la cámara o la galería. Devuelve la ruta guardada o `null` si el
  /// usuario canceló. Por defecto, la cámara se abre con el lente principal trasero.
  Future<String?> pick(
    PhotoSource source, {
    CameraDevice preferredCameraDevice = CameraDevice.rear,
  }) async {
    final XFile? picked;
    try {
      picked = await _picker.pickImage(
        source: source == PhotoSource.camera
            ? ImageSource.camera
            : ImageSource.gallery,
        maxWidth: _maxSide,
        maxHeight: _maxSide,
        imageQuality: _quality,
        requestFullMetadata: false,
        preferredCameraDevice: preferredCameraDevice,
      );
    } on PlatformException catch (e) {
      debugPrint('Error al abrir ${source.name}: $e');
      throw PhotoException(
        source == PhotoSource.camera
            ? 'No se pudo abrir la cámara. Revise el permiso de cámara en los ajustes del teléfono.'
            : 'No se pudo abrir la galería. Revise el permiso de fotos en los ajustes del teléfono.',
      );
    }
    if (picked == null) return null;

    final dir = await _directory();
    final extension = p.extension(picked.path).isEmpty
        ? '.jpg'
        : p.extension(picked.path).toLowerCase();
    final target = p.join(
      dir.path,
      'th_${DateTime.now().millisecondsSinceEpoch}$extension',
    );
    await picked.saveTo(target);

    if (source == PhotoSource.camera) {
      unawaited(_copyToGallery(target));
    }
    return target;
  }

  /// Borra la copia privada de la foto (la copia de la galería se conserva).
  Future<void> delete(String? path) async {
    if (path == null || path.isEmpty) return;
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (e) {
      debugPrint('No se pudo borrar la foto $path: $e');
    }
  }

  Future<void> deleteAll(Iterable<String?> paths) async {
    for (final path in paths) {
      await delete(path);
    }
  }

  Future<Directory> _directory() async {
    final cached = _photosDir;
    if (cached != null) return cached;
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, 'photos'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return _photosDir = dir;
  }

  Future<void> _copyToGallery(String path) async {
    try {
      var hasAccess = await Gal.hasAccess(toAlbum: true);
      if (!hasAccess) hasAccess = await Gal.requestAccess(toAlbum: true);
      if (!hasAccess) return;
      await Gal.putImage(path, album: albumName);
    } catch (e) {
      // La copia en la galería es un respaldo: si falla, la foto sigue
      // guardada en la app y el registro no se pierde.
      debugPrint('No se pudo copiar la foto a la galería: $e');
    }
  }
}
