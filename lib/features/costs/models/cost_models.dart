import 'package:flutter/widgets.dart';

import '../../../core/database/row_reader.dart';
import '../../../core/design/app_icons.dart';
import '../../../core/utils/choice_option.dart';
import '../../../core/utils/formatters.dart';

/// Categorías de gastos o compras agrícolas.
enum ExpenseCategory implements ChoiceOption {
  insumos('Insumos y fertilizantes', AppIcons.application),
  semilla('Semilla / Plántulas', AppIcons.pottedPlant),
  jornales('Jornales / Mano de obra', AppIcons.users),
  maquinaria('Maquinaria / Combustible', AppIcons.tractor),
  transporte('Transporte / Fletes', AppIcons.truck),
  otros('Otros gastos', AppIcons.receipt);

  const ExpenseCategory(this.label, this.icon);

  @override
  final String label;

  @override
  final IconData icon;
}

/// Registro de un gasto o compra invertida en el cultivo.
class Expense {
  const Expense({
    this.id,
    required this.cycleId,
    required this.category,
    this.description,
    this.quantity,
    this.unitPrice,
    required this.amount,
    required this.date,
    this.notes,
    required this.createdAt,
    this.cropTitle = '',
    this.plotName = '',
  });

  final int? id;
  final int cycleId;
  final ExpenseCategory category;
  final String? description;
  final double? quantity;
  final double? unitPrice;
  final double amount;
  final DateTime date;
  final String? notes;
  final DateTime createdAt;

  final String cropTitle;
  final String plotName;

  String get title => (description == null || description!.isEmpty)
      ? category.label
      : description!;

  String get amountDisplay => Formatters.money(amount);

  factory Expense.fromRow(
    Map<String, Object?> row, {
    String cropTitle = '',
    String plotName = '',
  }) {
    return Expense(
      id: row.integerOrNull('id'),
      cycleId: row.integer('cycle_id'),
      category: enumFromName(ExpenseCategory.values, row['category'], ExpenseCategory.insumos),
      description: row.textOrNull('description'),
      quantity: row.decimalOrNull('quantity'),
      unitPrice: row.decimalOrNull('unit_price'),
      amount: row.decimal('amount'),
      date: row.date('date'),
      notes: row.textOrNull('notes'),
      createdAt: row.date('created_at'),
      cropTitle: row.textOrNull('crop_title') ?? cropTitle,
      plotName: row.textOrNull('plot_name') ?? plotName,
    );
  }

  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      'cycle_id': cycleId,
      'category': category.name,
      'description': description,
      'quantity': quantity,
      'unit_price': unitPrice,
      'amount': amount,
      'date': date.millisecondsSinceEpoch,
      'notes': notes,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }
}

/// Registro de una venta de la cosecha obtenida.
class Sale {
  const Sale({
    this.id,
    required this.cycleId,
    this.quantity,
    this.unit,
    this.unitPrice,
    required this.amount,
    required this.date,
    this.buyer,
    this.notes,
    required this.createdAt,
    this.cropTitle = '',
    this.plotName = '',
  });

  final int? id;
  final int cycleId;
  final double? quantity;
  final String? unit;
  final double? unitPrice;
  final double amount;
  final DateTime date;
  final String? buyer;
  final String? notes;
  final DateTime createdAt;

  final String cropTitle;
  final String plotName;

  String get amountDisplay => Formatters.money(amount);

  factory Sale.fromRow(
    Map<String, Object?> row, {
    String cropTitle = '',
    String plotName = '',
  }) {
    return Sale(
      id: row.integerOrNull('id'),
      cycleId: row.integer('cycle_id'),
      quantity: row.decimalOrNull('quantity'),
      unit: row.textOrNull('unit'),
      unitPrice: row.decimalOrNull('unit_price'),
      amount: row.decimal('amount'),
      date: row.date('date'),
      buyer: row.textOrNull('buyer'),
      notes: row.textOrNull('notes'),
      createdAt: row.date('created_at'),
      cropTitle: row.textOrNull('crop_title') ?? cropTitle,
      plotName: row.textOrNull('plot_name') ?? plotName,
    );
  }

  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      'cycle_id': cycleId,
      'quantity': quantity,
      'unit': unit,
      'unit_price': unitPrice,
      'amount': amount,
      'date': date.millisecondsSinceEpoch,
      'buyer': buyer,
      'notes': notes,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }
}

/// Balance financiero consolidado para un ciclo o globalmente.
class FinancialSummary {
  const FinancialSummary({
    required this.totalExpenses,
    required this.totalSales,
    required this.expensesByCategory,
  });

  final double totalExpenses;
  final double totalSales;
  final Map<ExpenseCategory, double> expensesByCategory;

  double get netProfit => totalSales - totalExpenses;

  bool get isProfitable => netProfit >= 0;

  double get roiPercentage => totalExpenses > 0
      ? (netProfit / totalExpenses) * 100
      : (totalSales > 0 ? 100.0 : 0.0);
}
