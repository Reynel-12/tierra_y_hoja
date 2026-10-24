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
import '../../../core/widgets/media/photo_widgets.dart';
import '../../../core/widgets/metric_card.dart';
import '../../activities/views/incident_form_view.dart';
import '../../activities/views/task_form_view.dart';
import '../../costs/views/cost_summary_view.dart';
import '../../field_log/views/application_form_view.dart';
import '../../field_log/views/follow_up_form_view.dart';
import '../../history/data/history_repository.dart';
import '../../history/models/experience_models.dart';
import '../../history/views/cycle_timeline_view.dart';
import '../controllers/cycle_controllers.dart';
import '../data/cycle_repository.dart';
import '../models/crop_cycle.dart';
import 'close_cycle_view.dart';
import 'cycle_form_view.dart';

/// Plantilla B: Detalle de Ciclo / Siembra.
class CycleDetailView extends StatelessWidget {
  const CycleDetailView({super.key, required this.cycleId});

  final int cycleId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => CycleDetailController(
        cycleId,
        ctx.read<CycleRepository>(),
        ctx.read<HistoryRepository>(),
        ctx.read<DataChanges>(),
      ),
      child: const _CycleDetailContent(),
    );
  }
}


class _CycleDetailContent extends StatelessWidget {
  const _CycleDetailContent();

  Future<void> _delete(BuildContext context, CycleDetailController controller) async {
    final confirmed = await showConfirmDialog(
      context,
      title: '¿Eliminar esta siembra?',
      message: 'Se borrarán también las aplicaciones, labores y cuentas de este ciclo.',
      confirmLabel: 'Eliminar siembra',
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;
    final ok = await controller.delete();
    if (!context.mounted) return;
    if (ok) {
      AppToast.success(context, 'Siembra eliminada');
      Navigator.of(context).pop();
    } else {
      AppToast.error(context, 'No se pudo eliminar la siembra.');
    }
  }

  Future<void> _changeStage(
    BuildContext context,
    CycleDetailController controller,
    CropCycle cycle,
  ) async {
    CropStage selected = cycle.stage;
    final date = DateTime.now();

    final ok = await showAppSheet<bool>(
      context,
      title: 'Avanzar etapa fenológica',
      builder: (_) => StatefulBuilder(
        builder: (ctx, setState) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Seleccione la nueva fase en la que se encuentra el cultivo:',
                style: ctx.t.body,
              ),
              const SizedBox(height: AppSpace.md),
              Wrap(
                spacing: AppSpace.sm,
                runSpacing: AppSpace.sm,
                children: [
                  for (final st in CropStage.values)
                    ChoiceChip(
                      label: Text(st.label),
                      selected: selected == st,
                      avatar: Icon(st.icon, size: AppSize.iconSm),
                      onSelected: (_) => setState(() => selected = st),
                    ),
                ],
              ),
              const SizedBox(height: AppSpace.xl),
              AppButton.primary(
                label: 'Confirmar cambio de etapa',
                onPressed: () => Navigator.of(ctx).pop(true),
              ),
            ],
          );
        },
      ),
    );

    if (ok == true && context.mounted) {
      await controller.changeStage(selected, date);
      if (context.mounted) {
        AppToast.success(context, 'Etapa actualizada a ${selected.label}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<CycleDetailController>();
    final c = context.c;
    final t = context.t;
    final pad = context.screenPadding;

    return Scaffold(
      appBar: AppTopBar(
        title: 'Detalle de siembra',
        actions: [
          IconButton(
            tooltip: 'Editar datos de siembra',
            icon: const Icon(AppIcons.edit),
            onPressed: () {
              final cycle = controller.state.dataOrNull;
              if (cycle == null) return;
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => CycleFormView(cycleToEdit: cycle),
                ),
              );
            },
          ),
          PopupMenuButton<String>(
            tooltip: 'Más opciones',
            icon: const Icon(AppIcons.menu),
            onSelected: (val) {
              if (val == 'delete') _delete(context, controller);
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(AppIcons.delete, color: c.negative),
                    const SizedBox(width: AppSpace.md),
                    const Text('Eliminar siembra'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: ViewStateBuilder<CropCycle?>(
        state: controller.state,
        onRetry: () => controller.load(),
        builder: (context, cycle) {
          if (cycle == null) {
            return const Center(child: Text('Siembra no encontrada'));
          }

          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(pad, AppSpace.sm, pad, AppSpace.x4),
            child: ContentWidth(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Encabezado
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: ScreenTitle(
                          cycle.title,
                          subtitle: 'Lote: ${cycle.plotName}',
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

                  // Barra de progreso de la campaña
                  AppProgressBar(
                    progress: cycle.estimatedProgress,
                    color: cycle.stage.color(c),
                  ),
                  const SizedBox(height: AppSpace.xl),

                  // Cifras clave
                  MetricRow(
                    children: [
                      MetricCard(
                        label: 'Días de siembra',
                        value: '${cycle.daysSincePlanting}',
                        unit: 'días',
                      ),
                      MetricCard(
                        label: 'Fecha de siembra',
                        value: Formatters.date(cycle.plantingDate),
                      ),
                    ],
                  ),
                  if (cycle.densityDisplay.isNotEmpty) ...[
                    const SizedBox(height: AppSpace.md),
                    AppCard(
                      child: InfoLine(
                        label: 'Densidad de siembra',
                        value: cycle.densityDisplay,
                        icon: AppIcons.grains,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpace.section),

                  // Si el ciclo está cerrado, mostrar los resultados de la cosecha
                  if (cycle.isClosed) ...[
                    const SectionHeader(title: 'Resultados de cosecha y cierre'),
                    AccentCard(
                      accentColor: c.positive,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleIcon(icon: AppIcons.harvest, color: c.positive),
                              const SizedBox(width: AppSpace.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Cosecha finalizada', style: t.titleSm),
                                    Text(
                                      'Rendimiento total: ${cycle.yieldDisplay}',
                                      style: t.displaySm.copyWith(color: c.positive),
                                    ),
                                  ],
                                ),
                              ),
                              if (cycle.quality != null)
                                StatusBadge(
                                  label: cycle.quality!.label,
                                  icon: cycle.quality!.icon,
                                  color: c.positive,
                                ),
                            ],
                          ),
                          if (cycle.whatWorked != null && cycle.whatWorked!.isNotEmpty) ...[
                            const SizedBox(height: AppSpace.md),
                            const Divider(),
                            Text('¿Qué funcionó bien?:', style: t.label),
                            const SizedBox(height: 2),
                            Text(cycle.whatWorked!, style: t.body),
                          ],
                          if (cycle.whatFailed != null && cycle.whatFailed!.isNotEmpty) ...[
                            const SizedBox(height: AppSpace.md),
                            const Divider(),
                            Text('¿Qué falló o debe mejorarse?:', style: t.label),
                            const SizedBox(height: 2),
                            Text(cycle.whatFailed!, style: t.body),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpace.section),
                  ],

                  // Botones de acción del ciclo
                  if (!cycle.isClosed) ...[
                    const SectionHeader(title: 'Acciones de campaña'),
                    Row(
                      children: [
                        Expanded(
                          child: AppButton.secondary(
                            label: 'Avanzar etapa',
                            icon: AppIcons.cycle,
                            onPressed: () => _changeStage(context, controller, cycle),
                          ),
                        ),
                        const SizedBox(width: AppSpace.md),
                        Expanded(
                          child: AppButton.primary(
                            label: 'Cerrar ciclo',
                            icon: AppIcons.harvest,
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => CloseCycleView(cycle: cycle),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpace.section),
                  ],

                  // Acciones rápidas de bitácora
                  const SectionHeader(title: 'Registrar evento en la bitácora'),
                  Wrap(
                    spacing: AppSpace.sm,
                    runSpacing: AppSpace.sm,
                    children: [
                      ActionChip(
                        avatar: const Icon(AppIcons.application, size: AppSize.iconSm),
                        label: const Text('+ Aplicar insumo'),
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => ApplicationFormView(initialCycleId: cycle.id),
                          ),
                        ),
                      ),
                      ActionChip(
                        avatar: const Icon(AppIcons.task, size: AppSize.iconSm),
                        label: const Text('+ Labor cultural'),
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => TaskFormView(initialCycleId: cycle.id),
                          ),
                        ),
                      ),
                      ActionChip(
                        avatar: const Icon(AppIcons.incident, size: AppSize.iconSm),
                        label: const Text('+ Plaga / Clima'),
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => IncidentFormView(initialCycleId: cycle.id),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.section),

                  // Eventos y bitácora de la siembra
                  SectionHeader(
                    title: 'Eventos de esta siembra (${controller.events.length})',
                    actionLabel: controller.events.isNotEmpty ? 'Ver bitácora' : null,
                    onAction: controller.events.isNotEmpty
                        ? () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => CycleTimelineView(cycle: cycle),
                              ),
                            )
                        : null,
                  ),
                  if (controller.events.isEmpty)
                    AppCard(
                      child: Row(
                        children: [
                          CircleIcon(icon: AppIcons.leaf, color: c.inkMuted),
                          const SizedBox(width: AppSpace.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Aún no hay eventos registrados', style: t.titleSm),
                                const SizedBox(height: 2),
                                Text(
                                  'Registre insumos, labores o incidencias con los botones de arriba para consultar el historial aquí mismo.',
                                  style: t.bodySm.copyWith(color: c.inkMuted),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  else ...[
                    // Filtros rápidos dentro de la misma pantalla de siembra
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (final filter in [
                            TimelineEventType.todos,
                            TimelineEventType.insumo,
                            TimelineEventType.labor,
                            TimelineEventType.plaga,
                          ]) ...[
                            Padding(
                              padding: const EdgeInsets.only(right: AppSpace.xs),
                              child: FilterChip(
                                avatar: Icon(filter.icon, size: AppSize.iconBadge),
                                label: Text(
                                  filter == TimelineEventType.todos
                                      ? 'Todos (${controller.events.length})'
                                      : filter == TimelineEventType.insumo
                                          ? 'Insumos (${controller.events.where((e) => e.type == TimelineEventType.insumo).length})'
                                          : filter == TimelineEventType.labor
                                              ? 'Labores (${controller.events.where((e) => e.type == TimelineEventType.labor).length})'
                                              : 'Plagas (${controller.events.where((e) => e.type == TimelineEventType.plaga).length})',
                                ),
                                selected: controller.selectedFilter == filter,
                                onSelected: (_) => controller.setFilter(filter),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpace.md),
                    if (controller.filteredEvents.isEmpty)
                      AppCard(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
                          child: Center(
                            child: Text(
                              'No hay eventos de este tipo en esta siembra',
                              style: t.bodySm.copyWith(color: c.inkMuted),
                            ),
                          ),
                        ),
                      )
                    else
                      for (final eventItem in controller.filteredEvents) ...[
                        _CycleEventCard(item: eventItem),
                        const SizedBox(height: AppSpace.sm),
                      ],
                  ],
                  const SizedBox(height: AppSpace.section),

                  // Cuentas y Finanzas del ciclo
                  const SectionHeader(title: 'Finanzas de la siembra'),
                  AppCard(
                    child: Row(
                      children: [
                        CircleIcon(icon: AppIcons.money, color: c.accent),
                        const SizedBox(width: AppSpace.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Costos y Ventas de este lote', style: t.titleSm),
                              const SizedBox(height: 2),
                              Text('Insumos, jornales, compras y liquidaciones', style: t.bodySm),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpace.sm),
                        FilledButton.tonal(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => CostSummaryView(
                                cycleId: cycle.id,
                                cropTitle: cycle.title,
                              ),
                            ),
                          ),
                          child: const Text('Ver cuentas'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpace.section),

                  // Hitos de etapas
                  if (controller.stageEvents.isNotEmpty) ...[
                    const SectionHeader(title: 'Historial de etapas'),
                    AppCard(
                      child: Column(
                        children: [
                          for (var i = 0; i < controller.stageEvents.length; i++) ...[
                            if (i > 0) const Divider(),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  CircleIcon(
                                    icon: controller.stageEvents[i].stage.icon,
                                    color: controller.stageEvents[i].stage.color(c),
                                  ),
                                  const SizedBox(width: AppSpace.md),
                                  Expanded(
                                    child: Text(
                                      controller.stageEvents[i].stage.label,
                                      style: t.titleSm,
                                    ),
                                  ),
                                  Text(
                                    Formatters.date(controller.stageEvents[i].date),
                                    style: t.label,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
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

class _CycleEventCard extends StatelessWidget {
  const _CycleEventCard({required this.item});

  final UnifiedTimelineItem item;

  Color _getEventColor(AppColors c, TimelineEventType type) => switch (type) {
        TimelineEventType.insumo => c.primary,
        TimelineEventType.labor => c.accentText,
        TimelineEventType.plaga => c.negative,
        TimelineEventType.etapa => c.info,
        TimelineEventType.cosecha => c.positive,
        _ => c.primary,
      };

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final t = context.t;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleIcon(
                icon: item.icon,
                color: _getEventColor(c, item.type),
              ),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: t.titleSm,
                          ),
                        ),
                        Text(
                          Formatters.date(item.date),
                          style: t.caption,
                        ),
                      ],
                    ),
                    if (item.subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(item.subtitle!, style: t.bodySm),
                    ],
                    if (item.badgeText != null) ...[
                      const SizedBox(height: AppSpace.xs),
                      StatusBadge(
                        label: item.badgeText!,
                        icon: AppIcons.check,
                        color: _getEventColor(c, item.type),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (item.notes != null && item.notes!.isNotEmpty) ...[
            const SizedBox(height: AppSpace.sm),
            Text(
              item.notes!,
              style: t.bodySm.copyWith(color: c.ink),
            ),
          ],
          if (item.hasPhotos) ...[
            const SizedBox(height: AppSpace.md),
            Row(
              children: [
                if (item.photoBefore != null)
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpace.sm),
                    child: GestureDetector(
                      onTap: () => PhotoViewerPage.open(
                        context,
                        before: item.photoBefore,
                        after: item.photoAfter,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          PhotoThumb(
                            path: item.photoBefore,
                            size: 56,
                            semanticLabel: 'Foto antes',
                          ),
                          const SizedBox(height: 2),
                          Text('Antes', style: t.caption),
                        ],
                      ),
                    ),
                  ),
                if (item.photoAfter != null)
                  GestureDetector(
                    onTap: () => PhotoViewerPage.open(
                      context,
                      before: item.photoBefore,
                      after: item.photoAfter,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        PhotoThumb(
                          path: item.photoAfter,
                          size: 56,
                          semanticLabel: 'Foto después',
                        ),
                        const SizedBox(height: 2),
                        Text('Después', style: t.caption),
                      ],
                    ),
                  ),
              ],
            ),
          ],
          if (item.application != null &&
              item.application!.needsFollowUp &&
              item.application!.followUpVerdict == null) ...[
            const SizedBox(height: AppSpace.md),
            AppButton.secondary(
              label: 'Evaluar reacción',
              icon: AppIcons.check,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => FollowUpFormView(application: item.application!),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

