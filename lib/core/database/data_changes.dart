import 'dart:async';

import 'db_schema.dart';

/// Bus de cambios de la base de datos.
///
/// Los repositorios avisan qué tabla cambió y los controladores que
/// dependen de ella recargan. Así las listas siempre están al día sin
/// acoplar pantallas entre sí.
class DataChanges {
  final _controller = StreamController<Set<DbTable>>.broadcast();

  Stream<Set<DbTable>> get stream => _controller.stream;

  void notify(Set<DbTable> tables) {
    if (tables.isEmpty || _controller.isClosed) return;
    _controller.add(tables);
  }

  /// Emite solo cuando cambia alguna de las [tables] indicadas.
  Stream<Set<DbTable>> watch(Set<DbTable> tables) =>
      stream.where((changed) => changed.any(tables.contains));

  Future<void> dispose() => _controller.close();
}
