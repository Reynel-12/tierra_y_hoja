import 'package:flutter/widgets.dart';

/// Contrato para opciones seleccionables (enums de dominio) que se muestran
/// en chips, segmentados y listas: siempre texto + icono opcional.
abstract interface class ChoiceOption {
  String get label;
  IconData? get icon;
}

/// Convierte un nombre guardado en la base de datos a su enum,
/// con un valor por defecto si el dato es desconocido o nulo.
T enumFromName<T extends Enum>(List<T> values, Object? name, T fallback) {
  if (name is! String) return fallback;
  for (final value in values) {
    if (value.name == name) return value;
  }
  return fallback;
}

/// Igual que [enumFromName] pero devuelve `null` si no hay coincidencia.
T? enumFromNameOrNull<T extends Enum>(List<T> values, Object? name) {
  if (name is! String) return null;
  for (final value in values) {
    if (value.name == name) return value;
  }
  return null;
}
