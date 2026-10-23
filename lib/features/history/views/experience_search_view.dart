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
import '../../../core/widgets/feedback_states.dart';
import '../../../core/widgets/form/fields.dart';
import '../../../core/widgets/media/photo_widgets.dart';
import '../controllers/history_controllers.dart';
import '../data/history_repository.dart';
import '../models/experience_models.dart';

/// Plantilla A con búsqueda: Memoria Agrícola y Búsqueda de Experiencias Previas.
class ExperienceSearchView extends StatelessWidget {
  const ExperienceSearchView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => ExperienceSearchController(ctx.read<HistoryRepository>()),
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ExperienceSearchController>();
    final pad = context.screenPadding;

    return Scaffold(
      appBar: const AppTopBar(
        title: 'Memoria y Experiencias',
      ),
      body: Column(
        children: [
          // Barra de búsqueda con 4 sugerencias rápidas
          Padding(
            padding: EdgeInsets.fromLTRB(pad, AppSpace.sm, pad, AppSpace.xs),
            child: AppSearchField(
              controller: _searchController,
              hint: 'Buscar insumo, plaga, cultivo o abono...',
              onChanged: (query) => controller.search(query),
            ),
          ),

          // Chips de búsqueda rápida sugerida
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

          // Resultados
          Expanded(
            child: controller.isLoading
                ? const SkeletonList(count: 4, itemHeight: 120)
                : controller.currentQuery.isEmpty
                    ? const EmptyState(
                        icon: AppIcons.search,
                        title: 'Consulte su historial agrícola',
                        message: 'Escriba el nombre de un insumo, fertilizante o plaga para ver qué dosis usó antes y qué resultado le dio.',
                      )
                    : controller.results.isEmpty
                        ? EmptyState(
                            icon: AppIcons.leaf,
                            title: 'Sin experiencias previas',
                            message: 'No se encontraron registros de "${controller.currentQuery}". A medida que registre aplicaciones y cosechas, esta memoria crecerá.',
                          )
                        : ListView.separated(
                            padding: EdgeInsets.fromLTRB(pad, AppSpace.md, pad, AppSpace.x4),
                            itemCount: controller.results.length,
                            separatorBuilder: (_, _) => const SizedBox(height: AppSpace.listGap),
                            itemBuilder: (context, index) {
                              final item = controller.results[index];
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleIcon(
            icon: AppIcons.leaf,
            color: c.primary,
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
                    color: c.positive,
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
