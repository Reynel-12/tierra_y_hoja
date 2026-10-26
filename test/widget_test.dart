import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'package:tierra_y_hoja/core/database/data_changes.dart';
import 'package:tierra_y_hoja/core/design/app_theme.dart';
import 'package:tierra_y_hoja/core/widgets/form/verdict_tiles.dart';
import 'package:tierra_y_hoja/core/widgets/layout.dart';
import 'package:tierra_y_hoja/core/widgets/media/photo_widgets.dart';
import 'package:tierra_y_hoja/features/costs/data/cost_repository.dart';
import 'package:tierra_y_hoja/features/costs/models/cost_models.dart';
import 'package:tierra_y_hoja/features/costs/views/cost_detail_sheet.dart';
import 'package:tierra_y_hoja/features/costs/views/cost_summary_view.dart';
import 'package:tierra_y_hoja/features/costs/views/expense_form_view.dart';
import 'package:tierra_y_hoja/features/cycles/data/cycle_repository.dart';
import 'package:tierra_y_hoja/features/cycles/models/crop_cycle.dart';
import 'package:tierra_y_hoja/features/cycles/views/cycle_detail_view.dart';
import 'package:tierra_y_hoja/features/cycles/views/cycle_form_view.dart';
import 'package:tierra_y_hoja/features/field_log/models/input_application.dart';
import 'package:tierra_y_hoja/features/history/data/history_repository.dart';
import 'package:tierra_y_hoja/features/history/models/experience_models.dart';
import 'package:tierra_y_hoja/features/history/views/cycle_timeline_view.dart';
import 'package:tierra_y_hoja/features/history/views/event_detail_sheet.dart';
import 'package:tierra_y_hoja/features/history/views/experience_search_view.dart';
import 'package:tierra_y_hoja/features/plots/data/plot_repository.dart';
import 'package:tierra_y_hoja/features/plots/models/plot.dart';
import 'package:tierra_y_hoja/core/services/photo_storage_service.dart';
import 'package:tierra_y_hoja/core/services/reminder_service.dart';
import 'package:tierra_y_hoja/features/field_log/data/application_repository.dart';
import 'package:tierra_y_hoja/features/field_log/views/application_form_view.dart';
import 'package:tierra_y_hoja/features/plots/views/plot_detail_view.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:tierra_y_hoja/core/design/app_icons.dart';
import 'package:tierra_y_hoja/core/state/theme_controller.dart';
import 'package:tierra_y_hoja/features/more/views/more_view.dart';
import 'package:tierra_y_hoja/features/tour/controllers/guided_tour_controller.dart';
import 'package:tierra_y_hoja/features/tour/views/guided_tour_view.dart';

class FakeCostRepo implements CostRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeAppRepo implements ApplicationRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakePhotoService implements PhotoStorageService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<void> deleteAll(Iterable<String?> paths) async {}
}

class FakeReminderService implements ReminderService {
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
          cropTitle: 'Tomate Pólder',
          plotName: 'Lote El Rincón',
          application: InputApplication(
            id: 1,
            cycleId: cycleId,
            inputType: InputType.fertilizanteGranular,
            productName: 'Fertilizante Urea',
            doseValue: 2,
            doseUnit: DoseUnit.copasBomba,
            method: 'Al suelo al pie',
            appliedAt: DateTime.now(),
            timeOfDay: TimeOfDayChoice.morning,
            weather: WeatherCondition.sunny,
            verdict: ReactionVerdict.positive,
            reactionNotes: 'Excelente respuesta en 3 días',
            symptoms: 'Follaje verde oscuro',
            notes: 'Aplicado con suelo húmedo',
            createdAt: DateTime.now(),
            cropTitle: 'Tomate Pólder',
            plotName: 'Lote El Rincón',
          ),
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

class _FakeDuplicatePlotRepo implements PlotRepository {
  _FakeDuplicatePlotRepo(this._plots);
  final List<Plot> _plots;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<List<Plot>> getAll() async => _plots;
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

  testWidgets('CycleFormView handles duplicate plot IDs gracefully without throwing DropdownButton assertion', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;

    final duplicatePlots = [
      Plot(
        id: 1,
        name: 'Lote El Rincón',
        area: 2.0,
        areaUnit: AreaUnit.manzanas,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Plot(
        id: 1,
        name: 'Lote El Rincón (Duplicado)',
        area: 2.0,
        areaUnit: AreaUnit.manzanas,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<PlotRepository>(create: (_) => _FakeDuplicatePlotRepo(duplicatePlots)),
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

    // Verify Dropdown rendered without assertion error
    expect(find.byType(DropdownButtonFormField<int>), findsOneWidget);
    expect(tester.takeException(), isNull);
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
    expect(find.text('Paso 1 de 10'), findsOneWidget);
    expect(find.text('Módulo de Parcelas y Lotes'), findsOneWidget);
    expect(find.text('¿Por qué en este orden?'), findsOneWidget);
    expect(find.text('¿Dónde se ubica en la aplicación?'), findsOneWidget);
    expect(find.text('Probar: Guardar lote de ejemplo'), findsOneWidget);

    // Tap on next step button
    await tester.tap(find.textContaining('Siguiente:'));
    await tester.pumpAndSettle();

    // Verify Step 2 is now shown
    expect(find.text('Paso 2 de 10'), findsOneWidget);
    expect(find.text('Módulo de Ciclos de Siembra'), findsOneWidget);
    expect(find.text('Probar: Abrir ciclo de siembra'), findsOneWidget);
  });

  testWidgets('GuidedTourView allows jumping directly to Step 9 and Step 10 and testing demo actions', (tester) async {
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

    // Jump directly to Step 9 (Copias de Seguridad)
    tourController.goToStep(8);
    await tester.pumpAndSettle();

    expect(find.text('Paso 9 de 10'), findsOneWidget);
    expect(find.text('Copias de Seguridad y Respaldo'), findsOneWidget);
    expect(find.textContaining('Descargas'), findsWidgets);

    // Test changing folder demo action
    await tester.ensureVisible(find.text('Probar: Cambiar carpeta a "Descargas"'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Probar: Cambiar carpeta a "Descargas"'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.textContaining('Carpeta cambiada a "Descargas"'), findsOneWidget);

    // Wait for demo SnackBar to dismiss
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    // Test creating backup demo action
    await tester.ensureVisible(find.text('Probar: Crear copia de seguridad'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Probar: Crear copia de seguridad'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.textContaining('Copia creada:'), findsOneWidget);

    // Wait for demo SnackBar to dismiss
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    // Jump directly to Step 10 using controller
    tourController.goToStep(9);
    await tester.pumpAndSettle();

    expect(find.text('Paso 10 de 10'), findsOneWidget);
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

  testWidgets('Revisiting GuidedTourView from MoreView resets step and leaves no back arrow on root views', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;

    final tourController = GuidedTourController();
    await tourController.init();
    await tourController.completeTour();
    final themeController = _FakeThemeController();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ThemeController>.value(value: themeController),
          ChangeNotifierProvider<GuidedTourController>.value(value: tourController),
          Provider<PackageInfo>.value(
            value: PackageInfo(
              appName: 'Tierra & Hoja',
              packageName: 'com.tierrayhoja.app',
              version: '1.2.0',
              buildNumber: '7',
            ),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const MoreView(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify MoreView top bar has no back button
    expect(find.text('Más opciones'), findsOneWidget);
    expect(find.byIcon(AppIcons.back), findsNothing);

    // Tap on 'Tour Guiado de la Aplicación'
    await tester.ensureVisible(find.text('Tour Guiado de la Aplicación'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tour Guiado de la Aplicación'));
    await tester.pumpAndSettle();

    // GuidedTourView is opened as revisit: starts at Step 1 and has back button
    expect(find.text('Tour Guiado'), findsOneWidget);
    expect(find.text('Paso 1 de 10'), findsOneWidget);
    expect(find.byIcon(AppIcons.back), findsOneWidget);

    // Jump to step 10
    tourController.goToStep(9);
    await tester.pumpAndSettle();
    expect(find.text('Paso 10 de 10'), findsOneWidget);

    // Tap '¡Comenzar a registrar!' to finish revisit
    await tester.ensureVisible(find.text('¡Comenzar a registrar!'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('¡Comenzar a registrar!'));
    await tester.pumpAndSettle();

    // Returned to MoreView: MUST NOT have a back button!
    expect(find.text('Más opciones'), findsOneWidget);
    expect(find.byIcon(AppIcons.back), findsNothing);

    // Controller should be reset to step 0
    expect(tourController.currentStepIndex, 0);
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

  testWidgets('EventDetailSheet renders complete details for an input application', (tester) async {
    final now = DateTime.now();
    final item = UnifiedTimelineItem(
      id: 1,
      type: TimelineEventType.insumo,
      cycleId: 1,
      title: 'Fertilizante Urea',
      subtitle: 'Dosis: 2 copas/bomba',
      date: now,
      cropTitle: 'Tomate Pólder',
      plotName: 'Lote El Rincón',
      notes: 'Aplicado con suelo húmedo',
      application: InputApplication(
        id: 1,
        cycleId: 1,
        inputType: InputType.fertilizanteGranular,
        productName: 'Fertilizante Urea',
        doseValue: 2,
        doseUnit: DoseUnit.copasBomba,
        method: 'Al suelo al pie',
        appliedAt: now,
        timeOfDay: TimeOfDayChoice.morning,
        weather: WeatherCondition.sunny,
        verdict: ReactionVerdict.positive,
        reactionNotes: 'Excelente respuesta en 3 días',
        symptoms: 'Follaje verde oscuro',
        notes: 'Aplicado con suelo húmedo',
        createdAt: now,
        cropTitle: 'Tomate Pólder',
        plotName: 'Lote El Rincón',
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: SingleChildScrollView(
            child: EventDetailSheet(item: item),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify category and title
    expect(find.text('APLICACIÓN DE INSUMO O FOLIAR'), findsOneWidget);
    expect(find.text('Fertilizante Urea'), findsNWidgets(2)); // Header + Technical data
    expect(find.textContaining('Tomate Pólder · Lote: Lote El Rincón'), findsOneWidget);

    // Verify technical data
    expect(find.text('DATOS Y CONDICIONES DEL REGISTRO'), findsOneWidget);
    expect(find.text('Al suelo al pie'), findsOneWidget);
    expect(find.text('Soleado'), findsOneWidget);
    expect(find.text('Mañana fresca'), findsNWidgets(2)); // Header + row

    // Verify initial notes
    expect(find.text('Notas iniciales de la aplicación'), findsOneWidget);
    expect(find.text('Aplicado con suelo húmedo'), findsOneWidget);

    // Verify follow-up reaction details
    expect(find.text('EVALUACIÓN Y REACCIÓN OBSERVADA'), findsOneWidget);
    expect(find.text('Respuesta: Positiva'), findsOneWidget);
    expect(find.text('Follaje verde oscuro'), findsOneWidget);
    expect(find.text('Excelente respuesta en 3 días'), findsOneWidget);
  });

  testWidgets('EventDetailSheet renders negative reaction with separate symptom chips and legible phytotoxicity notes', (tester) async {
    final now = DateTime.now();
    final item = UnifiedTimelineItem(
      id: 2,
      type: TimelineEventType.insumo,
      cycleId: 1,
      title: 'Herbicida Secante',
      subtitle: 'Dosis: 50 cc/L',
      date: now,
      cropTitle: 'Maíz H-59',
      plotName: 'Lote Norte',
      application: InputApplication(
        id: 2,
        cycleId: 1,
        inputType: InputType.herbicida,
        productName: 'Herbicida Secante',
        appliedAt: now,
        verdict: ReactionVerdict.negative,
        symptoms: SymptomsData.format({'Hoja quemada', 'Marchitez'}, 'Quemazón severa por deriva de viento en bordes.'),
        reactionNotes: 'Se aisló el surco afectado con riego de lavado.',
        createdAt: now,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: SingleChildScrollView(
            child: EventDetailSheet(item: item),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify negative reaction section header and badge
    expect(find.text('EVALUACIÓN Y REACCIÓN OBSERVADA'), findsOneWidget);
    expect(find.text('Respuesta: Negativa'), findsOneWidget);

    // Verify symptom chips are displayed under their section
    expect(find.text('Síntomas manifestados por el cultivo:'), findsOneWidget);
    expect(find.text('Hoja quemada'), findsOneWidget);
    expect(find.text('Marchitez'), findsOneWidget);

    // Verify phytotoxicity notes are displayed in legible container matching reaction notes
    expect(find.text('Detalle o notas de fitotoxicidad:'), findsOneWidget);
    expect(find.text('Quemazón severa por deriva de viento en bordes.'), findsOneWidget);

    // Verify reaction notes are also displayed in their separate container
    expect(find.text('Descripción detallada de la reacción:'), findsOneWidget);
    expect(find.text('Se aisló el surco afectado con riego de lavado.'), findsOneWidget);

    // Verify Actualizar evaluación button exists
    expect(find.text('Actualizar evaluación'), findsOneWidget);
  });

  testWidgets('CycleDetailView opens EventDetailSheet on tapping ver detalle', (tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<CycleRepository>(create: (_) => FakeCycleRepo()),
          Provider<HistoryRepository>(create: (_) => FakeHistoryRepo()),
          Provider<PlotRepository>(create: (_) => FakePlotRepo()),
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

    // Tap on Ver detalle completo
    expect(find.text('Ver detalle completo'), findsWidgets);
    await tester.tap(find.text('Ver detalle completo').first);
    await tester.pumpAndSettle();

    // Verify EventDetailSheet is opened
    expect(find.text('DATOS Y CONDICIONES DEL REGISTRO'), findsOneWidget);
    expect(find.text('Al suelo al pie'), findsNWidgets(2)); // Chip on card + Sheet detail
    expect(find.text('Soleado'), findsNWidgets(2));
  });

  testWidgets('CycleDetailView renders event cards with photos and pending follow-up without layout errors', (tester) async {
    final pendingApp = InputApplication(
      id: 99,
      cycleId: 1,
      inputType: InputType.foliar,
      productName: 'Nutrifol 20-20-20',
      doseValue: 1.5,
      doseUnit: DoseUnit.copasBomba,
      method: 'Al follaje',
      appliedAt: DateTime.now(),
      reviewDueAt: DateTime.now().add(const Duration(days: 3)),
      verdict: null, // Pending evaluation
      photoBefore: 'mock_before.jpg',
      photoAfter: 'mock_after.jpg',
      createdAt: DateTime.now(),
    );

    final eventItem = UnifiedTimelineItem(
      id: 99,
      type: TimelineEventType.insumo,
      cycleId: 1,
      title: 'Nutrifol 20-20-20',
      subtitle: 'Dosis: 1.5 L/bomba',
      date: DateTime.now(),
      photoBefore: 'mock_before.jpg',
      photoAfter: 'mock_after.jpg',
      application: pendingApp,
    );

    final customHistoryRepo = _SingleEventHistoryRepo(eventItem);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<CycleRepository>(create: (_) => FakeCycleRepo()),
          Provider<HistoryRepository>(create: (_) => customHistoryRepo),
          Provider<PlotRepository>(create: (_) => FakePlotRepo()),
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

    // Verify photos with badges
    expect(find.text('Antes'), findsOneWidget);
    expect(find.text('Después'), findsOneWidget);

    // Verify pending review badge and action button
    expect(find.text('Revisión pendiente'), findsOneWidget);
    expect(find.text('Evaluar reacción'), findsOneWidget);
    expect(find.text('Ver detalle completo'), findsOneWidget);
  });

  testWidgets('PhotoPreviewThumb renders correctly and PhotoViewerPage handles missing files gracefully', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Column(
            children: [
              PhotoPreviewThumb(
                path: 'mock_photo.jpg',
                label: 'Antes',
                onTap: () {},
              ),
              const Expanded(
                child: PhotoViewerPage(
                  before: 'non_existent_before.jpg',
                  after: 'non_existent_after.jpg',
                ),
              ),
            ],
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Antes'), findsWidgets);
    expect(find.text('Después'), findsOneWidget);
  });

  testWidgets('CostSummaryView renders long categories and large amounts on narrow screens without overflow', (tester) async {
    // Set a compact mobile screen width (320 dp)
    tester.view.physicalSize = const Size(320 * 2, 1200 * 2);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final mockCostRepo = _RichCostRepo();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<CostRepository>(create: (_) => mockCostRepo),
          Provider<DataChanges>(create: (_) => DataChanges()),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const CostSummaryView(cycleId: 1, cropTitle: 'Tomate'),
        ),
      ),
    );

    await tester.pump();
    await tester.pumpAndSettle();

    // Verify category distribution rows are rendered
    expect(find.text('DISTRIBUCIÓN DE GASTOS'), findsOneWidget);
    expect(find.text('Insumos y fertilizantes'), findsOneWidget);
    expect(find.text('Maquinaria / Combustible'), findsOneWidget);

    // Verify percentages on the progress bars are rendered
    expect(find.text('50.2%'), findsOneWidget);
    expect(find.text('49.8%'), findsOneWidget);

    // Verify long expense titles and large amounts are rendered
    expect(find.text('Compra de fertilizante Urea al por mayor para todo el lote'), findsOneWidget);
    expect(find.text('L 125,500.00'), findsNWidgets(2)); // in breakdown + in expense card

    // Switch to Ventas tab to test sales cards
    await tester.ensureVisible(find.text('Ventas (1)'));
    await tester.tap(find.text('Ventas (1)'));
    await tester.pumpAndSettle();

    // Verify long sale concept and large amount are rendered without overflow
    await tester.ensureVisible(find.text('Venta a Distribuidora y Exportadora Agrícola del Norte'));
    expect(find.text('Venta a Distribuidora y Exportadora Agrícola del Norte'), findsOneWidget);
    expect(find.text('+ L 350,000.00'), findsOneWidget);
  });

  testWidgets('CycleTimelineView renders items with and without photos across screen sizes without IntrinsicHeight or layout exceptions', (tester) async {
    final cycle = CropCycle(
      id: 1,
      plotId: 1,
      crop: 'Tomate',
      variety: 'Pólder',
      plantingDate: DateTime.now().subtract(const Duration(days: 20)),
      stage: CropStage.growth,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      plotName: 'Lote El Rincón',
    );

    // 1. Test on standard screen (390x844)
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<HistoryRepository>.value(value: _TimelineWithPhotosHistoryRepo()),
          Provider<DataChanges>(create: (_) => DataChanges()),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: CycleTimelineView(cycle: cycle),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify timeline items rendered
    expect(find.text('Bitácora: Tomate Pólder'), findsOneWidget);
    expect(find.text('Fertilizante Foliar 20-20-20'), findsOneWidget);
    expect(find.text('Aporque y deshierbe de callejón'), findsOneWidget);

    // Verify photo preview labels rendered
    expect(find.text('Antes'), findsOneWidget);
    expect(find.text('Después'), findsOneWidget);

    // Verify follow-up evaluation button rendered
    expect(find.text('Evaluar reacción'), findsOneWidget);

    // 2. Test on narrow mobile screen (320x600) without layout overflow
    tester.view.physicalSize = const Size(320, 600);
    await tester.pumpAndSettle();
    expect(find.text('Bitácora: Tomate Pólder'), findsOneWidget);
    expect(find.text('Fertilizante Foliar 20-20-20'), findsOneWidget);

    // 3. Test on tablet/large screen (800x1200)
    tester.view.physicalSize = const Size(800, 1200);
    await tester.pumpAndSettle();
    expect(find.text('Bitácora: Tomate Pólder'), findsOneWidget);
    expect(find.text('Aporque y deshierbe de callejón'), findsOneWidget);
  });

  testWidgets('CostSummaryView opens ExpenseDetailSheet and SaleDetailSheet with full notes when tapping cards', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final mockCostRepo = _RichCostRepo();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<CostRepository>(create: (_) => mockCostRepo),
          Provider<DataChanges>(create: (_) => DataChanges()),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const CostSummaryView(cycleId: 1, cropTitle: 'Tomate'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify card shows snippet of notes
    await tester.ensureVisible(find.text('Factura #9872 con 15% descuento por pronto pago'));
    expect(find.text('Factura #9872 con 15% descuento por pronto pago'), findsOneWidget);

    // Tap on expense card to open ExpenseDetailSheet
    await tester.tap(find.text('Compra de fertilizante Urea al por mayor para todo el lote'));
    await tester.pumpAndSettle();

    // Verify ExpenseDetailSheet is displayed
    expect(find.byType(ExpenseDetailSheet), findsOneWidget);
    expect(find.text('Detalle del gasto'), findsOneWidget);
    expect(find.text('Notas del gasto:'), findsOneWidget);
    expect(find.text('Factura #9872 con 15% descuento por pronto pago'), findsWidgets);

    // Close the sheet
    await tester.tap(find.byTooltip('Cerrar'));
    await tester.pumpAndSettle();
    expect(find.byType(ExpenseDetailSheet), findsNothing);

    // Switch to Ventas tab
    await tester.ensureVisible(find.text('Ventas (1)'));
    await tester.tap(find.text('Ventas (1)'));
    await tester.pumpAndSettle();

    // Verify sale card shows snippet of notes
    await tester.ensureVisible(find.text('Entregado en bodega principal, saldo restante a 30 días'));
    expect(find.text('Entregado en bodega principal, saldo restante a 30 días'), findsOneWidget);

    // Tap on sale card to open SaleDetailSheet
    await tester.tap(find.text('Venta a Distribuidora y Exportadora Agrícola del Norte'));
    await tester.pumpAndSettle();

    // Verify SaleDetailSheet is displayed
    expect(find.byType(SaleDetailSheet), findsOneWidget);
    expect(find.text('Detalle de la venta'), findsOneWidget);
    expect(find.text('Notas de la venta:'), findsOneWidget);
    expect(find.text('Entregado en bodega principal, saldo restante a 30 días'), findsWidgets);

    // Close the sheet
    await tester.tap(find.byTooltip('Cerrar'));
    await tester.pumpAndSettle();
    expect(find.byType(SaleDetailSheet), findsNothing);
  });

  testWidgets('PlotDetailView shows copy coordinates button when coordinates are present and copies to clipboard', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    String? copiedClipboardText;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (MethodCall methodCall) async {
        if (methodCall.method == 'Clipboard.setData') {
          copiedClipboardText = (methodCall.arguments as Map)['text'] as String?;
          return null;
        }
        return null;
      },
    );
    addTearDown(() {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      );
    });

    final plotWithCoords = Plot(
      id: 10,
      name: 'Lote Las Colinas',
      area: 3.5,
      areaUnit: AreaUnit.manzanas,
      latitude: 14.08180,
      longitude: -87.20680,
      soilTexture: SoilTexture.franco,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final mockPlotRepo = _FakeSinglePlotRepo(plotWithCoords);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<PlotRepository>(create: (_) => mockPlotRepo),
          Provider<DataChanges>(create: (_) => DataChanges()),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const PlotDetailView(plotId: 10),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify plot information is displayed
    expect(find.text('Lote Las Colinas'), findsOneWidget);
    expect(find.text('14.08180, -87.20680'), findsOneWidget);

    // Verify copy button is present
    final copyBtn = find.byTooltip('Copiar coordenadas');
    expect(copyBtn, findsOneWidget);

    // Tap the copy button
    await tester.tap(copyBtn);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Verify clipboard content and toast message
    expect(copiedClipboardText, '14.08180, -87.20680');
    expect(find.text('Coordenadas copiadas al portapapeles'), findsOneWidget);

    // Dismiss toast
    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('PlotDetailView does not show copy button when plot has no coordinates', (tester) async {
    final plotWithoutCoords = Plot(
      id: 20,
      name: 'Lote Sin GPS',
      area: 1.0,
      areaUnit: AreaUnit.manzanas,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final mockPlotRepo = _FakeSinglePlotRepo(plotWithoutCoords);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<PlotRepository>(create: (_) => mockPlotRepo),
          Provider<DataChanges>(create: (_) => DataChanges()),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const PlotDetailView(plotId: 20),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Lote Sin GPS'), findsOneWidget);
    expect(find.byTooltip('Copiar coordenadas'), findsNothing);
  });

  testWidgets('CycleDetailView renders density and distancing notes when present', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final cycleWithNotes = CropCycle(
      id: 99,
      plotId: 1,
      crop: 'Maíz',
      variety: 'HB-104',
      plantingDate: DateTime.now().subtract(const Duration(days: 15)),
      stage: CropStage.growth,
      densityValue: 30,
      densityUnit: DensityUnit.libras,
      densityNotes: '0.80 m entre surcos, 0.20 m entre plantas, 2 semillas por postura',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      plotName: 'Lote La Vega',
    );

    final mockCycleRepo = _FakeSingleCycleRepo(cycleWithNotes);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<CycleRepository>(create: (_) => mockCycleRepo),
          Provider<HistoryRepository>(create: (_) => FakeHistoryRepo()),
          Provider<DataChanges>(create: (_) => DataChanges()),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const CycleDetailView(cycleId: 99),
        ),
      ),
    );

    await tester.pump();
    await tester.pumpAndSettle();

    // Verify title and plot
    expect(find.text('Maíz HB-104'), findsOneWidget);
    expect(find.text('Lote: Lote La Vega'), findsOneWidget);

    // Verify density quantity
    expect(find.text('Densidad de siembra'), findsOneWidget);
    expect(find.text('30 Libras de semilla'), findsOneWidget);

    // Verify distancing and planting notes
    expect(find.text('Notas de distanciamiento o siembra'), findsOneWidget);
    expect(
      find.text('0.80 m entre surcos, 0.20 m entre plantas, 2 semillas por postura'),
      findsOneWidget,
    );
  });

  testWidgets('ApplicationFormView renders reminder option chips and allows selecting them', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<ApplicationRepository>(create: (_) => FakeAppRepo()),
          Provider<CycleRepository>(create: (_) => FakeCycleRepo()),
          Provider<PhotoStorageService>(create: (_) => FakePhotoService()),
          Provider<ReminderService>(create: (_) => FakeReminderService()),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const ApplicationFormView(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify reminder options are displayed
    expect(find.text('¿Cuándo desea revisar la reacción del cultivo?'), findsOneWidget);
    expect(find.text('3 días'), findsOneWidget);
    expect(find.text('5 días'), findsOneWidget);
    expect(find.text('7 días'), findsOneWidget);
    expect(find.text('Sin recordatorio'), findsOneWidget);

    // Tap on '3 días' chip
    await tester.ensureVisible(find.text('3 días'));
    await tester.tap(find.text('3 días'));
    await tester.pumpAndSettle();
  });
}

class _FakeSingleCycleRepo extends FakeCycleRepo {
  _FakeSingleCycleRepo(this._cycle);
  final CropCycle _cycle;

  @override
  Future<CropCycle?> getById(int id) async => _cycle;
}

class _RichCostRepo implements CostRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<FinancialSummary> getSummaryForCycle(int cycleId) async => const FinancialSummary(
        totalExpenses: 250000.0,
        totalSales: 350000.0,
        expensesByCategory: {
          ExpenseCategory.insumos: 125500.0,
          ExpenseCategory.maquinaria: 124500.0,
        },
      );

  @override
  Future<List<Expense>> getExpensesByCycle(int cycleId) async => [
        Expense(
          id: 1,
          cycleId: cycleId,
          category: ExpenseCategory.insumos,
          description: 'Compra de fertilizante Urea al por mayor para todo el lote',
          amount: 125500.0,
          date: DateTime.now(),
          createdAt: DateTime.now(),
          cropTitle: 'Tomate',
          notes: 'Factura #9872 con 15% descuento por pronto pago',
        ),
      ];

  @override
  Future<List<Sale>> getSalesByCycle(int cycleId) async => [
        Sale(
          id: 1,
          cycleId: cycleId,
          buyer: 'Distribuidora y Exportadora Agrícola del Norte',
          quantity: 500,
          unit: 'cajas',
          amount: 350000.0,
          date: DateTime.now(),
          createdAt: DateTime.now(),
          cropTitle: 'Tomate',
          notes: 'Entregado en bodega principal, saldo restante a 30 días',
        ),
      ];
}

class _FakeSinglePlotRepo extends FakePlotRepo {
  _FakeSinglePlotRepo(this._plot);
  final Plot _plot;

  @override
  Future<Plot?> getById(int id) async => _plot;
}

class _SingleEventHistoryRepo extends FakeHistoryRepo {
  _SingleEventHistoryRepo(this.item);
  final UnifiedTimelineItem item;

  @override
  Future<List<UnifiedTimelineItem>> getTimelineForCycle(int cycleId) async => [item];
}

class _TimelineWithPhotosHistoryRepo extends FakeHistoryRepo {
  @override
  Future<List<UnifiedTimelineItem>> getTimelineForCycle(int cycleId) async => [
        UnifiedTimelineItem(
          id: 1,
          type: TimelineEventType.insumo,
          cycleId: cycleId,
          title: 'Fertilizante Foliar 20-20-20',
          subtitle: 'Dosis: 3 copas/bomba',
          date: DateTime.now().subtract(const Duration(days: 5)),
          photoBefore: 'dummy_path_before.jpg',
          photoAfter: 'dummy_path_after.jpg',
          notes: 'Follaje con leve amarillamiento antes de aplicar.',
          cropTitle: 'Tomate Pólder',
          plotName: 'Lote El Rincón',
          application: InputApplication(
            id: 1,
            cycleId: cycleId,
            inputType: InputType.foliar,
            productName: 'Fertilizante Foliar 20-20-20',
            doseValue: 3,
            doseUnit: DoseUnit.copasBomba,
            method: 'Foliar con boquilla fina',
            appliedAt: DateTime.now().subtract(const Duration(days: 5)),
            timeOfDay: TimeOfDayChoice.morning,
            weather: WeatherCondition.sunny,
            reviewDueAt: DateTime.now().add(const Duration(days: 3)),
            notes: 'Follaje con leve amarillamiento antes de aplicar.',
            createdAt: DateTime.now().subtract(const Duration(days: 5)),
          ),
        ),
        UnifiedTimelineItem(
          id: 2,
          type: TimelineEventType.labor,
          cycleId: cycleId,
          title: 'Aporque y deshierbe de callejón',
          subtitle: 'Método: Manual con azadón',
          date: DateTime.now().subtract(const Duration(days: 2)),
          notes: 'Labores realizadas sin contratiempos.',
          cropTitle: 'Tomate Pólder',
          plotName: 'Lote El Rincón',
        ),
      ];
}

class _FakeThemeController extends ChangeNotifier implements ThemeController {
  @override
  ThemeMode get themeMode => ThemeMode.system;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}


