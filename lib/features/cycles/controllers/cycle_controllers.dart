import 'package:flutter/widgets.dart';

import '../../../core/database/data_changes.dart';
import '../../../core/database/db_schema.dart';
import '../../../core/state/base_controllers.dart';
import '../../../core/state/view_state.dart';
import '../../../core/utils/formatters.dart';
import '../../plots/data/plot_repository.dart';
import '../../plots/models/plot.dart';
import '../data/cycle_repository.dart';
import '../models/crop_cycle.dart';

class CycleListController extends LoadableController<List<CropCycle>> {
  CycleListController(this._repository, DataChanges changes)
      : super(changes, watch: {DbTable.cycles, DbTable.plots}) {
    load();
  }

  final CycleRepository _repository;
  bool _onlyActive = false;
  String _filter = '';

  bool get onlyActive => _onlyActive;
  String get filter => _filter;

  void toggleFilterActive(bool onlyActive) {
    _onlyActive = onlyActive;
    notify();
  }

  void setFilter(String query) {
    _filter = query.trim().toLowerCase();
    notify();
  }

  List<CropCycle> filterList(List<CropCycle> cycles) {
    var result = cycles;
    if (_onlyActive) {
      result = result.where((c) => !c.isClosed).toList();
    }
    if (_filter.isNotEmpty) {
      result = result.where((c) {
        return c.crop.toLowerCase().contains(_filter) ||
            (c.variety?.toLowerCase().contains(_filter) ?? false) ||
            c.plotName.toLowerCase().contains(_filter);
      }).toList();
    }
    return result;
  }

  @override
  Future<List<CropCycle>> fetch() => _repository.getAll();
}

class CycleDetailController extends LoadableController<CropCycle?> {
  CycleDetailController(this.cycleId, this._repository, DataChanges changes)
      : super(changes, watch: {
          DbTable.cycles,
          DbTable.plots,
          DbTable.applications,
          DbTable.tasks,
          DbTable.incidents,
          DbTable.expenses,
          DbTable.sales,
          DbTable.stageEvents,
        }) {
    load();
  }

  final int cycleId;
  final CycleRepository _repository;
  List<StageEvent> stageEvents = [];

  @override
  Future<CropCycle?> fetch() async {
    final cycle = await _repository.getById(cycleId);
    if (cycle != null) {
      stageEvents = await _repository.getStageEvents(cycleId);
    }
    return cycle;
  }

  Future<void> changeStage(CropStage newStage, DateTime date) async {
    await _repository.updateStage(cycleId, newStage, date);
  }

  Future<bool> delete() async {
    try {
      await _repository.delete(cycleId);
      return true;
    } catch (_) {
      return false;
    }
  }
}

class CycleFormController extends FormController {
  CycleFormController(
    this._repository,
    this._plotRepository, {
    this.initialCycle,
    int? preselectedPlotId,
  }) {
    cropController = text(initialCycle?.crop ?? '');
    varietyController = text(initialCycle?.variety ?? '');
    densityValueController = text(
      initialCycle?.densityValue != null ? Formatters.editable(initialCycle!.densityValue) : '',
    );
    densityNotesController = text(initialCycle?.densityNotes ?? '');

    selectedPlotId = initialCycle?.plotId ?? preselectedPlotId;
    plantingDate = initialCycle?.plantingDate ?? DateTime.now();
    selectedDensityUnit = initialCycle?.densityUnit ?? DensityUnit.libras;
    selectedStage = initialCycle?.stage ?? CropStage.prep;

    _loadPlots();
  }

  final CycleRepository _repository;
  final PlotRepository _plotRepository;
  final CropCycle? initialCycle;

  late final TextEditingController cropController;
  late final TextEditingController varietyController;
  late final TextEditingController densityValueController;
  late final TextEditingController densityNotesController;

  List<Plot> availablePlots = [];
  int? selectedPlotId;
  late DateTime plantingDate;
  late DensityUnit selectedDensityUnit;
  late CropStage selectedStage;

  bool get isEditing => initialCycle != null;

  Future<void> _loadPlots() async {
    try {
      availablePlots = await _plotRepository.getAll();
      if (selectedPlotId == null && availablePlots.isNotEmpty) {
        selectedPlotId = availablePlots.first.id;
      }
    } catch (_) {
      availablePlots = [];
    }
    markReady();
  }

  void setPlot(int? plotId) => update(() => selectedPlotId = plotId);

  void setPlantingDate(DateTime date) => update(() => plantingDate = date);

  void setDensityUnit(DensityUnit unit) => update(() => selectedDensityUnit = unit);

  void setStage(CropStage stage) => update(() => selectedStage = stage);

  @override
  Future<SaveResult> performSave() async {
    if (selectedPlotId == null) {
      return const SaveFailure('Debe seleccionar el lote donde sembrará.');
    }

    final now = DateTime.now();
    final densityVal = Formatters.parseNumber(densityValueController.text);

    final cycle = CropCycle(
      id: initialCycle?.id,
      plotId: selectedPlotId!,
      crop: cropController.text.trim(),
      variety: varietyController.text.trim().isEmpty ? null : varietyController.text.trim(),
      plantingDate: plantingDate,
      densityValue: densityVal,
      densityUnit: densityVal != null ? selectedDensityUnit : null,
      densityNotes: densityNotesController.text.trim().isEmpty ? null : densityNotesController.text.trim(),
      stage: selectedStage,
      createdAt: initialCycle?.createdAt ?? now,
      updatedAt: now,
    );

    if (isEditing) {
      await _repository.update(cycle);
      return const SaveSuccess(message: 'Siembra actualizada');
    } else {
      final id = await _repository.insert(cycle);
      return SaveSuccess(id: id, message: 'Siembra registrada con éxito');
    }
  }
}

class CloseCycleFormController extends FormController {
  CloseCycleFormController(this.cycle, this._repository) {
    yieldController = text('');
    whatWorkedController = text('');
    whatFailedController = text('');

    harvestStart = cycle.harvestStart ?? DateTime.now().subtract(const Duration(days: 3));
    harvestEnd = cycle.harvestEnd ?? DateTime.now();
    selectedYieldUnit = cycle.yieldUnit ?? YieldUnit.quintales;
    selectedQuality = cycle.quality ?? CropQuality.primera;

    markReady();
  }

  final CropCycle cycle;
  final CycleRepository _repository;

  late final TextEditingController yieldController;
  late final TextEditingController whatWorkedController;
  late final TextEditingController whatFailedController;

  late DateTime harvestStart;
  late DateTime harvestEnd;
  late YieldUnit selectedYieldUnit;
  late CropQuality selectedQuality;

  void setHarvestStart(DateTime date) => update(() => harvestStart = date);

  void setHarvestEnd(DateTime date) => update(() => harvestEnd = date);

  void setYieldUnit(YieldUnit unit) => update(() => selectedYieldUnit = unit);

  void setQuality(CropQuality quality) => update(() => selectedQuality = quality);

  @override
  Future<SaveResult> performSave() async {
    final yieldVal = Formatters.parseNumber(yieldController.text) ?? 0.0;

    await _repository.closeCycle(
      cycleId: cycle.id!,
      harvestStart: harvestStart,
      harvestEnd: harvestEnd,
      yieldValue: yieldVal,
      yieldUnit: selectedYieldUnit,
      quality: selectedQuality,
      whatWorked: whatWorkedController.text.trim().isEmpty ? null : whatWorkedController.text.trim(),
      whatFailed: whatFailedController.text.trim().isEmpty ? null : whatFailedController.text.trim(),
    );

    return const SaveSuccess(message: 'Cosecha registrada y ciclo finalizado');
  }
}
