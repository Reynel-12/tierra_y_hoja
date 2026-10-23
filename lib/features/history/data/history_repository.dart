import '../../../core/database/app_database.dart';
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

  /// Búsqueda de experiencias previas (aprendizajes, insumos aplicados y lecciones de cosechas).
  Future<List<LearningResult>> searchLearnings(String query) async {
    final results = <LearningResult>[];
    final q = '%${query.trim()}%';

    // 1. Insumos con seguimiento o notas
    final appRows = await _database.db.rawQuery('''
      SELECT a.*, c.crop as crop_title, p.name as plot_name
      FROM input_applications a
      INNER JOIN crop_cycles c ON c.id = a.cycle_id
      INNER JOIN plots p ON p.id = c.plot_id
      WHERE a.product_name LIKE ? OR a.notes LIKE ? OR a.reaction_notes LIKE ? OR a.symptoms LIKE ?
      ORDER BY a.applied_at DESC
      LIMIT 30
    ''', [q, q, q, q]);

    for (final row in appRows) {
      final app = InputApplication.fromRow(row);
      results.add(LearningResult(
        crop: app.cropTitle,
        plotName: app.plotName,
        date: app.appliedAt,
        title: '${app.productName} (${app.inputType.label})',
        category: 'Insumo / Tratamiento',
        verdict: app.followUpVerdict?.label,
        observation: app.followUpNotes ?? app.notes ?? 'Dosis: ${app.doseDisplay}',
        photoPath: app.photoAfter ?? app.photoBefore,
      ));
    }

    // 2. Plagas y eventos con acciones
    final incidentRows = await _database.db.rawQuery('''
      SELECT i.*, c.crop as crop_title, p.name as plot_name
      FROM incidents i
      INNER JOIN crop_cycles c ON c.id = i.cycle_id
      INNER JOIN plots p ON p.id = c.plot_id
      WHERE i.name LIKE ? OR i.notes LIKE ? OR i.action_taken LIKE ?
      ORDER BY i.date DESC
      LIMIT 30
    ''', [q, q, q]);

    for (final row in incidentRows) {
      final inc = Incident.fromRow(row);
      results.add(LearningResult(
        crop: inc.cropTitle,
        plotName: inc.plotName,
        date: inc.date,
        title: inc.title,
        category: 'Plaga o Incidencia',
        verdict: 'Severidad: ${inc.severity.label}',
        observation: inc.actionTaken ?? inc.description,
        photoPath: inc.photoPath,
      ));
    }

    // 3. Lecciones de fin de cosecha (¿Qué funcionó? ¿Qué falló?)
    final cycleRows = await _database.db.rawQuery('''
      SELECT c.*, p.name as plot_name
      FROM crop_cycles c
      INNER JOIN plots p ON p.id = c.plot_id
      WHERE c.stage = 'done' AND (c.crop LIKE ? OR c.variety LIKE ? OR c.what_worked LIKE ? OR c.what_failed LIKE ?)
      ORDER BY c.harvest_end DESC
      LIMIT 20
    ''', [q, q, q, q]);

    for (final row in cycleRows) {
      final c = CropCycle.fromRow(row);
      final notes = [
        if (c.whatWorked != null && c.whatWorked!.isNotEmpty) 'Funcionó: ${c.whatWorked}',
        if (c.whatFailed != null && c.whatFailed!.isNotEmpty) 'Mejorar: ${c.whatFailed}',
      ].join(' | ');

      results.add(LearningResult(
        crop: c.title,
        plotName: c.plotName,
        date: c.harvestEnd ?? c.plantingDate,
        title: 'Cierre de ciclo: ${c.title}',
        category: 'Cosecha y Aprendizaje',
        verdict: c.yieldDisplay.isNotEmpty ? 'Rendimiento: ${c.yieldDisplay}' : null,
        observation: notes.isNotEmpty ? notes : 'Cosecha completada',
      ));
    }

    return results;
  }
}
