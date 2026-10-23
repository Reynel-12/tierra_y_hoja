import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_page_transitions.dart';
import 'app_tokens.dart';
import 'app_typography.dart';

/// Construye el `ThemeData` claro y oscuro a partir de los tokens.
abstract final class AppTheme {
  static ThemeData get light => _build(AppColors.light, Brightness.light);
  static ThemeData get dark => _build(AppColors.dark, Brightness.dark);

  static ThemeData _build(AppColors c, Brightness brightness) {
    final t = AppTypography.from(c);

    final scheme = ColorScheme(
      brightness: brightness,
      primary: c.primary,
      onPrimary: c.onPrimary,
      primaryContainer: c.primarySoft,
      onPrimaryContainer: c.onPrimarySoft,
      secondary: c.accent,
      onSecondary: c.onAccent,
      secondaryContainer: c.accentSoft,
      onSecondaryContainer: c.ink,
      error: c.negative,
      onError: c.paper,
      surface: c.surface,
      onSurface: c.ink,
      onSurfaceVariant: c.inkSoft,
      surfaceContainerLowest: c.surface,
      surfaceContainerLow: c.surface,
      surfaceContainer: c.surface,
      surfaceContainerHigh: c.surface,
      surfaceContainerHighest: c.surfaceAlt,
      outline: c.outlineStrong,
      outlineVariant: c.outline,
      surfaceTint: Colors.transparent,
    );

    final textTheme = TextTheme(
      displayLarge: t.displayLg,
      displayMedium: t.display,
      headlineMedium: t.headline,
      headlineSmall: t.headline,
      titleLarge: t.headline,
      titleMedium: t.title,
      titleSmall: t.label,
      bodyLarge: t.body,
      bodyMedium: t.bodySm.copyWith(color: c.ink),
      bodySmall: t.caption,
      labelLarge: t.label,
      labelMedium: t.label,
      labelSmall: t.overline,
    );

    final controlBorder = OutlineInputBorder(
      borderRadius: AppRadius.control,
      borderSide: BorderSide(color: c.outlineStrong, width: 1.5),
    );

    final buttonText = t.label.copyWith(fontSize: 16);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: AppTypography.fontUi,
      scaffoldBackgroundColor: c.bg,
      canvasColor: c.bg,
      textTheme: textTheme,
      extensions: [c, t],
      splashFactory: InkRipple.splashFactory,
      dividerColor: c.outline,
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      iconTheme: IconThemeData(color: c.ink, size: AppSize.iconMd),
      dividerTheme: DividerThemeData(color: c.outline, thickness: 1, space: 1),
      appBarTheme: AppBarTheme(
        backgroundColor: c.bg,
        foregroundColor: c.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: AppSpace.screenH,
        titleTextStyle: t.headline,
        iconTheme: IconThemeData(color: c.ink, size: AppSize.iconMd),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(AppSize.touch, AppSize.primaryAction),
          backgroundColor: c.primary,
          foregroundColor: c.onPrimary,
          disabledBackgroundColor: c.primary.withValues(alpha: 0.38),
          disabledForegroundColor: c.onPrimary.withValues(alpha: 0.8),
          textStyle: buttonText,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.xl),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.control),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(AppSize.touch, AppSize.primaryAction),
          foregroundColor: c.ink,
          side: BorderSide(color: c.outlineStrong, width: 1.5),
          textStyle: buttonText,
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.xl),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.control),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(AppSize.touch, AppSize.touch),
          foregroundColor: c.primary,
          textStyle: t.label,
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.md),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.control),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(AppSize.touch, AppSize.touch),
          foregroundColor: c.ink,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surface,
        isDense: false,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpace.lg,
          vertical: 16,
        ),
        hintStyle: t.body.copyWith(color: c.inkMuted),
        border: controlBorder,
        enabledBorder: controlBorder,
        disabledBorder: controlBorder.copyWith(
          borderSide: BorderSide(color: c.outline, width: 1.5),
        ),
        focusedBorder: controlBorder.copyWith(
          borderSide: BorderSide(color: c.primary, width: 2),
        ),
        errorBorder: controlBorder.copyWith(
          borderSide: BorderSide(color: c.negative, width: 2),
        ),
        focusedErrorBorder: controlBorder.copyWith(
          borderSide: BorderSide(color: c.negative, width: 2),
        ),
        helperStyle: t.caption,
        helperMaxLines: 3,
        errorStyle: t.bodySm.copyWith(color: c.ink),
        errorMaxLines: 3,
        prefixIconColor: c.inkSoft,
        suffixIconColor: c.inkSoft,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: c.primary,
        selectionColor: c.primarySoft,
        selectionHandleColor: c.primary,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: c.primary,
        linearTrackColor: c.surfaceAlt,
        circularTrackColor: Colors.transparent,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        modalBarrierColor: Colors.black.withValues(alpha: 0.5),
        showDragHandle: false,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.sheet),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        barrierColor: Colors.black.withValues(alpha: 0.5),
        elevation: 0,
        titleTextStyle: t.title,
        contentTextStyle: t.body,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: c.ink,
        contentTextStyle: t.bodySm.copyWith(color: c.bg),
        actionTextColor: c.bg,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.control),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: c.surface,
        surfaceTintColor: Colors.transparent,
        textStyle: t.body,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.control,
          side: BorderSide(color: c.outline),
        ),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        headerBackgroundColor: c.primary,
        headerForegroundColor: c.onPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: c.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(color: c.ink, borderRadius: AppRadius.thumb),
        textStyle: t.caption.copyWith(color: c.bg),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ShortSlidePageTransitionsBuilder(),
          TargetPlatform.iOS: ShortSlidePageTransitionsBuilder(),
          TargetPlatform.windows: ShortSlidePageTransitionsBuilder(),
          TargetPlatform.macOS: ShortSlidePageTransitionsBuilder(),
          TargetPlatform.linux: ShortSlidePageTransitionsBuilder(),
        },
      ),
    );
  }
}
