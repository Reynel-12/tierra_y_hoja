import 'package:flutter/material.dart';

import '../design/app_colors.dart';
import '../design/app_icons.dart';
import '../design/app_tokens.dart';
import '../design/app_typography.dart';
import '../utils/responsive.dart';

/// Encabezado de sección en `overline` (mayúsculas) con acción opcional.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: SizedBox(
        height: AppSize.touch,
        child: Row(
          children: [
            Expanded(
              child: Text(
                title.toUpperCase(),
                style: context.t.overline,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (actionLabel != null && onAction != null)
              TextButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ),
      ),
    );
  }
}

/// Barra de acción fija inferior: `surface`, nivel 2, padding 16, safe area.
class BottomActionBar extends StatelessWidget {
  const BottomActionBar({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(top: BorderSide(color: c.outline)),
        boxShadow: AppShadow.level2(c.ink),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.lg),
          child: Center(
            heightFactor: 1.0,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: AppSize.maxFormWidth),
              child: SizedBox(
                width: double.infinity,
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Fila de lista plana (ajustes, opciones): alto mínimo 64 y divisor con sangría.
class ListRow extends StatelessWidget {
  const ListRow({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.trailing,
    this.onTap,
    this.showDivider = true,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final t = context.t;
    final pad = context.screenPadding;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 64),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: pad,
                vertical: AppSpace.md,
              ),
              child: Row(
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: c.inkSoft),
                    const SizedBox(width: AppSpace.lg),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(title, style: t.body),
                        if (subtitle != null)
                          Text(subtitle!, style: t.bodySm),
                      ],
                    ),
                  ),
                  trailing ??
                      (onTap != null
                          ? Icon(AppIcons.forward,
                              size: AppSize.iconSm, color: c.inkMuted)
                          : const SizedBox.shrink()),
                ],
              ),
            ),
          ),
        ),
        if (showDivider) Divider(indent: pad, height: 1),
      ],
    );
  }
}

/// Barra de progreso fina (4 px) con texto opcional, p. ej. "Día 32".
class AppProgressBar extends StatelessWidget {
  const AppProgressBar({
    super.key,
    double? value,
    double? progress,
    this.label,
    this.color,
  }) : value = (value ?? progress ?? 0.0);

  final double value;
  final String? label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: AppRadius.pill,
            child: LinearProgressIndicator(
              value: value.clamp(0, 1),
              minHeight: AppSize.progressBar,
              backgroundColor: c.surfaceAlt,
              color: color ?? c.primary,
            ),
          ),
        ),
        if (label != null) ...[
          const SizedBox(width: AppSpace.md),
          Text(label!, style: context.t.caption),
        ],
      ],
    );
  }
}

/// Entrada escalonada (40 ms por elemento) solo en la primera aparición.
/// Respeta "reducir movimiento" (sin desplazamiento).
class StaggeredEntry extends StatelessWidget {
  const StaggeredEntry({super.key, required this.index, required this.child});

  final int index;
  final Widget child;

  static const _maxAnimated = 8;

  @override
  Widget build(BuildContext context) {
    if (index >= _maxAnimated || AppMotion.reduced(context)) return child;
    final duration = AppMotion.base + AppMotion.stagger * index;
    final start = (AppMotion.stagger * index).inMilliseconds /
        duration.inMilliseconds;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: duration,
      curve: Interval(start, 1, curve: AppMotion.enter),
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, (1 - value) * 12),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

/// Título de pantalla en `headline` dentro del cuerpo (permite varias líneas).
class ScreenTitle extends StatelessWidget {
  const ScreenTitle(this.title, {super.key, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Semantics(
      header: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: t.headline),
          if (subtitle != null) ...[
            const SizedBox(height: AppSpace.xs),
            Text(subtitle!, style: t.bodySm),
          ],
        ],
      ),
    );
  }
}

/// Par etiqueta/valor para fichas de detalle.
class InfoLine extends StatelessWidget {
  const InfoLine({
    super.key,
    required this.label,
    required this.value,
    this.icon,
  });

  final String label;
  final String value;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final t = context.t;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(icon, size: AppSize.iconSm, color: c.inkSoft),
            ),
            const SizedBox(width: AppSpace.md),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: t.caption),
                const SizedBox(height: 2),
                Text(value, style: t.body),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
