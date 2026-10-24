import '../../../core/database/app_database.dart';
import '../../../core/database/db_schema.dart';
import '../models/crop_cycle.dart';

class CycleRepository {
  const CycleRepository(this._database);

  final AppDatabase _database;

  Future<List<CropCycle>> getAll({bool onlyActive = false}) async {
    final where = onlyActive ? "WHERE c.stage != 'done'" : '';
    final results = await _database.db.rawQuery('''
      SELECT c.*, p.name as plot_name
      FROM crop_cycles c
      INNER JOIN plots p ON p.id = c.plot_id
      $where
      ORDER BY c.planting_date DESC
    ''');

    return results.map(CropCycle.fromRow).toList();
  }

  Future<List<CropCycle>> getByPlot(int plotId) async {
    final results = await _database.db.rawQuery(
      '''
      SELECT c.*, p.name as plot_name
      FROM crop_cycles c
      INNER JOIN plots p ON p.id = c.plot_id
      WHERE c.plot_id = ?
      ORDER BY c.planting_date DESC
    ''',
      [plotId],
    );

    return results.map(CropCycle.fromRow).toList();
  }

  Future<CropCycle?> getById(int id) async {
    final results = await _database.db.rawQuery(
      '''
      SELECT c.*, p.name as plot_name
      FROM crop_cycles c
      INNER JOIN plots p ON p.id = c.plot_id
      WHERE c.id = ?
      LIMIT 1
    ''',
      [id],
    );

    if (results.isEmpty) return null;
    return CropCycle.fromRow(results.first);
  }

  Future<int> insert(CropCycle cycle) async {
    final id = await _database.db.insert('crop_cycles', cycle.toMap());
    // Registrar el hito de la primera etapa
    await _database.db.insert('cycle_stage_events', {
      'cycle_id': id,
      'stage': cycle.stage.name,
      'date': cycle.plantingDate.millisecondsSinceEpoch,
    });
    _database.changes.notify({
      DbTable.cycles,
      DbTable.plots,
      DbTable.stageEvents,
    });
    return id;
  }

  Future<void> update(CropCycle cycle) async {
    if (cycle.id == null) return;
    await _database.db.update(
      'crop_cycles',
      cycle.toMap(),
      where: 'id = ?',
      whereArgs: [cycle.id],
    );
    _database.changes.notify({DbTable.cycles, DbTable.plots});
  }

  Future<void> updateStage(
    int cycleId,
    CropStage newStage,
    DateTime date,
  ) async {
    await _database.db.update(
      'crop_cycles',
      {
        'stage': newStage.name,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [cycleId],
    );

    await _database.db.insert('cycle_stage_events', {
      'cycle_id': cycleId,
      'stage': newStage.name,
      'date': date.millisecondsSinceEpoch,
    });

    _database.changes.notify({
      DbTable.cycles,
      DbTable.stageEvents,
      DbTable.plots,
    });
  }

  Future<void> closeCycle({
    required int cycleId,
    required DateTime harvestStart,
    required DateTime harvestEnd,
    required double yieldValue,
    required YieldUnit yieldUnit,
    required CropQuality quality,
    String? whatWorked,
    String? whatFailed,
  }) async {
    final now = DateTime.now();
    await _database.db.update(
      'crop_cycles',
      {
        'stage': CropStage.done.name,
        'harvest_start': harvestStart.millisecondsSinceEpoch,
        'harvest_end': harvestEnd.millisecondsSinceEpoch,
        'yield_value': yieldValue,
        'yield_unit': yieldUnit.name,
        'quality': quality.name,
        'what_worked': whatWorked,
        'what_failed': whatFailed,
        'updated_at': now.millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [cycleId],
    );

    await _database.db.insert('cycle_stage_events', {
      'cycle_id': cycleId,
      'stage': CropStage.done.name,
      'date': harvestEnd.millisecondsSinceEpoch,
    });

    _database.changes.notify({
      DbTable.cycles,
      DbTable.stageEvents,
      DbTable.plots,
    });
  }

  Future<void> delete(int id) async {
    await _database.db.delete('crop_cycles', where: 'id = ?', whereArgs: [id]);
    _database.changes.notify({
      DbTable.cycles,
      DbTable.plots,
      DbTable.applications,
      DbTable.tasks,
      DbTable.incidents,
      DbTable.expenses,
      DbTable.sales,
    });
  }

  Future<List<StageEvent>> getStageEvents(int cycleId) async {
    final results = await _database.db.query(
      'cycle_stage_events',
      where: 'cycle_id = ?',
      whereArgs: [cycleId],
      orderBy: 'date ASC',
    );
    return results.map(StageEvent.fromRow).toList();
  }

  Future<List<String>> getUniqueCrops() async {
    final results = await _database.db.rawQuery('''
      SELECT DISTINCT crop FROM crop_cycles ORDER BY crop COLLATE NOCASE ASC
    ''');
    return results.map((r) => r['crop'] as String).toList();
  }

  Future<List<CropCycle>> getCyclesByCrop(String crop) async {
    final results = await _database.db.rawQuery(
      '''
      SELECT c.*, p.name as plot_name
      FROM crop_cycles c
      INNER JOIN plots p ON p.id = c.plot_id
      WHERE c.crop = ? COLLATE NOCASE
      ORDER BY c.planting_date DESC
    ''',
      [crop],
    );
    return results.map(CropCycle.fromRow).toList();
  }
}
