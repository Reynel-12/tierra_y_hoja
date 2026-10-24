import 'package:flutter/widgets.dart';

import '../../../core/database/data_changes.dart';
import '../../../core/database/db_schema.dart';
import '../../../core/services/photo_storage_service.dart';
import '../../../core/services/reminder_service.dart';
import '../../../core/state/base_controllers.dart';
import '../../../core/state/photo_tracker.dart';
import '../../../core/state/view_state.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/form/verdict_tiles.dart';
import '../../cycles/data/cycle_repository.dart';
import '../../cycles/models/crop_cycle.dart';
import '../data/application_repository.dart';
import '../models/input_application.dart';

/// Opciones para recordatorio de revisión (§7.4): 3 días, 5 días, 7 días, Sin recordatorio.
enum ReminderOption {
  threeDays(3, '3 días'),
  fiveDays(5, '5 días'),
  sevenDays(7, '7 días'),
  none(0, 'Sin recordatorio');

  const ReminderOption(this.days, this.label);
  final int days;
  final String label;
}

class ApplicationFormController extends FormController {
  ApplicationFormController(
    this._repository,
    this._cycleRepository,
    this._photoService,
    this._reminderService, {
    this.initialApp,
    int? preselectedCycleId,
  }) {
    _photoTracker = PhotoTracker(_photoService);
    productNameController = text(initialApp?.productName ?? '');
    doseValueController = text(
      initialApp?.doseValue != null
          ? Formatters.editable(initialApp!.doseValue)
          : '',
    );
    methodController = text(initialApp?.method ?? '');
    notesController = text(initialApp?.notes ?? '');

    selectedCycleId = initialApp?.cycleId ?? preselectedCycleId;
    selectedInputType = initialApp?.inputType ?? InputType.fertilizanteGranular;
    selectedDoseUnit = initialApp?.doseUnit ?? DoseUnit.copasBomba;
    appliedAt = initialApp?.appliedAt ?? DateTime.now();
    selectedTimeOfDay = initialApp?.timeOfDay ?? TimeOfDayChoice.morning;
    selectedWeather = initialApp?.weather ?? WeatherCondition.sunny;
    photoBefore = initialApp?.photoBefore;

    // Calcular recordatorio
    if (initialApp?.reviewDueAt != null) {
      final diff = initialApp!.reviewDueAt!
          .difference(initialApp!.appliedAt)
          .inDays;
      if (diff <= 3) {
        selectedReminder = ReminderOption.threeDays;
      } else if (diff <= 5) {
        selectedReminder = ReminderOption.fiveDays;
      } else {
        selectedReminder = ReminderOption.sevenDays;
      }
    } else {
      selectedReminder =
          ReminderOption.threeDays; // Valor por defecto inteligente
    }

    _loadCycles();
  }

  final ApplicationRepository _repository;
  final CycleRepository _cycleRepository;
  final PhotoStorageService _photoService;
  final ReminderService _reminderService;
  final InputApplication? initialApp;
  late final PhotoTracker _photoTracker;

  late final TextEditingController productNameController;
  late final TextEditingController doseValueController;
  late final TextEditingController methodController;
  late final TextEditingController notesController;

  List<CropCycle> availableCycles = [];
  int? selectedCycleId;
  late InputType selectedInputType;
  late DoseUnit selectedDoseUnit;
  late DateTime appliedAt;
  TimeOfDayChoice? selectedTimeOfDay;
  WeatherCondition? selectedWeather;
  String? photoBefore;
  late ReminderOption selectedReminder;

  bool get isEditing => initialApp != null;

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

  void setInputType(InputType type) => update(() => selectedInputType = type);

  void setDoseUnit(DoseUnit unit) => update(() => selectedDoseUnit = unit);

  void setAppliedAt(DateTime date) => update(() => appliedAt = date);

  void setTimeOfDay(TimeOfDayChoice? time) =>
      update(() => selectedTimeOfDay = time);

  void setWeather(WeatherCondition? condition) =>
      update(() => selectedWeather = condition);

  void setReminder(ReminderOption option) =>
      update(() => selectedReminder = option);

  void setPhotoBefore(String? path) {
    _photoTracker.replace(oldPath: photoBefore, newPath: path);
    update(() => photoBefore = path);
  }

  @override
  Future<SaveResult> performSave() async {
    if (selectedCycleId == null) {
      return const SaveFailure(
        'Debe seleccionar la siembra a la que aplica este insumo.',
      );
    }

    final now = DateTime.now();
    final doseVal = Formatters.parseNumber(doseValueController.text);

    DateTime? reviewDue;
    if (selectedReminder != ReminderOption.none) {
      final dueDate = appliedAt.add(Duration(days: selectedReminder.days));
      reviewDue = DateTime(
        dueDate.year,
        dueDate.month,
        dueDate.day,
        ReminderService.reminderHour,
      );
    }

    final app = InputApplication(
      id: initialApp?.id,
      cycleId: selectedCycleId!,
      inputType: selectedInputType,
      productName: productNameController.text.trim(),
      doseValue: doseVal,
      doseUnit: doseVal != null ? selectedDoseUnit : null,
      method: methodController.text.trim().isEmpty
          ? null
          : methodController.text.trim(),
      appliedAt: appliedAt,
      timeOfDay: selectedTimeOfDay,
      weather: selectedWeather,
      reviewDueAt: reviewDue,
      photoBefore: photoBefore,
      notes: notesController.text.trim().isEmpty
          ? null
          : notesController.text.trim(),
      createdAt: initialApp?.createdAt ?? now,
    );

    int savedId;
    if (isEditing) {
      await _repository.update(app);
      savedId = initialApp!.id!;
    } else {
      savedId = await _repository.insert(app);
    }
    await _photoTracker.commit();

    // Programar notificación de recordatorio si corresponde
    if (reviewDue != null) {
      await _reminderService.requestPermission();
      await _reminderService.schedule(
        id: savedId,
        at: reviewDue,
        title: 'Revisión de cultivo pendiente',
        body:
            'Es momento de revisar la reacción a ${app.productName}. ¿Cómo respondió la planta?',
        payload: savedId.toString(),
      );
    } else if (isEditing) {
      await _reminderService.cancel(savedId);
    }

    return SaveSuccess(
      id: savedId,
      message: isEditing ? 'Aplicación actualizada' : 'Aplicación guardada',
    );
  }

  Future<bool> delete() async {
    if (initialApp?.id == null) return false;
    try {
      await _reminderService.cancel(initialApp!.id!);
      await _repository.delete(initialApp!.id!);
      if (initialApp?.photoBefore != null) {
        await _photoService.delete(initialApp!.photoBefore);
      }
      if (initialApp?.photoAfter != null) {
        await _photoService.delete(initialApp!.photoAfter);
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

class FollowUpFormController extends FormController {
  FollowUpFormController(
    this.application,
    this._repository,
    this._photoService,
    this._reminderService,
  ) {
    _photoTracker = PhotoTracker(_photoService);
    reactionNotesController = text(application.reactionNotes ?? '');
    symptomsDetailsController = text('');

    selectedVerdict = application.verdict ?? ReactionVerdict.positive;
    photoAfter = application.photoAfter;

    if (application.symptoms != null && application.symptoms!.isNotEmpty) {
      selectedSymptoms = application.symptoms!.split(', ').toSet();
    }

    markReady();
  }

  final InputApplication application;
  final ApplicationRepository _repository;
  final PhotoStorageService _photoService;
  final ReminderService _reminderService;
  late final PhotoTracker _photoTracker;

  late final TextEditingController reactionNotesController;
  late final TextEditingController symptomsDetailsController;

  ReactionVerdict? selectedVerdict;
  Set<String> selectedSymptoms = {};
  String? photoAfter;

  void setVerdict(ReactionVerdict? verdict) =>
      update(() => selectedVerdict = verdict);

  void setSymptoms(Set<String> symptoms) =>
      update(() => selectedSymptoms = symptoms);

  void setPhotoAfter(String? path) {
    _photoTracker.replace(oldPath: photoAfter, newPath: path);
    update(() => photoAfter = path);
  }

  @override
  Future<SaveResult> performSave() async {
    if (selectedVerdict == null) {
      return const SaveFailure('Por favor elija un veredicto de reacción.');
    }

    final symptomsList = selectedSymptoms.toList();
    if (symptomsDetailsController.text.trim().isNotEmpty) {
      symptomsList.add(symptomsDetailsController.text.trim());
    }

    await _repository.updateReaction(
      id: application.id!,
      verdict: selectedVerdict!.name,
      reactionNotes: reactionNotesController.text.trim().isEmpty
          ? null
          : reactionNotesController.text.trim(),
      symptoms: symptomsList.isEmpty ? null : symptomsList.join(', '),
      photoAfter: photoAfter,
    );

    await _photoTracker.commit();
    await _reminderService.cancel(application.id!);

    return const SaveSuccess(message: 'Veredicto de reacción guardado');
  }

  @override
  void dispose() {
    if (isDirty) {
      _photoTracker.rollback();
    }
    super.dispose();
  }
}

class PendingReviewsController
    extends LoadableController<List<InputApplication>> {
  PendingReviewsController(this._repository, DataChanges changes)
    : super(changes, watch: {DbTable.applications, DbTable.cycles}) {
    load();
  }

  final ApplicationRepository _repository;

  @override
  Future<List<InputApplication>> fetch() => _repository.getPendingReviews();
}
