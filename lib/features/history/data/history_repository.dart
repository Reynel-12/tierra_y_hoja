import '../../../core/database/app_database.dart';
import '../../../core/utils/choice_option.dart';
import '../../../core/widgets/form/verdict_tiles.dart';
import '../../activities/models/activity_models.dart';
import '../../cycles/models/crop_cycle.dart';
import '../../field_log/models/input_application.dart';
import '../models/experience_models.dart';

class HistoryRepository {
  const HistoryRepository(this._database);

  final AppDatabase _database;

  /// Obtiene todos los eventos de la bitácora para un ciclo específico en orden cronológico.
  Future<List<UnifiedTimelineItem>> getTimelineForCycle(int cycleId) async {
    final items = <UnifiedTimelineItem>[];

    // 1. Insumos y aplicaciones
    final appRows = await _database.db.rawQuery(
      '''
      SELECT a.*, c.crop as crop_title, p.name as plot_name
      FROM input_applications a
      INNER JOIN crop_cycles c ON c.id = a.cycle_id
      INNER JOIN plots p ON p.id = c.plot_id
      WHERE a.cycle_id = ?
    ''',
      [cycleId],
    );

    for (final row in appRows) {
      final app = InputApplication.fromRow(row);
      items.add(
        UnifiedTimelineItem(
          id: app.id!,
          type: TimelineEventType.insumo,
          cycleId: app.cycleId,
          title: '${app.inputType.label}: ${app.productName}',
          subtitle: app.doseDisplay.isNotEmpty
              ? 'Dosis: ${app.doseDisplay}'
              : null,
          date: app.appliedAt,
          photoBefore: app.photoBefore,
          photoAfter: app.photoAfter,
          badgeText: app.followUpVerdict?.label,
          notes: app.notes ?? app.followUpNotes,
          application: app,
          cropTitle: app.cropTitle,
          plotName: app.plotName,
        ),
      );
    }

    // 2. Labores culturales
    final taskRows = await _database.db.rawQuery(
      '''
      SELECT t.*, c.crop as crop_title, p.name as plot_name
      FROM cultural_tasks t
      INNER JOIN crop_cycles c ON c.id = t.cycle_id
      INNER JOIN plots p ON p.id = c.plot_id
      WHERE t.cycle_id = ?
    ''',
      [cycleId],
    );

    for (final row in taskRows) {
      final task = CulturalTask.fromRow(row);
      items.add(
        UnifiedTimelineItem(
          id: task.id!,
          type: TimelineEventType.labor,
          cycleId: task.cycleId,
          title: task.taskType.label,
          subtitle: task.peopleCount != null
              ? '${task.peopleCount} personas involucradas'
              : null,
          date: task.date,
          photoBefore: task.photoBefore,
          photoAfter: task.photoAfter,
          notes: task.notes,
          task: task,
          cropTitle: task.cropTitle,
          plotName: task.plotName,
        ),
      );
    }

    // 3. Incidencias, plagas y clima
    final incidentRows = await _database.db.rawQuery(
      '''
      SELECT i.*, c.crop as crop_title, p.name as plot_name
      FROM incidents i
      INNER JOIN crop_cycles c ON c.id = i.cycle_id
      INNER JOIN plots p ON p.id = c.plot_id
      WHERE i.cycle_id = ?
    ''',
      [cycleId],
    );

    for (final row in incidentRows) {
      final inc = Incident.fromRow(row);
      items.add(
        UnifiedTimelineItem(
          id: inc.id!,
          type: TimelineEventType.plaga,
          cycleId: inc.cycleId,
          title: inc.title,
          subtitle: inc.actionTaken != null && inc.actionTaken!.isNotEmpty
              ? 'Acción: ${inc.actionTaken}'
              : 'Severidad: ${inc.severity.label}',
          date: inc.date,
          photoBefore: inc.photoPath,
          badgeText: inc.severity.label,
          notes: inc.description,
          incident: inc,
          cropTitle: inc.cropTitle,
          plotName: inc.plotName,
        ),
      );
    }

    // 4. Hitos de etapa
    final stageRows = await _database.db.rawQuery(
      '''
      SELECT s.*, c.crop as crop_title, p.name as plot_name
      FROM cycle_stage_events s
      INNER JOIN crop_cycles c ON c.id = s.cycle_id
      INNER JOIN plots p ON p.id = c.plot_id
      WHERE s.cycle_id = ?
    ''',
      [cycleId],
    );

    for (final row in stageRows) {
      final st = StageEvent.fromRow(row);
      items.add(
        UnifiedTimelineItem(
          id: st.id ?? st.stage.hashCode,
          type: TimelineEventType.etapa,
          cycleId: st.cycleId,
          title: 'Hito: ${st.stage.label}',
          subtitle: 'Cambio de fase fenológica del cultivo',
          date: st.date,
          stageEvent: st,
          cropTitle: row['crop_title'] as String?,
          plotName: row['plot_name'] as String?,
        ),
      );
    }

    // 5. Cosecha y cierre de ciclo (si está cerrado o tiene rendimientos registrados)
    final cycleRows = await _database.db.rawQuery(
      '''
      SELECT c.*, p.name as plot_name
      FROM crop_cycles c
      INNER JOIN plots p ON p.id = c.plot_id
      WHERE c.id = ? AND (c.stage = 'done' OR c.harvest_end IS NOT NULL OR c.yield_value IS NOT NULL)
    ''',
      [cycleId],
    );

    for (final row in cycleRows) {
      final cycle = CropCycle.fromRow(row);
      final yieldStr = cycle.yieldDisplay.isNotEmpty
          ? 'Rendimiento: ${cycle.yieldDisplay}'
          : null;
      items.add(
        UnifiedTimelineItem(
          id: cycle.id!,
          type: TimelineEventType.cosecha,
          cycleId: cycle.id!,
          title: 'Cierre y cosecha: ${cycle.crop}',
          subtitle: yieldStr,
          date: cycle.harvestEnd ?? cycle.plantingDate,
          badgeText: cycle.quality?.label,
          notes: [
            if (cycle.whatWorked != null && cycle.whatWorked!.isNotEmpty)
              'Funcionó: ${cycle.whatWorked}',
            if (cycle.whatFailed != null && cycle.whatFailed!.isNotEmpty)
              'Mejorar: ${cycle.whatFailed}',
          ].join('\n'),
          cropTitle: cycle.crop,
          plotName: row['plot_name'] as String?,
        ),
      );
    }

    // Ordenar de más reciente a más antiguo
    items.sort((a, b) => b.date.compareTo(a.date));
    return items;
  }

  /// Búsqueda y listado paginado de eventos de la memoria agrícola con filtros de categoría.
  Future<PaginatedResult<LearningResult>> getMemoryEventsPaginated({
    TimelineEventType filter = TimelineEventType.todos,
    String query = '',
    int limit = 15,
    int offset = 0,
  }) async {
    final q = query.trim();
    final hasQuery = q.isNotEmpty;
    final param = '%$q%';

    final subqueries = <String>[];
    final args = <Object?>[];

    final includeInsumos =
        filter == TimelineEventType.todos || filter == TimelineEventType.insumo;
    final includeLabores =
        filter == TimelineEventType.todos || filter == TimelineEventType.labor;
    final includePlagas =
        filter == TimelineEventType.todos || filter == TimelineEventType.plaga;
    final includeCosechas =
        filter == TimelineEventType.todos ||
        filter == TimelineEventType.cosecha;

    if (includeInsumos) {
      var sql = '''
        SELECT 
          'insumo' AS type,
          a.id AS id,
          a.cycle_id AS cycle_id,
          c.crop AS crop,
          p.name AS plot_name,
          a.applied_at AS date,
          a.product_name AS name,
          a.input_type AS sub_type,
          'Insumo / Tratamiento' AS category,
          a.verdict AS verdict,
          a.notes AS notes,
          a.photo_before AS photo_before,
          a.photo_after AS photo_after,
          COALESCE(a.photo_after, a.photo_before) AS photo_path,
          a.dose_value AS dose_value,
          a.dose_unit AS dose_unit,
          a.method AS method,
          a.time_of_day AS time_of_day,
          a.weather AS weather,
          a.review_due_at AS review_due_at,
          a.reviewed_at AS reviewed_at,
          a.reaction_notes AS reaction_notes,
          a.symptoms AS symptoms,
          NULL AS workers,
          NULL AS irrigation_hours,
          NULL AS irrigation_mm,
          NULL AS action_taken,
          NULL AS severity,
          NULL AS yield_value,
          NULL AS yield_unit,
          NULL AS quality,
          NULL AS what_worked,
          NULL AS what_failed
        FROM input_applications a
        INNER JOIN crop_cycles c ON c.id = a.cycle_id
        INNER JOIN plots p ON p.id = c.plot_id
      ''';
      if (hasQuery) {
        sql +=
            ' WHERE (a.product_name LIKE ? OR a.notes LIKE ? OR a.reaction_notes LIKE ? OR a.symptoms LIKE ? OR c.crop LIKE ? OR p.name LIKE ?)';
        args.addAll([param, param, param, param, param, param]);
      }
      subqueries.add(sql);
    }

    if (includeLabores) {
      var sql = '''
        SELECT 
          'labor' AS type,
          t.id AS id,
          t.cycle_id AS cycle_id,
          c.crop AS crop,
          p.name AS plot_name,
          t.date AS date,
          t.task_type AS name,
          t.method AS sub_type,
          'Labor cultural' AS category,
          CASE WHEN t.workers IS NOT NULL AND t.workers > 0 THEN (t.workers || ' personas') ELSE NULL END AS verdict,
          t.notes AS notes,
          t.photo_path AS photo_before,
          NULL AS photo_after,
          t.photo_path AS photo_path,
          NULL AS dose_value,
          NULL AS dose_unit,
          t.method AS method,
          NULL AS time_of_day,
          NULL AS weather,
          NULL AS review_due_at,
          NULL AS reviewed_at,
          NULL AS reaction_notes,
          NULL AS symptoms,
          t.workers AS workers,
          t.irrigation_hours AS irrigation_hours,
          t.irrigation_mm AS irrigation_mm,
          NULL AS action_taken,
          NULL AS severity,
          NULL AS yield_value,
          NULL AS yield_unit,
          NULL AS quality,
          NULL AS what_worked,
          NULL AS what_failed
        FROM cultural_tasks t
        INNER JOIN crop_cycles c ON c.id = t.cycle_id
        INNER JOIN plots p ON p.id = c.plot_id
      ''';
      if (hasQuery) {
        sql +=
            ' WHERE (t.task_type LIKE ? OR t.notes LIKE ? OR t.method LIKE ? OR c.crop LIKE ? OR p.name LIKE ?)';
        args.addAll([param, param, param, param, param]);
      }
      subqueries.add(sql);
    }

    if (includePlagas) {
      var sql = '''
        SELECT 
          'plaga' AS type,
          i.id AS id,
          i.cycle_id AS cycle_id,
          c.crop AS crop,
          p.name AS plot_name,
          i.date AS date,
          i.name AS name,
          i.kind AS sub_type,
          'Plaga o Incidencia' AS category,
          ('Severidad: ' || i.severity) AS verdict,
          i.notes AS notes,
          i.photo_path AS photo_before,
          NULL AS photo_after,
          i.photo_path AS photo_path,
          NULL AS dose_value,
          NULL AS dose_unit,
          NULL AS method,
          NULL AS time_of_day,
          NULL AS weather,
          NULL AS review_due_at,
          NULL AS reviewed_at,
          NULL AS reaction_notes,
          NULL AS symptoms,
          NULL AS workers,
          NULL AS irrigation_hours,
          NULL AS irrigation_mm,
          i.action_taken AS action_taken,
          i.severity AS severity,
          NULL AS yield_value,
          NULL AS yield_unit,
          NULL AS quality,
          NULL AS what_worked,
          NULL AS what_failed
        FROM incidents i
        INNER JOIN crop_cycles c ON c.id = i.cycle_id
        INNER JOIN plots p ON p.id = c.plot_id
      ''';
      if (hasQuery) {
        sql +=
            ' WHERE (i.name LIKE ? OR i.notes LIKE ? OR i.action_taken LIKE ? OR c.crop LIKE ? OR p.name LIKE ?)';
        args.addAll([param, param, param, param, param]);
      }
      subqueries.add(sql);
    }

    if (includeCosechas) {
      var sql = '''
        SELECT 
          'cosecha' AS type,
          c.id AS id,
          c.id AS cycle_id,
          c.crop AS crop,
          p.name AS plot_name,
          COALESCE(c.harvest_end, c.planting_date) AS date,
          ('Cierre de ciclo: ' || c.crop) AS name,
          c.variety AS sub_type,
          'Cosecha y Aprendizaje' AS category,
          CASE 
            WHEN c.yield_value IS NOT NULL AND c.yield_value > 0 THEN ('Rendimiento: ' || c.yield_value || ' ' || COALESCE(c.yield_unit, ''))
            ELSE NULL
          END AS verdict,
          CASE 
            WHEN c.what_worked IS NOT NULL AND c.what_worked != '' AND c.what_failed IS NOT NULL AND c.what_failed != '' 
              THEN ('Funcionó: ' || c.what_worked || ' | Mejorar: ' || c.what_failed)
            WHEN c.what_worked IS NOT NULL AND c.what_worked != '' 
              THEN ('Funcionó: ' || c.what_worked)
            WHEN c.what_failed IS NOT NULL AND c.what_failed != '' 
              THEN ('Mejorar: ' || c.what_failed)
            ELSE 'Cosecha completada'
          END AS notes,
          NULL AS photo_before,
          NULL AS photo_after,
          NULL AS photo_path,
          NULL AS dose_value,
          NULL AS dose_unit,
          NULL AS method,
          NULL AS time_of_day,
          NULL AS weather,
          NULL AS review_due_at,
          NULL AS reviewed_at,
          NULL AS reaction_notes,
          NULL AS symptoms,
          NULL AS workers,
          NULL AS irrigation_hours,
          NULL AS irrigation_mm,
          NULL AS action_taken,
          NULL AS severity,
          c.yield_value AS yield_value,
          c.yield_unit AS yield_unit,
          c.quality AS quality,
          c.what_worked AS what_worked,
          c.what_failed AS what_failed
        FROM crop_cycles c
        INNER JOIN plots p ON p.id = c.plot_id
        WHERE (c.stage = 'done' OR c.harvest_end IS NOT NULL OR c.what_worked IS NOT NULL OR c.what_failed IS NOT NULL OR c.yield_value IS NOT NULL)
      ''';
      if (hasQuery) {
        sql +=
            ' AND (c.crop LIKE ? OR c.variety LIKE ? OR c.what_worked LIKE ? OR c.what_failed LIKE ? OR p.name LIKE ?)';
        args.addAll([param, param, param, param, param]);
      }
      subqueries.add(sql);
    }

    if (subqueries.isEmpty) {
      return const PaginatedResult(items: [], totalCount: 0, hasMore: false);
    }

    final unionSql = subqueries.join(' UNION ALL ');

    // 1. Conteo total de registros que coinciden con los filtros
    final countSql = 'SELECT COUNT(*) as total FROM ($unionSql)';
    final countRows = await _database.db.rawQuery(countSql, args);
    final totalCount = (countRows.first['total'] as num?)?.toInt() ?? 0;

    // 2. Consulta paginada con límite y desplazamiento
    final dataSql =
        'SELECT * FROM ($unionSql) ORDER BY date DESC LIMIT ? OFFSET ?';
    final dataRows = await _database.db.rawQuery(dataSql, [
      ...args,
      limit,
      offset,
    ]);

    final items = <LearningResult>[];
    for (final row in dataRows) {
      final typeStr = row['type'] as String;
      final eventType = switch (typeStr) {
        'insumo' => TimelineEventType.insumo,
        'labor' => TimelineEventType.labor,
        'plaga' => TimelineEventType.plaga,
        'cosecha' => TimelineEventType.cosecha,
        _ => TimelineEventType.todos,
      };

      final rawName = row['name'] as String;
      final subType = row['sub_type'] as String?;
      String title = rawName;

      InputApplication? application;
      CulturalTask? task;
      Incident? incident;

      if (eventType == TimelineEventType.insumo) {
        final inputLabel = enumFromName(
          InputType.values,
          subType,
          InputType.fertilizanteGranular,
        ).label;
        title = '$rawName ($inputLabel)';
        application = InputApplication(
          id: row['id'] as int?,
          cycleId: row['cycle_id'] as int,
          inputType: enumFromName(
            InputType.values,
            subType,
            InputType.fertilizanteGranular,
          ),
          productName: rawName,
          doseValue: (row['dose_value'] as num?)?.toDouble(),
          doseUnit: enumFromNameOrNull(DoseUnit.values, row['dose_unit']),
          method: row['method'] as String?,
          appliedAt: DateTime.fromMillisecondsSinceEpoch(row['date'] as int),
          timeOfDay: enumFromNameOrNull(
            TimeOfDayChoice.values,
            row['time_of_day'],
          ),
          weather: enumFromNameOrNull(WeatherCondition.values, row['weather']),
          reviewDueAt: row['review_due_at'] != null
              ? DateTime.fromMillisecondsSinceEpoch(row['review_due_at'] as int)
              : null,
          verdict: enumFromNameOrNull(ReactionVerdict.values, row['verdict']),
          reactionNotes: row['reaction_notes'] as String?,
          symptoms: row['symptoms'] as String?,
          reviewedAt: row['reviewed_at'] != null
              ? DateTime.fromMillisecondsSinceEpoch(row['reviewed_at'] as int)
              : null,
          photoBefore: row['photo_before'] as String?,
          photoAfter: row['photo_after'] as String?,
          notes: row['notes'] as String?,
          createdAt: DateTime.fromMillisecondsSinceEpoch(row['date'] as int),
          cropTitle: row['crop'] as String,
          plotName: row['plot_name'] as String,
        );
      } else if (eventType == TimelineEventType.labor) {
        final taskLabel = enumFromName(
          TaskType.values,
          rawName,
          TaskType.preparacionTierra,
        ).label;
        title = taskLabel;
        task = CulturalTask(
          id: row['id'] as int?,
          cycleId: row['cycle_id'] as int,
          taskType: enumFromName(
            TaskType.values,
            rawName,
            TaskType.preparacionTierra,
          ),
          method: row['method'] as String?,
          date: DateTime.fromMillisecondsSinceEpoch(row['date'] as int),
          irrigationHours: (row['irrigation_hours'] as num?)?.toDouble(),
          irrigationMm: (row['irrigation_mm'] as num?)?.toDouble(),
          workers: (row['workers'] as num?)?.toInt(),
          notes: row['notes'] as String?,
          photoPath: row['photo_before'] as String?,
          createdAt: DateTime.fromMillisecondsSinceEpoch(row['date'] as int),
          cropTitle: row['crop'] as String,
          plotName: row['plot_name'] as String,
        );
      } else if (eventType == TimelineEventType.plaga) {
        incident = Incident(
          id: row['id'] as int?,
          cycleId: row['cycle_id'] as int,
          kind: enumFromName(
            IncidentKind.values,
            row['sub_type'],
            IncidentKind.plaga,
          ),
          name: rawName,
          severity: enumFromName(
            IncidentSeverity.values,
            row['severity'],
            IncidentSeverity.moderada,
          ),
          date: DateTime.fromMillisecondsSinceEpoch(row['date'] as int),
          actionTaken: row['action_taken'] as String?,
          notes: row['notes'] as String?,
          photoPath: row['photo_before'] as String?,
          createdAt: DateTime.fromMillisecondsSinceEpoch(row['date'] as int),
          cropTitle: row['crop'] as String,
          plotName: row['plot_name'] as String,
        );
      }

      String? verdict = row['verdict'] as String?;
      if (eventType == TimelineEventType.insumo && verdict != null) {
        verdict = enumFromName(
          ReactionVerdict.values,
          verdict,
          ReactionVerdict.positive,
        ).label;
      } else if (eventType == TimelineEventType.plaga && verdict != null) {
        final severityStr = verdict.replaceFirst('Severidad: ', '');
        final severityLabel = enumFromName(
          IncidentSeverity.values,
          severityStr,
          IncidentSeverity.moderada,
        ).label;
        verdict = 'Severidad: $severityLabel';
      }

      final notesStr = row['notes'] as String?;
      final reactionNotesStr = row['reaction_notes'] as String?;
      final symptomsStr = row['symptoms'] as String?;
      final observationStr = reactionNotesStr ?? notesStr ?? symptomsStr;

      items.add(
        LearningResult(
          crop: row['crop'] as String,
          plotName: row['plot_name'] as String,
          date: DateTime.fromMillisecondsSinceEpoch(row['date'] as int),
          title: title,
          category: row['category'] as String,
          verdict: verdict,
          observation: observationStr,
          photoPath: row['photo_path'] as String?,
          type: eventType,
          id: row['id'] as int?,
          cycleId: row['cycle_id'] as int?,
          application: application,
          task: task,
          incident: incident,
          whatWorked: row['what_worked'] as String?,
          whatFailed: row['what_failed'] as String?,
          yieldValue: (row['yield_value'] as num?)?.toDouble(),
          yieldUnit: row['yield_unit'] as String?,
          quality: row['quality'] as String?,
          variety: row['sub_type'] as String?,
          notes: notesStr,
          method: row['method'] as String?,
          weather: enumFromNameOrNull(WeatherCondition.values, row['weather']),
          timeOfDay: enumFromNameOrNull(
            TimeOfDayChoice.values,
            row['time_of_day'],
          ),
          doseDisplay: application?.doseDisplay,
          photoBefore: row['photo_before'] as String?,
          photoAfter: row['photo_after'] as String?,
          symptoms: symptomsStr,
          reactionNotes: reactionNotesStr,
          reviewDueAt: row['review_due_at'] != null
              ? DateTime.fromMillisecondsSinceEpoch(row['review_due_at'] as int)
              : null,
          reviewedAt: row['reviewed_at'] != null
              ? DateTime.fromMillisecondsSinceEpoch(row['reviewed_at'] as int)
              : null,
          actionTaken: row['action_taken'] as String?,
          workers: (row['workers'] as num?)?.toInt(),
          irrigationHours: (row['irrigation_hours'] as num?)?.toDouble(),
          irrigationMm: (row['irrigation_mm'] as num?)?.toDouble(),
        ),
      );
    }

    final hasMore = (offset + items.length) < totalCount;
    return PaginatedResult(
      items: items,
      totalCount: totalCount,
      hasMore: hasMore,
    );
  }

  /// Búsqueda de experiencias previas (aprendizajes, insumos aplicados y lecciones de cosechas).
  Future<List<LearningResult>> searchLearnings(String query) async {
    final res = await getMemoryEventsPaginated(query: query, limit: 30);
    return res.items;
  }
}
