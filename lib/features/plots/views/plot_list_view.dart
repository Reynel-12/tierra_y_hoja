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
import '../../../core/widgets/form/fields.dart';
import '../../../core/widgets/layout.dart';
import '../../../core/widgets/media/photo_widgets.dart';
import '../controllers/plot_controllers.dart';
import '../data/plot_repository.dart';
import '../models/plot.dart';
import 'plot_detail_view.dart';
import 'plot_form_view.dart';

/// Plantilla A: Lista de Parcelas / Lotes.
class PlotListView extends StatelessWidget {
  const PlotListView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => PlotListController(
        ctx.read<PlotRepository>(),
        ctx.read<DataChanges>(),
      ),
      child: const _PlotListContent(),
    );
  }
}

class _PlotListContent extends StatefulWidget {
  const _PlotListContent();

  @override
  State<_PlotListContent> createState() => _PlotListContentState();
}

class _PlotListContentState extends State<_PlotListContent> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PlotListController>();
    final pad = context.screenPadding;

    return Scaffold(
      appBar: AppTopBar(
        title: 'Parcelas y lotes',
        showBack: false,
        actions: [
          IconButton(
            tooltip: 'Nuevo lote',
            icon: const Icon(AppIcons.add),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const PlotFormView()),
            ),
          ),
        ],
      ),
      body: ViewStateBuilder<List<Plot>>(
        state: controller.state,
        onRetry: () => controller.load(),
        builder: (context, plots) {
          final filtered = controller.filterList(plots);

          if (plots.isEmpty) {
            return Center(
              child: EmptyState(
                icon: AppIcons.plot,
                title: 'Aún no tiene parcelas registradas',
                message:
                    'Registre su primer lote o pedazo de tierra para abrir siembras.',
                actionLabel: 'Registrar lote',
                onAction: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const PlotFormView()),
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
                child: AppSearchField(
                  controller: _searchController,
                  hint: 'Buscar por nombre, suelo o cultivo...',
                  onChanged: controller.setFilter,
                ),
              ),
              const SizedBox(height: AppSpace.lg),
              if (filtered.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(AppSpace.xxl),
                  child: Center(
                    child: Text(
                      'No se encontraron lotes con esa búsqueda.',
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
                      final plot = filtered[index];
                      return StaggeredEntry(
                        index: index,
                        child: _PlotCard(
                          plot: plot,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => PlotDetailView(plotId: plot.id!),
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

class _PlotCard extends StatelessWidget {
  const _PlotCard({required this.plot, required this.onTap});

  final Plot plot;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final t = context.t;

    return AppCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      semanticLabel: 'Lote ${plot.name}, área: ${plot.areaDisplay}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (plot.photoPath != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadius.lg),
              ),
              child: PhotoBanner(
                path: plot.photoPath!,
                aspectRatio: 16 / 9,
                semanticLabel: 'Foto del lote ${plot.name}',
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(AppSpace.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (plot.photoPath == null) ...[
                      CircleIcon(
                        icon: AppIcons.plot,
                        size: 44,
                        iconSize: AppSize.iconMd,
                        background: c.primarySoft,
                        foreground: c.primary,
                      ),
                      const SizedBox(width: AppSpace.md),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(plot.name, style: t.title),
                          const SizedBox(height: 2),
                          Text(
                            '${plot.areaDisplay} · ${plot.waterAccess?.label ?? 'Temporal (lluvia)'}',
                            style: t.bodySm,
                          ),
                        ],
                      ),
                    ),
                    if (plot.activeCropName != null)
                      StatusBadge(
                        label: plot.activeCropName!,
                        icon: AppIcons.cycle,
                        color: c.positive,
                      ),
                  ],
                ),
                if (plot.soilTexture != null || plot.topography != null) ...[
                  const SizedBox(height: AppSpace.md),
                  Wrap(
                    spacing: AppSpace.sm,
                    children: [
                      if (plot.soilTexture != null)
                        StatusBadge(
                          label: plot.soilTexture!.label,
                          icon: AppIcons.tree,
                          color: c.neutral,
                        ),
                      if (plot.topography != null)
                        StatusBadge(
                          label: plot.topography!.label,
                          icon: AppIcons.waves,
                          color: c.neutral,
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
