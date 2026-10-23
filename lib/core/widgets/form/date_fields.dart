import 'package:flutter/material.dart';

import '../../design/app_icons.dart';
import '../../design/app_tokens.dart';
import '../../utils/formatters.dart';
import 'choices.dart';
import 'fields.dart';

/// Fecha con chips `Hoy · Ayer · Elegir fecha` ("Hoy" preseleccionado).
class DateChipsField extends StatelessWidget {
  const DateChipsField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.required = false,
    this.allowFuture = false,
    this.firstDate,
    this.helper,
  });

  final String label;
  final DateTime value;
  final ValueChanged<DateTime> onChanged;
  final bool required;
  final bool allowFuture;
  final DateTime? firstDate;
  final String? helper;

  Future<void> _pick(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: value,
      firstDate: firstDate ?? DateTime(now.year - 10),
      lastDate: allowFuture ? DateTime(now.year + 2) : now,
      helpText: label,
      cancelText: 'Cancelar',
      confirmText: 'Listo',
    );
    if (picked != null) onChanged(_keepTime(picked));
  }

  /// Conserva la hora del valor actual al cambiar solo el día.
  DateTime _keepTime(DateTime day) =>
      DateTime(day.year, day.month, day.day, value.hour, value.minute);

  @override
  Widget build(BuildContext context) {
    final today = DateUtilsX.today();
    final yesterday = today.subtract(const Duration(days: 1));
    final isToday = DateUtilsX.isSameDay(value, today);
    final isYesterday = DateUtilsX.isSameDay(value, yesterday);
    final isCustom = !isToday && !isYesterday;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        FieldLabel(label, required: required),
        Wrap(
          spacing: AppSpace.sm,
          children: [
            AppChip(
              label: 'Hoy',
              selected: isToday,
              onTap: () => onChanged(_keepTime(today)),
            ),
            AppChip(
              label: 'Ayer',
              selected: isYesterday,
              onTap: () => onChanged(_keepTime(yesterday)),
            ),
            AppChip(
              label: isCustom ? Formatters.date(value) : 'Elegir fecha',
              icon: AppIcons.calendar,
              selected: isCustom,
              onTap: () => _pick(context),
            ),
          ],
        ),
        if (helper != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpace.xs),
            child: Text(helper!, style: Theme.of(context).textTheme.bodySmall),
          ),
      ],
    );
  }
}

/// Selector de fecha opcional (por ejemplo inicio y fin de cosecha).
class DatePickerField extends StatelessWidget {
  const DatePickerField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.required = false,
    this.firstDate,
    this.validator,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime> onChanged;
  final bool required;
  final DateTime? firstDate;
  final String? Function(DateTime?)? validator;

  @override
  Widget build(BuildContext context) {
    return FormField<DateTime>(
      validator: validator == null ? null : (_) => validator!(value),
      builder: (field) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          FieldLabel(label, required: required),
          OutlinedButton.icon(
            onPressed: () async {
              final now = DateTime.now();
              final picked = await showDatePicker(
                context: context,
                initialDate: value ?? now,
                firstDate: firstDate ?? DateTime(now.year - 10),
                lastDate: DateTime(now.year + 2),
                helpText: label,
                cancelText: 'Cancelar',
                confirmText: 'Listo',
              );
              if (picked != null) {
                onChanged(picked);
                if (field.hasError) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (field.mounted) field.validate();
                  });
                }
              }
            },
            style: OutlinedButton.styleFrom(alignment: Alignment.centerLeft),
            icon: const Icon(AppIcons.calendar, size: AppSize.iconSm),
            label: Text(
              value == null ? 'Elegir fecha' : Formatters.date(value!),
            ),
          ),
          if (field.hasError) FieldError(message: field.errorText ?? ''),
        ],
      ),
    );
  }
}
