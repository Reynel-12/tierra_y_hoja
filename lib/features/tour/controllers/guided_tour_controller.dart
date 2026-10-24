import 'package:flutter/foundation.dart';

import '../../../core/database/app_database.dart';
import '../models/tour_step_data.dart';

/// Controlador del Tour Guiado de la aplicación.
///
/// Gestiona si el usuario ya vio el recorrido introductorio (guardado en
/// la tabla `app_settings` de SQLite), el paso actual y la navegación paso a paso.
class GuidedTourController extends ChangeNotifier {
  GuidedTourController([this._database]);

  final AppDatabase? _database;

  bool _isLoaded = false;
  bool _isCompleted = false;
  int _currentStepIndex = 0;

  bool get isLoaded => _isLoaded;
  bool get isCompleted => _isCompleted;
  int get currentStepIndex => _currentStepIndex;
  int get totalSteps => TourStepData.steps.length;

  TourStepData get currentStep => TourStepData.steps[_currentStepIndex];
  bool get isFirstStep => _currentStepIndex == 0;
  bool get isLastStep => _currentStepIndex == totalSteps - 1;

  /// Carga el estado inicial desde la base de datos local SQLite.
  Future<void> init() async {
    if (_database == null) {
      _isLoaded = true;
      notifyListeners();
      return;
    }

    try {
      final rows = await _database.db.query(
        'app_settings',
        where: 'key = ?',
        whereArgs: ['guided_tour_completed'],
      );
      if (rows.isNotEmpty) {
        final val = rows.first['value'] as String?;
        _isCompleted = val == 'true';
      } else {
        _isCompleted = false;
      }
    } catch (_) {
      _isCompleted = false;
    } finally {
      _isLoaded = true;
      notifyListeners();
    }
  }

  /// Cambia al paso especificado (0 a totalSteps - 1).
  void goToStep(int index) {
    if (index >= 0 && index < totalSteps && index != _currentStepIndex) {
      _currentStepIndex = index;
      notifyListeners();
    }
  }

  /// Avanza al siguiente paso.
  void nextStep() {
    if (_currentStepIndex < totalSteps - 1) {
      _currentStepIndex++;
      notifyListeners();
    }
  }

  /// Retrocede al paso anterior.
  void previousStep() {
    if (_currentStepIndex > 0) {
      _currentStepIndex--;
      notifyListeners();
    }
  }

  /// Marca el tour como completado en SQLite y notifica para pasar a la app real.
  Future<void> completeTour() async {
    _isCompleted = true;
    notifyListeners();

    if (_database != null) {
      try {
        await _database.db.rawInsert(
          'INSERT OR REPLACE INTO app_settings (key, value) VALUES (?, ?)',
          ['guided_tour_completed', 'true'],
        );
      } catch (_) {}
    }
  }

  /// Reinicia el tour para permitir que el usuario vuelva a verlo desde el inicio.
  Future<void> resetTour() async {
    _isCompleted = false;
    _currentStepIndex = 0;
    notifyListeners();

    if (_database != null) {
      try {
        await _database.db.rawInsert(
          'INSERT OR REPLACE INTO app_settings (key, value) VALUES (?, ?)',
          ['guided_tour_completed', 'false'],
        );
      } catch (_) {}
    }
  }
}
