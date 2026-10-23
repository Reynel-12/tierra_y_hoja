import 'package:intl/intl.dart';

import 'choice_option.dart';

/// Formatos de presentación (español, Lempiras, cifras con separadores).
abstract final class Formatters {
  static const locale = 'es';
  static const currencySymbol = 'L';

  static final _date = DateFormat('d \'de\' MMM yyyy', locale);
  static final _dateShort = DateFormat('d MMM', locale);
  static final _dateLong = DateFormat('EEEE d \'de\' MMMM', locale);
  static final _time = DateFormat('h:mm a', locale);
  static final _number = NumberFormat('#,##0.##', 'en_US');
  static final _money = NumberFormat('#,##0.00', 'en_US');
  static final _moneyCompact = NumberFormat('#,##0', 'en_US');

  /// 14 de oct. 2026
  static String date(DateTime d) => _date.format(d);

  /// 14 oct.
  static String dateShort(DateTime d) => _dateShort.format(d);

  /// Martes 14 de octubre
  static String dateLong(DateTime d) => _capitalize(_dateLong.format(d));

  /// 7:30 a. m.
  static String time(DateTime d) => _time.format(d);

  /// "Hoy", "Ayer", "Hace 3 días" o la fecha corta.
  static String relativeDay(DateTime d, {DateTime? now}) {
    final today = DateUtilsX.dateOnly(now ?? DateTime.now());
    final diff = today.difference(DateUtilsX.dateOnly(d)).inDays;
    if (diff == 0) return 'Hoy';
    if (diff == 1) return 'Ayer';
    if (diff == -1) return 'Mañana';
    if (diff > 1 && diff < 7) return 'Hace $diff días';
    if (diff < -1 && diff > -7) return 'En ${-diff} días';
    return date(d);
  }

  /// 1,234.5
  static String number(num value) => _number.format(value);

  /// L 1,234.50
  static String money(num value) =>
      '${value < 0 ? '-' : ''}$currencySymbol ${_money.format(value.abs())}';

  /// L 1,235 (sin decimales, para cifras héroe y gráficas).
  static String moneyCompact(num value) =>
      '${value < 0 ? '-' : ''}$currencySymbol ${_moneyCompact.format(value.abs())}';

  /// 18 %
  static String percent(num value) => '${_number.format(value)} %';

  /// 2.5 mz
  static String area(num value, [Object? unit]) {
    String sym = '';
    if (unit != null) {
      if (unit is Enum) {
        sym = switch (unit.name) {
          'manzanas' => 'mz',
          'hectareas' => 'ha',
          'tareas' => 'tareas',
          'metrosCuadrados' => 'm²',
          _ => unit.name,
        };
      } else if (unit is ChoiceOption) {
        sym = unit.label;
      } else {
        sym = unit.toString();
      }
    }
    final formatted = editable(value);
    return sym.isNotEmpty ? '$formatted $sym' : formatted;
  }

  /// Interpreta texto escrito por el usuario ("1,250.5" o "1250,5").
  static double? parseNumber(String? raw) {
    if (raw == null) return null;
    var text = raw.trim().replaceAll(' ', '');
    if (text.isEmpty) return null;
    final hasDot = text.contains('.');
    final hasComma = text.contains(',');
    if (hasDot && hasComma) {
      text = text.replaceAll(',', '');
    } else if (hasComma) {
      final parts = text.split(',');
      final looksDecimal = parts.length == 2 && parts.last.length <= 2;
      text = looksDecimal
          ? text.replaceAll(',', '.')
          : text.replaceAll(',', '');
    }
    return double.tryParse(text);
  }

  /// Número para rellenar un campo de texto (sin separador de miles).
  static String editable(num? value) {
    if (value == null) return '';
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toString();
  }

  static String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}

/// Utilidades de fecha sin dependencias de UI.
abstract final class DateUtilsX {
  static DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static DateTime today() => dateOnly(DateTime.now());

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Días transcurridos desde [start] (día de siembra = día 0).
  static int dayNumber(DateTime start, {DateTime? at}) =>
      dateOnly(at ?? DateTime.now()).difference(dateOnly(start)).inDays;

  static DateTime? fromMillis(Object? value) =>
      value is int ? DateTime.fromMillisecondsSinceEpoch(value) : null;
}
