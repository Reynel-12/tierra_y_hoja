import '../../../core/database/app_database.dart';
import '../../../core/database/db_schema.dart';
import '../models/activity_models.dart';

class ActivityRepository {
  const ActivityRepository(this._database);

  final AppDatabase _database;

  // Labores culturales
  Future<List<CulturalTask>> getTasksByCycle(int cycleId) async {
    final results = await _database.db.rawQuery(
      '''
      SELECT t.*, c.crop as crop_title, p.name as plot_name
      FROM cultural_tasks t
      INNER JOIN crop_cycles c ON c.id = t.cycle_id
      INNER JOIN plots p ON p.id = c.plot_id
      WHERE t.cycle_id = ?
      ORDER BY t.date DESC
    ''',
      [cycleId],
    );

    return results.map(CulturalTask.fromRow).toList();
  }

  Future<int> insertTask(CulturalTask task) async {
    final id = await _database.db.insert('cultural_tasks', task.toMap());
    _database.changes.notify({DbTable.tasks});
    return id;
  }

  Future<void> updateTask(CulturalTask task) async {
    if (task.id == null) return;
    await _database.db.update(
      'cultural_tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
    _database.changes.notify({DbTable.tasks});
  }

  Future<void> deleteTask(int id) async {
    await _database.db.delete(
      'cultural_tasks',
      where: 'id = ?',
      whereArgs: [id],
    );
    _database.changes.notify({DbTable.tasks});
  }

  // Incidencias y eventos climáticos
  Future<List<Incident>> getIncidentsByCycle(int cycleId) async {
    final results = await _database.db.rawQuery(
      '''
      SELECT i.*, c.crop as crop_title, p.name as plot_name
      FROM incidents i
      INNER JOIN crop_cycles c ON c.id = i.cycle_id
      INNER JOIN plots p ON p.id = c.plot_id
      WHERE i.cycle_id = ?
      ORDER BY i.date DESC
    ''',
      [cycleId],
    );

    return results.map(Incident.fromRow).toList();
  }

  Future<int> insertIncident(Incident incident) async {
    final id = await _database.db.insert('incidents', incident.toMap());
    _database.changes.notify({DbTable.incidents});
    return id;
  }

  Future<void> updateIncident(Incident incident) async {
    if (incident.id == null) return;
    await _database.db.update(
      'incidents',
      incident.toMap(),
      where: 'id = ?',
      whereArgs: [incident.id],
    );
    _database.changes.notify({DbTable.incidents});
  }

  Future<void> deleteIncident(int id) async {
    await _database.db.delete('incidents', where: 'id = ?', whereArgs: [id]);
    _database.changes.notify({DbTable.incidents});
  }
}
