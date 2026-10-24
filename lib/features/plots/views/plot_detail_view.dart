import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/database/data_changes.dart';
import '../../../core/design/app_colors.dart';
import '../../../core/design/app_icons.dart';
import '../../../core/design/app_tokens.dart';
import '../../../core/design/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/badges.dart';
import '../../../core/widgets/dialogs.dart';
import '../../../core/widgets/feedback_states.dart';
import '../../../core/widgets/layout.dart';
import '../../../core/widgets/media/photo_widgets.dart';
import '../../../core/widgets/metric_card.dart';
import '../../cycles/views/cycle_form_view.dart';
import '../controllers/plot_controllers.dart';
import '../data/plot_repository.dart';
import '../models/plot.dart';
import 'plot_form_view.dart';

/// Plantilla B: Detalle de Parcela / Lote.
class PlotDetailView extends StatelessWidget {
  const PlotDetailView({super.key, required this.plotId});

  final int plotId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => PlotDetailController(
        plotId,
        ctx.read<PlotRepository>(),
        ctx.read<DataChanges>(),
      ),
      child: const _PlotDetailContent(),
    );
  }
}

class _PlotDetailContent extends StatelessWidget {
  const _PlotDetailContent();

  Future<void> _deletePlot(
    BuildContext context,
    PlotDetailController controller,
  ) async {
    final confirmed = await showConfirmDialog(
      context,
      title: '¿Eliminar este lote?',
      message:
          'Se eliminarán también todos los ciclos y registros vinculados a esta tierra.',
      confirmLabel: 'Eliminar lote',
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;
    final ok = await controller.deletePlot();
    if (!context.mounted) return;
    if (ok) {
      AppToast.success(context, 'Lote eliminado');
      Navigator.of(context).pop();
    } else {
      AppToast.error(context, 'No se pudo eliminar el lote.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PlotDetailController>();
    final c = context.c;
    final t = context.t;
    final pad = context.screenPadding;

    return Scaffold(
      appBar: AppTopBar(
        title: 'Detalle del lote',
        actions: [
          IconButton(
            tooltip: 'Editar lote',
            icon: const Icon(AppIcons.edit),
            onPressed: () {
              final plot = controller.state.dataOrNull;
              if (plot == null) return;
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => PlotFormView(plotToEdit: plot),
                ),
              );
            },
          ),
          PopupMenuButton<String>(
            tooltip: 'Más opciones',
            icon: const Icon(AppIcons.menu),
            onSelected: (val) {
              if (val == 'delete') _deletePlot(context, controller);
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(AppIcons.delete, color: c.negative),
                    const SizedBox(width: AppSpace.md),
                    const Text('Eliminar lote'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: ViewStateBuilder<Plot?>(
        state: controller.state,
        onRetry: () => controller.load(),
        builder: (context, plot) {
          if (plot == null) {
            return const Center(child: Text('Lote no encontrado'));
          }

          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(pad, AppSpace.sm, pad, AppSpace.x4),
            child: ContentWidth(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (plot.photoPath != null) ...[
                    GestureDetector(
                      onTap: () =>
                          PhotoViewerPage.open(context, before: plot.photoPath),
                      child: ClipRRect(
                        borderRadius: AppRadius.card,
                        child: PhotoBanner(
                          path: plot.photoPath!,
                          aspectRatio: 16 / 9,
                          radius: AppRadius.lg,
                          semanticLabel: 'Foto del lote ${plot.name}',
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpace.lg),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: ScreenTitle(
                          plot.name,
                          subtitle: 'Ficha técnica del terreno',
                        ),
                      ),
                      if (plot.activeCropName != null)
                        StatusBadge(
                          label: 'Sembrado: ${plot.activeCropName}',
                          icon: AppIcons.cycle,
                          color: c.positive,
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.xl),

                  // Cifras clave
                  MetricRow(
                    children: [
                      MetricCard(
                        label: 'Área total',
                        value: Formatters.editable(plot.area),
                        unit: plot.areaUnit.label,
                      ),
                      MetricCard(
                        label: 'Acceso a agua',
                        value: plot.waterAccess?.label ?? 'Temporal',
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.section),

                  // Perfil del suelo
                  const SectionHeader(title: 'Perfil del suelo y terreno'),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        InfoLine(
                          label: 'Textura del suelo',
                          value: plot.soilTexture?.label ?? 'No especificada',
                          icon: AppIcons.tree,
                        ),
                        const Divider(),
                        InfoLine(
                          label: 'Topografía',
                          value: plot.topography?.label ?? 'No especificada',
                          icon: AppIcons.waves,
                        ),
                        const Divider(),
                        InfoLine(
                          label: 'Acceso a agua',
                          value: plot.waterAccess?.label ?? 'No especificado',
                          icon: AppIcons.water,
                        ),
                        if (plot.hasCoordinates) ...[
                          const Divider(),
                          InfoLine(
                            label: 'Coordenadas GPS',
                            value:
                                '${plot.latitude!.toStringAsFixed(5)}, ${plot.longitude!.toStringAsFixed(5)}',
                            icon: AppIcons.location,
                          ),
                        ],
                        if (plot.previousCrops != null &&
                            plot.previousCrops!.isNotEmpty) ...[
                          const Divider(),
                          InfoLine(
                            label: 'Historial previo (rotación)',
                            value: plot.previousCrops!,
                            icon: AppIcons.history,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpace.section),

                  // Acción para abrir siembra en esta parcela
                  AppCard(
                    color: c.primarySoft,
                    borderColor: c.primary,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('¿Desea sembrar en este lote?', style: t.title),
                        const SizedBox(height: AppSpace.xs),
                        Text(
                          'Abra una nueva campaña o ciclo productivo para iniciar la bitácora.',
                          style: t.bodySm,
                        ),
                        const SizedBox(height: AppSpace.lg),
                        FilledButton.icon(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  CycleFormView(initialPlotId: plot.id),
                            ),
                          ),
                          icon: const Icon(
                            AppIcons.cycle,
                            size: AppSize.iconSm,
                          ),
                          label: const Text('Abrir siembra en este lote'),
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
