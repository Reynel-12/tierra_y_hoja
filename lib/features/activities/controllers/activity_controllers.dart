import 'package:flutter/widgets.dart';

import '../../../core/services/photo_storage_service.dart';
import '../../../core/state/base_controllers.dart';
import '../../../core/state/photo_tracker.dart';
import '../../../core/state/view_state.dart';
import '../../../core/utils/formatters.dart';
import '../../cycles/data/cycle_repository.dart';
import '../../cycles/models/crop_cycle.dart';
import '../data/activity_repository.dart';
import '../models/activity_models.dart';

class TaskFormController extends FormController {
  TaskFormController(
    this._repository,
    this._cycleRepository,
    this._photoService, {
    this.initialTask,
    int? preselectedCycleId,
  }) {
    _photoTracker = PhotoTracker(_photoService);
    methodController = text(initialTask?.method ?? '');
    irrigationHoursController = text(
      initialTask?.irrigationHours != null
          ? Formatters.editable(initialTask!.irrigationHours)
          : '',
    );
    irrigationMmController = text(
      initialTask?.irrigationMm != null ? Formatters.editable(initialTask!.irrigationMm) : '',
    );
    workersController = text(
      initialTask?.workers != null ? initialTask!.workers.toString() : '',
    );
    notesController = text(initialTask?.notes ?? '');

    selectedCycleId = initialTask?.cycleId ?? preselectedCycleId;
    selectedTaskType = initialTask?.taskType ?? TaskType.deshierbeChapea;
    date = initialTask?.date ?? DateTime.now();
    photoPath = initialTask?.photoPath;

    _loadCycles();
  }

  final ActivityRepository _repository;
  final CycleRepository _cycleRepository;
  final PhotoStorageService _photoService;
  final CulturalTask? initialTask;
  late final PhotoTracker _photoTracker;

  late final TextEditingController methodController;
  late final TextEditingController irrigationHoursController;
  late final TextEditingController irrigationMmController;
  late final TextEditingController workersController;
  late final TextEditingController notesController;

  List<CropCycle> availableCycles = [];
  int? selectedCycleId;
  late TaskType selectedTaskType;
  late DateTime date;
  String? photoPath;

  bool get isEditing => initialTask != null;

  Future<void> _loadCycles() async {
    try {
      availableCycles = await _cycleRepository.getAll(onlyActive: true);
      if (availableCycles.isEmpty) {
        availableCycles = await _cycleRepository.getAll();
      }
      if (selectedCycleId == null && availableCycles.isNotEmpty) {
        selectedCycleId = availableCycles.first.id;
      }
    } catch (_) {
      availableCycles = [];
    }
    markReady();
  }

  void setCycle(int? cycleId) => update(() => selectedCycleId = cycleId);

  void setTaskType(TaskType type) => update(() => selectedTaskType = type);

  void setDate(DateTime d) => update(() => date = d);

  void setPhoto(String? path) {
    _photoTracker.replace(oldPath: photoPath, newPath: path);
    update(() => photoPath = path);
  }

  @override
  Future<SaveResult> performSave() async {
    if (selectedCycleId == null) {
      return const SaveFailure('Debe seleccionar la siembra correspondiente.');
    }

    final now = DateTime.now();
    final task = CulturalTask(
      id: initialTask?.id,
      cycleId: selectedCycleId!,
      taskType: selectedTaskType,
      method: methodController.text.trim().isEmpty ? null : methodController.text.trim(),
      date: date,
      irrigationHours: Formatters.parseNumber(irrigationHoursController.text),
      irrigationMm: Formatters.parseNumber(irrigationMmController.text),
      workers: int.tryParse(workersController.text.trim()),
      notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
      photoPath: photoPath,
      createdAt: initialTask?.createdAt ?? now,
    );

    if (isEditing) {
      await _repository.updateTask(task);
    } else {
      await _repository.insertTask(task);
    }
    await _photoTracker.commit();

    return SaveSuccess(message: isEditing ? 'Labor actualizada' : 'Labor registrada');
  }

  Future<bool> delete() async {
    if (initialTask?.id == null) return false;
    try {
      await _repository.deleteTask(initialTask!.id!);
      if (initialTask?.photoPath != null) {
        await _photoService.delete(initialTask!.photoPath);
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  void dispose() {
    if (isDirty) {
      _photoTracker.rollback();
    }
    super.dispose();
  }
}

class IncidentFormController extends FormController {
  IncidentFormController(
    this._repository,
    this._cycleRepository,
    this._photoService, {
    this.initialIncident,
    int? preselectedCycleId,
  }) {
    _photoTracker = PhotoTracker(_photoService);
    nameController = text(initialIncident?.name ?? '');
    actionTakenController = text(initialIncident?.actionTaken ?? '');
    notesController = text(initialIncident?.notes ?? '');

    selectedCycleId = initialIncident?.cycleId ?? preselectedCycleId;
    selectedKind = initialIncident?.kind ?? IncidentKind.plaga;
    selectedSeverity = initialIncident?.severity ?? IncidentSeverity.moderada;
    date = initialIncident?.date ?? DateTime.now();
    photoPath = initialIncident?.photoPath;

    _loadCycles();
  }

  final ActivityRepository _repository;
  final CycleRepository _cycleRepository;
  final PhotoStorageService _photoService;
  final Incident? initialIncident;
  late final PhotoTracker _photoTracker;

  late final TextEditingController nameController;
  late final TextEditingController actionTakenController;
  late final TextEditingController notesController;

  List<CropCycle> availableCycles = [];
  int? selectedCycleId;
  late IncidentKind selectedKind;
  late IncidentSeverity selectedSeverity;
  late DateTime date;
  String? photoPath;

  bool get isEditing => initialIncident != null;

  Future<void> _loadCycles() async {
    try {
      availableCycles = await _cycleRepository.getAll(onlyActive: true);
      if (availableCycles.isEmpty) {
        availableCycles = await _cycleRepository.getAll();
      }
      if (selectedCycleId == null && availableCycles.isNotEmpty) {
        selectedCycleId = availableCycles.first.id;
      }
    } catch (_) {
      availableCycles = [];
    }
    markReady();
  }

  void setCycle(int? cycleId) => update(() => selectedCycleId = cycleId);

  void setKind(IncidentKind kind) => update(() => selectedKind = kind);

  void setSeverity(IncidentSeverity severity) => update(() => selectedSeverity = severity);

  void setDate(DateTime d) => update(() => date = d);

  void setPhoto(String? path) {
    _photoTracker.replace(oldPath: photoPath, newPath: path);
    update(() => photoPath = path);
  }

  @override
  Future<SaveResult> performSave() async {
    if (selectedCycleId == null) {
      return const SaveFailure('Debe seleccionar la siembra correspondiente.');
    }

    final now = DateTime.now();
    final incident = Incident(
      id: initialIncident?.id,
      cycleId: selectedCycleId!,
      kind: selectedKind,
      name: nameController.text.trim(),
      severity: selectedSeverity,
      date: date,
      actionTaken: actionTakenController.text.trim().isEmpty ? null : actionTakenController.text.trim(),
      notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
      photoPath: photoPath,
      createdAt: initialIncident?.createdAt ?? now,
    );

    if (isEditing) {
      await _repository.updateIncident(incident);
    } else {
      await _repository.insertIncident(incident);
    }
    await _photoTracker.commit();

    return SaveSuccess(message: isEditing ? 'Incidencia actualizada' : 'Incidencia registrada');
  }

  Future<bool> delete() async {
    if (initialIncident?.id == null) return false;
    try {
      await _repository.deleteIncident(initialIncident!.id!);
      if (initialIncident?.photoPath != null) {
        await _photoService.delete(initialIncident!.photoPath);
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  void dispose() {
    if (isDirty) {
      _photoTracker.rollback();
    }
    super.dispose();
  }
}
