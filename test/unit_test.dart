import 'package:flutter_test/flutter_test.dart';
import 'package:tierra_y_hoja/core/database/data_changes.dart';
import 'package:tierra_y_hoja/core/design/app_colors.dart';
import 'package:tierra_y_hoja/core/utils/formatters.dart';
import 'package:tierra_y_hoja/core/utils/validators.dart';
import 'package:tierra_y_hoja/core/widgets/form/verdict_tiles.dart';
import 'package:tierra_y_hoja/features/costs/models/cost_models.dart';
import 'package:tierra_y_hoja/features/cycles/controllers/cycle_controllers.dart';
import 'package:tierra_y_hoja/features/cycles/data/cycle_repository.dart';
import 'package:tierra_y_hoja/features/cycles/models/crop_cycle.dart';
import 'package:tierra_y_hoja/features/field_log/models/input_application.dart';
import 'package:tierra_y_hoja/features/history/data/history_repository.dart';
import 'package:tierra_y_hoja/features/history/models/experience_models.dart';
import 'package:tierra_y_hoja/core/services/photo_storage_service.dart';
import 'package:tierra_y_hoja/core/services/reminder_service.dart';
import 'package:tierra_y_hoja/features/field_log/controllers/application_controllers.dart';
import 'package:tierra_y_hoja/features/field_log/data/application_repository.dart';
import 'package:tierra_y_hoja/features/plots/models/plot.dart';
import 'package:tierra_y_hoja/features/tour/models/tour_step_data.dart';

void main() {
  group('Formatters & Design System', () {
    test('Formatters.money formats Honduran Lempira with L and 2 decimals', () {
      expect(Formatters.money(0), 'L 0.00');
      expect(Formatters.money(1500), 'L 1,500.00');
      expect(Formatters.money(1234.5), 'L 1,234.50');
      expect(Formatters.money(-250.75), '-L 250.75');
    });

    test('Formatters.area formats with correct unit symbol', () {
      expect(Formatters.area(2.5, AreaUnit.manzanas), '2.5 mz');
      expect(Formatters.area(1.0, AreaUnit.hectareas), '1 ha');
      expect(Formatters.area(3.0, AreaUnit.tareas), '3 tareas');
    });

    test('Formatters.parseNumber parses comma and dot decimals', () {
      expect(Formatters.parseNumber('12.5'), 12.5);
      expect(Formatters.parseNumber('12,5'), 12.5);
      expect(Formatters.parseNumber('1,250.50'), 1250.5);
      expect(Formatters.parseNumber(''), isNull);
    });
  });

  group('Validators & Formal Usted Tone', () {
    test('Validators.required gives user-friendly message', () {
      final v = Validators.required('Falta el nombre.');
      expect(v(''), 'Falta el nombre.');
      expect(v('Tomate'), isNull);
    });

    test('Validators.requiredPositive validates numbers > 0', () {
      final v = Validators.requiredPositive('El área debe ser mayor a 0');
      expect(v('0'), 'Escriba una cantidad mayor que cero.');
      expect(v('-5'), 'Escriba una cantidad mayor que cero.');
      expect(v('2.5'), isNull);
    });
  });

  group('FinancialSummary Business Logic', () {
    test('calculates net profit and profitability correctly', () {
      const summary = FinancialSummary(
        totalExpenses: 5000.0,
        totalSales: 12000.0,
        expensesByCategory: {
          ExpenseCategory.insumos: 3000.0,
          ExpenseCategory.jornales: 2000.0,
        },
      );

      expect(summary.netProfit, 7000.0);
      expect(summary.isProfitable, isTrue);
      expect(summary.roiPercentage, 140.0);
    });

    test('detects loss when expenses exceed sales', () {
      const summary = FinancialSummary(
        totalExpenses: 8000.0,
        totalSales: 4000.0,
        expensesByCategory: {
          ExpenseCategory.insumos: 8000.0,
        },
      );

      expect(summary.netProfit, -4000.0);
      expect(summary.isProfitable, isFalse);
    });
  });

  group('CropCycle Logic', () {
    test('progress estimation matches stage definition', () {
      final now = DateTime.now();
      final cycle = CropCycle(
        plotId: 1,
        crop: 'Maíz',
        variety: 'H-59',
        plantingDate: now.subtract(const Duration(days: 30)),
        stage: CropStage.growth,
        createdAt: now,
        updatedAt: now,
      );

      expect(cycle.title, 'Maíz H-59');
      expect(cycle.estimatedProgress, 0.40);
      expect(cycle.isClosed, isFalse);
    });
  });

  group('Guided Tour Order and Structure', () {
    test('contains exactly 9 steps in authentic agricultural workflow order', () {
      expect(TourStepData.steps.length, 9);

      // Verify strict agricultural order: Lote -> Siembra -> Insumo -> Veredicto -> Labor/Plaga -> Costos -> Cosecha -> Memoria -> Inicio
      expect(TourStepData.steps[0].shortName, '1. Lotes');
      expect(TourStepData.steps[1].shortName, '2. Siembras');
      expect(TourStepData.steps[2].shortName, '3. Insumos');
      expect(TourStepData.steps[3].shortName, '4. Veredicto');
      expect(TourStepData.steps[4].shortName, '5. Labores y Plagas');
      expect(TourStepData.steps[5].shortName, '6. Finanzas');
      expect(TourStepData.steps[6].shortName, '7. Cosecha');
      expect(TourStepData.steps[7].shortName, '8. Memoria');
      expect(TourStepData.steps[8].shortName, '9. Inicio y FAB');
    });

    test('each step has comprehensive field explanations and tips', () {
      for (final step in TourStepData.steps) {
        expect(step.title.isNotEmpty, isTrue);
        expect(step.whyOrder.isNotEmpty, isTrue);
        expect(step.appLocation.isNotEmpty, isTrue);
        expect(step.screenPurpose.isNotEmpty, isTrue);
        expect(step.inputsSummary.isNotEmpty, isTrue);
        expect(step.agriculturalTip.isNotEmpty, isTrue);

        for (final input in step.inputsSummary) {
          expect(input.name.isNotEmpty, isTrue);
          expect(input.dataType.isNotEmpty, isTrue);
          expect(input.description.isNotEmpty, isTrue);
        }
      }
    });
  });

  group('Memory Models & Pagination', () {
    test('TimelineEventType contains todos and cosecha options', () {
      expect(TimelineEventType.values.contains(TimelineEventType.todos), isTrue);
      expect(TimelineEventType.values.contains(TimelineEventType.cosecha), isTrue);
      expect(TimelineEventType.todos.label, 'Todos los eventos');
      expect(TimelineEventType.cosecha.label, 'Cosechas y cierres');
    });

    test('PaginatedResult properly holds pagination metadata', () {
      const result = PaginatedResult<String>(
        items: ['Evento 1', 'Evento 2'],
        totalCount: 5,
        hasMore: true,
      );

      expect(result.items.length, 2);
      expect(result.totalCount, 5);
      expect(result.hasMore, isTrue);
    });

    test('LearningResult assigns icon and color according to event type', () {
      final now = DateTime.now();
      const colors = AppColors.light;

      final itemInsumo = LearningResult(
        crop: 'Tomate',
        plotName: 'Lote 1',
        date: now,
        title: 'Urea',
        category: 'Insumo',
        type: TimelineEventType.insumo,
      );
      expect(itemInsumo.color(colors), colors.primary);

      final itemLabor = LearningResult(
        crop: 'Tomate',
        plotName: 'Lote 1',
        date: now,
        title: 'Deshierbe',
        category: 'Labor',
        type: TimelineEventType.labor,
      );
      expect(itemLabor.color(colors), colors.accentText);

      final itemPlaga = LearningResult(
        crop: 'Tomate',
        plotName: 'Lote 1',
        date: now,
        title: 'Gusano',
        category: 'Plaga',
        type: TimelineEventType.plaga,
      );
      expect(itemPlaga.color(colors), colors.negative);

      final itemCosecha = LearningResult(
        crop: 'Tomate',
        plotName: 'Lote 1',
        date: now,
        title: 'Cosecha final',
        category: 'Cosecha',
        type: TimelineEventType.cosecha,
      );
      expect(itemCosecha.color(colors), colors.positive);
    });

    test('LearningResult.toTimelineItem preserves all detailed properties', () {
      final now = DateTime.now();
      final app = InputApplication(
        id: 10,
        cycleId: 5,
        inputType: InputType.foliar,
        productName: 'Calcio Boro 20L',
        doseValue: 50,
        doseUnit: DoseUnit.copasBomba,
        method: 'Foliar mochila',
        appliedAt: now,
        timeOfDay: TimeOfDayChoice.morning,
        weather: WeatherCondition.sunny,
        verdict: ReactionVerdict.positive,
        reactionNotes: 'Follaje verde vigoroso',
        symptoms: 'Vigor renovado, sin quemaduras',
        reviewedAt: now,
        notes: 'Aplicado temprano con rocío ligero',
        createdAt: now,
        cropTitle: 'Tomate Santa Clara',
        plotName: 'Lote El Roble',
      );

      final learning = LearningResult(
        crop: 'Tomate Santa Clara',
        plotName: 'Lote El Roble',
        date: now,
        title: 'Calcio Boro 20L (Foliar)',
        category: 'Insumo / Tratamiento',
        type: TimelineEventType.insumo,
        id: 10,
        cycleId: 5,
        application: app,
        verdict: 'Positiva',
        notes: 'Aplicado temprano con rocío ligero',
        method: 'Foliar mochila',
        weather: WeatherCondition.sunny,
        timeOfDay: TimeOfDayChoice.morning,
        doseDisplay: '50 copas/bomba',
        symptoms: 'Vigor renovado, sin quemaduras',
        reactionNotes: 'Follaje verde vigoroso',
      );

      final timelineItem = learning.toTimelineItem();
      expect(timelineItem.id, 10);
      expect(timelineItem.cycleId, 5);
      expect(timelineItem.type, TimelineEventType.insumo);
      expect(timelineItem.title, 'Calcio Boro 20L (Foliar)');
      expect(timelineItem.application, isNotNull);
      expect(timelineItem.application?.method, 'Foliar mochila');
      expect(timelineItem.application?.weather, WeatherCondition.sunny);
      expect(timelineItem.application?.verdict, ReactionVerdict.positive);
      expect(timelineItem.application?.reactionNotes, 'Follaje verde vigoroso');
      expect(timelineItem.cropTitle, 'Tomate Santa Clara');
      expect(timelineItem.plotName, 'Lote El Roble');
    });
  });

  group('CycleDetailController Events Filtering', () {
    test('filteredEvents filters items according to selected category', () {
      final now = DateTime.now();
      final controller = CycleDetailController(
        1,
        _FakeCycleRepoForTest(),
        _FakeHistoryRepoForTest(),
        DataChanges(),
      );

      controller.events = [
        UnifiedTimelineItem(
          id: 1,
          type: TimelineEventType.insumo,
          cycleId: 1,
          title: 'Fertilizante Urea',
          date: now,
        ),
        UnifiedTimelineItem(
          id: 2,
          type: TimelineEventType.labor,
          cycleId: 1,
          title: 'Aporco',
          date: now,
        ),
        UnifiedTimelineItem(
          id: 3,
          type: TimelineEventType.plaga,
          cycleId: 1,
          title: 'Roya',
          date: now,
        ),
      ];

      // Default: todos
      expect(controller.selectedFilter, TimelineEventType.todos);
      expect(controller.filteredEvents.length, 3);

      // Filter by insumo
      controller.setFilter(TimelineEventType.insumo);
      expect(controller.filteredEvents.length, 1);
      expect(controller.filteredEvents.first.title, 'Fertilizante Urea');

      // Filter by labor
      controller.setFilter(TimelineEventType.labor);
      expect(controller.filteredEvents.length, 1);
      expect(controller.filteredEvents.first.title, 'Aporco');

      // Filter by plaga
      controller.setFilter(TimelineEventType.plaga);
      expect(controller.filteredEvents.length, 1);
      expect(controller.filteredEvents.first.title, 'Roya');

      // Return to todos
      controller.setFilter(TimelineEventType.todos);
      expect(controller.filteredEvents.length, 3);
    });
  });

  group('SymptomsData & Phytotoxicity Notes Logic', () {
    test('SymptomsData handles null, empty and whitespace strings', () {
      final parsedNull = SymptomsData.parse(null);
      expect(parsedNull.hasChips, isFalse);
      expect(parsedNull.hasNotes, isFalse);
      expect(parsedNull.isEmpty, isTrue);

      final parsedEmpty = SymptomsData.parse('');
      expect(parsedEmpty.isEmpty, isTrue);

      final parsedSpaces = SymptomsData.parse('   ');
      expect(parsedSpaces.isEmpty, isTrue);

      expect(SymptomsData.format({}, null), isNull);
      expect(SymptomsData.format({}, ''), isNull);
    });

    test('SymptomsData formats and parses structured chips only', () {
      final chips = {'Hoja quemada', 'Marchitez'};
      final formatted = SymptomsData.format(chips, null);
      expect(formatted, 'Hoja quemada, Marchitez');

      final parsed = SymptomsData.parse(formatted);
      expect(parsed.chips, equals(chips));
      expect(parsed.hasChips, isTrue);
      expect(parsed.hasNotes, isFalse);
      expect(parsed.notes, isNull);
    });

    test('SymptomsData formats and parses structured notes only', () {
      const notes = 'Bordes necrosados por aplicación al mediodía con sol fuerte.';
      final formatted = SymptomsData.format({}, notes);
      expect(formatted, contains(notes));

      final parsed = SymptomsData.parse(formatted);
      expect(parsed.hasChips, isFalse);
      expect(parsed.hasNotes, isTrue);
      expect(parsed.notes, notes);
    });

    test('SymptomsData formats and parses chips with detailed notes including commas and newlines', () {
      final chips = {'Hoja quemada', 'Amarillamiento'};
      const notes = 'Se quemaron las hojas más tiernas, especialmente brotes.\nRevisado a los 2 días.';
      final formatted = SymptomsData.format(chips, notes);
      expect(formatted, isNotNull);

      final parsed = SymptomsData.parse(formatted);
      expect(parsed.chips, equals(chips));
      expect(parsed.hasChips, isTrue);
      expect(parsed.hasNotes, isTrue);
      expect(parsed.notes, notes);
    });

    test('SymptomsData backward compatibility parses legacy comma-joined strings', () {
      // Caso 1: chips estándar históricos + notas libres con comas
      const legacy = 'Hoja quemada, Amarillamiento, Se quemaron las hojas, brotes secos';
      final parsed = SymptomsData.parse(legacy);

      expect(parsed.chips, contains('Hoja quemada'));
      expect(parsed.chips, contains('Amarillamiento'));
      expect(parsed.hasNotes, isTrue);
      expect(parsed.notes, 'Se quemaron las hojas, brotes secos');

      // Caso 2: solo notas libres sin chips
      const legacyNotesOnly = 'Las hojas se marchitaron al sol';
      final parsedNotesOnly = SymptomsData.parse(legacyNotesOnly);
      expect(parsedNotesOnly.hasChips, isFalse);
      expect(parsedNotesOnly.hasNotes, isTrue);
      expect(parsedNotesOnly.notes, 'Las hojas se marchitaron al sol');
    });

    test('InputApplication and UnifiedTimelineItem expose parsedSymptoms getter', () {
      final now = DateTime.now();
      final app = InputApplication(
        cycleId: 1,
        inputType: InputType.foliar,
        productName: 'Foliar Cobre',
        appliedAt: now,
        verdict: ReactionVerdict.negative,
        symptoms: 'Hoja quemada\n\nDetalle de fitotoxicidad:\nQuemazón en ápice foliar',
        createdAt: now,
      );

      expect(app.parsedSymptoms.hasChips, isTrue);
      expect(app.parsedSymptoms.chips, contains('Hoja quemada'));
      expect(app.parsedSymptoms.hasNotes, isTrue);
      expect(app.parsedSymptoms.notes, 'Quemazón en ápice foliar');

      final timelineItem = UnifiedTimelineItem(
        id: 1,
        type: TimelineEventType.insumo,
        cycleId: 1,
        title: 'Foliar Cobre',
        date: now,
        application: app,
      );

      expect(timelineItem.parsedSymptoms.notes, 'Quemazón en ápice foliar');
    });

    test('FollowUpFormController initializes with pre-populated phytotoxicity notes and chips for updating evaluation', () {
      final now = DateTime.now();
      final app = InputApplication(
        id: 1,
        cycleId: 1,
        inputType: InputType.foliar,
        productName: 'Producto Test',
        appliedAt: now,
        verdict: ReactionVerdict.negative,
        symptoms: SymptomsData.format({'Hoja quemada'}, 'Puntas quemadas por sobrefertilización'),
        reactionNotes: 'Se lavó el follaje',
        createdAt: now,
      );

      final controller = FollowUpFormController(
        app,
        _FakeAppRepoForTest(),
        _FakePhotoServiceForTest(),
        _FakeReminderServiceForTest(),
      );

      // Verify data is populated and not blank
      expect(controller.selectedVerdict, ReactionVerdict.negative);
      expect(controller.selectedSymptoms, contains('Hoja quemada'));
      expect(controller.symptomsDetailsController.text, 'Puntas quemadas por sobrefertilización');
      expect(controller.reactionNotesController.text, 'Se lavó el follaje');
    });
  });

  group('CropCycle Density & Distancing Notes Logic', () {
    test('hasDensity, hasDensityNotes and densityQuantityDisplay work as expected', () {
      final cycleBoth = CropCycle(
        id: 1,
        plotId: 1,
        crop: 'Maíz',
        plantingDate: DateTime.now(),
        densityValue: 25,
        densityUnit: DensityUnit.libras,
        densityNotes: '0.80 m entre surcos',
        stage: CropStage.growth,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(cycleBoth.hasDensity, isTrue);
      expect(cycleBoth.hasDensityNotes, isTrue);
      expect(cycleBoth.densityQuantityDisplay, '25 Libras de semilla');

      final cycleNotesOnly = CropCycle(
        id: 2,
        plotId: 1,
        crop: 'Frijol',
        plantingDate: DateTime.now(),
        densityNotes: '2 semillas por postura cada 15 cm',
        stage: CropStage.growth,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(cycleNotesOnly.hasDensity, isFalse);
      expect(cycleNotesOnly.hasDensityNotes, isTrue);
      expect(cycleNotesOnly.densityQuantityDisplay, '');

      final cycleNone = CropCycle(
        id: 3,
        plotId: 1,
        crop: 'Café',
        plantingDate: DateTime.now(),
        stage: CropStage.growth,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(cycleNone.hasDensity, isFalse);
      expect(cycleNone.hasDensityNotes, isFalse);
      expect(cycleNone.densityQuantityDisplay, '');
    });
  });
}

class _FakeCycleRepoForTest implements CycleRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<CropCycle?> getById(int id) async => null;

  @override
  Future<List<StageEvent>> getStageEvents(int cycleId) async => [];
}

class _FakeHistoryRepoForTest implements HistoryRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<List<UnifiedTimelineItem>> getTimelineForCycle(int cycleId) async => [];
}

class _FakeAppRepoForTest implements ApplicationRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakePhotoServiceForTest implements PhotoStorageService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeReminderServiceForTest implements ReminderService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

