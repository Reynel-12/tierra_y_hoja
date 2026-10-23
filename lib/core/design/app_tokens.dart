import 'package:flutter/material.dart';

/// Escala de espaciado (múltiplos de 4/8). Ver sistema de diseño §4.1.
abstract final class AppSpace {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const xxl = 24.0;
  static const x3 = 32.0;
  static const x4 = 48.0;
  static const x5 = 64.0;

  /// Margen horizontal de pantalla.
  static const screenH = 20.0;

  /// Margen horizontal en teléfonos muy angostos (< 340 dp).
  static const screenHCompact = 16.0;

  /// Espacio entre secciones.
  static const section = 32.0;

  /// Espacio entre tarjetas de una lista.
  static const listGap = 12.0;

  /// Espacio entre campos de un formulario.
  static const fieldGap = 20.0;

  /// Espacio entre etiqueta y campo.
  static const labelGap = 8.0;
}

/// Radios. Ver sistema de diseño §4.2.
abstract final class AppRadius {
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 20.0;
  static const xl = 28.0;
  static const full = 999.0;

  static BorderRadius get card => BorderRadius.circular(lg);
  static BorderRadius get control => BorderRadius.circular(md);
  static BorderRadius get chip => BorderRadius.circular(sm);
  static BorderRadius get thumb => BorderRadius.circular(xs);
  static BorderRadius get pill => BorderRadius.circular(full);
  static BorderRadius get sheet =>
      const BorderRadius.vertical(top: Radius.circular(xl));
}

/// Tamaños de controles e iconos.
abstract final class AppSize {
  static const touch = 48.0;
  static const primaryAction = 56.0;
  static const field = 56.0;
  static const chip = 40.0;
  static const bottomNav = 72.0;
  static const quickAddTile = 72.0;
  static const verdictTile = 104.0;
  static const thumb = 56.0;
  static const typeCircle = 40.0;
  static const timelineNode = 32.0;
  static const emptyCircle = 96.0;
  static const progressBar = 4.0;
  static const maxContentWidth = 720.0;
  static const maxFormWidth = 640.0;

  static const iconSm = 20.0;
  static const iconMd = 24.0;
  static const iconLg = 32.0;
  static const iconXl = 48.0;
  static const iconBadge = 16.0;
}

/// Movimiento. Ver sistema de diseño §6.
abstract final class AppMotion {
  static const fast = Duration(milliseconds: 150);
  static const base = Duration(milliseconds: 220);
  static const slow = Duration(milliseconds: 320);
  static const slowExit = Duration(milliseconds: 210);
  static const stagger = Duration(milliseconds: 40);
  static const toast = Duration(seconds: 4);
  static const undo = Duration(seconds: 5);
  static const enter = Curves.easeOutCubic;
  static const exit = Curves.easeInCubic;

  /// `true` si el usuario pidió reducir el movimiento.
  static bool reduced(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;
}

/// Sombras casi invisibles. Ver sistema de diseño §4.3.
abstract final class AppShadow {
  static List<BoxShadow> level1(Color ink) => [
    BoxShadow(
      color: ink.withValues(alpha: 0.04),
      blurRadius: 2,
      offset: const Offset(0, 1),
    ),
  ];

  static List<BoxShadow> level2(Color ink) => [
    BoxShadow(
      color: ink.withValues(alpha: 0.08),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> level3(Color ink) => [
    BoxShadow(
      color: ink.withValues(alpha: 0.14),
      blurRadius: 40,
      offset: const Offset(0, 16),
    ),
  ];
}
