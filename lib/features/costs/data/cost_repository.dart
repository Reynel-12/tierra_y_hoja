import '../../../core/database/app_database.dart';
import '../../../core/database/db_schema.dart';
import '../../../core/utils/choice_option.dart';
import '../models/cost_models.dart';

class CostRepository {
  const CostRepository(this._database);

  final AppDatabase _database;

  // Gastos
  Future<List<Expense>> getExpensesByCycle(int cycleId) async {
    final results = await _database.db.rawQuery('''
      SELECT e.*, c.crop as crop_title, p.name as plot_name
      FROM expenses e
      INNER JOIN crop_cycles c ON c.id = e.cycle_id
      INNER JOIN plots p ON p.id = c.plot_id
      WHERE e.cycle_id = ?
      ORDER BY e.date DESC
    ''', [cycleId]);

    return results.map(Expense.fromRow).toList();
  }

  Future<List<Expense>> getAllExpenses() async {
    final results = await _database.db.rawQuery('''
      SELECT e.*, c.crop as crop_title, p.name as plot_name
      FROM expenses e
      INNER JOIN crop_cycles c ON c.id = e.cycle_id
      INNER JOIN plots p ON p.id = c.plot_id
      ORDER BY e.date DESC
    ''');

    return results.map(Expense.fromRow).toList();
  }

  Future<int> insertExpense(Expense expense) async {
    final id = await _database.db.insert('expenses', expense.toMap());
    _database.changes.notify({DbTable.expenses});
    return id;
  }

  Future<void> updateExpense(Expense expense) async {
    if (expense.id == null) return;
    await _database.db.update(
      'expenses',
      expense.toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
    _database.changes.notify({DbTable.expenses});
  }

  Future<void> deleteExpense(int id) async {
    await _database.db.delete('expenses', where: 'id = ?', whereArgs: [id]);
    _database.changes.notify({DbTable.expenses});
  }

  // Ventas
  Future<List<Sale>> getSalesByCycle(int cycleId) async {
    final results = await _database.db.rawQuery('''
      SELECT s.*, c.crop as crop_title, p.name as plot_name
      FROM sales s
      INNER JOIN crop_cycles c ON c.id = s.cycle_id
      INNER JOIN plots p ON p.id = c.plot_id
      WHERE s.cycle_id = ?
      ORDER BY s.date DESC
    ''', [cycleId]);

    return results.map(Sale.fromRow).toList();
  }

  Future<List<Sale>> getAllSales() async {
    final results = await _database.db.rawQuery('''
      SELECT s.*, c.crop as crop_title, p.name as plot_name
      FROM sales s
      INNER JOIN crop_cycles c ON c.id = s.cycle_id
      INNER JOIN plots p ON p.id = c.plot_id
      ORDER BY s.date DESC
    ''');

    return results.map(Sale.fromRow).toList();
  }

  Future<int> insertSale(Sale sale) async {
    final id = await _database.db.insert('sales', sale.toMap());
    _database.changes.notify({DbTable.sales});
    return id;
  }

  Future<void> updateSale(Sale sale) async {
    if (sale.id == null) return;
    await _database.db.update(
      'sales',
      sale.toMap(),
      where: 'id = ?',
      whereArgs: [sale.id],
    );
    _database.changes.notify({DbTable.sales});
  }

  Future<void> deleteSale(int id) async {
    await _database.db.delete('sales', where: 'id = ?', whereArgs: [id]);
    _database.changes.notify({DbTable.sales});
  }

  // Resumen consolidado para un ciclo específico
  Future<FinancialSummary> getSummaryForCycle(int cycleId) async {
    final expenseRows = await _database.db.rawQuery('''
      SELECT category, SUM(amount) as total
      FROM expenses
      WHERE cycle_id = ?
      GROUP BY category
    ''', [cycleId]);

    double totalExpenses = 0.0;
    final byCategory = <ExpenseCategory, double>{};
    for (final row in expenseRows) {
      final cat = enumFromName(ExpenseCategory.values, row['category'], ExpenseCategory.otros);
      final amt = (row['total'] as num?)?.toDouble() ?? 0.0;
      byCategory[cat] = amt;
      totalExpenses += amt;
    }

    final salesRows = await _database.db.rawQuery('''
      SELECT SUM(amount) as total
      FROM sales
      WHERE cycle_id = ?
    ''', [cycleId]);

    final totalSales = (salesRows.firstOrNull?['total'] as num?)?.toDouble() ?? 0.0;

    return FinancialSummary(
      totalExpenses: totalExpenses,
      totalSales: totalSales,
      expensesByCategory: byCategory,
    );
  }

  // Resumen consolidado global
  Future<FinancialSummary> getGlobalSummary() async {
    final expenseRows = await _database.db.rawQuery('''
      SELECT category, SUM(amount) as total
      FROM expenses
      GROUP BY category
    ''');

    double totalExpenses = 0.0;
    final byCategory = <ExpenseCategory, double>{};
    for (final row in expenseRows) {
      final cat = enumFromName(ExpenseCategory.values, row['category'], ExpenseCategory.otros);
      final amt = (row['total'] as num?)?.toDouble() ?? 0.0;
      byCategory[cat] = amt;
      totalExpenses += amt;
    }

    final salesRows = await _database.db.rawQuery('''
      SELECT SUM(amount) as total
      FROM sales
    ''');

    final totalSales = (salesRows.firstOrNull?['total'] as num?)?.toDouble() ?? 0.0;

    return FinancialSummary(
      totalExpenses: totalExpenses,
      totalSales: totalSales,
      expensesByCategory: byCategory,
    );
  }
}
