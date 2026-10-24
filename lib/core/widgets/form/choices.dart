import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../design/app_colors.dart';
import '../../design/app_icons.dart';
import '../../design/app_tokens.dart';
import '../../design/app_typography.dart';
import '../../utils/choice_option.dart';
import '../../utils/responsive.dart';
import 'fields.dart';

/// Chip seleccionable: alto 40 (zona táctil 48), radio 12.
/// Reposo `surfaceAlt`; seleccionado `primarySoft` + borde `primary` + check.
class AppChip extends StatelessWidget {
  const AppChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.iconColor,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final t = context.t;
    final leading = selected ? AppIcons.check : icon;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpace.xs),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              onTap();
            },
            borderRadius: AppRadius.chip,
            child: AnimatedContainer(
              duration: AppMotion.fast,
              curve: AppMotion.enter,
              constraints: const BoxConstraints(minHeight: AppSize.chip),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.md + 2,
                vertical: AppSpace.sm,
              ),
              decoration: BoxDecoration(
                color: selected ? c.primarySoft : c.surfaceAlt,
                borderRadius: AppRadius.chip,
                border: Border.all(
                  color: selected ? c.primary : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (leading != null) ...[
                    Icon(
                      leading,
                      size: selected ? AppSize.iconBadge : AppSize.iconSm - 2,
                      color: selected ? c.primary : (iconColor ?? c.inkSoft),
                    ),
                    const SizedBox(width: AppSpace.sm - 2),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      style: t.label.copyWith(
                        color: selected ? c.onPrimarySoft : c.ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Envoltura de [FormField] para selectores que no son texto: muestra la
/// etiqueta, el control y el error debajo con icono.
class _ChoiceFieldShell<T> extends StatelessWidget {
  const _ChoiceFieldShell({
    required this.label,
    required this.required,
    required this.value,
    required this.validator,
    required this.helper,
    required this.builder,
  });

  final String? label;
  final bool required;
  final T value;
  final String? Function(T value)? validator;
  final String? helper;
  final Widget Function(void Function() revalidate) builder;

  @override
  Widget build(BuildContext context) {
    return FormField<T>(
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
            if (label != null) FieldLabel(label!, required: required),
            builder(revalidate),
            if (field.hasError)
              FieldError(message: field.errorText ?? '')
            else if (helper != null)
              Padding(
                padding: const EdgeInsets.only(top: AppSpace.xs),
                child: Text(helper!, style: context.t.caption),
              ),
          ],
        );
      },
    );
  }
}

/// Mensaje de error debajo de un control: icono `warning` + texto en `ink`.
class FieldError extends StatelessWidget {
  const FieldError({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpace.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            AppIcons.warning,
            size: AppSize.iconBadge + 2,
            color: c.negative,
          ),
          const SizedBox(width: AppSpace.sm),
          Expanded(
            child: Text(
              message,
              style: context.t.bodySm.copyWith(color: c.ink),
            ),
          ),
        ],
      ),
    );
  }
}

/// Grupo de chips de selección única (cuadrícula que se ajusta en varias
/// líneas en pantallas pequeñas).
class AppChoiceChips<T extends ChoiceOption> extends StatelessWidget {
  const AppChoiceChips({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    this.label,
    this.required = false,
    this.validator,
    this.helper,
    this.allowDeselect = true,
    this.iconColorOf,
  });

  final List<T> options;
  final T? value;
  final ValueChanged<T?> onChanged;
  final String? label;
  final bool required;
  final String? Function(T? value)? validator;
  final String? helper;
  final bool allowDeselect;
  final Color? Function(T option)? iconColorOf;

  @override
  Widget build(BuildContext context) {
    return _ChoiceFieldShell<T?>(
      label: label,
      required: required,
      value: value,
      validator: validator,
      helper: helper,
      builder: (revalidate) => Wrap(
        spacing: AppSpace.sm,
        runSpacing: AppSpace.sm,
        children: [
          for (final option in options)
            AppChip(
              label: option.label,
              icon: option.icon,
              iconColor: iconColorOf?.call(option),
              selected: option == value,
              onTap: () {
                final next = option == value && allowDeselect ? null : option;
                onChanged(next);
                revalidate();
              },
            ),
        ],
      ),
    );
  }
}

/// Chips de selección múltiple.
class AppMultiChoiceChips<T extends ChoiceOption> extends StatelessWidget {
  const AppMultiChoiceChips({
    super.key,
    required this.options,
    required this.values,
    required this.onChanged,
    this.label,
    this.helper,
  });

  final List<T> options;
  final Set<T> values;
  final ValueChanged<Set<T>> onChanged;
  final String? label;
  final String? helper;

  @override
  Widget build(BuildContext context) {
    return _ChoiceFieldShell<Set<T>>(
      label: label,
      required: false,
      value: values,
      validator: null,
      helper: helper,
      builder: (_) => Wrap(
        spacing: AppSpace.sm,
        runSpacing: AppSpace.sm,
        children: [
          for (final option in options)
            AppChip(
              label: option.label,
              icon: option.icon,
              selected: values.contains(option),
              onTap: () {
                final next = {...values};
                if (!next.remove(option)) next.add(option);
                onChanged(next);
              },
            ),
        ],
      ),
    );
  }
}

/// Selector segmentado (2–4 opciones). Contenedor `surfaceAlt`, segmento
/// activo `surface` con borde y sombra nivel 1. En teléfonos angostos el
/// icono va arriba del texto para que la etiqueta quepa sin cortarse.
class AppSegmented<T extends ChoiceOption> extends StatelessWidget {
  const AppSegmented({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    this.label,
    this.required = false,
    this.validator,
    this.helper,
    this.iconColorOf,
  });

  final List<T> options;
  final T? value;
  final ValueChanged<T> onChanged;
  final String? label;
  final bool required;
  final String? Function(T? value)? validator;
  final String? helper;
  final Color? Function(T option)? iconColorOf;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return _ChoiceFieldShell<T?>(
      label: label,
      required: required,
      value: value,
      validator: validator,
      helper: helper,
      builder: (revalidate) => Container(
        padding: const EdgeInsets.all(AppSpace.xs),
        decoration: BoxDecoration(
          color: c.surfaceAlt,
          borderRadius: AppRadius.control,
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final option in options)
                Expanded(
                  child: _Segment(
                    label: option.label,
                    icon: option.icon,
                    iconColor: iconColorOf?.call(option),
                    selected: option == value,
                    stacked: context.isCompact && options.length > 2,
                    onTap: () {
                      onChanged(option);
                      revalidate();
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.selected,
    required this.stacked,
    required this.onTap,
  });

  final String label;
  final IconData? icon;
  final Color? iconColor;
  final bool selected;
  final bool stacked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final t = context.t;
    final text = Text(
      label,
      style: t.label,
      textAlign: TextAlign.center,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
    final iconWidget = icon == null
        ? null
        : Icon(icon, size: AppSize.iconSm, color: iconColor ?? c.inkSoft);

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: AnimatedContainer(
          duration: AppMotion.fast,
          curve: AppMotion.enter,
          constraints: const BoxConstraints(minHeight: AppSize.touch),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.sm,
            vertical: AppSpace.sm,
          ),
          decoration: BoxDecoration(
            color: selected ? c.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.md - 4),
            border: Border.all(
              color: selected ? c.outlineStrong : Colors.transparent,
            ),
            boxShadow: selected ? AppShadow.level1(c.ink) : null,
          ),
          alignment: Alignment.center,
          child: iconWidget == null
              ? text
              : stacked
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    iconWidget,
                    const SizedBox(height: AppSpace.xs),
                    text,
                  ],
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    iconWidget,
                    const SizedBox(width: AppSpace.sm - 2),
                    Flexible(child: text),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Fila horizontal de chips de filtro (plantillas A y D).
class FilterChipsBar<T extends ChoiceOption> extends StatelessWidget {
  const FilterChipsBar({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  final List<T> options;
  final T value;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final pad = context.screenPadding;
    return SizedBox(
      height: AppSize.touch,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: pad),
        itemCount: options.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpace.sm),
        itemBuilder: (context, index) {
          final option = options[index];
          return AppChip(
            label: option.label,
            icon: option.icon,
            selected: option == value,
            onTap: () => onChanged(option),
          );
        },
      ),
    );
  }
}
