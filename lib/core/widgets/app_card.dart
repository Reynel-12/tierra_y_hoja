import 'package:flutter/material.dart';

import '../design/app_colors.dart';
import '../design/app_tokens.dart';

/// Tarjeta base: `surface`, borde fino, radio 20, sombra nivel 1.
/// Toda la tarjeta es tocable con ripple recortado y escala 0.98 al presionar.
class AppCard extends StatefulWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.compact = false,
    this.padding,
    this.color,
    this.borderColor,
    this.borderWidth = 1,
    this.semanticLabel,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool compact;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final Color? borderColor;
  final double borderWidth;
  final String? semanticLabel;

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final interactive = widget.onTap != null || widget.onLongPress != null;
    final padding =
        widget.padding ??
        EdgeInsets.all(widget.compact ? AppSpace.lg : AppSpace.xl);

    final card = DecoratedBox(
      decoration: BoxDecoration(
        color: widget.color ?? c.surface,
        borderRadius: AppRadius.card,
        border: Border.all(
          color: widget.borderColor ?? c.outline,
          width: widget.borderWidth,
        ),
        boxShadow: AppShadow.level1(c.ink),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: AppRadius.card,
          onTap: widget.onTap,
          onLongPress: widget.onLongPress,
          onTapDown: interactive ? (_) => _setPressed(true) : null,
          onTapUp: interactive ? (_) => _setPressed(false) : null,
          onTapCancel: interactive ? () => _setPressed(false) : null,
          child: Padding(padding: padding, child: widget.child),
        ),
      ),
    );

    final scaled = AnimatedScale(
      scale: _pressed && !AppMotion.reduced(context) ? 0.98 : 1,
      duration: AppMotion.fast,
      curve: AppMotion.enter,
      child: card,
    );

    if (widget.semanticLabel == null) return scaled;
    return Semantics(
      button: interactive,
      label: widget.semanticLabel,
      child: scaled,
    );
  }
}

/// Tarjeta de "pendiente": borde izquierdo de 4 px en ocre y fondo `accentSoft`.
/// Es el único uso fuerte del ocre en la pantalla donde aparece.
class AccentCard extends StatelessWidget {
  const AccentCard({
    super.key,
    required this.child,
    this.onTap,
    this.accentColor,
    this.color,
  });

  final Widget child;
  final VoidCallback? onTap;
  final Color? accentColor;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final acColor = accentColor ?? c.accent;
    final bgColor =
        color ??
        (accentColor != null
            ? accentColor!.withValues(alpha: 0.12)
            : c.accentSoft);

    return ClipRRect(
      borderRadius: AppRadius.card,
      child: Material(
        color: bgColor,
        child: InkWell(
          onTap: onTap,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: acColor, width: 4)),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.lg,
                AppSpace.lg,
                AppSpace.lg,
                AppSpace.sm,
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
