import '../../../core/database/app_database.dart';
import '../../../core/database/db_schema.dart';
import '../models/input_application.dart';

class ApplicationRepository {
  const ApplicationRepository(this._database);

  final AppDatabase _database;

  Future<List<InputApplication>> getByCycle(int cycleId) async {
    final results = await _database.db.rawQuery('''
      SELECT a.*, c.crop as crop_title, p.name as plot_name
      FROM input_applications a
      INNER JOIN crop_cycles c ON c.id = a.cycle_id
      INNER JOIN plots p ON p.id = c.plot_id
      WHERE a.cycle_id = ?
      ORDER BY a.applied_at DESC
    ''', [cycleId]);

    return results.map(InputApplication.fromRow).toList();
  }

  Future<List<InputApplication>> getPendingReviews() async {
    final results = await _database.db.rawQuery('''
      SELECT a.*, c.crop as crop_title, p.name as plot_name
      FROM input_applications a
      INNER JOIN crop_cycles c ON c.id = a.cycle_id
      INNER JOIN plots p ON p.id = c.plot_id
      WHERE a.verdict IS NULL AND a.review_due_at IS NOT NULL
      ORDER BY a.review_due_at ASC
    ''');

    return results.map(InputApplication.fromRow).toList();
  }

  Future<InputApplication?> getById(int id) async {
    final results = await _database.db.rawQuery('''
      SELECT a.*, c.crop as crop_title, p.name as plot_name
      FROM input_applications a
      INNER JOIN crop_cycles c ON c.id = a.cycle_id
      INNER JOIN plots p ON p.id = c.plot_id
      WHERE a.id = ?
      LIMIT 1
    ''', [id]);

    if (results.isEmpty) return null;
    return InputApplication.fromRow(results.first);
  }

  Future<int> insert(InputApplication app) async {
    final id = await _database.db.insert('input_applications', app.toMap());
    _database.changes.notify({DbTable.applications});
    return id;
  }

  Future<void> update(InputApplication app) async {
    if (app.id == null) return;
    await _database.db.update(
      'input_applications',
      app.toMap(),
      where: 'id = ?',
      whereArgs: [app.id],
    );
    _database.changes.notify({DbTable.applications});
  }

  Future<void> updateReaction({
    required int id,
    required String verdict,
    String? reactionNotes,
    String? symptoms,
    String? photoAfter,
  }) async {
    final now = DateTime.now();
    await _database.db.update(
      'input_applications',
      {
        'verdict': verdict,
        'reaction_notes': reactionNotes,
        'symptoms': symptoms,
        'photo_after': photoAfter,
        'reviewed_at': now.millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    _database.changes.notify({DbTable.applications});
  }

  Future<void> delete(int id) async {
    await _database.db.delete('input_applications', where: 'id = ?', whereArgs: [id]);
    _database.changes.notify({DbTable.applications});
  }

  Future<List<InputApplication>> searchExperience(String query) async {
    final term = '%$query%';
    final results = await _database.db.rawQuery('''
      SELECT a.*, c.crop as crop_title, p.name as plot_name
      FROM input_applications a
      INNER JOIN crop_cycles c ON c.id = a.cycle_id
      INNER JOIN plots p ON p.id = c.plot_id
      WHERE a.product_name LIKE ?
         OR a.input_type LIKE ?
         OR a.reaction_notes LIKE ?
         OR a.symptoms LIKE ?
         OR c.crop LIKE ?
         OR p.soil_texture LIKE ?
      ORDER BY a.applied_at DESC
    ''', [term, term, term, term, term, term]);

    return results.map(InputApplication.fromRow).toList();
  }
}
