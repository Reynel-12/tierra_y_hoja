import 'package:flutter/material.dart';

import 'app_tokens.dart';

/// Transición de pantalla: deslizamiento horizontal corto + opacidad.
///
/// Si el usuario pidió reducir el movimiento, solo cambia la opacidad.
class ShortSlidePageTransitionsBuilder extends PageTransitionsBuilder {
  const ShortSlidePageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: AppMotion.enter,
      reverseCurve: AppMotion.exit,
    );
    final fade = FadeTransition(opacity: curved, child: child);
    if (AppMotion.reduced(context)) return fade;

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0.08, 0),
        end: Offset.zero,
      ).animate(curved),
      child: fade,
    );
  }
}
