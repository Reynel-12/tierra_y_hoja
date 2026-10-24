import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/database/data_changes.dart';
import '../../../core/design/app_colors.dart';
import '../../../core/design/app_icons.dart';
import '../../../core/design/app_tokens.dart';
import '../../../core/design/app_typography.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/badges.dart';
import '../../../core/widgets/feedback_states.dart';
import '../../../core/widgets/form/choices.dart';
import '../../../core/widgets/form/fields.dart';
import '../../../core/widgets/layout.dart';
import '../controllers/cycle_controllers.dart';
import '../data/cycle_repository.dart';
import '../models/crop_cycle.dart';
import 'cycle_detail_view.dart';
import 'cycle_form_view.dart';

/// Plantilla A: Lista de Ciclos de Siembra.
class CycleListView extends StatelessWidget {
  const CycleListView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => CycleListController(
        ctx.read<CycleRepository>(),
        ctx.read<DataChanges>(),
      ),
      child: const _CycleListContent(),
    );
  }
}

class _CycleListContent extends StatefulWidget {
  const _CycleListContent();

  @override
  State<_CycleListContent> createState() => _CycleListContentState();
}

class _CycleListContentState extends State<_CycleListContent> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<CycleListController>();
    final pad = context.screenPadding;

    return Scaffold(
      appBar: AppTopBar(
        title: 'Siembras y ciclos',
        showBack: false,
        actions: [
          IconButton(
            tooltip: 'Abrir siembra',
            icon: const Icon(AppIcons.add),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const CycleFormView()),
            ),
          ),
        ],
      ),
      body: ViewStateBuilder<List<CropCycle>>(
        state: controller.state,
        onRetry: () => controller.load(),
        builder: (context, cycles) {
          final filtered = controller.filterList(cycles);

          if (cycles.isEmpty) {
            return Center(
              child: EmptyState(
                icon: AppIcons.cycle,
                title: 'Aún no tiene siembras registradas',
                message:
                    'Abra la primera siembra o campaña para comenzar su bitácora de campo.',
                actionLabel: 'Abrir siembra',
                onAction: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const CycleFormView(),
                  ),
                ),
              ),
            );
          }

          return ListView(
            padding: EdgeInsets.fromLTRB(
              pad,
              AppSpace.sm,
              pad,
              AppSpace.x4 * 2,
            ),
            children: [
              ContentWidth(
                child: Column(
                  children: [
                    AppSearchField(
                      controller: _searchController,
                      hint: 'Buscar por cultivo, variedad o lote...',
                      onChanged: controller.setFilter,
                    ),
                    const SizedBox(height: AppSpace.sm),
                    Row(
                      children: [
                        AppChip(
                          label: 'Todas las siembras',
                          selected: !controller.onlyActive,
                          onTap: () => controller.toggleFilterActive(false),
                        ),
                        const SizedBox(width: AppSpace.sm),
                        AppChip(
                          label: 'Solo activas',
                          selected: controller.onlyActive,
                          onTap: () => controller.toggleFilterActive(true),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpace.lg),
              if (filtered.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(AppSpace.xxl),
                  child: Center(
                    child: Text(
                      'No se encontraron siembras con ese filtro.',
                      style: context.t.bodySm,
                    ),
                  ),
                )
              else
                ContentWidth(
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpace.listGap),
                    itemBuilder: (context, index) {
                      final cycle = filtered[index];
                      return StaggeredEntry(
                        index: index,
                        child: CycleCard(
                          cycle: cycle,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  CycleDetailView(cycleId: cycle.id!),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Tarjeta de siembra según el diseño §7.6.
class CycleCard extends StatelessWidget {
  const CycleCard({super.key, required this.cycle, required this.onTap});

  final CropCycle cycle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final t = context.t;

    return AppCard(
      onTap: onTap,
      semanticLabel:
          '${cycle.title} en lote ${cycle.plotName}. Estado: ${cycle.stage.label}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(cycle.title, style: t.title),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          AppIcons.plot,
                          size: AppSize.iconBadge,
                          color: c.inkMuted,
                        ),
                        const SizedBox(width: AppSpace.xs),
                        Expanded(
                          child: Text(
                            'Lote: ${cycle.plotName}',
                            style: t.bodySm,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              StatusBadge(
                label: cycle.stage.label,
                icon: cycle.stage.icon,
                color: cycle.stage.color(c),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          AppProgressBar(
            value: cycle.estimatedProgress,
            label: cycle.isClosed
                ? 'Cosechado'
                : 'Día ${cycle.daysSincePlanting}',
          ),
          if (cycle.isClosed && cycle.yieldValue != null) ...[
            const SizedBox(height: AppSpace.sm),
            Text(
              'Rendimiento: ${cycle.yieldDisplay} · Calidad: ${cycle.quality?.label ?? ''}',
              style: t.caption.copyWith(color: c.ink),
            ),
          ],
        ],
      ),
    );
  }
}
