/// Estructura para separar los síntomas estándar (chips) de las notas
/// detalladas de fitotoxicidad ingresadas por el agricultor o usuario.
class SymptomsData {
  const SymptomsData({
    this.chips = const {},
    this.notes,
  });

  /// Conjunto de síntomas estándar seleccionados (chips).
  final Set<String> chips;

  /// Detalle libre o notas dictadas por voz sobre la fitotoxicidad.
  final String? notes;

  bool get hasChips => chips.isNotEmpty;
  bool get hasNotes => notes != null && notes!.trim().isNotEmpty;
  bool get isEmpty => !hasChips && !hasNotes;
  bool get isNotEmpty => !isEmpty;

  /// Lista estándar de síntomas para chips rápidos.
  static const defaultSymptoms = [
    'Hoja quemada',
    'Amarillamiento',
    'Marchitez',
    'Caída de flor',
    'Manchas foliares',
    'Detención de crecimiento',
  ];

  /// Lista expandida con variantes comunes para reconocimiento histórico.
  static const recognizedSymptoms = [
    'Hoja quemada',
    'Hojas quemadas',
    'Amarillamiento',
    'Marchitez',
    'Caída de flor',
    'Caída de hojas',
    'Manchas foliares',
    'Manchas necróticas',
    'Detención de crecimiento',
  ];

  static const String notesHeader = 'Detalle de fitotoxicidad:';
  static const String delimiter = '\n\n$notesHeader\n';

  /// Serializa los chips seleccionados y las notas a una sola cadena
  /// compatible para almacenamiento en base de datos.
  static String? format(Set<String> chips, String? notes) {
    final cleanNotes = notes?.trim();
    final hasChips = chips.isNotEmpty;
    final hasNotes = cleanNotes != null && cleanNotes.isNotEmpty;

    if (!hasChips && !hasNotes) return null;

    final chipsStr = chips.join(', ');
    if (hasChips && hasNotes) {
      return '$chipsStr$delimiter$cleanNotes';
    } else if (hasNotes) {
      return '$notesHeader\n$cleanNotes';
    } else {
      return chipsStr;
    }
  }

  /// Parsea una cadena de síntomas, compatible tanto con el nuevo formato
  /// estructurado como con registros históricos guardados previamente.
  factory SymptomsData.parse(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return const SymptomsData();
    }

    final trimmed = raw.trim();

    // 1. Formato estructurado nuevo con delimitador (chips + notas)
    if (trimmed.contains(delimiter)) {
      final parts = trimmed.split(delimiter);
      final chipsPart = parts[0].trim();
      final notesPart = parts.sublist(1).join(delimiter).trim();
      final chips = chipsPart.isEmpty
          ? <String>{}
          : chipsPart
              .split(',')
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toSet();
      return SymptomsData(
        chips: chips,
        notes: notesPart.isEmpty ? null : notesPart,
      );
    }

    // 2. Formato estructurado nuevo solo con notas (con cabecera estándar)
    if (trimmed.startsWith(notesHeader)) {
      final notesPart = trimmed.substring(notesHeader.length).trim();
      return SymptomsData(
        chips: const {},
        notes: notesPart.isEmpty ? null : notesPart,
      );
    }

    // 2b. Formato con prefijo alternativo común
    const altHeader = 'Detalle o notas de fitotoxicidad:';
    if (trimmed.startsWith(altHeader)) {
      final notesPart = trimmed.substring(altHeader.length).trim();
      return SymptomsData(
        chips: const {},
        notes: notesPart.isEmpty ? null : notesPart,
      );
    }

    // 3. Formato histórico (separado por comas) o texto libre
    final commaTokens = trimmed.split(',');
    final chips = <String>{};
    int? firstNonChipIndex;

    for (var i = 0; i < commaTokens.length; i++) {
      final token = commaTokens[i].trim();
      if (firstNonChipIndex == null && recognizedSymptoms.contains(token)) {
        chips.add(token);
      } else {
        firstNonChipIndex = i;
        break;
      }
    }

    String? notes;
    if (firstNonChipIndex != null) {
      notes = commaTokens.sublist(firstNonChipIndex).join(',').trim();
    }

    return SymptomsData(
      chips: chips,
      notes: (notes == null || notes.isEmpty) ? null : notes,
    );
  }
}
