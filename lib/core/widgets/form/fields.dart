import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../design/app_colors.dart';
import '../../design/app_icons.dart';
import '../../design/app_tokens.dart';
import '../../design/app_typography.dart';
import '../../utils/choice_option.dart';
import '../dialogs.dart';
import 'voice_note_button.dart';

/// Etiqueta siempre visible arriba del campo. Los obligatorios llevan
/// "(obligatorio)"; los opcionales no llevan marca.
class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key, this.required = false});

  final String text;
  final bool required;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.labelGap),
      child: Text.rich(
        TextSpan(
          text: text,
          style: t.label,
          children: [
            if (required)
              TextSpan(
                text: ' (obligatorio)',
                style: t.label.copyWith(
                  color: context.c.inkMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Formateador para campos numéricos: solo cifras, punto y coma.
final numberInputFormatters = <TextInputFormatter>[
  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
];

const numberKeyboard = TextInputType.numberWithOptions(decimal: true);

/// Campo de texto con etiqueta arriba, ayuda persistente debajo, validación
/// al salir del campo y botón de dictado opcional.
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.label,
    required this.controller,
    this.required = false,
    this.hint,
    this.helper,
    this.validator,
    this.keyboardType,
    this.inputFormatters,
    this.maxLines = 1,
    this.minLines,
    this.textInputAction,
    this.prefixText,
    this.suffixText,
    this.enableVoice = false,
    this.textCapitalization = TextCapitalization.sentences,
    this.onChanged,
    this.maxLength,
  });

  /// Campo numérico (dosis, área, precios): teclado numérico y filtro.
  const AppTextField.number({
    super.key,
    required this.label,
    required this.controller,
    this.required = false,
    this.hint,
    this.helper,
    this.validator,
    this.prefixText,
    this.suffixText,
    this.onChanged,
    this.textInputAction = TextInputAction.next,
  }) : keyboardType = numberKeyboard,
       maxLines = 1,
       minLines = null,
       enableVoice = false,
       textCapitalization = TextCapitalization.none,
       maxLength = 12,
       inputFormatters = null;

  /// Campo de notas multilínea con dictado por voz.
  const AppTextField.notes({
    super.key,
    required this.label,
    required this.controller,
    this.required = false,
    this.hint,
    this.helper,
    this.validator,
    this.onChanged,
  }) : keyboardType = TextInputType.multiline,
       maxLines = 6,
       minLines = 3,
       enableVoice = true,
       textCapitalization = TextCapitalization.sentences,
       textInputAction = TextInputAction.newline,
       prefixText = null,
       suffixText = null,
       maxLength = null,
       inputFormatters = null;

  final String label;
  final TextEditingController controller;
  final bool required;
  final String? hint;
  final String? helper;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int maxLines;
  final int? minLines;
  final TextInputAction? textInputAction;
  final String? prefixText;
  final String? suffixText;
  final bool enableVoice;
  final TextCapitalization textCapitalization;
  final ValueChanged<String>? onChanged;
  final int? maxLength;

  @override
  Widget build(BuildContext context) {
    final isNumber = keyboardType == numberKeyboard;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        FieldLabel(label, required: required),
        TextFormField(
          controller: controller,
          validator: validator,
          autovalidateMode: AutovalidateMode.onUnfocus,
          keyboardType: keyboardType,
          inputFormatters:
              inputFormatters ?? (isNumber ? numberInputFormatters : null),
          maxLines: maxLines,
          minLines: minLines,
          maxLength: maxLength,
          textInputAction:
              textInputAction ??
              (maxLines > 1 ? TextInputAction.newline : TextInputAction.next),
          textCapitalization: textCapitalization,
          style: context.t.body,
          onChanged: onChanged,
          onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
          decoration: InputDecoration(
            hintText: hint,
            helperText: helper,
            counterText: '',
            prefixText: prefixText == null ? null : '$prefixText ',
            suffixText: suffixText,
            errorMaxLines: 3,
            suffixIcon: enableVoice
                ? Align(
                    widthFactor: 1,
                    heightFactor: 1,
                    alignment: Alignment.topCenter,
                    child: VoiceNoteButton(controller: controller),
                  )
                : null,
          ),
        ),
      ],
    );
  }
}

/// Campo con unidad: número a la izquierda y selector de unidad pegado a la
/// derecha en el mismo contenedor (`2 | quintales ▾`).
class UnitField<U extends ChoiceOption> extends StatelessWidget {
  const UnitField({
    super.key,
    required this.label,
    required this.controller,
    required this.units,
    required this.unit,
    required this.onUnitChanged,
    this.required = false,
    this.hint,
    this.helper,
    this.validator,
  });

  final String label;
  final TextEditingController controller;
  final List<U> units;
  final U unit;
  final ValueChanged<U> onUnitChanged;
  final bool required;
  final String? hint;
  final String? helper;
  final FormFieldValidator<String>? validator;

  Future<void> _pickUnit(BuildContext context) async {
    final selected = await showAppSheet<U>(
      context,
      title: 'Elegir unidad',
      builder: (sheetContext) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final option in units)
            _UnitOptionTile(
              label: option.label,
              selected: option == unit,
              onTap: () => Navigator.of(sheetContext).pop(option),
            ),
        ],
      ),
    );
    if (selected != null && selected != unit) onUnitChanged(selected);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final t = context.t;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        FieldLabel(label, required: required),
        TextFormField(
          controller: controller,
          validator: validator,
          autovalidateMode: AutovalidateMode.onUnfocus,
          keyboardType: numberKeyboard,
          inputFormatters: numberInputFormatters,
          textInputAction: TextInputAction.next,
          maxLength: 12,
          style: t.body,
          onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
          decoration: InputDecoration(
            hintText: hint,
            helperText: helper,
            counterText: '',
            suffixIconConstraints: const BoxConstraints(
              minHeight: AppSize.touch,
              minWidth: AppSize.touch,
            ),
            suffixIcon: Semantics(
              button: true,
              label: 'Unidad: ${unit.label}. Cambiar unidad',
              excludeSemantics: true,
              child: InkWell(
                onTap: () => _pickUnit(context),
                borderRadius: const BorderRadius.horizontal(
                  right: Radius.circular(AppRadius.md),
                ),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 170),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpace.md,
                    vertical: AppSpace.md,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(color: c.outlineStrong, width: 1),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          unit.label,
                          style: t.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: AppSpace.xs),
                      Icon(
                        AppIcons.expand,
                        size: AppSize.iconBadge,
                        color: c.inkSoft,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _UnitOptionTile extends StatelessWidget {
  const _UnitOptionTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.control,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Row(
            children: [
              Expanded(child: Text(label, style: context.t.body)),
              if (selected) Icon(AppIcons.check, color: c.primary),
            ],
          ),
        ),
      ),
    );
  }
}

/// Buscador para listas (plantilla A).
class AppSearchField extends StatelessWidget {
  const AppSearchField({
    super.key,
    required this.controller,
    required this.hint,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) => TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        style: context.t.body,
        onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: const Icon(AppIcons.search, size: AppSize.iconSm),
          suffixIcon: value.text.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Borrar búsqueda',
                  icon: const Icon(AppIcons.close, size: AppSize.iconSm),
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                ),
        ),
      ),
    );
  }
}
