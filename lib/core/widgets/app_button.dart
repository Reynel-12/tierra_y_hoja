import 'package:flutter/material.dart';

import '../design/app_colors.dart';
import '../design/app_tokens.dart';
import '../design/app_typography.dart';

enum AppButtonVariant { primary, secondary, outline, text, destructive }

/// Botón del sistema de diseño (§7.1). Alto 56 (texto: 48), radio 16,
/// icono opcional de 20 a la izquierda y estado "cargando" que conserva el ancho.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = AppButtonVariant.primary,
    this.loading = false,
    this.expand = true,
  });

  const AppButton.primary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.expand = true,
  }) : variant = AppButtonVariant.primary;

  const AppButton.secondary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.expand = true,
  }) : variant = AppButtonVariant.secondary;

  const AppButton.outline({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.expand = true,
  }) : variant = AppButtonVariant.outline;

  const AppButton.text({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.expand = false,
  }) : variant = AppButtonVariant.text;

  const AppButton.ghost({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.expand = true,
  }) : variant = AppButtonVariant.text;

  const AppButton.destructive({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.expand = true,
  }) : variant = AppButtonVariant.destructive;

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final AppButtonVariant variant;
  final bool loading;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final t = context.t;
    final height = variant == AppButtonVariant.text
        ? AppSize.touch
        : AppSize.primaryAction;
    final action = loading ? null : onPressed;

    final foreground = switch (variant) {
      AppButtonVariant.primary => c.onPrimary,
      AppButtonVariant.secondary => c.onPrimarySoft,
      AppButtonVariant.outline => c.ink,
      AppButtonVariant.text => c.primary,
      AppButtonVariant.destructive => c.paper,
    };

    final content = _ButtonContent(
      label: label,
      icon: icon,
      loading: loading,
      color: foreground,
    );

    final textStyle = variant == AppButtonVariant.text
        ? t.label
        : t.label.copyWith(fontSize: 16);

    final minimumSize = Size(AppSize.touch, height);

    final button = switch (variant) {
      AppButtonVariant.primary => FilledButton(
        onPressed: action,
        style: FilledButton.styleFrom(
          minimumSize: minimumSize,
          textStyle: textStyle,
        ),
        child: content,
      ),
      AppButtonVariant.secondary => FilledButton(
        onPressed: action,
        style: FilledButton.styleFrom(
          minimumSize: minimumSize,
          backgroundColor: c.primarySoft,
          foregroundColor: c.onPrimarySoft,
          disabledBackgroundColor: c.primarySoft.withValues(alpha: 0.38),
          disabledForegroundColor: c.onPrimarySoft.withValues(alpha: 0.38),
          textStyle: textStyle,
        ),
        child: content,
      ),
      AppButtonVariant.outline => OutlinedButton(
        onPressed: action,
        style: OutlinedButton.styleFrom(
          minimumSize: minimumSize,
          textStyle: textStyle,
        ),
        child: content,
      ),
      AppButtonVariant.text => TextButton(
        onPressed: action,
        style: TextButton.styleFrom(
          minimumSize: minimumSize,
          textStyle: textStyle,
        ),
        child: content,
      ),
      AppButtonVariant.destructive => FilledButton(
        onPressed: action,
        style: FilledButton.styleFrom(
          minimumSize: minimumSize,
          backgroundColor: c.negative,
          foregroundColor: c.paper,
          disabledBackgroundColor: c.negative.withValues(alpha: 0.38),
          textStyle: textStyle,
        ),
        child: content,
      ),
    };

    if (expand) {
      return SizedBox(width: double.infinity, child: button);
    }

    return button;
  }
}

class _ButtonContent extends StatelessWidget {
  const _ButtonContent({
    required this.label,
    required this.icon,
    required this.loading,
    required this.color,
  });

  final String label;
  final IconData? icon;
  final bool loading;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final leading = loading
        ? SizedBox.square(
            dimension: AppSize.iconSm,
            child: CircularProgressIndicator(strokeWidth: 2, color: color),
          )
        : (icon == null ? null : Icon(icon, size: AppSize.iconSm));

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (leading != null) ...[leading, const SizedBox(width: AppSpace.sm)],
        Flexible(
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
