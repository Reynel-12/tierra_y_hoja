import '../../../core/database/data_changes.dart';
import '../../../core/database/db_schema.dart';
import '../../../core/state/base_controllers.dart';
import '../../costs/data/cost_repository.dart';
import '../../costs/models/cost_models.dart';
import '../../cycles/data/cycle_repository.dart';
import '../../cycles/models/crop_cycle.dart';
import '../../field_log/data/application_repository.dart';
import '../../field_log/models/input_application.dart';
import '../../plots/data/plot_repository.dart';
import '../../plots/models/plot.dart';

class HomeDashboardData {
  const HomeDashboardData({
    required this.activeCycles,
    required this.pendingReviews,
    required this.plots,
    required this.financialSummary,
  });

  final List<CropCycle> activeCycles;
  final List<InputApplication> pendingReviews;
  final List<Plot> plots;
  final FinancialSummary financialSummary;
}

class HomeController extends LoadableController<HomeDashboardData> {
  HomeController(
    this._cycleRepository,
    this._plotRepository,
    this._applicationRepository,
    this._costRepository,
    DataChanges changes,
  ) : super(
        changes,
        watch: {
          DbTable.cycles,
          DbTable.plots,
          DbTable.applications,
          DbTable.expenses,
          DbTable.sales,
        },
      ) {
    load();
  }

  final CycleRepository _cycleRepository;
  final PlotRepository _plotRepository;
  final ApplicationRepository _applicationRepository;
  final CostRepository _costRepository;

  @override
  Future<HomeDashboardData> fetch() async {
    final allCycles = await _cycleRepository.getAll();
    final activeCycles = allCycles.where((c) => !c.isClosed).toList();

    final pendingReviews = await _applicationRepository.getPendingReviews();
    final plots = await _plotRepository.getAll();
    final financialSummary = await _costRepository.getGlobalSummary();

    return HomeDashboardData(
      activeCycles: activeCycles,
      pendingReviews: pendingReviews,
      plots: plots,
      financialSummary: financialSummary,
    );
  }
}
