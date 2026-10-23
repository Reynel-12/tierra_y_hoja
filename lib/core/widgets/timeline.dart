import 'package:flutter/material.dart';

import '../design/app_colors.dart';
import '../design/app_tokens.dart';
import '../design/app_typography.dart';
import 'badges.dart';

/// Cabecera de grupo de la línea de tiempo ("SEMANA 3 · DÍA 15–21").
class TimelineGroupHeader extends StatelessWidget {
  const TimelineGroupHeader({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Padding(
        padding: const EdgeInsets.only(
          left: 40 + AppSpace.md,
          top: AppSpace.xl,
          bottom: AppSpace.sm,
        ),
        child: Text(label.toUpperCase(), style: context.t.overline),
      ),
    );
  }
}

/// Elemento de la línea de tiempo: riel vertical de 2 px en `outline` y nodo
/// circular de 32 con el icono del tipo de evento, junto a su tarjeta.
class TimelineItem extends StatelessWidget {
  const TimelineItem({
    super.key,
    required this.icon,
    required this.child,
    this.nodeColor,
    this.iconColor,
    this.isFirst = false,
    this.isLast = false,
  });

  final IconData icon;
  final Widget child;
  final Color? nodeColor;
  final Color? iconColor;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 40,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                Positioned(
                  top: isFirst ? AppSpace.lg : 0,
                  bottom: isLast ? null : 0,
                  height: isLast ? AppSpace.lg : null,
                  child: Container(width: 2, color: c.outline),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: AppSpace.sm),
                  child: CircleIcon(
                    icon: icon,
                    size: AppSize.timelineNode,
                    iconSize: AppSize.iconBadge + 2,
                    background: nodeColor ?? c.primarySoft,
                    foreground: iconColor ?? c.onPrimarySoft,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpace.md),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}
