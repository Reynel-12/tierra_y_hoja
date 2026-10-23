import 'dart:async';

import 'package:flutter/widgets.dart';

import '../database/data_changes.dart';
import '../database/db_schema.dart';
import 'view_state.dart';

/// Controlador base con `notifyListeners` seguro tras `dispose`.
abstract class BaseController extends ChangeNotifier {
  bool _disposed = false;

  bool get isDisposed => _disposed;

  @protected
  void notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

/// Controlador que carga datos de la base y se recarga solo cuando cambian
/// las tablas que observa.
abstract class LoadableController<T> extends BaseController {
  LoadableController(DataChanges changes, {required Set<DbTable> watch}) {
    _subscription = changes.watch(watch).listen((_) => load(silent: true));
  }

  StreamSubscription<Set<DbTable>>? _subscription;
  ViewState<T> _state = const ViewLoading();
  int _loadToken = 0;

  ViewState<T> get state => _state;

  /// Obtiene los datos. Lo implementa cada controlador.
  @protected
  Future<T> fetch();

  /// Carga los datos. Con [silent] no muestra skeleton (recarga en segundo
  /// plano conservando lo que ya se ve).
  Future<void> load({bool silent = false}) async {
    final token = ++_loadToken;
    if (!silent || _state is! ViewData<T>) {
      _state = const ViewLoading();
      notify();
    }
    try {
      final data = await fetch();
      if (token != _loadToken) return;
      _state = ViewData(data);
    } catch (error, stack) {
      if (token != _loadToken) return;
      debugPrint('Error al cargar $runtimeType: $error\n$stack');
      _state = const ViewError(
        'No se pudieron leer los datos del teléfono. Intente de nuevo.',
      );
    }
    notify();
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }
}

/// Controlador base de formularios: guarda estado de "sucio" y "guardando",
/// y es dueño de los `TextEditingController` que registra.
abstract class FormController extends BaseController {
  final List<TextEditingController> _textControllers = [];
  bool _dirty = false;
  bool _saving = false;
  bool _ready = true;

  bool get isDirty => _dirty;
  bool get isSaving => _saving;

  /// `false` mientras se cargan los datos de un registro a editar.
  bool get isReady => _ready;

  /// Crea un campo de texto que marca el formulario como modificado.
  @protected
  TextEditingController text([String initial = '']) {
    final controller = TextEditingController(text: initial);
    controller.addListener(markDirty);
    _textControllers.add(controller);
    return controller;
  }

  /// Rellena un campo sin marcar el formulario como modificado.
  @protected
  void setTextSilently(TextEditingController controller, String value) {
    controller.removeListener(markDirty);
    controller.text = value;
    controller.addListener(markDirty);
  }

  void markDirty() {
    if (_dirty) return;
    _dirty = true;
    notify();
  }

  /// Cambia un valor de selección y marca el formulario como modificado.
  @protected
  void update(VoidCallback change) {
    change();
    _dirty = true;
    notify();
  }

  @protected
  void markReady() {
    _ready = true;
    notify();
  }

  /// Ejecuta el guardado mostrando el estado "guardando".
  Future<SaveResult> save() async {
    if (_saving) return const SaveFailure('Ya se está guardando.');
    _saving = true;
    notify();
    try {
      final result = await performSave();
      if (result is SaveSuccess) _dirty = false;
      return result;
    } catch (error, stack) {
      debugPrint('Error al guardar $runtimeType: $error\n$stack');
      return const SaveFailure(
        'No se pudo guardar en el teléfono. Revise el espacio libre e intente de nuevo.',
      );
    } finally {
      _saving = false;
      notify();
    }
  }

  /// Lógica concreta de guardado. Se llama solo si el formulario es válido.
  @protected
  Future<SaveResult> performSave();

  @override
  void dispose() {
    for (final controller in _textControllers) {
      controller.dispose();
    }
    super.dispose();
  }
}
