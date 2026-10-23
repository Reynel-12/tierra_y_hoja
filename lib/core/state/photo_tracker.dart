import '../services/photo_storage_service.dart';

/// Lleva el control de las fotos tomadas en un formulario para no dejar
/// archivos huérfanos:
/// - Si el formulario se descarta, borra las fotos nuevas.
/// - Si se guarda, borra las fotos que fueron reemplazadas o quitadas.
class PhotoTracker {
  PhotoTracker(this._service);

  final PhotoStorageService _service;
  final Set<String> _added = {};
  final Set<String> _removed = {};

  /// Registra el cambio de una foto por otra (cualquiera puede ser `null`).
  void replace({String? oldPath, String? newPath}) {
    if (oldPath == newPath) return;
    if (oldPath != null) {
      if (_added.remove(oldPath)) {
        _service.delete(oldPath);
      } else {
        _removed.add(oldPath);
      }
    }
    if (newPath != null) _added.add(newPath);
  }

  /// Llamar después de guardar con éxito.
  Future<void> commit() async {
    final toDelete = {..._removed};
    _added.clear();
    _removed.clear();
    await _service.deleteAll(toDelete);
  }

  /// Llamar si el formulario se cierra sin guardar.
  Future<void> rollback() async {
    final toDelete = {..._added};
    _added.clear();
    _removed.clear();
    await _service.deleteAll(toDelete);
  }
}
