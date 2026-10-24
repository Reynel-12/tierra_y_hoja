import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/design/app_colors.dart';
import '../../../core/design/app_icons.dart';
import '../../../core/design/app_tokens.dart';
import '../../../core/design/app_typography.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/badges.dart';
import '../../../core/widgets/layout.dart';
import '../controllers/guided_tour_controller.dart';
import '../models/tour_step_data.dart';
import 'tour_step_simulators.dart';

/// Vista principal del Tour Guiado de la aplicación.
///
/// Presenta los 9 módulos en estricto orden cronológico agrícola,
/// con explicaciones claras, ubicación de cada pantalla, tipos de datos
/// e interactivos simuladores que no alteran la base de datos local.
class GuidedTourView extends StatefulWidget {
  const GuidedTourView({super.key, this.isRevisit = false});

  /// Indica si el usuario está revisando el tour desde la sección de ajustes
  /// o si es su primera vez abriendo la aplicación.
  final bool isRevisit;

  @override
  State<GuidedTourView> createState() => _GuidedTourViewState();
}

class _GuidedTourViewState extends State<GuidedTourView> {
  final ScrollController _scrollController = ScrollController();
  final ScrollController _chipScrollController = ScrollController();

  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Widget _buildStepSimulator(int stepIndex) {
    switch (stepIndex) {
      case 0:
        return const PlotStepSimulator();
      case 1:
        return const CycleStepSimulator();
      case 2:
        return const ApplicationStepSimulator();
      case 3:
        return const FollowUpStepSimulator();
      case 4:
        return const TaskIncidentStepSimulator();
      case 5:
        return const CostSaleStepSimulator();
      case 6:
        return const CloseCycleStepSimulator();
      case 7:
        return const HistoryMemoryStepSimulator();
      case 8:
        return const HomeFabStepSimulator();
      default:
        return const PlotStepSimulator();
    }
  }

  void _onSkipTour(
    BuildContext context,
    GuidedTourController controller,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Saltar el tour guiado?'),
        content: const Text(
          'Podrá comenzar a registrar sus datos inmediatamente. Si desea volver a ver esta guía en cualquier momento, la encontrará en la pestaña "Más".',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Continuar viendo'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Saltar guía'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      if (widget.isRevisit) {
        Navigator.of(context).pop();
      } else {
        await controller.completeTour();
      }
    }
  }

  void _onFinishTour(
    BuildContext context,
    GuidedTourController controller,
  ) async {
    if (widget.isRevisit) {
      Navigator.of(context).pop();
    } else {
      await controller.completeTour();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              '¡Listo! La aplicación está configurada para guardar sus registros reales.',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: context.c.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _chipScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<GuidedTourController>();
    final c = context.c;
    final t = context.t;
    final pad = context.screenPadding;

    final currentStep = controller.currentStep;
    final stepIndex = controller.currentStepIndex;
    final totalSteps = controller.totalSteps;
    final isLastStep = controller.isLastStep;

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppTopBar(
        title: widget.isRevisit ? 'Tour Guiado' : 'Tierra & Hoja',
        showBack: widget.isRevisit,
        actions: [
          if (!widget.isRevisit)
            TextButton.icon(
              icon: const Icon(AppIcons.forward, size: 16),
              label: const Text('Saltar guía'),
              onPressed: () => _onSkipTour(context, controller),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Barra de progreso y pasos
            Container(
              color: c.surface,
              padding: EdgeInsets.symmetric(
                horizontal: pad,
                vertical: AppSpace.sm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Paso ${stepIndex + 1} de $totalSteps',
                        style: t.label.copyWith(
                          color: c.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: AppSpace.sm),
                      Flexible(
                        child: Text(
                          currentStep.tagline,
                          style: t.caption.copyWith(color: c.inkMuted),
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.xs),
                  ClipRRect(
                    borderRadius: AppRadius.pill,
                    child: LinearProgressIndicator(
                      value: (stepIndex + 1) / totalSteps,
                      backgroundColor: c.outline,
                      valueColor: AlwaysStoppedAnimation<Color>(c.primary),
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: AppSpace.sm),

                  // Selector horizontal de pasos para salto rápido
                  SingleChildScrollView(
                    controller: _chipScrollController,
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: List.generate(totalSteps, (index) {
                        final stepData = TourStepData.steps[index];
                        final isSelected = index == stepIndex;
                        return Padding(
                          padding: const EdgeInsets.only(right: AppSpace.xs),
                          child: ChoiceChip(
                            avatar: Icon(
                              stepData.icon,
                              size: 16,
                              color: isSelected ? c.onPrimary : c.inkSoft,
                            ),
                            label: Text(stepData.shortName),
                            selected: isSelected,
                            onSelected: (_) {
                              controller.goToStep(index);
                              _scrollToTop();
                            },
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Contenido dinámico del paso
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: EdgeInsets.fromLTRB(
                  pad,
                  AppSpace.md,
                  pad,
                  AppSpace.x4,
                ),
                child: ContentWidth(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Encabezado del Módulo
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleIcon(
                            icon: currentStep.icon,
                            size: 48,
                            iconSize: 24,
                            color: c.primary,
                          ),
                          const SizedBox(width: AppSpace.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(currentStep.title, style: t.headline),
                                const SizedBox(height: 2),
                                Text(
                                  currentStep.tagline,
                                  style: t.caption.copyWith(
                                    color: c.accentText,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpace.md),

                      // ¿Por qué va en este orden?
                      AppCard(
                        color: c.primarySoft.withValues(alpha: 0.5),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  AppIcons.clock,
                                  size: AppSize.iconSm,
                                  color: c.primary,
                                ),
                                const SizedBox(width: AppSpace.xs),
                                Flexible(
                                  child: Text(
                                    '¿Por qué en este orden?',
                                    style: t.label.copyWith(color: c.primary),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpace.xs),
                            Text(currentStep.whyOrder, style: t.bodySm),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpace.md),

                      // Ubicación y propósito
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  AppIcons.location,
                                  size: AppSize.iconSm,
                                  color: c.primary,
                                ),
                                const SizedBox(width: AppSpace.xs),
                                Flexible(
                                  child: Text(
                                    '¿Dónde se ubica en la aplicación?',
                                    style: t.label,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              currentStep.appLocation,
                              style: t.bodySm.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Divider(height: AppSpace.lg),
                            Row(
                              children: [
                                Icon(
                                  AppIcons.lightbulb,
                                  size: AppSize.iconSm,
                                  color: c.accentText,
                                ),
                                const SizedBox(width: AppSpace.xs),
                                Flexible(
                                  child: Text(
                                    '¿Para qué sirve esta pantalla?',
                                    style: t.label,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(currentStep.screenPurpose, style: t.bodySm),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpace.section),

                      // SIMULADOR INTERACTIVO DEL MÓDULO (Datos de ejemplo)
                      _buildStepSimulator(stepIndex),
                      const SizedBox(height: AppSpace.section),

                      // RESUMEN DE CAMPOS Y TIPOS DE DATOS ACEPTADOS
                      const SectionHeader(
                        title: 'Campos y tipos de datos en esta pantalla',
                      ),
                      AppCard(
                        child: Column(
                          children: [
                            for (
                              int i = 0;
                              i < currentStep.inputsSummary.length;
                              i++
                            ) ...[
                              _InputFieldSummaryRow(
                                info: currentStep.inputsSummary[i],
                              ),
                              if (i < currentStep.inputsSummary.length - 1)
                                const Divider(height: AppSpace.md),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpace.section),

                      // CONSEJO DE CAMPO
                      AppCard(
                        color: c.accentSoft.withValues(alpha: 0.3),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(AppIcons.leaf, size: 24, color: c.accentText),
                            const SizedBox(width: AppSpace.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Consejo de campo',
                                    style: t.label.copyWith(
                                      color: c.accentText,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    currentStep.agriculturalTip,
                                    style: t.bodySm,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpace.section),
                    ],
                  ),
                ),
              ),
            ),

            // Barra inferior fija con botones de navegación
            Container(
              padding: EdgeInsets.fromLTRB(pad, AppSpace.sm, pad, AppSpace.md),
              decoration: BoxDecoration(
                color: c.surface,
                border: Border(top: BorderSide(color: c.outline)),
              ),
              child: ContentWidth(
                child: Row(
                  children: [
                    if (!controller.isFirstStep)
                      Expanded(
                        flex: 1,
                        child: Padding(
                          padding: const EdgeInsets.only(right: AppSpace.sm),
                          child: AppButton.outline(
                            icon: AppIcons.back,
                            label: 'Anterior',
                            onPressed: () {
                              controller.previousStep();
                              _scrollToTop();
                            },
                          ),
                        ),
                      ),
                    Expanded(
                      flex: 2,
                      child: AppButton.primary(
                        icon: isLastStep ? AppIcons.check : AppIcons.forward,
                        label: isLastStep
                            ? '¡Comenzar a registrar!'
                            : 'Siguiente: ${TourStepData.steps[stepIndex + 1].shortName}',
                        onPressed: () {
                          if (isLastStep) {
                            _onFinishTour(context, controller);
                          } else {
                            controller.nextStep();
                            _scrollToTop();
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Fila que describe un campo específico de entrada, su tipo de dato y su función.
class _InputFieldSummaryRow extends StatelessWidget {
  const _InputFieldSummaryRow({required this.info});

  final TourInputFieldInfo info;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final t = context.t;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.only(top: 6),
          decoration: BoxDecoration(
            color: info.isRequired ? c.negative : c.primary,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: AppSpace.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: AppSpace.xs,
                children: [
                  Text(
                    info.name,
                    style: t.label.copyWith(fontWeight: FontWeight.bold),
                  ),
                  if (info.isRequired)
                    Text(
                      '(Obligatorio)',
                      style: t.caption.copyWith(
                        color: c.negative,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: c.surfaceAlt,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Tipo: ${info.dataType}',
                  style: t.caption.copyWith(
                    color: c.inkSoft,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(info.description, style: t.bodySm),
            ],
          ),
        ),
      ],
    );
  }
}
