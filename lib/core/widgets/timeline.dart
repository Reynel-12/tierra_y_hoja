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
    return CustomPaint(
      painter: _TimelineLinePainter(
        lineColor: c.outline,
        lineWidth: 2.0,
        nodeCenterX: 20.0,
        nodeCenterY: AppSpace.sm + (AppSize.timelineNode / 2),
        isFirst: isFirst,
        isLast: isLast,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 40,
            child: Padding(
              padding: const EdgeInsets.only(top: AppSpace.sm),
              child: Center(
                child: CircleIcon(
                  icon: icon,
                  size: AppSize.timelineNode,
                  iconSize: AppSize.iconBadge + 2,
                  background: nodeColor ?? c.primarySoft,
                  foreground: iconColor ?? c.onPrimarySoft,
                ),
              ),
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

class _TimelineLinePainter extends CustomPainter {
  const _TimelineLinePainter({
    required this.lineColor,
    required this.lineWidth,
    required this.nodeCenterX,
    required this.nodeCenterY,
    required this.isFirst,
    required this.isLast,
  });

  final Color lineColor;
  final double lineWidth;
  final double nodeCenterX;
  final double nodeCenterY;
  final bool isFirst;
  final bool isLast;

  @override
  void paint(Canvas canvas, Size size) {
    if (isFirst && isLast) return;

    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = lineWidth
      ..style = PaintingStyle.stroke;

    final startY = isFirst ? nodeCenterY : 0.0;
    final endY = isLast ? nodeCenterY : size.height;

    if (endY > startY) {
      canvas.drawLine(
        Offset(nodeCenterX, startY),
        Offset(nodeCenterX, endY),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TimelineLinePainter oldDelegate) {
    return oldDelegate.lineColor != lineColor ||
        oldDelegate.lineWidth != lineWidth ||
        oldDelegate.nodeCenterX != nodeCenterX ||
        oldDelegate.nodeCenterY != nodeCenterY ||
        oldDelegate.isFirst != isFirst ||
        oldDelegate.isLast != isLast;
  }
}
