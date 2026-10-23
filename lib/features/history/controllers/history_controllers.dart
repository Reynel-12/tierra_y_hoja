import 'package:flutter/widgets.dart';

import '../../../core/database/data_changes.dart';
import '../../../core/database/db_schema.dart';
import '../../../core/state/base_controllers.dart';
import '../../costs/data/cost_repository.dart';
import '../../costs/models/cost_models.dart';
import '../../cycles/data/cycle_repository.dart';
import '../../cycles/models/crop_cycle.dart';
import '../data/history_repository.dart';
import '../models/experience_models.dart';

class CycleTimelineController extends LoadableController<List<UnifiedTimelineItem>> {
  CycleTimelineController(
    this.cycleId,
    this._repository,
    DataChanges changes,
  ) : super(changes, watch: {
          DbTable.applications,
          DbTable.tasks,
          DbTable.incidents,
          DbTable.stageEvents,
        }) {
    load();
  }

  final int cycleId;
  final HistoryRepository _repository;
  TimelineEventType _selectedFilter = TimelineEventType.todos;

  TimelineEventType get selectedFilter => _selectedFilter;

  void setFilter(TimelineEventType filter) {
    _selectedFilter = filter;
    notify();
  }

  List<UnifiedTimelineItem> filterList(List<UnifiedTimelineItem> items) {
    if (_selectedFilter == TimelineEventType.todos) return items;
    return items.where((item) => item.type == _selectedFilter).toList();
  }

  @override
  Future<List<UnifiedTimelineItem>> fetch() => _repository.getTimelineForCycle(cycleId);
}

class ExperienceSearchController extends ChangeNotifier {
  ExperienceSearchController(this._repository);

  final HistoryRepository _repository;
  List<LearningResult> results = [];
  bool isLoading = false;
  String currentQuery = '';

  Future<void> search(String query) async {
    currentQuery = query.trim();
    if (currentQuery.isEmpty) {
      results = [];
      notifyListeners();
      return;
    }

    isLoading = true;
    notifyListeners();

    try {
      results = await _repository.searchLearnings(currentQuery);
    } catch (_) {
      results = [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}

class ComparisonMetrics {
  const ComparisonMetrics({
    required this.cycleA,
    required this.cycleB,
    required this.summaryA,
    required this.summaryB,
  });

  final CropCycle cycleA;
  final CropCycle cycleB;
  final FinancialSummary summaryA;
  final FinancialSummary summaryB;
}

class CycleComparisonController extends ChangeNotifier {
  CycleComparisonController(
    this._cycleRepository,
    this._costRepository,
  ) {
    _init();
  }

  final CycleRepository _cycleRepository;
  final CostRepository _costRepository;

  List<CropCycle> availableCycles = [];
  CropCycle? cycleA;
  CropCycle? cycleB;
  ComparisonMetrics? metrics;
  bool isLoading = true;

  Future<void> _init() async {
    availableCycles = await _cycleRepository.getAll();
    if (availableCycles.length >= 2) {
      cycleA = availableCycles[0];
      cycleB = availableCycles[1];
      await compare();
    } else if (availableCycles.isNotEmpty) {
      cycleA = availableCycles[0];
    }
    isLoading = false;
    notifyListeners();
  }

  void selectCycleA(CropCycle? cycle) {
    cycleA = cycle;
    compare();
  }

  void selectCycleB(CropCycle? cycle) {
    cycleB = cycle;
    compare();
  }

  Future<void> compare() async {
    if (cycleA == null || cycleB == null || cycleA!.id == null || cycleB!.id == null) {
      metrics = null;
      notifyListeners();
      return;
    }

    isLoading = true;
    notifyListeners();

    final summaryA = await _costRepository.getSummaryForCycle(cycleA!.id!);
    final summaryB = await _costRepository.getSummaryForCycle(cycleB!.id!);

    metrics = ComparisonMetrics(
      cycleA: cycleA!,
      cycleB: cycleB!,
      summaryA: summaryA,
      summaryB: summaryB,
    );

    isLoading = false;
    notifyListeners();
  }
}
