import 'package:flutter/widgets.dart';

import '../../../core/database/data_changes.dart';
import '../../../core/database/db_schema.dart';
import '../../../core/state/base_controllers.dart';
import '../../../core/state/view_state.dart';
import '../../../core/utils/formatters.dart';
import '../../cycles/data/cycle_repository.dart';
import '../../cycles/models/crop_cycle.dart';
import '../data/cost_repository.dart';
import '../models/cost_models.dart';

class CostSummaryData {
  const CostSummaryData({
    required this.summary,
    required this.expenses,
    required this.sales,
  });

  final FinancialSummary summary;
  final List<Expense> expenses;
  final List<Sale> sales;
}

class CostSummaryController extends LoadableController<CostSummaryData> {
  CostSummaryController(
    this._repository,
    DataChanges changes, {
    this.cycleId,
  }) : super(changes, watch: {DbTable.expenses, DbTable.sales}) {
    load();
  }

  final CostRepository _repository;
  final int? cycleId;

  @override
  Future<CostSummaryData> fetch() async {
    final summary = cycleId != null
        ? await _repository.getSummaryForCycle(cycleId!)
        : await _repository.getGlobalSummary();

    final expenses = cycleId != null
        ? await _repository.getExpensesByCycle(cycleId!)
        : await _repository.getAllExpenses();

    final sales = cycleId != null
        ? await _repository.getSalesByCycle(cycleId!)
        : await _repository.getAllSales();

    return CostSummaryData(
      summary: summary,
      expenses: expenses,
      sales: sales,
    );
  }

  Future<void> deleteExpense(int id) async {
    await _repository.deleteExpense(id);
  }

  Future<void> deleteSale(int id) async {
    await _repository.deleteSale(id);
  }
}

class ExpenseFormController extends FormController {
  ExpenseFormController(
    this._repository,
    this._cycleRepository, {
    this.initialExpense,
    int? preselectedCycleId,
  }) {
    descriptionController = text(initialExpense?.description ?? '');
    quantityController = text(
      initialExpense?.quantity != null ? Formatters.editable(initialExpense!.quantity) : '',
    );
    unitPriceController = text(
      initialExpense?.unitPrice != null ? Formatters.editable(initialExpense!.unitPrice) : '',
    );
    amountController = text(
      initialExpense != null ? Formatters.editable(initialExpense!.amount) : '',
    );
    notesController = text(initialExpense?.notes ?? '');

    selectedCycleId = initialExpense?.cycleId ?? preselectedCycleId;
    selectedCategory = initialExpense?.category ?? ExpenseCategory.insumos;
    date = initialExpense?.date ?? DateTime.now();

    // Auto-calculo del total al cambiar cantidad o precio unitario
    quantityController.addListener(_onQuantityOrPriceChanged);
    unitPriceController.addListener(_onQuantityOrPriceChanged);

    _loadCycles();
  }

  final CostRepository _repository;
  final CycleRepository _cycleRepository;
  final Expense? initialExpense;

  late final TextEditingController descriptionController;
  late final TextEditingController quantityController;
  late final TextEditingController unitPriceController;
  late final TextEditingController amountController;
  late final TextEditingController notesController;

  List<CropCycle> availableCycles = [];
  int? selectedCycleId;
  late ExpenseCategory selectedCategory;
  late DateTime date;

  bool get isEditing => initialExpense != null;

  void _onQuantityOrPriceChanged() {
    final qty = Formatters.parseNumber(quantityController.text);
    final price = Formatters.parseNumber(unitPriceController.text);
    if (qty != null && price != null && qty > 0 && price > 0) {
      final calculated = qty * price;
      amountController.text = Formatters.editable(calculated);
    }
  }

  Future<void> _loadCycles() async {
    try {
      availableCycles = await _cycleRepository.getAll();
      if (selectedCycleId == null && availableCycles.isNotEmpty) {
        // Priorizar el ciclo activo más reciente
        final active = availableCycles.where((c) => !c.isClosed).toList();
        selectedCycleId = active.isNotEmpty ? active.first.id : availableCycles.first.id;
      }
    } catch (_) {
      availableCycles = [];
    }
    markReady();
  }

  void setCycle(int? cycleId) => update(() => selectedCycleId = cycleId);

  void setCategory(ExpenseCategory category) => update(() => selectedCategory = category);

  void setDate(DateTime newDate) => update(() => date = newDate);

  @override
  void dispose() {
    quantityController.removeListener(_onQuantityOrPriceChanged);
    unitPriceController.removeListener(_onQuantityOrPriceChanged);
    super.dispose();
  }

  @override
  Future<SaveResult> performSave() async {
    if (selectedCycleId == null) {
      return const SaveFailure('Debe seleccionar a qué siembra o lote pertenece este gasto.');
    }

    final amount = Formatters.parseNumber(amountController.text);
    if (amount == null || amount <= 0) {
      return const SaveFailure('Debe ingresar un monto válido mayor a 0.');
    }

    final now = DateTime.now();
    final expense = Expense(
      id: initialExpense?.id,
      cycleId: selectedCycleId!,
      category: selectedCategory,
      description: descriptionController.text.trim().isEmpty ? null : descriptionController.text.trim(),
      quantity: Formatters.parseNumber(quantityController.text),
      unitPrice: Formatters.parseNumber(unitPriceController.text),
      amount: amount,
      date: date,
      notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
      createdAt: initialExpense?.createdAt ?? now,
    );

    if (isEditing) {
      await _repository.updateExpense(expense);
      return const SaveSuccess(message: 'Gasto actualizado con éxito');
    } else {
      final id = await _repository.insertExpense(expense);
      return SaveSuccess(id: id, message: 'Gasto registrado con éxito');
    }
  }
}

class SaleFormController extends FormController {
  SaleFormController(
    this._repository,
    this._cycleRepository, {
    this.initialSale,
    int? preselectedCycleId,
  }) {
    quantityController = text(
      initialSale?.quantity != null ? Formatters.editable(initialSale!.quantity) : '',
    );
    unitController = text(initialSale?.unit ?? 'Quintales');
    unitPriceController = text(
      initialSale?.unitPrice != null ? Formatters.editable(initialSale!.unitPrice) : '',
    );
    amountController = text(
      initialSale != null ? Formatters.editable(initialSale!.amount) : '',
    );
    buyerController = text(initialSale?.buyer ?? '');
    notesController = text(initialSale?.notes ?? '');

    selectedCycleId = initialSale?.cycleId ?? preselectedCycleId;
    date = initialSale?.date ?? DateTime.now();

    quantityController.addListener(_onQuantityOrPriceChanged);
    unitPriceController.addListener(_onQuantityOrPriceChanged);

    _loadCycles();
  }

  final CostRepository _repository;
  final CycleRepository _cycleRepository;
  final Sale? initialSale;

  late final TextEditingController quantityController;
  late final TextEditingController unitController;
  late final TextEditingController unitPriceController;
  late final TextEditingController amountController;
  late final TextEditingController buyerController;
  late final TextEditingController notesController;

  List<CropCycle> availableCycles = [];
  int? selectedCycleId;
  late DateTime date;

  bool get isEditing => initialSale != null;

  void _onQuantityOrPriceChanged() {
    final qty = Formatters.parseNumber(quantityController.text);
    final price = Formatters.parseNumber(unitPriceController.text);
    if (qty != null && price != null && qty > 0 && price > 0) {
      final calculated = qty * price;
      amountController.text = Formatters.editable(calculated);
    }
  }

  Future<void> _loadCycles() async {
    try {
      availableCycles = await _cycleRepository.getAll();
      if (selectedCycleId == null && availableCycles.isNotEmpty) {
        final active = availableCycles.where((c) => !c.isClosed).toList();
        selectedCycleId = active.isNotEmpty ? active.first.id : availableCycles.first.id;
      }
    } catch (_) {
      availableCycles = [];
    }
    markReady();
  }

  void setCycle(int? cycleId) => update(() => selectedCycleId = cycleId);

  void setDate(DateTime newDate) => update(() => date = newDate);

  @override
  void dispose() {
    quantityController.removeListener(_onQuantityOrPriceChanged);
    unitPriceController.removeListener(_onQuantityOrPriceChanged);
    super.dispose();
  }

  @override
  Future<SaveResult> performSave() async {
    if (selectedCycleId == null) {
      return const SaveFailure('Debe seleccionar a qué siembra o lote pertenece esta venta.');
    }

    final amount = Formatters.parseNumber(amountController.text);
    if (amount == null || amount <= 0) {
      return const SaveFailure('Debe ingresar un monto total de venta mayor a 0.');
    }

    final now = DateTime.now();
    final sale = Sale(
      id: initialSale?.id,
      cycleId: selectedCycleId!,
      quantity: Formatters.parseNumber(quantityController.text),
      unit: unitController.text.trim().isEmpty ? null : unitController.text.trim(),
      unitPrice: Formatters.parseNumber(unitPriceController.text),
      amount: amount,
      date: date,
      buyer: buyerController.text.trim().isEmpty ? null : buyerController.text.trim(),
      notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
      createdAt: initialSale?.createdAt ?? now,
    );

    if (isEditing) {
      await _repository.updateSale(sale);
      return const SaveSuccess(message: 'Venta actualizada con éxito');
    } else {
      final id = await _repository.insertSale(sale);
      return SaveSuccess(id: id, message: 'Venta registrada con éxito');
    }
  }
}
