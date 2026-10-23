/// Tablas de la base de datos local. También se usan como "canales" para
/// avisar a los controladores que deben recargar sus datos.
enum DbTable {
  plots('plots'),
  cycles('crop_cycles'),
  stageEvents('cycle_stage_events'),
  applications('input_applications'),
  tasks('cultural_tasks'),
  incidents('incidents'),
  expenses('expenses'),
  sales('sales'),
  settings('app_settings');

  const DbTable(this.sql);

  /// Nombre real de la tabla en SQLite.
  final String sql;
}

/// Esquema y migraciones versionadas.
///
/// Para cambiar el esquema: subir [version] y agregar la migración
/// correspondiente en [migrations] (nunca editar una ya publicada).
abstract final class DbSchema {
  static const version = 1;
  static const fileName = 'tierra_y_hoja.db';

  /// Script de la versión 1 (instalación limpia).
  static const List<String> createV1 = [
    '''
    CREATE TABLE plots(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      area REAL NOT NULL,
      area_unit TEXT NOT NULL,
      latitude REAL,
      longitude REAL,
      soil_texture TEXT,
      topography TEXT,
      water_access TEXT,
      previous_crops TEXT,
      photo_path TEXT,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL
    )
    ''',
    '''
    CREATE TABLE crop_cycles(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      plot_id INTEGER NOT NULL REFERENCES plots(id) ON DELETE CASCADE,
      crop TEXT NOT NULL,
      variety TEXT,
      planting_date INTEGER NOT NULL,
      density_value REAL,
      density_unit TEXT,
      density_notes TEXT,
      stage TEXT NOT NULL,
      harvest_start INTEGER,
      harvest_end INTEGER,
      yield_value REAL,
      yield_unit TEXT,
      quality TEXT,
      what_worked TEXT,
      what_failed TEXT,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL
    )
    ''',
    'CREATE INDEX idx_cycles_plot ON crop_cycles(plot_id)',
    'CREATE INDEX idx_cycles_stage ON crop_cycles(stage)',
    'CREATE INDEX idx_cycles_crop ON crop_cycles(crop COLLATE NOCASE)',
    '''
    CREATE TABLE cycle_stage_events(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      cycle_id INTEGER NOT NULL REFERENCES crop_cycles(id) ON DELETE CASCADE,
      stage TEXT NOT NULL,
      date INTEGER NOT NULL
    )
    ''',
    'CREATE INDEX idx_stage_events_cycle ON cycle_stage_events(cycle_id, date)',
    '''
    CREATE TABLE input_applications(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      cycle_id INTEGER NOT NULL REFERENCES crop_cycles(id) ON DELETE CASCADE,
      input_type TEXT NOT NULL,
      product_name TEXT NOT NULL,
      dose_value REAL,
      dose_unit TEXT,
      method TEXT,
      applied_at INTEGER NOT NULL,
      time_of_day TEXT,
      weather TEXT,
      review_due_at INTEGER,
      verdict TEXT,
      reaction_notes TEXT,
      symptoms TEXT,
      reviewed_at INTEGER,
      photo_before TEXT,
      photo_after TEXT,
      notes TEXT,
      created_at INTEGER NOT NULL
    )
    ''',
    'CREATE INDEX idx_app_cycle ON input_applications(cycle_id, applied_at)',
    'CREATE INDEX idx_app_review ON input_applications(review_due_at) '
        'WHERE verdict IS NULL',
    'CREATE INDEX idx_app_product ON input_applications(product_name COLLATE NOCASE)',
    '''
    CREATE TABLE cultural_tasks(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      cycle_id INTEGER NOT NULL REFERENCES crop_cycles(id) ON DELETE CASCADE,
      task_type TEXT NOT NULL,
      method TEXT,
      date INTEGER NOT NULL,
      irrigation_hours REAL,
      irrigation_mm REAL,
      workers INTEGER,
      notes TEXT,
      photo_path TEXT,
      created_at INTEGER NOT NULL
    )
    ''',
    'CREATE INDEX idx_tasks_cycle ON cultural_tasks(cycle_id, date)',
    '''
    CREATE TABLE incidents(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      cycle_id INTEGER NOT NULL REFERENCES crop_cycles(id) ON DELETE CASCADE,
      kind TEXT NOT NULL,
      name TEXT NOT NULL,
      severity TEXT NOT NULL,
      date INTEGER NOT NULL,
      action_taken TEXT,
      notes TEXT,
      photo_path TEXT,
      created_at INTEGER NOT NULL
    )
    ''',
    'CREATE INDEX idx_incidents_cycle ON incidents(cycle_id, date)',
    '''
    CREATE TABLE expenses(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      cycle_id INTEGER NOT NULL REFERENCES crop_cycles(id) ON DELETE CASCADE,
      category TEXT NOT NULL,
      description TEXT,
      quantity REAL,
      unit_price REAL,
      amount REAL NOT NULL,
      date INTEGER NOT NULL,
      notes TEXT,
      created_at INTEGER NOT NULL
    )
    ''',
    'CREATE INDEX idx_expenses_cycle ON expenses(cycle_id, date)',
    '''
    CREATE TABLE sales(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      cycle_id INTEGER NOT NULL REFERENCES crop_cycles(id) ON DELETE CASCADE,
      quantity REAL,
      unit TEXT,
      unit_price REAL,
      amount REAL NOT NULL,
      date INTEGER NOT NULL,
      buyer TEXT,
      notes TEXT,
      created_at INTEGER NOT NULL
    )
    ''',
    'CREATE INDEX idx_sales_cycle ON sales(cycle_id, date)',
    '''
    CREATE TABLE app_settings(
      key TEXT PRIMARY KEY,
      value TEXT
    )
    ''',
  ];

  /// Migraciones incrementales: clave = versión destino.
  static const Map<int, List<String>> migrations = {};
}
