import 'formatters.dart';

/// Validadores de formulario. Cada mensaje dice qué pasó y cómo arreglarlo.
abstract final class Validators {
  /// Campo de texto obligatorio.
  static String? Function(String?) required(String message) =>
      (value) => (value == null || value.trim().isEmpty) ? message : null;

  /// Número opcional: si se escribe, debe ser válido y no negativo.
  static String? optionalNumber(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final parsed = Formatters.parseNumber(value);
    if (parsed == null) {
      return 'Ese número no se entiende. Use solo cifras, por ejemplo 2.5';
    }
    if (parsed < 0) return 'El número no puede ser negativo.';
    return null;
  }

  /// Número obligatorio mayor que cero.
  static String? Function(String?) requiredPositive(String missingMessage) =>
      (value) {
        if (value == null || value.trim().isEmpty) return missingMessage;
        final parsed = Formatters.parseNumber(value);
        if (parsed == null) {
          return 'Ese número no se entiende. Use solo cifras, por ejemplo 2.5';
        }
        if (parsed <= 0) return 'Escriba una cantidad mayor que cero.';
        return null;
      };

  /// Monto de dinero obligatorio mayor que cero.
  static String? Function(String?) requiredMoney(String missingMessage) =>
      requiredPositive(missingMessage);

  /// Valor obligatorio en selectores (chips, segmentados, listas).
  static String? Function(T?) requiredSelection<T>(String message) =>
      (value) => value == null ? message : null;
}
