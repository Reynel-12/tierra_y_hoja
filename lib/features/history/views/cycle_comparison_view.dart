import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/design/app_colors.dart';
import '../../../core/design/app_icons.dart';
import '../../../core/design/app_tokens.dart';
import '../../../core/design/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/badges.dart';
import '../../../core/widgets/comparison_bars.dart';
import '../../../core/widgets/feedback_states.dart';
import '../../../core/widgets/layout.dart';
import '../../costs/data/cost_repository.dart';
import '../../cycles/data/cycle_repository.dart';
import '../controllers/history_controllers.dart';

/// Plantilla E: Comparador entre ciclos de siembra.
class CycleComparisonView extends StatelessWidget {
  const CycleComparisonView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => CycleComparisonController(
        ctx.read<CycleRepository>(),
        ctx.read<CostRepository>(),
      ),
      child: const _CycleComparisonContent(),
    );
  }
}

class _CycleComparisonContent extends StatelessWidget {
  const _CycleComparisonContent();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<CycleComparisonController>();
    final c = context.c;
    final t = context.t;
    final pad = context.screenPadding;

    if (controller.isLoading) {
      return const Scaffold(
        appBar: AppTopBar(title: 'Comparar siembras'),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (controller.availableCycles.length < 2) {
      return const Scaffold(
        appBar: AppTopBar(title: 'Comparar siembras'),
        body: EmptyState(
          icon: AppIcons.scales,
          title: 'Se necesitan al menos 2 siembras',
          message: 'Registre al menos dos ciclos para comparar rendimientos, costos y resultados lado a lado.',
        ),
      );
    }

    final m = controller.metrics;

    return Scaffold(
      appBar: const AppTopBar(
        title: 'Comparar siembras',
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(pad, AppSpace.sm, pad, AppSpace.x4),
        child: ContentWidth(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Selector de Ciclo A y Ciclo B
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Seleccione las siembras a comparar:', style: t.label),
                    const SizedBox(height: AppSpace.md),
                    Row(
                      children: [
                        CircleIcon(icon: AppIcons.cycle, color: c.primary),
                        const SizedBox(width: AppSpace.sm),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            key: ValueKey(controller.cycleA?.id),
                            initialValue: controller.availableCycles.any((e) => e.id == controller.cycleA?.id)
                                ? controller.cycleA?.id
                                : null,
                            isExpanded: true,
                            decoration: const InputDecoration(labelText: 'Siembra A'),
                            items: [
                              for (final cycle in controller.availableCycles)
                                DropdownMenuItem(
                                  value: cycle.id,
                                  child: Text('${cycle.title} (${cycle.plotName})'),
                                ),
                            ],
                            onChanged: (id) {
                              if (id == null) return;
                              final match = controller.availableCycles.firstWhere((e) => e.id == id);
                              controller.selectCycleA(match);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpace.md),
                    Row(
                      children: [
                        CircleIcon(icon: AppIcons.cycle, color: c.accent),
                        const SizedBox(width: AppSpace.sm),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            key: ValueKey(controller.cycleB?.id),
                            initialValue: controller.availableCycles.any((e) => e.id == controller.cycleB?.id)
                                ? controller.cycleB?.id
                                : null,
                            isExpanded: true,
                            decoration: const InputDecoration(labelText: 'Siembra B'),
                            items: [
                              for (final cycle in controller.availableCycles)
                                DropdownMenuItem(
                                  value: cycle.id,
                                  child: Text('${cycle.title} (${cycle.plotName})'),
                                ),
                            ],
                            onChanged: (id) {
                              if (id == null) return;
                              final match = controller.availableCycles.firstWhere((e) => e.id == id);
                              controller.selectCycleB(match);
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpace.xl),

              if (m == null)
                const Center(child: Text('Cargando métricas...'))
              else ...[
                // Comparación Gráfica con Barras
                const SectionHeader(title: 'Comparativa de resultados'),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ComparisonBars(
                        title: 'Rendimiento de cosecha',
                        labelA: 'A',
                        labelB: 'B',
                        valueA: m.cycleA.yieldValue,
                        valueB: m.cycleB.yieldValue,
                        format: (v) => '$v ${m.cycleA.yieldUnit?.symbol ?? ''}',
                      ),
                      const SizedBox(height: AppSpace.lg),
                      ComparisonBars(
                        title: 'Días de ciclo productivo',
                        labelA: 'A',
                        labelB: 'B',
                        valueA: m.cycleA.daysSincePlanting.toDouble(),
                        valueB: m.cycleB.daysSincePlanting.toDouble(),
                        format: (v) => '${v.toInt()} días',
                      ),
                      const SizedBox(height: AppSpace.lg),
                      ComparisonBars(
                        title: 'Inversión total gastada',
                        labelA: 'A',
                        labelB: 'B',
                        valueA: m.summaryA.totalExpenses,
                        valueB: m.summaryB.totalExpenses,
                        format: Formatters.money,
                      ),
                      const SizedBox(height: AppSpace.lg),
                      ComparisonBars(
                        title: 'Ventas brutas ingresadas',
                        labelA: 'A',
                        labelB: 'B',
                        valueA: m.summaryA.totalSales,
                        valueB: m.summaryB.totalSales,
                        format: Formatters.money,
                      ),
                      const SizedBox(height: AppSpace.lg),
                      ComparisonBars(
                        title: 'Ganancia neta final',
                        labelA: 'A',
                        labelB: 'B',
                        valueA: m.summaryA.netProfit,
                        valueB: m.summaryB.netProfit,
                        format: Formatters.money,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpace.section),

                // Calidad obtenida
                const SectionHeader(title: 'Calidad obtenida'),
                Row(
                  children: [
                    Expanded(
                      child: AppCard(
                        borderColor: c.primary,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Siembra A', style: t.label.copyWith(color: c.primary)),
                            const SizedBox(height: AppSpace.xs),
                            Text(m.cycleA.title, style: t.titleSm),
                            const SizedBox(height: AppSpace.sm),
                            if (m.cycleA.quality != null)
                              StatusBadge(
                                label: m.cycleA.quality!.label,
                                icon: m.cycleA.quality!.icon,
                                color: c.positive,
                              )
                            else
                              Text('Sin evaluar', style: t.caption),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpace.md),
                    Expanded(
                      child: AppCard(
                        borderColor: c.accent,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Siembra B', style: t.label.copyWith(color: c.accent)),
                            const SizedBox(height: AppSpace.xs),
                            Text(m.cycleB.title, style: t.titleSm),
                            const SizedBox(height: AppSpace.sm),
                            if (m.cycleB.quality != null)
                              StatusBadge(
                                label: m.cycleB.quality!.label,
                                icon: m.cycleB.quality!.icon,
                                color: c.accent,
                              )
                            else
                              Text('Sin evaluar', style: t.caption),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
