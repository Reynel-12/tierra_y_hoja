import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'package:tierra_y_hoja/core/database/data_changes.dart';
import 'package:tierra_y_hoja/core/design/app_theme.dart';
import 'package:tierra_y_hoja/core/widgets/layout.dart';
import 'package:tierra_y_hoja/features/costs/data/cost_repository.dart';
import 'package:tierra_y_hoja/features/costs/views/expense_form_view.dart';
import 'package:tierra_y_hoja/features/cycles/data/cycle_repository.dart';
import 'package:tierra_y_hoja/features/cycles/models/crop_cycle.dart';
import 'package:tierra_y_hoja/features/cycles/views/cycle_detail_view.dart';
import 'package:tierra_y_hoja/features/cycles/views/cycle_form_view.dart';
import 'package:tierra_y_hoja/features/history/data/history_repository.dart';
import 'package:tierra_y_hoja/features/history/models/experience_models.dart';
import 'package:tierra_y_hoja/features/history/views/experience_search_view.dart';
import 'package:tierra_y_hoja/features/plots/data/plot_repository.dart';
import 'package:tierra_y_hoja/features/plots/models/plot.dart';
import 'package:tierra_y_hoja/features/tour/controllers/guided_tour_controller.dart';
import 'package:tierra_y_hoja/features/tour/views/guided_tour_view.dart';

class FakeCostRepo implements CostRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeCycleRepo implements CycleRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<List<CropCycle>> getAll({bool onlyActive = false}) async => [];

  @override
  Future<CropCycle?> getById(int id) async => CropCycle(
        id: id,
        plotId: 1,
        crop: 'Tomate',
        variety: 'Pólder',
        plantingDate: DateTime.now().subtract(const Duration(days: 20)),
        stage: CropStage.growth,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        plotName: 'Lote El Rincón',
      );

  @override
  Future<List<StageEvent>> getStageEvents(int cycleId) async => [];
}

class FakeHistoryRepo implements HistoryRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<List<UnifiedTimelineItem>> getTimelineForCycle(int cycleId) async => [
        UnifiedTimelineItem(
          id: 1,
          type: TimelineEventType.insumo,
          cycleId: cycleId,
          title: 'Fertilizante Urea',
          subtitle: 'Dosis: 2 copas/bomba',
          date: DateTime.now(),
        ),
        UnifiedTimelineItem(
          id: 2,
          type: TimelineEventType.labor,
          cycleId: cycleId,
          title: 'Deshierbe manual',
          date: DateTime.now(),
        ),
      ];

  @override
  Future<PaginatedResult<LearningResult>> getMemoryEventsPaginated({
    TimelineEventType filter = TimelineEventType.todos,
    String query = '',
    int limit = 15,
    int offset = 0,
  }) async =>
      PaginatedResult<LearningResult>(
        items: [
          LearningResult(
            crop: 'Tomate',
            plotName: 'Lote El Rincón',
            date: DateTime.now(),
            title: 'Fertilizante Urea',
            category: 'Insumo / Tratamiento',
            type: TimelineEventType.insumo,
            cycleId: 1,
          ),
        ],
        totalCount: 20,
        hasMore: true,
      );
}

class FakePlotRepo implements PlotRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<List<Plot>> getAll() async => [];
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('es', null);
  });

  testWidgets('CycleFormView renders fields properly and BottomActionBar is constrained at bottom', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<PlotRepository>(create: (_) => FakePlotRepo()),
          Provider<CycleRepository>(create: (_) => FakeCycleRepo()),
          Provider<DataChanges>(create: (_) => DataChanges()),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const CycleFormView(),
        ),
      ),
    );

    await tester.pump();
    await tester.pumpAndSettle();

    // Verify fields are present
    expect(find.textContaining('Cultivo'), findsOneWidget);
    expect(find.textContaining('Variedad o híbrido'), findsOneWidget);
    expect(find.text('Abrir siembra'), findsOneWidget);

    // Verify BottomActionBar is NOT taking up the entire screen (1200 logical px)
    final barSize = tester.getSize(find.byType(BottomActionBar));
    expect(barSize.height, lessThan(150.0));

    // Verify Form is taking the majority of the screen
    final formSize = tester.getSize(find.byType(Form));
    expect(formSize.height, greaterThan(500.0));

    // Verify the submit button is located at the bottom of the screen, not the top
    final buttonTop = tester.getTopLeft(find.text('Abrir siembra')).dy;
    expect(buttonTop, greaterThan(1000.0));

    // Tap submit button to trigger validation without crashing SnackBar layout
    await tester.tap(find.text('Abrir siembra'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  });

  testWidgets('ExpenseFormView renders fields properly', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<CostRepository>(create: (_) => FakeCostRepo()),
          Provider<CycleRepository>(create: (_) => FakeCycleRepo()),
          Provider<DataChanges>(create: (_) => DataChanges()),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const ExpenseFormView(),
        ),
      ),
    );

    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.textContaining('Monto total invertido'), findsOneWidget);
    expect(find.text('Guardar gasto'), findsOneWidget);

    final barSize = tester.getSize(find.byType(BottomActionBar));
    expect(barSize.height, lessThan(150.0));
  });

  testWidgets('FilledButton and OutlinedButton in Row do not force infinite width', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Row(
            children: [
              const Expanded(child: Text('Left')),
              FilledButton.tonal(
                onPressed: () {},
                child: const Text('Ver cuentas'),
              ),
              OutlinedButton(
                onPressed: () {},
                child: const Text('Detalle'),
              ),
            ],
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Ver cuentas'), findsOneWidget);
    expect(find.text('Detalle'), findsOneWidget);
  });

  testWidgets('GuidedTourView renders step 1 and advances to step 2 correctly', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;

    final tourController = GuidedTourController();
    await tourController.init();

    await tester.pumpWidget(
      ChangeNotifierProvider<GuidedTourController>.value(
        value: tourController,
        child: MaterialApp(
          theme: AppTheme.light,
          home: const GuidedTourView(isRevisit: false),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Step 1 is rendered
    expect(find.text('Paso 1 de 9'), findsOneWidget);
    expect(find.text('Módulo de Parcelas y Lotes'), findsOneWidget);
    expect(find.text('¿Por qué en este orden?'), findsOneWidget);
    expect(find.text('¿Dónde se ubica en la aplicación?'), findsOneWidget);
    expect(find.text('Probar: Guardar lote de ejemplo'), findsOneWidget);

    // Tap on next step button
    await tester.tap(find.textContaining('Siguiente:'));
    await tester.pumpAndSettle();

    // Verify Step 2 is now shown
    expect(find.text('Paso 2 de 9'), findsOneWidget);
    expect(find.text('Módulo de Ciclos de Siembra'), findsOneWidget);
    expect(find.text('Probar: Abrir ciclo de siembra'), findsOneWidget);
  });

  testWidgets('GuidedTourView allows jumping directly to Step 9 and testing demo actions', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;

    final tourController = GuidedTourController();
    await tourController.init();

    await tester.pumpWidget(
      ChangeNotifierProvider<GuidedTourController>.value(
        value: tourController,
        child: MaterialApp(
          theme: AppTheme.light,
          home: const GuidedTourView(isRevisit: false),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Jump directly to Step 9 using controller
    tourController.goToStep(8);
    await tester.pumpAndSettle();

    expect(find.text('Paso 9 de 9'), findsOneWidget);
    expect(find.text('Pantalla de Inicio y Acceso Rápido'), findsOneWidget);
    // Test a simulated demo FAB action
    await tester.ensureVisible(find.text('Insumo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Insumo'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.textContaining('Acceso directo a: Registrar Insumo.'), findsOneWidget);

    // Wait for demo SnackBar to dismiss
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    // Finish the tour
    await tester.tap(find.text('¡Comenzar a registrar!'));
    await tester.pumpAndSettle();
    expect(tourController.isCompleted, isTrue);
  });

  testWidgets('ExperienceSearchView renders category filter chips including Todos and Cargar más datos button', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<HistoryRepository>(create: (_) => FakeHistoryRepo()),
          Provider<DataChanges>(create: (_) => DataChanges()),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const ExperienceSearchView(),
        ),
      ),
    );

    await tester.pump();
    await tester.pumpAndSettle();

    // Verify search field and top bar title
    expect(find.text('Memoria y Experiencias'), findsOneWidget);
    expect(find.textContaining('Buscar insumo'), findsOneWidget);

    // Verify filter chips: Todos, Insumos, Labores, Plagas / Clima, Cosechas
    expect(find.text('Todos'), findsOneWidget);
    expect(find.text('Insumos'), findsOneWidget);
    expect(find.text('Labores'), findsOneWidget);
    expect(find.text('Plagas / Clima'), findsOneWidget);
    expect(find.text('Cosechas'), findsOneWidget);

    // Verify event card is rendered
    expect(find.text('Fertilizante Urea'), findsOneWidget);
    expect(find.textContaining('Lote: Lote El Rincón'), findsOneWidget);

    // Verify "Cargar más datos" button is rendered since hasMore is true
    expect(find.text('Cargar más datos'), findsOneWidget);
  });

  testWidgets('CycleDetailView renders events section and category chips within planting screen', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<CycleRepository>(create: (_) => FakeCycleRepo()),
          Provider<HistoryRepository>(create: (_) => FakeHistoryRepo()),
          Provider<DataChanges>(create: (_) => DataChanges()),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const CycleDetailView(cycleId: 1),
        ),
      ),
    );

    await tester.pump();
    await tester.pumpAndSettle();

    // Verify cycle info
    expect(find.text('Tomate Pólder'), findsOneWidget);

    // Verify events section header is rendered right on this planting screen
    expect(find.textContaining('EVENTOS DE ESTA SIEMBRA (2)'), findsOneWidget);

    // Verify filter chips within planting screen
    expect(find.text('Todos (2)'), findsOneWidget);
    expect(find.text('Insumos (1)'), findsOneWidget);
    expect(find.text('Labores (1)'), findsOneWidget);
    expect(find.text('Plagas (0)'), findsOneWidget);

    // Verify events cards are rendered on this screen
    expect(find.text('Fertilizante Urea'), findsOneWidget);
    expect(find.text('Deshierbe manual'), findsOneWidget);

    // Tap Insumos filter chip
    await tester.tap(find.text('Insumos (1)'));
    await tester.pumpAndSettle();

    // Now only Insumo is visible, Deshierbe manual is filtered out
    expect(find.text('Fertilizante Urea'), findsOneWidget);
    expect(find.text('Deshierbe manual'), findsNothing);
  });
}

