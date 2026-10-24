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
import '../../../core/widgets/media/photo_widgets.dart';
import '../../../core/widgets/timeline.dart';
import '../../cycles/models/crop_cycle.dart';
import '../../field_log/views/follow_up_form_view.dart';
import '../controllers/history_controllers.dart';
import '../data/history_repository.dart';
import '../models/experience_models.dart';
import 'export_sheet.dart';

/// Plantilla D: Línea de Tiempo y Bitácora Cronológica del Cultivo.
class CycleTimelineView extends StatelessWidget {
  const CycleTimelineView({super.key, required this.cycle});

  final CropCycle cycle;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => CycleTimelineController(
        cycle.id!,
        ctx.read<HistoryRepository>(),
        ctx.read<DataChanges>(),
      ),
      child: _CycleTimelineContent(cycle: cycle),
    );
  }
}

class _CycleTimelineContent extends StatelessWidget {
  const _CycleTimelineContent({required this.cycle});

  final CropCycle cycle;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<CycleTimelineController>();
    final c = context.c;
    final pad = context.screenPadding;

    return Scaffold(
      appBar: AppTopBar(
        title: 'Bitácora: ${cycle.title}',
        actions: [
          IconButton(
            tooltip: 'Exportar bitácora en PDF',
            icon: const Icon(AppIcons.export),
            onPressed: () => ExportSheet.show(context, cycle),
          ),
        ],
      ),
      body: ViewStateBuilder<List<UnifiedTimelineItem>>(
        state: controller.state,
        onRetry: () => controller.load(),
        builder: (context, allItems) {
          final items = controller.filterList(allItems);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Barra de filtros por tipo de evento
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: pad, vertical: AppSpace.sm),
                child: Row(
                  children: [
                    for (final filter in TimelineEventType.values) ...[
                      Padding(
                        padding: const EdgeInsets.only(right: AppSpace.sm),
                        child: FilterChip(
                          avatar: Icon(filter.icon, size: AppSize.iconBadge),
                          label: Text(filter.label),
                          selected: controller.selectedFilter == filter,
                          onSelected: (_) => controller.setFilter(filter),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Divider(height: 1),

              // Contenido de la línea de tiempo
              Expanded(
                child: items.isEmpty
                    ? const EmptyState(
                        icon: AppIcons.leaf,
                        title: 'Sin eventos en este filtro',
                        message: 'No se encontraron aplicaciones o labores que coincidan con el filtro seleccionado.',
                      )
                    : ListView.builder(
                        padding: EdgeInsets.fromLTRB(pad, AppSpace.md, pad, AppSpace.x4),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          final isFirst = index == 0;
                          final isLast = index == items.length - 1;

                          // Verificamos si es cambio de semana respecto al anterior para poner encabezado
                          final showWeekHeader = _shouldShowWeekHeader(items, index, cycle.plantingDate);

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (showWeekHeader != null)
                                TimelineGroupHeader(label: showWeekHeader),
                              TimelineItem(
                                icon: item.icon,
                                isFirst: isFirst && showWeekHeader == null,
                                isLast: isLast,
                                nodeColor: _getNodeColor(c, item.type),
                                iconColor: _getIconColor(c, item.type),
                                child: _TimelineCard(item: item),
                              ),
                            ],
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

  String? _shouldShowWeekHeader(List<UnifiedTimelineItem> items, int index, DateTime plantingDate) {
    final currentItem = items[index];
    final currentWeek = (currentItem.date.difference(plantingDate).inDays / 7).floor() + 1;
    final weekNum = currentWeek <= 0 ? 1 : currentWeek;

    if (index == 0) {
      return 'Semana $weekNum · Día ${DateUtilsX.dayNumber(plantingDate, at: currentItem.date)}';
    }

    final prevItem = items[index - 1];
    final prevWeek = (prevItem.date.difference(plantingDate).inDays / 7).floor() + 1;
    if (currentWeek != prevWeek) {
      return 'Semana $weekNum · Día ${DateUtilsX.dayNumber(plantingDate, at: currentItem.date)}';
    }

    return null;
  }

  Color _getNodeColor(AppColors c, TimelineEventType type) => switch (type) {
        TimelineEventType.insumo => c.primarySoft,
        TimelineEventType.labor => c.secondarySoft,
        TimelineEventType.plaga => c.negativeSoft,
        TimelineEventType.etapa => c.accentSoft,
        TimelineEventType.cosecha => c.positiveSoft,
        _ => c.surfaceRaised,
      };

  Color _getIconColor(AppColors c, TimelineEventType type) => switch (type) {
        TimelineEventType.insumo => c.onPrimarySoft,
        TimelineEventType.labor => c.onSecondarySoft,
        TimelineEventType.plaga => c.onNegativeSoft,
        TimelineEventType.etapa => c.onAccentSoft,
        TimelineEventType.cosecha => c.onPositiveSoft,
        _ => c.ink,
      };
}


class _TimelineCard extends StatelessWidget {
  const _TimelineCard({required this.item});

  final UnifiedTimelineItem item;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final t = context.t;

    return AppCard(
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
          if (item.notes != null && item.notes!.isNotEmpty) ...[
            const SizedBox(height: AppSpace.xs),
            Text(
              item.notes!,
              style: t.caption.copyWith(color: c.ink),
            ),
          ],
          if (item.badgeText != null) ...[
            const SizedBox(height: AppSpace.sm),
            StatusBadge(
              label: item.badgeText!,
              icon: AppIcons.check,
              color: c.positive,
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
                            size: 64,
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
                          size: 64,
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
          // Si es una aplicación que requiere seguimiento y aún no lo tiene:
          if (item.application != null &&
              item.application!.needsFollowUp &&
              item.application!.followUpVerdict == null) ...[
            const SizedBox(height: AppSpace.md),
            AppButton.secondary(
              label: 'Registrar seguimiento',
              icon: AppIcons.clock,
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
