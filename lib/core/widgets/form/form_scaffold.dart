import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../design/app_colors.dart';
import '../../design/app_icons.dart';
import '../../design/app_tokens.dart';
import '../../design/app_typography.dart';
import '../../state/view_state.dart';
import '../../utils/responsive.dart';
import '../app_button.dart';
import '../app_card.dart';
import '../app_top_bar.dart';
import '../dialogs.dart';
import '../layout.dart';

/// Plantilla C — Formulario.
///
/// Barra con "X" → título `headline` → campos en tarjetas → "Agregar más
/// detalles" → barra fija con **Guardar**. Pregunta antes de descartar
/// cambios, lleva el foco al primer campo con error y ofrece "Eliminar"
/// cuando se edita un registro.
class FormScaffold extends StatefulWidget {
  const FormScaffold({
    super.key,
    required this.title,
    required this.children,
    required this.onSave,
    required this.isDirty,
    required this.isSaving,
    this.subtitle,
    this.saveLabel = 'Guardar',
    this.isReady = true,
    this.onDelete,
    this.deleteTitle = '¿Eliminar este registro?',
    this.deleteMessage = 'Se borrará del teléfono y no se puede recuperar.',
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;
  final Future<SaveResult> Function() onSave;
  final bool isDirty;
  final bool isSaving;
  final String saveLabel;
  final bool isReady;

  /// Si existe, aparece el menú ⋯ con "Eliminar". Devuelve `true` si borró.
  final Future<bool> Function()? onDelete;
  final String deleteTitle;
  final String deleteMessage;

  @override
  State<FormScaffold> createState() => _FormScaffoldState();
}

class _FormScaffoldState extends State<FormScaffold> {
  final _formKey = GlobalKey<FormState>();
  bool _closing = false;

  Future<void> _submit() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final form = _formKey.currentState;
    if (form == null) return;

    final invalid = form.validateGranularly();
    if (invalid.isNotEmpty) {
      unawaitedHaptic(HapticFeedback.lightImpact());
      _focusFirstInvalid(invalid);
      return;
    }

    final result = await widget.onSave();
    if (!mounted) return;
    switch (result) {
      case SaveSuccess(:final message):
        unawaitedHaptic(HapticFeedback.selectionClick());
        if (message != null) AppToast.success(context, message);
        _closeWith(result);
      case SaveFailure(:final message):
        AppToast.error(context, message);
    }
  }

  /// Desplaza hasta el primer campo inválido (en orden visual) y le da foco.
  void _focusFirstInvalid(Set<FormFieldState<Object?>> invalid) {
    FormFieldState<Object?>? first;
    double? firstTop;
    for (final field in invalid) {
      final box = field.context.findRenderObject();
      if (box is! RenderBox || !box.attached) continue;
      final top = box.localToGlobal(Offset.zero).dy;
      if (firstTop == null || top < firstTop) {
        firstTop = top;
        first = field;
      }
    }
    final target = first ?? invalid.first;
    Scrollable.ensureVisible(
      target.context,
      alignment: 0.2,
      duration: AppMotion.base,
      curve: AppMotion.enter,
    );
    void visit(Element element) {
      final widget = element.widget;
      if (widget is EditableText) {
        widget.focusNode.requestFocus();
        return;
      }
      element.visitChildElements(visit);
    }

    if (target.context is Element) visit(target.context as Element);
  }

  void _closeWith(Object? result) {
    setState(() => _closing = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop(result);
    });
  }

  Future<void> _confirmDiscard() async {
    final discard = await showConfirmDialog(
      context,
      title: '¿Descartar los cambios?',
      message: 'Los datos que escribió no se guardarán.',
      confirmLabel: 'Descartar',
      cancelLabel: 'Seguir editando',
      destructive: true,
    );
    if (discard && mounted) _closeWith(null);
  }

  Future<void> _delete() async {
    final onDelete = widget.onDelete;
    if (onDelete == null) return;
    final confirmed = await showConfirmDialog(
      context,
      title: widget.deleteTitle,
      message: widget.deleteMessage,
      confirmLabel: 'Eliminar',
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    final deleted = await onDelete();
    if (!mounted) return;
    if (deleted) {
      AppToast.success(context, 'Registro eliminado');
      _closeWith(const SaveSuccess());
    } else {
      AppToast.error(context, 'No se pudo eliminar. Intente de nuevo.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final pad = context.screenPadding;
    return PopScope<Object?>(
      canPop: _closing || !widget.isDirty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmDiscard();
      },
      child: Scaffold(
        appBar: AppTopBar(
          closeStyle: true,
          actions: [
            if (widget.onDelete != null)
              PopupMenuButton<String>(
                tooltip: 'Más opciones',
                icon: const Icon(AppIcons.menu),
                onSelected: (_) => _delete(),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(AppIcons.delete, color: context.c.negative),
                        const SizedBox(width: AppSpace.md),
                        const Text('Eliminar'),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.fromLTRB(pad, AppSpace.sm, pad, AppSpace.x3),
            child: ContentWidth(
              maxWidth: AppSize.maxFormWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!widget.isReady)
                    const Padding(
                      padding: EdgeInsets.only(bottom: AppSpace.md),
                      child: LinearProgressIndicator(),
                    ),
                  ScreenTitle(widget.title, subtitle: widget.subtitle),
                  const SizedBox(height: AppSpace.xxl),
                  for (var i = 0; i < widget.children.length; i++) ...[
                    if (i > 0) const SizedBox(height: AppSpace.lg),
                    widget.children[i],
                  ],
                ],
              ),
            ),
          ),
        ),
        bottomNavigationBar: BottomActionBar(
          child: AppButton.primary(
            label: widget.saveLabel,
            icon: AppIcons.check,
            loading: widget.isSaving,
            onPressed: widget.isReady ? _submit : null,
          ),
        ),
      ),
    );
  }
}

/// Evita advertencias por futuros de háptica no esperados.
void unawaitedHaptic(Future<void> future) {
  future.ignore();
}

/// Tarjeta que agrupa campos por tema, con 20 entre campos.
class FormSection extends StatelessWidget {
  const FormSection({super.key, required this.children, this.title});

  final String? title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final visible = children.whereType<Widget>().toList();
    return AppCard(
      compact: context.isCompact,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null) ...[
            Text(title!, style: context.t.title),
            const SizedBox(height: AppSpace.lg),
          ],
          for (var i = 0; i < visible.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpace.fieldGap),
            visible[i],
          ],
        ],
      ),
    );
  }
}

/// "Agregar más detalles": oculta los campos opcionales hasta que se piden.
class MoreDetails extends StatefulWidget {
  const MoreDetails({
    super.key,
    required this.children,
    this.initiallyExpanded = false,
    this.label = 'Agregar más detalles',
  });

  final List<Widget> children;
  final bool initiallyExpanded;
  final String label;

  @override
  State<MoreDetails> createState() => _MoreDetailsState();
}

class _MoreDetailsState extends State<MoreDetails> {
  late bool _expanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final reduced = AppMotion.reduced(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          expanded: _expanded,
          button: true,
          child: InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: AppRadius.control,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: AppSize.touch),
              child: Row(
                children: [
                  Icon(
                    _expanded ? AppIcons.close : AppIcons.add,
                    size: AppSize.iconSm,
                    color: c.primary,
                  ),
                  const SizedBox(width: AppSpace.sm),
                  Expanded(
                    child: Text(
                      _expanded ? 'Ocultar detalles' : widget.label,
                      style: context.t.label.copyWith(color: c.primary),
                    ),
                  ),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: reduced ? Duration.zero : AppMotion.base,
                    child: Icon(AppIcons.expand,
                        size: AppSize.iconSm, color: c.primary),
                  ),
                ],
              ),
            ),
          ),
        ),
        AnimatedSize(
          duration: reduced ? Duration.zero : AppMotion.base,
          curve: AppMotion.enter,
          alignment: Alignment.topCenter,
          child: _expanded
              ? Padding(
                  padding: const EdgeInsets.only(top: AppSpace.md),
                  child: FormSection(children: widget.children),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}
