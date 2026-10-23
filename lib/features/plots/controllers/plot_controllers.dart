import 'package:flutter/widgets.dart';

import '../../../core/database/data_changes.dart';
import '../../../core/database/db_schema.dart';
import '../../../core/services/photo_storage_service.dart';
import '../../../core/state/base_controllers.dart';
import '../../../core/state/photo_tracker.dart';
import '../../../core/state/view_state.dart';
import '../../../core/utils/formatters.dart';
import '../data/plot_repository.dart';
import '../models/plot.dart';

class PlotListController extends LoadableController<List<Plot>> {
  PlotListController(this._repository, DataChanges changes)
      : super(changes, watch: {DbTable.plots, DbTable.cycles}) {
    load();
  }

  final PlotRepository _repository;
  String _filter = '';

  String get filter => _filter;

  void setFilter(String query) {
    _filter = query.trim().toLowerCase();
    notify();
  }

  List<Plot> filterList(List<Plot> plots) {
    if (_filter.isEmpty) return plots;
    return plots.where((p) {
      return p.name.toLowerCase().contains(_filter) ||
          (p.activeCropName?.toLowerCase().contains(_filter) ?? false) ||
          (p.soilTexture?.label.toLowerCase().contains(_filter) ?? false);
    }).toList();
  }

  @override
  Future<List<Plot>> fetch() => _repository.getAll();
}

class PlotDetailController extends LoadableController<Plot?> {
  PlotDetailController(this.plotId, this._repository, DataChanges changes)
      : super(changes, watch: {DbTable.plots, DbTable.cycles}) {
    load();
  }

  final int plotId;
  final PlotRepository _repository;

  @override
  Future<Plot?> fetch() => _repository.getById(plotId);

  Future<bool> deletePlot() async {
    try {
      await _repository.delete(plotId);
      return true;
    } catch (_) {
      return false;
    }
  }
}

class PlotFormController extends FormController {
  PlotFormController(
    this._repository,
    this._photoService, {
    this.initialPlot,
  }) {
    _photoTracker = PhotoTracker(_photoService);
    nameController = text(initialPlot?.name ?? '');
    areaController = text(initialPlot != null ? Formatters.editable(initialPlot!.area) : '');
    previousCropsController = text(initialPlot?.previousCrops ?? '');

    selectedAreaUnit = initialPlot?.areaUnit ?? AreaUnit.manzanas;
    latitude = initialPlot?.latitude;
    longitude = initialPlot?.longitude;
    selectedSoilTexture = initialPlot?.soilTexture;
    selectedTopography = initialPlot?.topography;
    selectedWaterAccess = initialPlot?.waterAccess;
    photoPath = initialPlot?.photoPath;

    markReady();
  }

  final PlotRepository _repository;
  final PhotoStorageService _photoService;
  final Plot? initialPlot;
  late final PhotoTracker _photoTracker;

  late final TextEditingController nameController;
  late final TextEditingController areaController;
  late final TextEditingController previousCropsController;

  late AreaUnit selectedAreaUnit;
  double? latitude;
  double? longitude;
  SoilTexture? selectedSoilTexture;
  Topography? selectedTopography;
  WaterAccess? selectedWaterAccess;
  String? photoPath;

  bool get isEditing => initialPlot != null;

  void setAreaUnit(AreaUnit unit) => update(() => selectedAreaUnit = unit);

  void setLocation(double? lat, double? lng) => update(() {
        latitude = lat;
        longitude = lng;
      });

  void setSoilTexture(SoilTexture? texture) => update(() => selectedSoilTexture = texture);

  void setTopography(Topography? topo) => update(() => selectedTopography = topo);

  void setWaterAccess(WaterAccess? access) => update(() => selectedWaterAccess = access);

  void setPhoto(String? path) {
    _photoTracker.replace(oldPath: photoPath, newPath: path);
    update(() => photoPath = path);
  }

  @override
  Future<SaveResult> performSave() async {
    final now = DateTime.now();
    final areaVal = Formatters.parseNumber(areaController.text) ?? 1.0;

    final plot = Plot(
      id: initialPlot?.id,
      name: nameController.text.trim(),
      area: areaVal,
      areaUnit: selectedAreaUnit,
      latitude: latitude,
      longitude: longitude,
      soilTexture: selectedSoilTexture,
      topography: selectedTopography,
      waterAccess: selectedWaterAccess,
      previousCrops: previousCropsController.text.trim().isEmpty ? null : previousCropsController.text.trim(),
      photoPath: photoPath,
      createdAt: initialPlot?.createdAt ?? now,
      updatedAt: now,
    );

    if (isEditing) {
      await _repository.update(plot);
      await _photoTracker.commit();
      return const SaveSuccess(message: 'Lote actualizado');
    } else {
      final id = await _repository.insert(plot);
      await _photoTracker.commit();
      return SaveSuccess(id: id, message: 'Lote registrado');
    }
  }

  Future<bool> delete() async {
    if (initialPlot?.id == null) return false;
    try {
      await _repository.delete(initialPlot!.id!);
      if (initialPlot?.photoPath != null) {
        await _photoService.delete(initialPlot!.photoPath);
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
