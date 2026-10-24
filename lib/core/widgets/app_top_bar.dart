import 'package:flutter/material.dart';

import '../design/app_colors.dart';
import '../design/app_icons.dart';
import '../design/app_tokens.dart';
import '../design/app_typography.dart';
import '../utils/responsive.dart';

/// Barra superior: fondo `bg`, sin línea hasta que el contenido hace scroll
/// (entonces borde 1 `outline`). Título `headline` a la izquierda.
class AppTopBar extends StatefulWidget implements PreferredSizeWidget {
  const AppTopBar({
    super.key,
    this.title,
    this.actions = const [],
    this.closeStyle = false,
    this.showBack = true,
    this.backgroundColor,
    this.onBack,
  });

  final String? title;
  final List<Widget> actions;

  /// Muestra "X" en vez de flecha (formularios).
  final bool closeStyle;
  final bool showBack;
  final Color? backgroundColor;
  final VoidCallback? onBack;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  State<AppTopBar> createState() => _AppTopBarState();
}

class _AppTopBarState extends State<AppTopBar> {
  ScrollNotificationObserverState? _observer;
  bool _scrolled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _observer?.removeListener(_onScroll);
    _observer = ScrollNotificationObserver.maybeOf(context);
    _observer?.addListener(_onScroll);
  }

  @override
  void dispose() {
    _observer?.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll(ScrollNotification notification) {
    if (notification is! ScrollUpdateNotification ||
        notification.depth != 0 ||
        notification.metrics.axis != Axis.vertical) {
      return;
    }
    final scrolled = notification.metrics.extentBefore > 0;
    if (scrolled != _scrolled) setState(() => _scrolled = scrolled);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final canPop = Navigator.of(context).canPop();
    final hasLeading = widget.showBack && canPop;

    return AppBar(
      toolbarHeight: 64,
      automaticallyImplyLeading: false,
      backgroundColor: widget.backgroundColor ?? c.bg,
      titleSpacing: hasLeading ? AppSpace.xs : context.screenPadding,
      shape: Border(
        bottom: BorderSide(color: _scrolled ? c.outline : Colors.transparent),
      ),
      leading: hasLeading
          ? IconButton(
              tooltip: widget.closeStyle ? 'Cerrar' : 'Atrás',
              icon: Icon(widget.closeStyle ? AppIcons.close : AppIcons.back),
              onPressed:
                  widget.onBack ?? () => Navigator.of(context).maybePop(),
            )
          : null,
      title: widget.title == null
          ? null
          : Text(
              widget.title!,
              style: context.t.headline,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
      actions: [
        ...widget.actions,
        SizedBox(width: hasLeading ? AppSpace.xs : AppSpace.sm),
      ],
    );
  }
}
