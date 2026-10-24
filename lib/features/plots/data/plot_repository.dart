import '../../../core/database/app_database.dart';
import '../../../core/database/db_schema.dart';
import '../models/plot.dart';

class PlotRepository {
  const PlotRepository(this._database);

  final AppDatabase _database;

  Future<List<Plot>> getAll() async {
    // Obtenemos los lotes con el cultivo activo si existe
    final results = await _database.db.rawQuery('''
      SELECT p.*, 
        (SELECT c.crop FROM crop_cycles c WHERE c.plot_id = p.id AND c.stage != 'done' ORDER BY c.id DESC LIMIT 1) as active_crop
      FROM plots p
      ORDER BY p.name COLLATE NOCASE ASC
    ''');

    return results.map((row) {
      final activeCrop = row['active_crop'] as String?;
      return Plot.fromRow(row, activeCropName: activeCrop);
    }).toList();
  }

  Future<Plot?> getById(int id) async {
    final results = await _database.db.rawQuery('''
      SELECT p.*, 
        (SELECT c.crop FROM crop_cycles c WHERE c.plot_id = p.id AND c.stage != 'done' ORDER BY c.id DESC LIMIT 1) as active_crop
      FROM plots p
      WHERE p.id = ?
      LIMIT 1
    ''', [id]);

    if (results.isEmpty) return null;
    final row = results.first;
    return Plot.fromRow(row, activeCropName: row['active_crop'] as String?);
  }

  Future<int> insert(Plot plot) async {
    final id = await _database.db.insert('plots', plot.toMap());
    _database.changes.notify({DbTable.plots});
    return id;
  }

  Future<void> update(Plot plot) async {
    if (plot.id == null) return;
    await _database.db.update(
      'plots',
      plot.toMap(),
      where: 'id = ?',
      whereArgs: [plot.id],
    );
    _database.changes.notify({DbTable.plots});
  }

  Future<void> delete(int id) async {
    await _database.db.delete('plots', where: 'id = ?', whereArgs: [id]);
    _database.changes.notify({DbTable.plots, DbTable.cycles});
  }

  Future<int> count() async {
    final count = await _database.db.rawQuery('SELECT COUNT(*) as count FROM plots');
    if (count.isEmpty) return 0;
    return (count.first['count'] as num?)?.toInt() ?? 0;
  }
}
