import 'package:flutter_test/flutter_test.dart';
import 'package:tierra_y_hoja/core/utils/formatters.dart';
import 'package:tierra_y_hoja/core/utils/validators.dart';
import 'package:tierra_y_hoja/features/costs/models/cost_models.dart';
import 'package:tierra_y_hoja/features/cycles/models/crop_cycle.dart';
import 'package:tierra_y_hoja/features/plots/models/plot.dart';

void main() {
  group('Formatters & Design System', () {
    test('Formatters.money formats Honduran Lempira with L and 2 decimals', () {
      expect(Formatters.money(0), 'L 0.00');
      expect(Formatters.money(1500), 'L 1,500.00');
      expect(Formatters.money(1234.5), 'L 1,234.50');
      expect(Formatters.money(-250.75), '-L 250.75');
    });

    test('Formatters.area formats with correct unit symbol', () {
      expect(Formatters.area(2.5, AreaUnit.manzanas), '2.5 mz');
      expect(Formatters.area(1.0, AreaUnit.hectareas), '1 ha');
      expect(Formatters.area(3.0, AreaUnit.tareas), '3 tareas');
    });

    test('Formatters.parseNumber parses comma and dot decimals', () {
      expect(Formatters.parseNumber('12.5'), 12.5);
      expect(Formatters.parseNumber('12,5'), 12.5);
      expect(Formatters.parseNumber('1,250.50'), 1250.5);
      expect(Formatters.parseNumber(''), isNull);
    });
  });

  group('Validators & Formal Usted Tone', () {
    test('Validators.required gives user-friendly message', () {
      final v = Validators.required('Falta el nombre.');
      expect(v(''), 'Falta el nombre.');
      expect(v('Tomate'), isNull);
    });

    test('Validators.requiredPositive validates numbers > 0', () {
      final v = Validators.requiredPositive('El área debe ser mayor a 0');
      expect(v('0'), 'Escriba una cantidad mayor que cero.');
      expect(v('-5'), 'Escriba una cantidad mayor que cero.');
      expect(v('2.5'), isNull);
    });
  });

  group('FinancialSummary Business Logic', () {
    test('calculates net profit and profitability correctly', () {
      const summary = FinancialSummary(
        totalExpenses: 5000.0,
        totalSales: 12000.0,
        expensesByCategory: {
          ExpenseCategory.insumos: 3000.0,
          ExpenseCategory.jornales: 2000.0,
        },
      );

      expect(summary.netProfit, 7000.0);
      expect(summary.isProfitable, isTrue);
      expect(summary.roiPercentage, 140.0);
    });

    test('detects loss when expenses exceed sales', () {
      const summary = FinancialSummary(
        totalExpenses: 8000.0,
        totalSales: 4000.0,
        expensesByCategory: {
          ExpenseCategory.insumos: 8000.0,
        },
      );

      expect(summary.netProfit, -4000.0);
      expect(summary.isProfitable, isFalse);
    });
  });

  group('CropCycle Logic', () {
    test('progress estimation matches stage definition', () {
      final now = DateTime.now();
      final cycle = CropCycle(
        plotId: 1,
        crop: 'Maíz',
        variety: 'H-59',
        plantingDate: now.subtract(const Duration(days: 30)),
        stage: CropStage.growth,
        createdAt: now,
        updatedAt: now,
      );

      expect(cycle.title, 'Maíz H-59');
      expect(cycle.estimatedProgress, 0.40);
      expect(cycle.isClosed, isFalse);
    });
  });
}
