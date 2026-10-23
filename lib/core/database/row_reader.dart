/// Lectura tipada y segura de filas de SQLite (compatible con `strict-casts`).
extension RowReader on Map<String, Object?> {
  int integer(String key) => (this[key] as num).toInt();

  int? integerOrNull(String key) => (this[key] as num?)?.toInt();

  double decimal(String key) => (this[key] as num? ?? 0).toDouble();

  double? decimalOrNull(String key) => (this[key] as num?)?.toDouble();

  String text(String key) => this[key] as String? ?? '';

  /// Texto opcional; las cadenas vacías se tratan como `null`.
  String? textOrNull(String key) {
    final value = this[key] as String?;
    return (value == null || value.isEmpty) ? null : value;
  }

  DateTime date(String key) =>
      DateTime.fromMillisecondsSinceEpoch(integer(key));

  DateTime? dateOrNull(String key) {
    final value = integerOrNull(key);
    return value == null ? null : DateTime.fromMillisecondsSinceEpoch(value);
  }
}

/// Utilidades para escribir valores en SQLite.
abstract final class DbValue {
  static int? date(DateTime? d) => d?.millisecondsSinceEpoch;

  /// Guarda `null` en vez de cadenas vacías.
  static String? text(String? s) {
    final trimmed = s?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }

  static int now() => DateTime.now().millisecondsSinceEpoch;
}
