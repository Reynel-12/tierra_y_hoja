import 'package:flutter/material.dart';

/// Paleta "Tierra & Hoja". Única fuente de color de la app.
///
/// Los widgets nunca usan hex directos: siempre `context.c.<token>`.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.bg,
    required this.surface,
    required this.surfaceAlt,
    required this.outline,
    required this.outlineStrong,
    required this.ink,
    required this.inkSoft,
    required this.inkMuted,
    required this.primary,
    required this.onPrimary,
    required this.primarySoft,
    required this.onPrimarySoft,
    required this.accent,
    required this.onAccent,
    required this.accentSoft,
    required this.accentText,
    required this.positive,
    required this.neutral,
    required this.negative,
    required this.info,
    required this.positiveSoft,
    required this.neutralSoft,
    required this.negativeSoft,
    required this.infoSoft,
    required this.stagePrep,
    required this.stageGrowth,
    required this.stageFlower,
    required this.stageHarvest,
    required this.stageDone,
    required this.paper,
  });

  final Color bg, surface, surfaceAlt, outline, outlineStrong;
  final Color ink, inkSoft, inkMuted;
  final Color primary, onPrimary, primarySoft, onPrimarySoft;
  final Color accent, onAccent, accentSoft, accentText;
  final Color positive, neutral, negative, info;
  final Color positiveSoft, neutralSoft, negativeSoft, infoSoft;
  final Color stagePrep, stageGrowth, stageFlower, stageHarvest, stageDone;

  /// Blanco de hoja para el texto sobre botones destructivos.
  final Color paper;

  Color get surfaceRaised => surfaceAlt;
  Color get secondarySoft => accentSoft;
  Color get onSecondarySoft => accentText;
  Color get onNegativeSoft => negative;
  Color get onAccentSoft => accentText;
  Color get onPositiveSoft => positive;

  static const light = AppColors(
    bg: Color(0xFFF5F1E8),
    surface: Color(0xFFFCFAF5),
    surfaceAlt: Color(0xFFEDE7DA),
    outline: Color(0xFFDDD5C4),
    outlineStrong: Color(0xFF857D68),
    ink: Color(0xFF1E1C17),
    inkSoft: Color(0xFF5A5445),
    inkMuted: Color(0xFF6F6855),
    primary: Color(0xFF2C4A3A),
    onPrimary: Color(0xFFF5F1E8),
    primarySoft: Color(0xFFDDE6D8),
    onPrimarySoft: Color(0xFF1B3025),
    accent: Color(0xFFC8892B),
    onAccent: Color(0xFF1E1C17),
    accentSoft: Color(0xFFF1E2C0),
    accentText: Color(0xFF7A5210),
    positive: Color(0xFF2F6B41),
    neutral: Color(0xFF6F695A),
    negative: Color(0xFFA63F27),
    info: Color(0xFF2F5F73),
    positiveSoft: Color(0xFFDCEBDD),
    neutralSoft: Color(0xFFE7E3D8),
    negativeSoft: Color(0xFFF4DDD5),
    infoSoft: Color(0xFFDAE8EE),
    stagePrep: Color(0xFF7A5A3A),
    stageGrowth: Color(0xFF2F6B41),
    stageFlower: Color(0xFF7B4B6A),
    stageHarvest: Color(0xFF8A5C0E),
    stageDone: Color(0xFF6F695A),
    paper: Color(0xFFFFFFFF),
  );

  /// En oscuro, los fondos suaves son el color semántico al 16 % sobre `surface`.
  static const dark = AppColors(
    bg: Color(0xFF14130F),
    surface: Color(0xFF1C1B16),
    surfaceAlt: Color(0xFF25231D),
    outline: Color(0xFF38352B),
    outlineStrong: Color(0xFF6F6958),
    ink: Color(0xFFEFEAD9),
    inkSoft: Color(0xFFBDB6A1),
    inkMuted: Color(0xFF8E8774),
    primary: Color(0xFF8DB89A),
    onPrimary: Color(0xFF12231A),
    primarySoft: Color(0xFF243629),
    onPrimarySoft: Color(0xFFCFE3D4),
    accent: Color(0xFFD9A453),
    onAccent: Color(0xFF1E1C17),
    accentSoft: Color(0xFF3A2F18),
    accentText: Color(0xFFD9A453),
    positive: Color(0xFF7FC08F),
    neutral: Color(0xFFA8A18E),
    negative: Color(0xFFE58A6F),
    info: Color(0xFF7FB3C8),
    positiveSoft: Color(0xFF2C3529),
    neutralSoft: Color(0xFF323029),
    negativeSoft: Color(0xFF3C2D24),
    infoSoft: Color(0xFF2C3332),
    stagePrep: Color(0xFFC9A27C),
    stageGrowth: Color(0xFF7FC08F),
    stageFlower: Color(0xFFC99BB8),
    stageHarvest: Color(0xFFD9A453),
    stageDone: Color(0xFFA8A18E),
    paper: Color(0xFFFFFFFF),
  );

  /// Color de estado al 12 % sobre `surface` (fondo de badges).
  Color tint(Color color, {double alpha = 0.12}) =>
      Color.alphaBlend(color.withValues(alpha: alpha), surface);

  @override
  AppColors copyWith() => this;

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) =>
      other is AppColors ? (t < 0.5 ? this : other) : this;
}

extension AppColorsX on BuildContext {
  /// Acceso corto a la paleta activa: `context.c.primary`.
  AppColors get c => Theme.of(this).extension<AppColors>() ?? AppColors.light;
}
