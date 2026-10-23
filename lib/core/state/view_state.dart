/// Estado de una vista que carga datos. Sellado: el compilador obliga a
/// cubrir cargando, datos y error en cada `switch`.
sealed class ViewState<T> {
  const ViewState();

  /// Datos actuales si existen (útil para mostrar contenido mientras recarga).
  T? get dataOrNull => switch (this) {
    ViewData<T>(:final data) => data,
    _ => null,
  };
}

final class ViewLoading<T> extends ViewState<T> {
  const ViewLoading();
}

final class ViewData<T> extends ViewState<T> {
  const ViewData(this.data);
  final T data;
}

final class ViewError<T> extends ViewState<T> {
  const ViewError(this.message);
  final String message;
}

/// Resultado de una operación de guardado.
sealed class SaveResult {
  const SaveResult();
}

final class SaveSuccess extends SaveResult {
  const SaveSuccess({this.id, this.message});

  /// Id del registro creado o actualizado.
  final int? id;

  /// Mensaje para el aviso de confirmación.
  final String? message;
}

final class SaveFailure extends SaveResult {
  const SaveFailure(this.message);
  final String message;
}
