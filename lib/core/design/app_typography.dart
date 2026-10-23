import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Escala tipográfica con nombres del sistema de diseño (§3).
///
/// Fraunces para títulos y cifras; Manrope para interfaz y cuerpo.
/// Todas las cifras usan `tabularFigures` para que no "bailen".
@immutable
class AppTypography extends ThemeExtension<AppTypography> {
  const AppTypography({
    required this.displayLg,
    required this.display,
    required this.headline,
    required this.title,
    required this.body,
    required this.bodySm,
    required this.label,
    required this.overline,
    required this.caption,
  });

  factory AppTypography.from(AppColors c) {
    TextStyle ui(double size, double lineHeight, FontWeight weight) =>
        TextStyle(
          fontFamily: fontUi,
          fontSize: size,
          height: lineHeight / size,
          fontWeight: weight,
          color: c.ink,
          fontFeatures: const [FontFeature.tabularFigures()],
        );
    TextStyle serif(double size, double lineHeight, FontWeight weight) =>
        TextStyle(
          fontFamily: fontSerif,
          fontSize: size,
          height: lineHeight / size,
          fontWeight: weight,
          color: c.ink,
          fontFeatures: const [FontFeature.tabularFigures()],
        );

    return AppTypography(
      displayLg: serif(40, 44, FontWeight.w500),
      display: serif(32, 38, FontWeight.w500),
      headline: serif(24, 30, FontWeight.w600),
      title: ui(18, 24, FontWeight.w700),
      body: ui(16, 24, FontWeight.w500),
      bodySm: ui(14, 20, FontWeight.w500).copyWith(color: c.inkSoft),
      label: ui(14, 20, FontWeight.w600),
      overline: ui(
        12,
        16,
        FontWeight.w700,
      ).copyWith(letterSpacing: 0.8, color: c.inkSoft),
      caption: ui(12, 16, FontWeight.w600).copyWith(color: c.inkMuted),
    );
  }

  static const fontUi = 'Manrope';
  static const fontSerif = 'Fraunces';

  final TextStyle displayLg;
  final TextStyle display;
  final TextStyle headline;
  final TextStyle title;
  final TextStyle body;
  final TextStyle bodySm;
  final TextStyle label;
  final TextStyle overline;
  final TextStyle caption;

  TextStyle get titleSm => label;
  TextStyle get numericLg => display;
  TextStyle get displaySm => headline;

  @override
  AppTypography copyWith() => this;

  @override
  AppTypography lerp(ThemeExtension<AppTypography>? other, double t) =>
      other is AppTypography ? (t < 0.5 ? this : other) : this;
}

extension AppTypographyX on BuildContext {
  /// Acceso corto a la escala tipográfica: `context.t.title`.
  AppTypography get t =>
      Theme.of(this).extension<AppTypography>() ??
      AppTypography.from(AppColors.light);
}
