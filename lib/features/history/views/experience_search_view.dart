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
import '../../../core/widgets/form/fields.dart';
import '../../../core/widgets/media/photo_widgets.dart';
import '../../cycles/views/cycle_detail_view.dart';
import '../controllers/history_controllers.dart';
import '../data/history_repository.dart';
import '../models/experience_models.dart';

/// Plantilla A con búsqueda: Memoria Agrícola y Búsqueda de Experiencias Previas.
class ExperienceSearchView extends StatelessWidget {
  const ExperienceSearchView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => ExperienceSearchController(
        ctx.read<HistoryRepository>(),
        ctx.read<DataChanges>(),
      ),
      child: const _ExperienceSearchContent(),
    );
  }
}

class _ExperienceSearchContent extends StatefulWidget {
  const _ExperienceSearchContent();

  @override
  State<_ExperienceSearchContent> createState() => _ExperienceSearchContentState();
}

class _ExperienceSearchContentState extends State<_ExperienceSearchContent> {
  final _searchController = TextEditingController();

  static const _filters = [
    TimelineEventType.todos,
    TimelineEventType.insumo,
    TimelineEventType.labor,
    TimelineEventType.plaga,
    TimelineEventType.cosecha,
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ExperienceSearchController>();
    final c = context.c;
    final t = context.t;
    final pad = context.screenPadding;

    return Scaffold(
      appBar: const AppTopBar(
        title: 'Memoria y Experiencias',
      ),
      body: Column(
        children: [
          // Barra de búsqueda de la memoria
          Padding(
            padding: EdgeInsets.fromLTRB(pad, AppSpace.sm, pad, AppSpace.xs),
            child: AppSearchField(
              controller: _searchController,
              hint: 'Buscar insumo, labor, plaga o cultivo...',
              onChanged: (query) => controller.search(query),
            ),
          ),

          // Chips de categorías / Filtros: Todos, Insumos, Labores, Plagas, Cosechas
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: pad, vertical: AppSpace.xs),
            child: Row(
              children: [
                for (final filter in _filters) ...[
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpace.xs),
                    child: FilterChip(
                      avatar: Icon(filter.icon, size: AppSize.iconBadge),
                      label: Text(
                        filter == TimelineEventType.todos
                            ? 'Todos'
                            : filter == TimelineEventType.insumo
                                ? 'Insumos'
                                : filter == TimelineEventType.labor
                                    ? 'Labores'
                                    : filter == TimelineEventType.plaga
                                        ? 'Plagas / Clima'
                                        : 'Cosechas',
                      ),
                      selected: controller.selectedFilter == filter,
                      onSelected: (_) => controller.setFilter(filter),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Sugerencias de búsqueda rápida cuando se consulta
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: pad, vertical: AppSpace.xs),
            child: Row(
              children: [
                _SuggestionChip(
                  label: 'Urea',
                  onTap: () => _applyQuery('Urea', controller),
                ),
                _SuggestionChip(
                  label: 'Foliar',
                  onTap: () => _applyQuery('Foliar', controller),
                ),
                _SuggestionChip(
                  label: 'Gusano',
                  onTap: () => _applyQuery('Gusano', controller),
                ),
                _SuggestionChip(
                  label: 'Roya',
                  onTap: () => _applyQuery('Roya', controller),
                ),
                _SuggestionChip(
                  label: 'Tomate',
                  onTap: () => _applyQuery('Tomate', controller),
                ),
                _SuggestionChip(
                  label: 'Maíz',
                  onTap: () => _applyQuery('Maíz', controller),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Resultados paginados
          Expanded(
            child: controller.isLoading
                ? const SkeletonList(count: 4, itemHeight: 120)
                : controller.items.isEmpty
                    ? EmptyState(
                        icon: controller.currentQuery.isNotEmpty ? AppIcons.search : AppIcons.leaf,
                        title: controller.currentQuery.isNotEmpty ? 'Sin resultados' : 'Sin eventos registrados',
                        message: controller.currentQuery.isNotEmpty
                            ? 'No se encontraron registros para "${controller.currentQuery}".'
                            : 'No hay eventos en la categoría seleccionada. A medida que registre aplicaciones, labores o cosechas, aparecerán aquí.',
                      )
                    : ListView.separated(
                        padding: EdgeInsets.fromLTRB(pad, AppSpace.md, pad, AppSpace.x4),
                        itemCount: controller.items.length + 1,
                        separatorBuilder: (_, index) {
                          if (index == controller.items.length - 1) {
                            return const SizedBox(height: AppSpace.md);
                          }
                          return const SizedBox(height: AppSpace.listGap);
                        },
                        itemBuilder: (context, index) {
                          // Fila de paginación al final de la lista
                          if (index == controller.items.length) {
                            if (controller.hasMore) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: AppSpace.md),
                                child: controller.isLoadingMore
                                    ? const Center(
                                        child: Padding(
                                          padding: EdgeInsets.all(AppSpace.md),
                                          child: CircularProgressIndicator(),
                                        ),
                                      )
                                    : Center(
                                        child: AppButton.secondary(
                                          label: 'Cargar más datos',
                                          icon: AppIcons.history,
                                          onPressed: () => controller.loadMore(),
                                        ),
                                      ),
                              );
                            } else {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: AppSpace.md),
                                child: Center(
                                  child: Text(
                                    'Se mostraron todos los registros (${controller.totalCount})',
                                    style: t.caption.copyWith(color: c.inkMuted),
                                  ),
                                ),
                              );
                            }
                          }

                          final item = controller.items[index];
                          return _LearningCard(item: item);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  void _applyQuery(String term, ExperienceSearchController controller) {
    _searchController.text = term;
    controller.search(term);
  }
}

class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpace.xs),
      child: ActionChip(
        label: Text(label),
        onPressed: onTap,
      ),
    );
  }
}

class _LearningCard extends StatelessWidget {
  const _LearningCard({required this.item});

  final LearningResult item;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final t = context.t;

    return AppCard(
      onTap: item.cycleId != null
          ? () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => CycleDetailView(cycleId: item.cycleId!),
                ),
              )
          : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleIcon(
            icon: item.icon,
            color: item.color(c),
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
                const SizedBox(height: 2),
                Text(
                  '${item.crop} · Lote: ${item.plotName}',
                  style: t.bodySm.copyWith(color: c.inkMuted),
                ),
                if (item.verdict != null) ...[
                  const SizedBox(height: AppSpace.xs),
                  StatusBadge(
                    label: item.verdict!,
                    icon: AppIcons.checkCircle,
                    color: item.color(c),
                  ),
                ],
                if (item.observation != null && item.observation!.isNotEmpty) ...[
                  const SizedBox(height: AppSpace.xs),
                  Text(
                    item.observation!,
                    style: t.bodySm,
                  ),
                ],
              ],
            ),
          ),
          if (item.photoPath != null) ...[
            const SizedBox(width: AppSpace.sm),
            GestureDetector(
              onTap: () => PhotoViewerPage.open(context, before: item.photoPath),
              child: PhotoThumb(
                path: item.photoPath,
                size: 54,
                semanticLabel: 'Foto del resultado',
              ),
            ),
          ],
        ],
      ),
    );
  }
}

