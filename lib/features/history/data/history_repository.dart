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
    final appRows = await _database.db.rawQuery('''
      SELECT a.*, c.crop as crop_title, p.name as plot_name
      FROM input_applications a
      INNER JOIN crop_cycles c ON c.id = a.cycle_id
      INNER JOIN plots p ON p.id = c.plot_id
      WHERE a.cycle_id = ?
    ''', [cycleId]);

    for (final row in appRows) {
      final app = InputApplication.fromRow(row);
      items.add(UnifiedTimelineItem(
        id: app.id!,
        type: TimelineEventType.insumo,
        cycleId: app.cycleId,
        title: '${app.inputType.label}: ${app.productName}',
        subtitle: app.doseDisplay.isNotEmpty ? 'Dosis: ${app.doseDisplay}' : null,
        date: app.appliedAt,
        photoBefore: app.photoBefore,
        photoAfter: app.photoAfter,
        badgeText: app.followUpVerdict?.label,
        notes: app.notes ?? app.followUpNotes,
        application: app,
      ));
    }

    // 2. Labores culturales
    final taskRows = await _database.db.rawQuery('''
      SELECT t.*, c.crop as crop_title, p.name as plot_name
      FROM cultural_tasks t
      INNER JOIN crop_cycles c ON c.id = t.cycle_id
      INNER JOIN plots p ON p.id = c.plot_id
      WHERE t.cycle_id = ?
    ''', [cycleId]);

    for (final row in taskRows) {
      final task = CulturalTask.fromRow(row);
      items.add(UnifiedTimelineItem(
        id: task.id!,
        type: TimelineEventType.labor,
        cycleId: task.cycleId,
        title: task.taskType.label,
        subtitle: task.peopleCount != null ? '${task.peopleCount} personas involucradas' : null,
        date: task.date,
        photoBefore: task.photoBefore,
        photoAfter: task.photoAfter,
        notes: task.notes,
        task: task,
      ));
    }

    // 3. Incidencias, plagas y clima
    final incidentRows = await _database.db.rawQuery('''
      SELECT i.*, c.crop as crop_title, p.name as plot_name
      FROM incidents i
      INNER JOIN crop_cycles c ON c.id = i.cycle_id
      INNER JOIN plots p ON p.id = c.plot_id
      WHERE i.cycle_id = ?
    ''', [cycleId]);

    for (final row in incidentRows) {
      final inc = Incident.fromRow(row);
      items.add(UnifiedTimelineItem(
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
      ));
    }

    // 4. Hitos de etapa
    final stageRows = await _database.db.rawQuery('''
      SELECT * FROM cycle_stage_events
      WHERE cycle_id = ?
    ''', [cycleId]);

    for (final row in stageRows) {
      final st = StageEvent.fromRow(row);
      items.add(UnifiedTimelineItem(
        id: st.id ?? st.stage.hashCode,
        type: TimelineEventType.etapa,
        cycleId: st.cycleId,
        title: 'Hito: ${st.stage.label}',
        subtitle: 'Cambio de fase fenológica del cultivo',
        date: st.date,
        stageEvent: st,
      ));
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

    final includeInsumos = filter == TimelineEventType.todos || filter == TimelineEventType.insumo;
    final includeLabores = filter == TimelineEventType.todos || filter == TimelineEventType.labor;
    final includePlagas = filter == TimelineEventType.todos || filter == TimelineEventType.plaga;
    final includeCosechas = filter == TimelineEventType.todos || filter == TimelineEventType.cosecha;

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
          CASE 
            WHEN a.notes IS NOT NULL AND a.notes != '' THEN a.notes
            WHEN a.reaction_notes IS NOT NULL AND a.reaction_notes != '' THEN a.reaction_notes
            WHEN a.symptoms IS NOT NULL AND a.symptoms != '' THEN a.symptoms
            WHEN a.dose_value IS NOT NULL THEN ('Dosis: ' || a.dose_value || ' ' || COALESCE(a.dose_unit, ''))
            ELSE NULL
          END AS observation,
          COALESCE(a.photo_after, a.photo_before) AS photo_path
        FROM input_applications a
        INNER JOIN crop_cycles c ON c.id = a.cycle_id
        INNER JOIN plots p ON p.id = c.plot_id
      ''';
      if (hasQuery) {
        sql += ' WHERE (a.product_name LIKE ? OR a.notes LIKE ? OR a.reaction_notes LIKE ? OR a.symptoms LIKE ? OR c.crop LIKE ? OR p.name LIKE ?)';
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
          t.notes AS observation,
          t.photo_path AS photo_path
        FROM cultural_tasks t
        INNER JOIN crop_cycles c ON c.id = t.cycle_id
        INNER JOIN plots p ON p.id = c.plot_id
      ''';
      if (hasQuery) {
        sql += ' WHERE (t.task_type LIKE ? OR t.notes LIKE ? OR t.method LIKE ? OR c.crop LIKE ? OR p.name LIKE ?)';
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
          CASE 
            WHEN i.action_taken IS NOT NULL AND i.action_taken != '' THEN ('Acción: ' || i.action_taken)
            ELSE i.notes
          END AS observation,
          i.photo_path AS photo_path
        FROM incidents i
        INNER JOIN crop_cycles c ON c.id = i.cycle_id
        INNER JOIN plots p ON p.id = c.plot_id
      ''';
      if (hasQuery) {
        sql += ' WHERE (i.name LIKE ? OR i.notes LIKE ? OR i.action_taken LIKE ? OR c.crop LIKE ? OR p.name LIKE ?)';
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
          END AS observation,
          NULL AS photo_path
        FROM crop_cycles c
        INNER JOIN plots p ON p.id = c.plot_id
        WHERE (c.stage = 'done' OR c.harvest_end IS NOT NULL OR c.what_worked IS NOT NULL OR c.what_failed IS NOT NULL OR c.yield_value IS NOT NULL)
      ''';
      if (hasQuery) {
        sql += ' AND (c.crop LIKE ? OR c.variety LIKE ? OR c.what_worked LIKE ? OR c.what_failed LIKE ? OR p.name LIKE ?)';
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
    final dataSql = 'SELECT * FROM ($unionSql) ORDER BY date DESC LIMIT ? OFFSET ?';
    final dataRows = await _database.db.rawQuery(dataSql, [...args, limit, offset]);

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
      if (eventType == TimelineEventType.insumo) {
        final inputLabel = enumFromName(InputType.values, subType, InputType.fertilizanteGranular).label;
        title = '$rawName ($inputLabel)';
      } else if (eventType == TimelineEventType.labor) {
        final taskLabel = enumFromName(TaskType.values, rawName, TaskType.preparacionTierra).label;
        title = taskLabel;
      }

      String? verdict = row['verdict'] as String?;
      if (eventType == TimelineEventType.insumo && verdict != null) {
        verdict = enumFromName(ReactionVerdict.values, verdict, ReactionVerdict.positive).label;
      } else if (eventType == TimelineEventType.plaga && verdict != null) {
        final severityStr = verdict.replaceFirst('Severidad: ', '');
        final severityLabel = enumFromName(IncidentSeverity.values, severityStr, IncidentSeverity.moderada).label;
        verdict = 'Severidad: $severityLabel';
      }

      items.add(LearningResult(
        crop: row['crop'] as String,
        plotName: row['plot_name'] as String,
        date: DateTime.fromMillisecondsSinceEpoch(row['date'] as int),
        title: title,
        category: row['category'] as String,
        verdict: verdict,
        observation: row['observation'] as String?,
        photoPath: row['photo_path'] as String?,
        type: eventType,
        id: row['id'] as int?,
        cycleId: row['cycle_id'] as int?,
      ));
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

