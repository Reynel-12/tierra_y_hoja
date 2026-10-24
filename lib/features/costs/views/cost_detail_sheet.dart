import 'package:flutter/material.dart';

import '../../../core/design/app_colors.dart';
import '../../../core/design/app_icons.dart';
import '../../../core/design/app_tokens.dart';
import '../../../core/design/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/badges.dart';
import '../../../core/widgets/dialogs.dart';
import '../models/cost_models.dart';

/// Modal bottom sheet con la información completa y detallada de un gasto o compra agrícola.
class ExpenseDetailSheet extends StatelessWidget {
  const ExpenseDetailSheet({
    super.key,
    required this.expense,
    this.onDelete,
    this.onEdit,
  });

  final Expense expense;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  /// Abre el bottom sheet de detalle para un [Expense].
  static Future<void> show(
    BuildContext context, {
    required Expense expense,
    VoidCallback? onDelete,
    VoidCallback? onEdit,
  }) {
    return showAppSheet<void>(
      context,
      title: 'Detalle del gasto',
      builder: (_) => ExpenseDetailSheet(
        expense: expense,
        onDelete: onDelete,
        onEdit: onEdit,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final t = context.t;

    final hasNotes = expense.notes != null && expense.notes!.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. Cabecera contextual destacada
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleIcon(icon: expense.category.icon, color: c.primary, size: 48),
            const SizedBox(width: AppSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'GASTO O COMPRA AGRÍCOLA',
                    style: t.overline.copyWith(color: c.primary),
                  ),
                  const SizedBox(height: 2),
                  Text(expense.title, style: t.title),
                  if (expense.cropTitle.isNotEmpty ||
                      expense.plotName.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          AppIcons.leaf,
                          size: AppSize.iconSm,
                          color: c.inkMuted,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            [
                              if (expense.cropTitle.isNotEmpty)
                                expense.cropTitle,
                              if (expense.plotName.isNotEmpty)
                                'Lote: ${expense.plotName}',
                            ].join(' · '),
                            style: t.bodySm.copyWith(color: c.inkMuted),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        AppIcons.calendar,
                        size: AppSize.iconSm,
                        color: c.inkMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(Formatters.date(expense.date), style: t.caption),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpace.sm),
            StatusBadge(
              label: expense.amountDisplay,
              icon: AppIcons.money,
              color: c.primary,
            ),
          ],
        ),

        const SizedBox(height: AppSpace.lg),
        const Divider(height: 1),
        const SizedBox(height: AppSpace.lg),

        // 2. Ficha de Datos Técnicos y Financieros
        Container(
          padding: const EdgeInsets.all(AppSpace.md),
          decoration: BoxDecoration(
            color: c.surfaceRaised,
            borderRadius: AppRadius.card,
            border: Border.all(color: c.outline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(AppIcons.receipt, size: AppSize.iconSm, color: c.primary),
                  const SizedBox(width: AppSpace.xs),
                  Text(
                    'DATOS DE LA INVERSIÓN',
                    style: t.overline.copyWith(color: c.primary),
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.md),
              _CostDataRow(
                icon: expense.category.icon,
                label: 'Categoría',
                value: expense.category.label,
              ),
              const SizedBox(height: AppSpace.sm),
              _CostDataRow(
                icon: AppIcons.money,
                label: 'Total invertido',
                value: expense.amountDisplay,
                isHighlight: true,
                highlightColor: c.primary,
              ),
              if (expense.description != null &&
                  expense.description!.isNotEmpty &&
                  expense.description != expense.category.label) ...[
                const SizedBox(height: AppSpace.sm),
                _CostDataRow(
                  icon: AppIcons.note,
                  label: 'Concepto / Detalle',
                  value: expense.description!,
                ),
              ],
              if (expense.quantity != null && expense.unitPrice != null) ...[
                const SizedBox(height: AppSpace.sm),
                _CostDataRow(
                  icon: AppIcons.scales,
                  label: 'Cantidad y costo',
                  value:
                      '${Formatters.editable(expense.quantity)} un. × ${Formatters.money(expense.unitPrice!)}',
                ),
              ] else if (expense.quantity != null) ...[
                const SizedBox(height: AppSpace.sm),
                _CostDataRow(
                  icon: AppIcons.scales,
                  label: 'Cantidad',
                  value: '${Formatters.editable(expense.quantity)} un.',
                ),
              ] else if (expense.unitPrice != null) ...[
                const SizedBox(height: AppSpace.sm),
                _CostDataRow(
                  icon: AppIcons.coins,
                  label: 'Precio unitario',
                  value: Formatters.money(expense.unitPrice!),
                ),
              ],
              const SizedBox(height: AppSpace.sm),
              _CostDataRow(
                icon: AppIcons.calendar,
                label: 'Fecha de gasto',
                value: Formatters.date(expense.date),
              ),
              if (expense.cropTitle.isNotEmpty) ...[
                const SizedBox(height: AppSpace.sm),
                _CostDataRow(
                  icon: AppIcons.cycle,
                  label: 'Siembra asociada',
                  value: expense.cropTitle,
                ),
              ],
              if (expense.plotName.isNotEmpty) ...[
                const SizedBox(height: AppSpace.sm),
                _CostDataRow(
                  icon: AppIcons.plot,
                  label: 'Lote / Parcela',
                  value: expense.plotName,
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: AppSpace.md),

        // 3. Notas del gasto
        _buildNotesContainer(
          context,
          c,
          t,
          title: 'Notas del gasto:',
          notes: expense.notes,
          hasNotes: hasNotes,
        ),

        const SizedBox(height: AppSpace.xl),

        // 4. Acciones del pie
        Row(
          children: [
            if (onEdit != null) ...[
              Expanded(
                child: AppButton.secondary(
                  label: 'Editar gasto',
                  icon: AppIcons.edit,
                  onPressed: () {
                    Navigator.of(context).pop();
                    onEdit!();
                  },
                ),
              ),
              const SizedBox(width: AppSpace.md),
            ],
            if (onDelete != null) ...[
              IconButton(
                icon: const Icon(AppIcons.delete, size: AppSize.iconSm),
                color: c.negative,
                tooltip: 'Eliminar gasto',
                onPressed: () {
                  Navigator.of(context).pop();
                  onDelete!();
                },
              ),
              const SizedBox(width: AppSpace.xs),
            ],
            Expanded(
              child: AppButton.outline(
                label: 'Cerrar',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Modal bottom sheet con la información completa y detallada de una venta de cosecha.
class SaleDetailSheet extends StatelessWidget {
  const SaleDetailSheet({
    super.key,
    required this.sale,
    this.onDelete,
    this.onEdit,
  });

  final Sale sale;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  /// Abre el bottom sheet de detalle para una [Sale].
  static Future<void> show(
    BuildContext context, {
    required Sale sale,
    VoidCallback? onDelete,
    VoidCallback? onEdit,
  }) {
    return showAppSheet<void>(
      context,
      title: 'Detalle de la venta',
      builder: (_) => SaleDetailSheet(
        sale: sale,
        onDelete: onDelete,
        onEdit: onEdit,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final t = context.t;

    final hasNotes = sale.notes != null && sale.notes!.trim().isNotEmpty;
    final title = sale.buyer != null && sale.buyer!.isNotEmpty
        ? 'Venta a ${sale.buyer}'
        : 'Venta de cosecha';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. Cabecera contextual destacada
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleIcon(icon: AppIcons.sale, color: c.positive, size: 48),
            const SizedBox(width: AppSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'VENTA E INGRESO DE COSECHA',
                    style: t.overline.copyWith(color: c.positive),
                  ),
                  const SizedBox(height: 2),
                  Text(title, style: t.title),
                  if (sale.cropTitle.isNotEmpty || sale.plotName.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          AppIcons.leaf,
                          size: AppSize.iconSm,
                          color: c.inkMuted,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            [
                              if (sale.cropTitle.isNotEmpty) sale.cropTitle,
                              if (sale.plotName.isNotEmpty)
                                'Lote: ${sale.plotName}',
                            ].join(' · '),
                            style: t.bodySm.copyWith(color: c.inkMuted),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        AppIcons.calendar,
                        size: AppSize.iconSm,
                        color: c.inkMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(Formatters.date(sale.date), style: t.caption),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpace.sm),
            StatusBadge(
              label: '+ ${sale.amountDisplay}',
              icon: AppIcons.money,
              color: c.positive,
            ),
          ],
        ),

        const SizedBox(height: AppSpace.lg),
        const Divider(height: 1),
        const SizedBox(height: AppSpace.lg),

        // 2. Ficha de Datos Comerciales
        Container(
          padding: const EdgeInsets.all(AppSpace.md),
          decoration: BoxDecoration(
            color: c.surfaceRaised,
            borderRadius: AppRadius.card,
            border: Border.all(color: c.outline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(AppIcons.coins, size: AppSize.iconSm, color: c.positive),
                  const SizedBox(width: AppSpace.xs),
                  Text(
                    'DATOS DE LA TRANSACCIÓN',
                    style: t.overline.copyWith(color: c.positive),
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.md),
              if (sale.buyer != null && sale.buyer!.isNotEmpty) ...[
                _CostDataRow(
                  icon: AppIcons.users,
                  label: 'Comprador / Cliente',
                  value: sale.buyer!,
                ),
                const SizedBox(height: AppSpace.sm),
              ],
              _CostDataRow(
                icon: AppIcons.money,
                label: 'Ingreso total',
                value: '+ ${sale.amountDisplay}',
                isHighlight: true,
                highlightColor: c.positive,
              ),
              if (sale.quantity != null && sale.unitPrice != null) ...[
                const SizedBox(height: AppSpace.sm),
                _CostDataRow(
                  icon: AppIcons.scales,
                  label: 'Cantidad y precio',
                  value:
                      '${Formatters.editable(sale.quantity)} ${sale.unit ?? ''} × ${Formatters.money(sale.unitPrice!)}',
                ),
              ] else if (sale.quantity != null) ...[
                const SizedBox(height: AppSpace.sm),
                _CostDataRow(
                  icon: AppIcons.scales,
                  label: 'Cantidad vendida',
                  value:
                      '${Formatters.editable(sale.quantity)} ${sale.unit ?? ''}',
                ),
              ] else if (sale.unitPrice != null) ...[
                const SizedBox(height: AppSpace.sm),
                _CostDataRow(
                  icon: AppIcons.coins,
                  label: 'Precio unitario',
                  value: Formatters.money(sale.unitPrice!),
                ),
              ],
              const SizedBox(height: AppSpace.sm),
              _CostDataRow(
                icon: AppIcons.calendar,
                label: 'Fecha de venta',
                value: Formatters.date(sale.date),
              ),
              if (sale.cropTitle.isNotEmpty) ...[
                const SizedBox(height: AppSpace.sm),
                _CostDataRow(
                  icon: AppIcons.cycle,
                  label: 'Siembra asociada',
                  value: sale.cropTitle,
                ),
              ],
              if (sale.plotName.isNotEmpty) ...[
                const SizedBox(height: AppSpace.sm),
                _CostDataRow(
                  icon: AppIcons.plot,
                  label: 'Lote / Parcela',
                  value: sale.plotName,
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: AppSpace.md),

        // 3. Notas de la venta
        _buildNotesContainer(
          context,
          c,
          t,
          title: 'Notas de la venta:',
          notes: sale.notes,
          hasNotes: hasNotes,
        ),

        const SizedBox(height: AppSpace.xl),

        // 4. Acciones del pie
        Row(
          children: [
            if (onEdit != null) ...[
              Expanded(
                child: AppButton.secondary(
                  label: 'Editar venta',
                  icon: AppIcons.edit,
                  onPressed: () {
                    Navigator.of(context).pop();
                    onEdit!();
                  },
                ),
              ),
              const SizedBox(width: AppSpace.md),
            ],
            if (onDelete != null) ...[
              IconButton(
                icon: const Icon(AppIcons.delete, size: AppSize.iconSm),
                color: c.negative,
                tooltip: 'Eliminar venta',
                onPressed: () {
                  Navigator.of(context).pop();
                  onDelete!();
                },
              ),
              const SizedBox(width: AppSpace.xs),
            ],
            Expanded(
              child: AppButton.outline(
                label: 'Cerrar',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

Widget _buildNotesContainer(
  BuildContext context,
  AppColors c,
  AppTypography t, {
  required String title,
  required String? notes,
  required bool hasNotes,
}) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(AppSpace.md),
    decoration: BoxDecoration(
      color: c.surface,
      borderRadius: AppRadius.control,
      border: Border.all(color: c.outline),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(AppIcons.note, size: AppSize.iconSm, color: c.inkSoft),
            const SizedBox(width: AppSpace.xs),
            Text(title, style: t.label),
          ],
        ),
        const SizedBox(height: AppSpace.xs),
        if (hasNotes)
          Text(notes!.trim(), style: t.bodySm)
        else
          Text(
            'Sin notas adicionales registradas.',
            style: t.caption.copyWith(
              color: c.inkMuted,
              fontStyle: FontStyle.italic,
            ),
          ),
      ],
    ),
  );
}

class _CostDataRow extends StatelessWidget {
  const _CostDataRow({
    required this.icon,
    required this.label,
    required this.value,
    this.highlightColor,
    this.isHighlight = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? highlightColor;
  final bool isHighlight;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final t = context.t;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: AppSize.iconSm, color: highlightColor ?? c.inkSoft),
        const SizedBox(width: AppSpace.sm),
        SizedBox(
          width: 130,
          child: Text(label, style: t.caption.copyWith(color: c.inkMuted)),
        ),
        const SizedBox(width: AppSpace.xs),
        Expanded(
          child: Text(
            value,
            style: isHighlight
                ? t.titleSm.copyWith(
                    color: highlightColor ?? c.primary,
                    fontWeight: FontWeight.w700,
                  )
                : t.bodySm.copyWith(color: c.ink),
          ),
        ),
      ],
    );
  }
}
