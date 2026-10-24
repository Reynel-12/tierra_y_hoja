import 'package:flutter/material.dart';

import '../design/app_colors.dart';
import '../design/app_tokens.dart';
import '../design/app_typography.dart';

/// Icono dentro de un círculo tonal (tipo de registro, estados vacíos, nodos).
class CircleIcon extends StatelessWidget {
  const CircleIcon({
    super.key,
    required this.icon,
    this.size = AppSize.typeCircle,
    this.iconSize = AppSize.iconSm,
    this.background,
    this.foreground,
    this.color,
    this.semanticLabel,
  });

  final IconData icon;
  final double size;
  final double iconSize;
  final Color? background;
  final Color? foreground;
  final Color? color;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final bg =
        background ??
        (color != null ? color!.withValues(alpha: 0.15) : c.primarySoft);
    final fg = foreground ?? color ?? c.onPrimarySoft;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Icon(
        icon,
        size: iconSize,
        color: fg,
        semanticLabel: semanticLabel,
      ),
    );
  }
}

/// Badge de estado: fondo del color al 12 %, icono de 16 en el color y texto
/// en `ink`. El color nunca informa solo: siempre va con icono y texto.
class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.md - 2,
        vertical: AppSpace.xs,
      ),
      decoration: BoxDecoration(
        color: c.tint(color),
        borderRadius: AppRadius.pill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppSize.iconBadge, color: color),
          const SizedBox(width: AppSpace.xs + 2),
          Flexible(
            child: Text(
              label,
              style: context.t.label.copyWith(fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Chip informativo pequeño (no seleccionable) con icono y borde semántico,
/// por ejemplo el veredicto en una entrada de bitácora.
class InfoChip extends StatelessWidget {
  const InfoChip({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.background,
  });

  final String label;
  final IconData icon;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.sm + 2,
        vertical: AppSpace.xs,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppRadius.thumb,
        border: Border.all(color: color, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppSize.iconBadge, color: color),
          const SizedBox(width: AppSpace.xs),
          Flexible(
            child: Text(
              label,
              style: context.t.caption.copyWith(color: context.c.ink),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
