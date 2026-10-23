import 'package:flutter/material.dart';

import '../design/app_colors.dart';
import '../design/app_icons.dart';
import '../design/app_tokens.dart';
import '../design/app_typography.dart';
import '../state/view_state.dart';
import '../utils/responsive.dart';
import 'app_button.dart';
import 'badges.dart';

/// Estado vacío: círculo 96 · título · una línea · un solo botón.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: context.screenPadding,
        vertical: AppSpace.x3,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleIcon(
            icon: icon,
            size: AppSize.emptyCircle,
            iconSize: AppSize.iconXl,
            foreground: context.c.primary,
          ),
          const SizedBox(height: AppSpace.xl),
          Text(title, style: t.title, textAlign: TextAlign.center),
          const SizedBox(height: AppSpace.sm),
          Text(message, style: t.bodySm, textAlign: TextAlign.center),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: AppSpace.xxl),
            AppButton.primary(
              label: actionLabel!,
              onPressed: onAction,
              icon: AppIcons.add,
              expand: false,
            ),
          ],
        ],
      ),
    );
  }
}

/// Error con reintento.
class ErrorState extends StatelessWidget {
  const ErrorState({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Padding(
      padding: EdgeInsets.all(context.screenPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleIcon(
            icon: AppIcons.warning,
            size: AppSize.emptyCircle,
            iconSize: AppSize.iconXl,
            background: c.negativeSoft,
            foreground: c.negative,
          ),
          const SizedBox(height: AppSpace.xl),
          Text(
            message,
            style: context.t.body,
            textAlign: TextAlign.center,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: AppSpace.xl),
            AppButton.outline(
              label: 'Reintentar',
              onPressed: onRetry,
              expand: false,
            ),
          ],
        ],
      ),
    );
  }
}

/// Bloque de skeleton en `surfaceAlt` con pulso suave.
class SkeletonBox extends StatefulWidget {
  const SkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.radius = AppRadius.xs,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AppMotion.reduced(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.55, end: 1).animate(_controller),
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: context.c.surfaceAlt,
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      ),
    );
  }
}

/// Lista de tarjetas skeleton para cargas de más de 300 ms.
class SkeletonList extends StatelessWidget {
  const SkeletonList({super.key, this.count = 4, this.itemHeight = 112});

  final int count;
  final double itemHeight;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Cargando',
      child: Padding(
        padding: EdgeInsets.all(context.screenPadding),
        child: Column(
          children: [
            for (var i = 0; i < count; i++) ...[
              if (i > 0) const SizedBox(height: AppSpace.listGap),
              SkeletonBox(height: itemHeight, radius: AppRadius.lg),
            ],
          ],
        ),
      ),
    );
  }
}

/// Muestra skeleton, error con reintento o el contenido según [state].
class ViewStateBuilder<T> extends StatelessWidget {
  const ViewStateBuilder({
    super.key,
    required this.state,
    required this.builder,
    this.onRetry,
    this.loading,
  });

  final ViewState<T> state;
  final Widget Function(BuildContext context, T data) builder;
  final VoidCallback? onRetry;
  final Widget? loading;

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      ViewLoading<T>() => loading ?? const SkeletonList(),
      ViewError<T>(:final message) =>
        Center(child: ErrorState(message: message, onRetry: onRetry)),
      ViewData<T>(:final data) => builder(context, data),
    };
  }
}
