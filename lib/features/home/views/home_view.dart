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
import '../../../core/widgets/feedback_states.dart';
import '../../../core/widgets/layout.dart';
import '../../../core/widgets/metric_card.dart';
import '../../../core/widgets/offline_banner.dart';
import '../../costs/data/cost_repository.dart';
import '../../costs/views/cost_summary_view.dart';
import '../../cycles/data/cycle_repository.dart';
import '../../cycles/views/cycle_detail_view.dart';
import '../../cycles/views/cycle_form_view.dart';
import '../../cycles/views/cycle_list_view.dart';
import '../../field_log/data/application_repository.dart';
import '../../field_log/views/follow_up_form_view.dart';
import '../../plots/data/plot_repository.dart';
import '../controllers/home_controller.dart';

/// Plantilla E: Pantalla de Inicio y Panel General de la Finca.
class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => HomeController(
        ctx.read<CycleRepository>(),
        ctx.read<PlotRepository>(),
        ctx.read<ApplicationRepository>(),
        ctx.read<CostRepository>(),
        ctx.read<DataChanges>(),
      ),
      child: const _HomeContent(),
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<HomeController>();
    final c = context.c;
    final t = context.t;
    final pad = context.screenPadding;

    return Scaffold(
      appBar: AppTopBar(
        title: 'Tierra & Hoja',
        showBack: false,
        actions: [
          IconButton(
            tooltip: 'Balance económico',
            icon: const Icon(AppIcons.money),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const CostSummaryView()),
            ),
          ),
        ],
      ),
      body: ViewStateBuilder<HomeDashboardData>(
        state: controller.state,
        onRetry: () => controller.load(),
        builder: (context, data) {
          final activeCycles = data.activeCycles;
          final pendingReviews = data.pendingReviews;
          final plots = data.plots;
          final finances = data.financialSummary;

          final now = DateTime.now();
          final dateString = 'Hoy, ${Formatters.date(now)}';

          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(pad, AppSpace.sm, pad, AppSpace.x5),
            child: ContentWidth(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Saludo y Fecha
                  ScreenTitle('Mi Finca y Cultivos', subtitle: dateString),
                  const SizedBox(height: AppSpace.md),

                  // Banner 100% Offline
                  const OfflineBanner(),
                  const SizedBox(height: AppSpace.lg),

                  // Alerta prioritaria si hay seguimientos pendientes de revisión
                  if (pendingReviews.isNotEmpty) ...[
                    AccentCard(
                      accentColor: c.accent,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                AppIcons.clock,
                                color: c.accent,
                                size: AppSize.iconMd,
                              ),
                              const SizedBox(width: AppSpace.sm),
                              Expanded(
                                child: Text(
                                  'Pendiente de revisión',
                                  style: t.titleSm.copyWith(color: c.accent),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpace.xs),
                          Text(
                            pendingReviews.length == 1
                                ? 'Tiene 1 aplicación de insumo pendiente de evaluar en campo hoy.'
                                : 'Tiene ${pendingReviews.length} aplicaciones de insumos listas para evaluar su efecto en las plantas.',
                            style: t.body,
                          ),
                          const SizedBox(height: AppSpace.md),
                          AppButton.primary(
                            label: 'Revisar ahora',
                            icon: AppIcons.check,
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => FollowUpFormView(
                                  application: pendingReviews.first,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpace.section),
                  ],

                  // Siembras activas
                  SectionHeader(
                    title: 'Siembras en desarrollo',
                    actionLabel: activeCycles.isNotEmpty ? 'Ver todas' : null,
                    onAction: activeCycles.isNotEmpty
                        ? () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const CycleListView(),
                            ),
                          )
                        : null,
                  ),
                  if (activeCycles.isEmpty)
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'No hay siembras activas en este momento',
                            style: t.titleSm,
                          ),
                          const SizedBox(height: AppSpace.xs),
                          Text(
                            'Inicie un ciclo para comenzar a llevar el registro de aplicaciones, labores y cosechas de sus lotes.',
                            style: t.bodySm,
                          ),
                          const SizedBox(height: AppSpace.lg),
                          FilledButton.icon(
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const CycleFormView(),
                              ),
                            ),
                            icon: const Icon(
                              AppIcons.plus,
                              size: AppSize.iconSm,
                            ),
                            label: const Text('Abrir nueva siembra'),
                          ),
                        ],
                      ),
                    )
                  else
                    for (final cycle in activeCycles) ...[
                      CycleCard(
                        cycle: cycle,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => CycleDetailView(cycleId: cycle.id!),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpace.listGap),
                    ],
                  const SizedBox(height: AppSpace.section),

                  // Resumen y Métricas Generales
                  const SectionHeader(title: 'Resumen general de la finca'),
                  MetricRow(
                    children: [
                      MetricCard(
                        label: 'Lotes registrados',
                        value: '${plots.length}',
                        unit: 'lotes',
                      ),
                      MetricCard(
                        label: 'Siembras en curso',
                        value: '${activeCycles.length}',
                        unit: 'cultivos',
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.md),
                  AppCard(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const CostSummaryView(),
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleIcon(
                          icon: AppIcons.money,
                          color: finances.isProfitable ? c.positive : c.accent,
                        ),
                        const SizedBox(width: AppSpace.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Balance económico acumulado',
                                style: t.label,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                Formatters.money(finances.netProfit),
                                style: t.title.copyWith(
                                  color: finances.isProfitable
                                      ? c.positive
                                      : c.ink,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          AppIcons.forward,
                          size: AppSize.iconSm,
                          color: c.inkMuted,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
