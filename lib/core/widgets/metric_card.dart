import 'package:flutter/material.dart';

import '../design/app_colors.dart';
import '../design/app_tokens.dart';
import '../design/app_typography.dart';
import 'app_card.dart';

/// Tendencia opcional de una cifra (siempre icono + texto, no solo color).
class MetricTrend {
  const MetricTrend({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;
}

/// Tarjeta cifra: `overline` arriba · número `display` · unidad `bodySm`.
class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.label,
    required this.value,
    this.unit,
    this.trend,
    this.onTap,
  });

  final String label;
  final String value;
  final String? unit;
  final MetricTrend? trend;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return AppCard(
      compact: true,
      onTap: onTap,
      semanticLabel: '$label: $value ${unit ?? ''}',
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label.toUpperCase(),
              style: t.overline,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpace.sm),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value, style: t.display, maxLines: 1),
            ),
            if (unit != null)
              Text(
                unit!,
                style: t.bodySm,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            if (trend != null) ...[
              const SizedBox(height: AppSpace.xs),
              Row(
                children: [
                  Icon(
                    trend!.icon,
                    size: AppSize.iconBadge,
                    color: trend!.color,
                  ),
                  const SizedBox(width: AppSpace.xs),
                  Expanded(
                    child: Text(
                      trend!.label,
                      style: t.caption.copyWith(color: context.c.ink),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Fila de 2–3 tarjetas cifra que se reacomoda en pantallas angostas:
/// calcula cuántas columnas caben y mantiene la misma altura por fila.
class MetricRow extends StatelessWidget {
  const MetricRow({super.key, required this.children, this.minItemWidth = 140});

  final List<Widget> children;
  final double minItemWidth;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = AppSpace.md;
        final fit = ((constraints.maxWidth + gap) / (minItemWidth + gap))
            .floor()
            .clamp(1, children.length);
        final rows = <Widget>[];
        for (var i = 0; i < children.length; i += fit) {
          final slice = children.skip(i).take(fit).toList();
          rows.add(
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var j = 0; j < fit; j++) ...[
                    if (j > 0) const SizedBox(width: gap),
                    Expanded(
                      child: j < slice.length
                          ? slice[j]
                          : const SizedBox.shrink(),
                    ),
                  ],
                ],
              ),
            ),
          );
        }
        return Column(
          children: [
            for (var i = 0; i < rows.length; i++) ...[
              if (i > 0) const SizedBox(height: gap),
              rows[i],
            ],
          ],
        );
      },
    );
  }
}

/// Cifra héroe en `displayLg` sobre el fondo (sin tarjeta), plantilla E.
class HeroFigure extends StatelessWidget {
  const HeroFigure({
    super.key,
    required this.label,
    required this.value,
    this.caption,
    this.trend,
    this.valueColor,
  });

  final String label;
  final String value;
  final String? caption;
  final MetricTrend? trend;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Semantics(
      label: '$label: $value. ${trend?.label ?? ''} ${caption ?? ''}',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: t.overline),
          const SizedBox(height: AppSpace.sm),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: t.displayLg.copyWith(color: valueColor),
              maxLines: 1,
            ),
          ),
          if (trend != null) ...[
            const SizedBox(height: AppSpace.xs),
            Row(
              children: [
                Icon(trend!.icon, size: AppSize.iconSm, color: trend!.color),
                const SizedBox(width: AppSpace.sm),
                Expanded(child: Text(trend!.label, style: t.label)),
              ],
            ),
          ],
          if (caption != null) ...[
            const SizedBox(height: AppSpace.xs),
            Text(caption!, style: t.bodySm),
          ],
        ],
      ),
    );
  }
}
