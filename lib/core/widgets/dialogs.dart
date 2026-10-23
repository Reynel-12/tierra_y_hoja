import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../design/app_colors.dart';
import '../design/app_icons.dart';
import '../design/app_tokens.dart';
import '../design/app_typography.dart';
import '../utils/responsive.dart';
import 'app_button.dart';

/// Diálogo de confirmación: máximo 2 botones (seguro a la izquierda en
/// contorno, principal a la derecha). En teléfonos muy angostos se apilan.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  String cancelLabel = 'Cancelar',
  bool destructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => _ConfirmDialog(
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      destructive: destructive,
    ),
  );
  return result ?? false;
}

class _ConfirmDialog extends StatelessWidget {
  const _ConfirmDialog({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.destructive,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final cancel = AppButton.outline(
      label: cancelLabel,
      onPressed: () => Navigator.of(context).pop(false),
    );
    final confirm = destructive
        ? AppButton.destructive(
            label: confirmLabel,
            onPressed: () => Navigator.of(context).pop(true),
          )
        : AppButton.primary(
            label: confirmLabel,
            onPressed: () => Navigator.of(context).pop(true),
          );

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: context.screenPadding,
        vertical: AppSpace.xxl,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: t.title),
              const SizedBox(height: AppSpace.md),
              Text(message, style: t.body.copyWith(color: context.c.inkSoft)),
              const SizedBox(height: AppSpace.xxl),
              if (context.isTiny)
                Column(
                  children: [
                    confirm,
                    const SizedBox(height: AppSpace.sm),
                    cancel,
                  ],
                )
              else
                Row(
                  children: [
                    Expanded(child: cancel),
                    const SizedBox(width: AppSpace.md),
                    Expanded(child: confirm),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet del sistema: asa 40×4, título, botón "Cerrar" y safe area.
Future<T?> showAppSheet<T>(
  BuildContext context, {
  required String title,
  required WidgetBuilder builder,
  bool scrollable = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    constraints: BoxConstraints(
      maxHeight: MediaQuery.sizeOf(context).height * 0.9,
      maxWidth: AppSize.maxFormWidth,
    ),
    builder: (sheetContext) => _AppSheet(
      title: title,
      scrollable: scrollable,
      child: builder(sheetContext),
    ),
  );
}

class _AppSheet extends StatelessWidget {
  const _AppSheet({
    required this.title,
    required this.child,
    required this.scrollable,
  });

  final String title;
  final Widget child;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final pad = context.screenPadding;
    final body = Padding(
      padding: EdgeInsets.fromLTRB(pad, 0, pad, AppSpace.xl),
      child: child,
    );
    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpace.md),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: c.outlineStrong,
                borderRadius: AppRadius.pill,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(pad, AppSpace.sm, AppSpace.xs, 0),
            child: Row(
              children: [
                Expanded(child: Text(title, style: context.t.title)),
                IconButton(
                  tooltip: 'Cerrar',
                  icon: const Icon(AppIcons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.sm),
          if (scrollable)
            Flexible(child: SingleChildScrollView(child: body))
          else
            body,
        ],
      ),
    );
  }
}

enum ToastKind { success, error, info }

/// Avisos flotantes: fondo `ink` invertido, icono semántico, 4 s,
/// acción "Deshacer" opcional. Nunca roban el foco.
abstract final class AppToast {
  static void success(BuildContext context, String message) =>
      _show(context, message, ToastKind.success);

  static void error(BuildContext context, String message) =>
      _show(context, message, ToastKind.error);

  static void info(BuildContext context, String message) =>
      _show(context, message, ToastKind.info);

  static void undo(
    BuildContext context,
    String message, {
    required VoidCallback onUndo,
  }) =>
      _show(context, message, ToastKind.success, onUndo: onUndo);

  static void _show(
    BuildContext context,
    String message,
    ToastKind kind, {
    VoidCallback? onUndo,
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    final isLight = Theme.of(context).brightness == Brightness.light;
    // Sobre el fondo invertido se usan los semánticos del tema opuesto.
    final inverse = isLight ? AppColors.dark : AppColors.light;
    final (icon, color) = switch (kind) {
      ToastKind.success => (AppIcons.checkCircle, inverse.positive),
      ToastKind.error => (AppIcons.warning, inverse.negative),
      ToastKind.info => (AppIcons.info, inverse.info),
    };
    if (kind == ToastKind.error) HapticFeedback.lightImpact();

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: onUndo != null ? AppMotion.undo : AppMotion.toast,
          content: Row(
            children: [
              Icon(icon, color: color, size: AppSize.iconMd),
              const SizedBox(width: AppSpace.md),
              Expanded(child: Text(message)),
            ],
          ),
          action: onUndo == null
              ? null
              : SnackBarAction(label: 'Deshacer', onPressed: onUndo),
        ),
      );
  }
}
