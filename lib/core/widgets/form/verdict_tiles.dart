import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../design/app_colors.dart';
import '../../design/app_icons.dart';
import '../../design/app_tokens.dart';
import '../../design/app_typography.dart';
import '../../utils/choice_option.dart';
import 'choices.dart';
import 'fields.dart';

/// Veredicto de reacción post-aplicación (reemplaza los emojis).
enum ReactionVerdict implements ChoiceOption {
  positive('Positiva', AppIcons.checkCircle),
  neutral('Sin cambio', AppIcons.minusCircle),
  negative('Negativa', AppIcons.warning);

  const ReactionVerdict(this.label, this.icon);

  @override
  final String label;

  @override
  final IconData icon;
}

/// Tiles de veredicto (Positiva / Sin cambio / Negativa) — Diseño §7.5
///
/// Tres tiles iguales en una fila, alto 104, radio rMd (16), separación 12.
/// - Reposo: `surface`, borde 1.5 `outlineStrong`, icono 32 (color semántico), etiqueta `label` debajo.
/// - Seleccionado: fondo = color suave semántico, borde 2.5 en color semántico, check pequeño arriba a la derecha, háptico.
/// - Negativa seleccionada despliega debajo el campo "¿Qué síntomas observó?" con chips rápidos y nota de voz.
class VerdictTiles extends StatelessWidget {
  const VerdictTiles({
    super.key,
    required this.value,
    required this.onChanged,
    this.symptomsController,
    this.selectedSymptoms = const {},
    this.onSymptomsChanged,
    this.required = false,
    this.validator,
  });

  final ReactionVerdict? value;
  final ValueChanged<ReactionVerdict?> onChanged;
  final TextEditingController? symptomsController;
  final Set<String> selectedSymptoms;
  final ValueChanged<Set<String>>? onSymptomsChanged;
  final bool required;
  final String? Function(ReactionVerdict?)? validator;

  static const defaultSymptoms = [
    'Hoja quemada',
    'Amarillamiento',
    'Marchitez',
    'Caída de flor',
    'Manchas foliares',
    'Detención de crecimiento',
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return FormField<ReactionVerdict>(
      validator: validator == null ? null : (_) => validator!(value),
      builder: (field) {
        void revalidate() {
          if (!field.hasError) return;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (field.mounted) field.validate();
          });
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            FieldLabel('Veredicto de reacción', required: required),
            Row(
              children: [
                Expanded(
                  child: _VerdictTile(
                    verdict: ReactionVerdict.positive,
                    label: 'Positiva',
                    icon: AppIcons.checkCircle,
                    color: c.positive,
                    softColor: c.positiveSoft,
                    isSelected: value == ReactionVerdict.positive,
                    onTap: () {
                      onChanged(value == ReactionVerdict.positive ? null : ReactionVerdict.positive);
                      revalidate();
                    },
                  ),
                ),
                const SizedBox(width: AppSpace.md),
                Expanded(
                  child: _VerdictTile(
                    verdict: ReactionVerdict.neutral,
                    label: 'Sin cambio',
                    icon: AppIcons.minusCircle,
                    color: c.neutral,
                    softColor: c.neutralSoft,
                    isSelected: value == ReactionVerdict.neutral,
                    onTap: () {
                      onChanged(value == ReactionVerdict.neutral ? null : ReactionVerdict.neutral);
                      revalidate();
                    },
                  ),
                ),
                const SizedBox(width: AppSpace.md),
                Expanded(
                  child: _VerdictTile(
                    verdict: ReactionVerdict.negative,
                    label: 'Negativa',
                    icon: AppIcons.warning,
                    color: c.negative,
                    softColor: c.negativeSoft,
                    isSelected: value == ReactionVerdict.negative,
                    onTap: () {
                      onChanged(value == ReactionVerdict.negative ? null : ReactionVerdict.negative);
                      revalidate();
                    },
                  ),
                ),
              ],
            ),
            if (field.hasError) FieldError(message: field.errorText ?? ''),

            // Sección de síntomas si el veredicto es negativo
            AnimatedSize(
              duration: AppMotion.base,
              curve: AppMotion.enter,
              child: value == ReactionVerdict.negative
                  ? Padding(
                      padding: const EdgeInsets.only(top: AppSpace.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const FieldLabel('¿Qué síntomas observó?'),
                          if (onSymptomsChanged != null)
                            Wrap(
                              spacing: AppSpace.sm,
                              runSpacing: AppSpace.xs,
                              children: [
                                for (final symptom in defaultSymptoms)
                                  AppChip(
                                    label: symptom,
                                    selected: selectedSymptoms.contains(symptom),
                                    onTap: () {
                                      final updated = {...selectedSymptoms};
                                      if (updated.contains(symptom)) {
                                        updated.remove(symptom);
                                      } else {
                                        updated.add(symptom);
                                      }
                                      onSymptomsChanged!(updated);
                                    },
                                  ),
                              ],
                            ),
                          if (symptomsController != null) ...[
                            const SizedBox(height: AppSpace.md),
                            AppTextField.notes(
                              label: 'Detalle o notas de fitotoxicidad',
                              controller: symptomsController!,
                              hint: 'Describa el daño o síntomas observados en la planta...',
                            ),
                          ],
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        );
      },
    );
  }
}

class _VerdictTile extends StatelessWidget {
  const _VerdictTile({
    required this.verdict,
    required this.label,
    required this.icon,
    required this.color,
    required this.softColor,
    required this.isSelected,
    required this.onTap,
  });

  final ReactionVerdict verdict;
  final String label;
  final IconData icon;
  final Color color;
  final Color softColor;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final t = context.t;

    return Semantics(
      button: true,
      selected: isSelected,
      label: 'Veredicto $label',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          borderRadius: AppRadius.control,
          child: AnimatedContainer(
            duration: AppMotion.fast,
            curve: AppMotion.enter,
            height: AppSize.verdictTile,
            decoration: BoxDecoration(
              color: isSelected ? softColor : c.surface,
              borderRadius: AppRadius.control,
              border: Border.all(
                color: isSelected ? color : c.outlineStrong,
                width: isSelected ? 2.5 : 1.5,
              ),
              boxShadow: AppShadow.level1(c.ink),
            ),
            child: Stack(
              children: [
                if (isSelected)
                  Positioned(
                    top: AppSpace.xs + 2,
                    right: AppSpace.xs + 2,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        AppIcons.check,
                        size: 12,
                        color: c.paper,
                      ),
                    ),
                  ),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpace.xs),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(icon, size: AppSize.iconLg, color: color),
                        const SizedBox(height: AppSpace.sm),
                        Text(
                          label,
                          style: t.label.copyWith(
                            color: c.ink,
                            fontSize: 13,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
