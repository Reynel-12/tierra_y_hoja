import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/design/app_colors.dart';
import '../../../core/design/app_icons.dart';
import '../../../core/design/app_tokens.dart';
import '../../../core/design/app_typography.dart';
import '../../../core/state/theme_controller.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/badges.dart';
import '../../../core/widgets/layout.dart';
import '../../costs/views/cost_summary_view.dart';
import '../../history/views/cycle_comparison_view.dart';
import '../../history/views/experience_search_view.dart';
import '../../tour/views/guided_tour_view.dart';

/// Pantilla B / Configuración: Menú de Más Opciones y Preferencias.
class MoreView extends StatelessWidget {
  const MoreView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final t = context.t;
    final pad = context.screenPadding;
    final themeController = context.watch<ThemeController>();

    return Scaffold(
      appBar: const AppTopBar(
        title: 'Más opciones',
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(pad, AppSpace.sm, pad, AppSpace.x4),
        child: ContentWidth(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const ScreenTitle(
                'Herramientas y Ajustes',
                subtitle: 'Finanzas, aprendizajes e información offline',
              ),
              const SizedBox(height: AppSpace.xl),

              // Herramientas analíticas
              const SectionHeader(title: 'Análisis y Memoria'),
              AppCard(
                child: Column(
                  children: [
                    ListRow(
                      icon: AppIcons.money,
                      title: 'Costos y Finanzas Globales',
                      subtitle: 'Balance consolidado de insumos, jornales y ventas',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const CostSummaryView(),
                        ),
                      ),
                    ),
                    const Divider(),
                    ListRow(
                      icon: AppIcons.search,
                      title: 'Memoria y Experiencias Previas',
                      subtitle: 'Consulte insumos usados antes, dosis y resultados',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const ExperienceSearchView(),
                        ),
                      ),
                    ),
                    const Divider(),
                    ListRow(
                      icon: AppIcons.scales,
                      title: 'Comparador de Siembras',
                      subtitle: 'Compare rendimientos y costos de 2 ciclos lado a lado',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const CycleComparisonView(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpace.section),

              // Guía y Aprendizaje
              const SectionHeader(title: 'Guía y Aprendizaje'),
              AppCard(
                child: Column(
                  children: [
                    ListRow(
                      icon: AppIcons.book,
                      title: 'Tour Guiado de la Aplicación',
                      subtitle: 'Repase el orden correcto de registro y el uso de cada pantalla',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const GuidedTourView(isRevisit: true),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpace.section),

              // Apariencia y Tema
              const SectionHeader(title: 'Apariencia visual'),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tema de la aplicación', style: t.titleSm),
                    const SizedBox(height: AppSpace.xs),
                    Text(
                      'Optimizado con tonos tierra cálidos para alta visibilidad bajo el sol y modo oscuro para la noche.',
                      style: t.bodySm,
                    ),
                    const SizedBox(height: AppSpace.md),
                    Wrap(
                      spacing: AppSpace.sm,
                      children: [
                        ChoiceChip(
                          label: const Text('Sistema'),
                          selected: themeController.themeMode == ThemeMode.system,
                          onSelected: (_) => themeController.setThemeMode(ThemeMode.system),
                        ),
                        ChoiceChip(
                          avatar: const Icon(AppIcons.sun, size: AppSize.iconSm),
                          label: const Text('Claro (Sol)'),
                          selected: themeController.themeMode == ThemeMode.light,
                          onSelected: (_) => themeController.setThemeMode(ThemeMode.light),
                        ),
                        ChoiceChip(
                          avatar: const Icon(AppIcons.moon, size: AppSize.iconSm),
                          label: const Text('Oscuro (Noche)'),
                          selected: themeController.themeMode == ThemeMode.dark,
                          onSelected: (_) => themeController.setThemeMode(ThemeMode.dark),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpace.section),

              // Información del Sistema 100% Offline
              const SectionHeader(title: 'Garantía 100% Offline'),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleIcon(icon: AppIcons.leaf, color: c.primary),
                        const SizedBox(width: AppSpace.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Tierra & Hoja', style: t.titleSm),
                              Text('Versión 1.1.0 · Cuaderno de Campo', style: t.caption),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpace.md),
                    Text(
                      'Esta aplicación funciona de forma totalmente autónoma. Su base de datos SQLite y sus fotografías se guardan localmente en su teléfono, permitiendo trabajar en zonas sin señal de internet ni cobertura celular.',
                      style: t.bodySm,
                    ),
                    const SizedBox(height: AppSpace.md),
                    Row(
                      children: [
                        Icon(AppIcons.checkCircle, size: AppSize.iconSm, color: c.positive),
                        const SizedBox(width: AppSpace.xs),
                        Text('Base de datos SQLite local', style: t.label),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(AppIcons.checkCircle, size: AppSize.iconSm, color: c.positive),
                        const SizedBox(width: AppSpace.xs),
                        Text('Fotos respaldadas en la galería', style: t.label),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
