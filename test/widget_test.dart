import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:tierra_y_hoja/core/database/data_changes.dart';
import 'package:tierra_y_hoja/core/design/app_theme.dart';
import 'package:tierra_y_hoja/core/widgets/layout.dart';
import 'package:tierra_y_hoja/features/costs/data/cost_repository.dart';
import 'package:tierra_y_hoja/features/costs/views/expense_form_view.dart';
import 'package:tierra_y_hoja/features/cycles/data/cycle_repository.dart';
import 'package:tierra_y_hoja/features/cycles/models/crop_cycle.dart';
import 'package:tierra_y_hoja/features/cycles/views/cycle_form_view.dart';
import 'package:tierra_y_hoja/features/plots/data/plot_repository.dart';
import 'package:tierra_y_hoja/features/plots/models/plot.dart';

class FakeCostRepo implements CostRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeCycleRepo implements CycleRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<List<CropCycle>> getAll({bool onlyActive = false}) async => [];
}

class FakePlotRepo implements PlotRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<List<Plot>> getAll() async => [];
}

void main() {
  testWidgets('CycleFormView renders fields properly and BottomActionBar is constrained at bottom', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<PlotRepository>(create: (_) => FakePlotRepo()),
          Provider<CycleRepository>(create: (_) => FakeCycleRepo()),
          Provider<DataChanges>(create: (_) => DataChanges()),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const CycleFormView(),
        ),
      ),
    );

    await tester.pump();
    await tester.pumpAndSettle();

    // Verify fields are present
    expect(find.textContaining('Cultivo'), findsOneWidget);
    expect(find.textContaining('Variedad o híbrido'), findsOneWidget);
    expect(find.text('Abrir siembra'), findsOneWidget);

    // Verify BottomActionBar is NOT taking up the entire screen (1200 logical px)
    final barSize = tester.getSize(find.byType(BottomActionBar));
    expect(barSize.height, lessThan(150.0));

    // Verify Form is taking the majority of the screen
    final formSize = tester.getSize(find.byType(Form));
    expect(formSize.height, greaterThan(500.0));

    // Verify the submit button is located at the bottom of the screen, not the top
    final buttonTop = tester.getTopLeft(find.text('Abrir siembra')).dy;
    expect(buttonTop, greaterThan(1000.0));

    // Tap submit button to trigger validation without crashing SnackBar layout
    await tester.tap(find.text('Abrir siembra'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  });

  testWidgets('ExpenseFormView renders fields properly', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<CostRepository>(create: (_) => FakeCostRepo()),
          Provider<CycleRepository>(create: (_) => FakeCycleRepo()),
          Provider<DataChanges>(create: (_) => DataChanges()),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const ExpenseFormView(),
        ),
      ),
    );

    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.textContaining('Monto total invertido'), findsOneWidget);
    expect(find.text('Guardar gasto'), findsOneWidget);

    final barSize = tester.getSize(find.byType(BottomActionBar));
    expect(barSize.height, lessThan(150.0));
  });

  testWidgets('FilledButton and OutlinedButton in Row do not force infinite width', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Row(
            children: [
              const Expanded(child: Text('Left')),
              FilledButton.tonal(
                onPressed: () {},
                child: const Text('Ver cuentas'),
              ),
              OutlinedButton(
                onPressed: () {},
                child: const Text('Detalle'),
              ),
            ],
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Ver cuentas'), findsOneWidget);
    expect(find.text('Detalle'), findsOneWidget);
  });
}
