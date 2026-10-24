import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/database/data_changes.dart';
import '../../../core/design/app_colors.dart';
import '../../../core/design/app_icons.dart';
import '../../../core/design/app_tokens.dart';
import '../../../core/design/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/badges.dart';
import '../../../core/widgets/dialogs.dart';
import '../../../core/widgets/feedback_states.dart';
import '../../../core/widgets/layout.dart';
import '../../../core/widgets/metric_card.dart';
import '../controllers/cost_controllers.dart';
import '../data/cost_repository.dart';
import '../models/cost_models.dart';
import 'expense_form_view.dart';
import 'sale_form_view.dart';

/// Plantilla E: Balance Económico y Finanzas Agrícolas.
class CostSummaryView extends StatelessWidget {
  const CostSummaryView({super.key, this.cycleId, this.cropTitle});

  final int? cycleId;
  final String? cropTitle;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => CostSummaryController(
        ctx.read<CostRepository>(),
        ctx.read<DataChanges>(),
        cycleId: cycleId,
      ),
      child: _CostSummaryContent(cropTitle: cropTitle, cycleId: cycleId),
    );
  }
}

class _CostSummaryContent extends StatefulWidget {
  const _CostSummaryContent({this.cropTitle, this.cycleId});

  final String? cropTitle;
  final int? cycleId;

  @override
  State<_CostSummaryContent> createState() => _CostSummaryContentState();
}

class _CostSummaryContentState extends State<_CostSummaryContent> {
  int _selectedTab = 0; // 0 = Gastos, 1 = Ventas

  Future<void> _confirmDeleteExpense(
    BuildContext context,
    CostSummaryController controller,
    Expense expense,
  ) async {
    final confirmed = await showConfirmDialog(
      context,
      title: '¿Eliminar este gasto?',
      message: 'Se borrará el registro de ${expense.amountDisplay}.',
      confirmLabel: 'Eliminar',
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;
    await controller.deleteExpense(expense.id!);
    if (context.mounted) AppToast.success(context, 'Gasto eliminado');
  }

  Future<void> _confirmDeleteSale(
    BuildContext context,
    CostSummaryController controller,
    Sale sale,
  ) async {
    final confirmed = await showConfirmDialog(
      context,
      title: '¿Eliminar esta venta?',
      message: 'Se borrará el registro de ${sale.amountDisplay}.',
      confirmLabel: 'Eliminar',
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;
    await controller.deleteSale(sale.id!);
    if (context.mounted) AppToast.success(context, 'Venta eliminada');
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<CostSummaryController>();
    final c = context.c;
    final t = context.t;
    final pad = context.screenPadding;

    final title = widget.cropTitle != null
        ? 'Costos: ${widget.cropTitle}'
        : 'Costos y Finanzas';

    return Scaffold(
      appBar: AppTopBar(title: title),
      body: ViewStateBuilder<CostSummaryData>(
        state: controller.state,
        onRetry: () => controller.load(),
        builder: (context, data) {
          final summary = data.summary;
          final expenses = data.expenses;
          final sales = data.sales;

          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(pad, AppSpace.sm, pad, AppSpace.x5),
            child: ContentWidth(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Figura Hero: Balance neto
                  HeroFigure(
                    value: Formatters.money(summary.netProfit),
                    label: summary.isProfitable
                        ? 'Ganancia neta acumulada'
                        : 'Balance actual (en inversión)',
                    caption:
                        'Ventas menos costos de insumos, jornales y fletes',
                    valueColor: summary.isProfitable ? c.positive : c.ink,
                  ),
                  const SizedBox(height: AppSpace.lg),

                  // Cifras Clave (Gastos vs Ventas)
                  MetricRow(
                    children: [
                      MetricCard(
                        label: 'Total invertido',
                        value: Formatters.money(summary.totalExpenses),
                      ),
                      MetricCard(
                        label: 'Total cosechado / vendido',
                        value: Formatters.money(summary.totalSales),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.xl),

                  // Botones rápidos de registro
                  Row(
                    children: [
                      Expanded(
                        child: AppButton.secondary(
                          label: 'Registrar gasto',
                          icon: AppIcons.plus,
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => ExpenseFormView(
                                initialCycleId: widget.cycleId,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpace.md),
                      Expanded(
                        child: AppButton.primary(
                          label: 'Registrar venta',
                          icon: AppIcons.check,
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  SaleFormView(initialCycleId: widget.cycleId),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.section),

                  // Desglose por categoría si hay gastos
                  if (summary.totalExpenses > 0) ...[
                    const SectionHeader(title: 'Distribución de gastos'),
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final cat in ExpenseCategory.values) ...[
                            if ((summary.expensesByCategory[cat] ?? 0) > 0) ...[
                              _CategoryProgressRow(
                                category: cat,
                                amount: summary.expensesByCategory[cat]!,
                                total: summary.totalExpenses,
                              ),
                              const SizedBox(height: AppSpace.md),
                            ],
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpace.section),
                  ],

                  // Pestañas de movimientos (Gastos / Ventas)
                  Row(
                    children: [
                      Expanded(
                        child: FilterChip(
                          selected: _selectedTab == 0,
                          label: Text('Gastos (${expenses.length})'),
                          onSelected: (_) => setState(() => _selectedTab = 0),
                        ),
                      ),
                      const SizedBox(width: AppSpace.sm),
                      Expanded(
                        child: FilterChip(
                          selected: _selectedTab == 1,
                          label: Text('Ventas (${sales.length})'),
                          onSelected: (_) => setState(() => _selectedTab = 1),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.md),

                  // Contenido de la pestaña activa
                  if (_selectedTab == 0) ...[
                    if (expenses.isEmpty)
                      const EmptyState(
                        icon: AppIcons.receipt,
                        title: 'Sin gastos registrados',
                        message:
                            'Presione "Registrar gasto" para llevar el control de insumos y jornales.',
                      )
                    else
                      for (final expense in expenses)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpace.sm),
                          child: AppCard(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleIcon(
                                  icon: expense.category.icon,
                                  color: c.primary,
                                ),
                                const SizedBox(width: AppSpace.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(expense.title, style: t.titleSm),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${expense.cropTitle} · ${Formatters.date(expense.date)}',
                                        style: t.bodySm,
                                      ),
                                      if (expense.quantity != null &&
                                          expense.unitPrice != null) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          '${Formatters.editable(expense.quantity)} un. × ${Formatters.money(expense.unitPrice!)}',
                                          style: t.caption,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(width: AppSpace.sm),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    ConstrainedBox(
                                      constraints: const BoxConstraints(
                                        maxWidth: 130,
                                      ),
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        alignment: Alignment.centerRight,
                                        child: Text(
                                          expense.amountDisplay,
                                          style: t.title.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        AppIcons.delete,
                                        size: AppSize.iconSm,
                                      ),
                                      color: c.negative,
                                      tooltip: 'Eliminar gasto',
                                      visualDensity: VisualDensity.compact,
                                      onPressed: () => _confirmDeleteExpense(
                                        context,
                                        controller,
                                        expense,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                  ] else ...[
                    if (sales.isEmpty)
                      const EmptyState(
                        icon: AppIcons.check,
                        title: 'Sin ventas registradas',
                        message:
                            'Presione "Registrar venta" cuando empiece a comercializar la cosecha.',
                      )
                    else
                      for (final sale in sales)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpace.sm),
                          child: AppCard(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleIcon(
                                  icon: AppIcons.check,
                                  color: c.positive,
                                ),
                                const SizedBox(width: AppSpace.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        sale.buyer != null &&
                                                sale.buyer!.isNotEmpty
                                            ? 'Venta a ${sale.buyer}'
                                            : 'Venta de cosecha',
                                        style: t.titleSm,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${sale.cropTitle} · ${Formatters.date(sale.date)}',
                                        style: t.bodySm,
                                      ),
                                      if (sale.quantity != null) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          '${Formatters.editable(sale.quantity)} ${sale.unit ?? ''}',
                                          style: t.caption,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(width: AppSpace.sm),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    ConstrainedBox(
                                      constraints: const BoxConstraints(
                                        maxWidth: 130,
                                      ),
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        alignment: Alignment.centerRight,
                                        child: Text(
                                          '+ ${sale.amountDisplay}',
                                          style: t.title.copyWith(
                                            color: c.positive,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        AppIcons.delete,
                                        size: AppSize.iconSm,
                                      ),
                                      color: c.negative,
                                      tooltip: 'Eliminar venta',
                                      visualDensity: VisualDensity.compact,
                                      onPressed: () => _confirmDeleteSale(
                                        context,
                                        controller,
                                        sale,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CategoryProgressRow extends StatelessWidget {
  const _CategoryProgressRow({
    required this.category,
    required this.amount,
    required this.total,
  });

  final ExpenseCategory category;
  final double amount;
  final double total;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final percent = total > 0 ? (amount / total) : 0.0;
    final percentText = '${(percent * 100).toStringAsFixed(1)}%';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(category.icon, size: AppSize.iconSm),
            const SizedBox(width: AppSpace.sm),
            Expanded(child: Text(category.label, style: t.body)),
            const SizedBox(width: AppSpace.sm),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 140),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text(
                  Formatters.money(amount),
                  style: t.label.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpace.xs),
        AppProgressBar(progress: percent, label: percentText),
      ],
    );
  }
}
