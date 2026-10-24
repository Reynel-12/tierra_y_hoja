import 'package:flutter/widgets.dart';

import '../../../core/database/row_reader.dart';
import '../../../core/design/app_icons.dart';
import '../../../core/utils/choice_option.dart';
import '../../../core/widgets/form/verdict_tiles.dart';
import 'symptoms_data.dart';

export 'symptoms_data.dart';

/// Tipo de insumo agrícola aplicado al cultivo.
enum InputType implements ChoiceOption {
  fertilizanteGranular('Fertilizante granular', AppIcons.grains),
  foliar('Foliar (Calcio, Boro, etc.)', AppIcons.leaf),
  biofertilizante('Biofertilizante', AppIcons.plant),
  enmienda('Enmienda (cal, orgánica)', AppIcons.tree),
  insecticida('Insecticida', AppIcons.bug),
  fungicida('Fungicida', AppIcons.pottedPlant),
  herbicida('Herbicida', AppIcons.scissors);

  const InputType(this.label, this.icon);

  @override
  final String label;

  @override
  final IconData icon;
}

/// Unidades comunes de dosis agrícola.
enum DoseUnit implements ChoiceOption {
  copasBomba('Copas / Bomba 20L', 'copas/bomba', AppIcons.sprayBottle),
  ccLitro('cc / Litro de agua', 'cc/L', AppIcons.sprayBottle),
  quintalesManzana('Quintales / Manzana', 'qq/mz', AppIcons.package),
  gramosPlanta('Gramos / Planta', 'g/planta', AppIcons.scales),
  litrosManzana('Litros / Manzana', 'L/mz', AppIcons.water),
  kilogramosManzana('Kg / Manzana', 'kg/mz', AppIcons.scales);

  const DoseUnit(this.label, this.symbol, this.icon);

  @override
  final String label;

  final String symbol;

  @override
  final IconData icon;
}

/// Momento / hora del día de la aplicación.
enum TimeOfDayChoice implements ChoiceOption {
  morning('Mañana fresca', AppIcons.morning),
  noon('Mediodía', AppIcons.noon),
  afternoon('Tarde', AppIcons.afternoon);

  const TimeOfDayChoice(this.label, this.icon);

  @override
  final String label;

  @override
  final IconData icon;
}

/// Condiciones climáticas observadas al momento de aplicar.
enum WeatherCondition implements ChoiceOption {
  sunny('Soleado', AppIcons.sunny),
  cloudy('Nublado', AppIcons.cloudy),
  wetSoil('Suelo húmedo', AppIcons.wetSoil),
  rainAfter('Lluvia posterior', AppIcons.rainAfter);

  const WeatherCondition(this.label, this.icon);

  @override
  final String label;

  @override
  final IconData icon;
}

/// Registro de una aplicación de insumos en la bitácora de campo.
class InputApplication {
  const InputApplication({
    this.id,
    required this.cycleId,
    required this.inputType,
    required this.productName,
    this.doseValue,
    this.doseUnit,
    this.method,
    required this.appliedAt,
    this.timeOfDay,
    this.weather,
    this.reviewDueAt,
    this.verdict,
    this.reactionNotes,
    this.symptoms,
    this.reviewedAt,
    this.photoBefore,
    this.photoAfter,
    this.notes,
    required this.createdAt,
    this.cropTitle = '',
    this.plotName = '',
  });

  final int? id;
  final int cycleId;
  final InputType inputType;
  final String productName;
  final double? doseValue;
  final DoseUnit? doseUnit;
  final String? method;
  final DateTime appliedAt;
  final TimeOfDayChoice? timeOfDay;
  final WeatherCondition? weather;
  final DateTime? reviewDueAt;
  final ReactionVerdict? verdict;
  final String? reactionNotes;
  final String? symptoms;
  final DateTime? reviewedAt;
  final String? photoBefore;
  final String? photoAfter;
  final String? notes;
  final DateTime createdAt;

  // Propiedades unidas para mostrar en tarjetas globales
  final String cropTitle;
  final String plotName;

  bool get hasReviewed => verdict != null;

  bool get isPendingReview {
    if (verdict != null || reviewDueAt == null) return false;
    return true;
  }

  bool get needsFollowUp => isPendingReview;
  ReactionVerdict? get followUpVerdict => verdict;
  String? get followUpNotes => reactionNotes;

  bool get isDueTodayOrPast {
    if (!isPendingReview || reviewDueAt == null) return false;
    final now = DateTime.now();
    return reviewDueAt!.isBefore(now) ||
        (reviewDueAt!.year == now.year &&
            reviewDueAt!.month == now.month &&
            reviewDueAt!.day == now.day);
  }

  String get doseDisplay {
    if (doseValue == null) return '';
    final val = doseValue == doseValue!.roundToDouble()
        ? doseValue!.toInt().toString()
        : doseValue.toString();
    return '$val ${doseUnit?.label ?? ''}';
  }

  /// Desglosa los síntomas registrados en chips estándar y notas de fitotoxicidad.
  SymptomsData get parsedSymptoms => SymptomsData.parse(symptoms);

  factory InputApplication.fromRow(
    Map<String, Object?> row, {
    String cropTitle = '',
    String plotName = '',
  }) {
    return InputApplication(
      id: row.integerOrNull('id'),
      cycleId: row.integer('cycle_id'),
      inputType: enumFromName(
        InputType.values,
        row['input_type'],
        InputType.fertilizanteGranular,
      ),
      productName: row.text('product_name'),
      doseValue: row.decimalOrNull('dose_value'),
      doseUnit: enumFromNameOrNull(DoseUnit.values, row['dose_unit']),
      method: row.textOrNull('method'),
      appliedAt: row.date('applied_at'),
      timeOfDay: enumFromNameOrNull(TimeOfDayChoice.values, row['time_of_day']),
      weather: enumFromNameOrNull(WeatherCondition.values, row['weather']),
      reviewDueAt: row.dateOrNull('review_due_at'),
      verdict: enumFromNameOrNull(ReactionVerdict.values, row['verdict']),
      reactionNotes: row.textOrNull('reaction_notes'),
      symptoms: row.textOrNull('symptoms'),
      reviewedAt: row.dateOrNull('reviewed_at'),
      photoBefore: row.textOrNull('photo_before'),
      photoAfter: row.textOrNull('photo_after'),
      notes: row.textOrNull('notes'),
      createdAt: row.date('created_at'),
      cropTitle: row.textOrNull('crop_title') ?? cropTitle,
      plotName: row.textOrNull('plot_name') ?? plotName,
    );
  }

  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      'cycle_id': cycleId,
      'input_type': inputType.name,
      'product_name': productName,
      'dose_value': doseValue,
      'dose_unit': doseUnit?.name,
      'method': method,
      'applied_at': appliedAt.millisecondsSinceEpoch,
      'time_of_day': timeOfDay?.name,
      'weather': weather?.name,
      'review_due_at': reviewDueAt?.millisecondsSinceEpoch,
      'verdict': verdict?.name,
      'reaction_notes': reactionNotes,
      'symptoms': symptoms,
      'reviewed_at': reviewedAt?.millisecondsSinceEpoch,
      'photo_before': photoBefore,
      'photo_after': photoAfter,
      'notes': notes,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  InputApplication copyWith({
    int? id,
    int? cycleId,
    InputType? inputType,
    String? productName,
    double? doseValue,
    DoseUnit? doseUnit,
    String? method,
    DateTime? appliedAt,
    TimeOfDayChoice? timeOfDay,
    WeatherCondition? weather,
    DateTime? reviewDueAt,
    ReactionVerdict? verdict,
    String? reactionNotes,
    String? symptoms,
    DateTime? reviewedAt,
    String? photoBefore,
    String? photoAfter,
    String? notes,
    DateTime? createdAt,
    String? cropTitle,
    String? plotName,
  }) {
    return InputApplication(
      id: id ?? this.id,
      cycleId: cycleId ?? this.cycleId,
      inputType: inputType ?? this.inputType,
      productName: productName ?? this.productName,
      doseValue: doseValue ?? this.doseValue,
      doseUnit: doseUnit ?? this.doseUnit,
      method: method ?? this.method,
      appliedAt: appliedAt ?? this.appliedAt,
      timeOfDay: timeOfDay ?? this.timeOfDay,
      weather: weather ?? this.weather,
      reviewDueAt: reviewDueAt ?? this.reviewDueAt,
      verdict: verdict ?? this.verdict,
      reactionNotes: reactionNotes ?? this.reactionNotes,
      symptoms: symptoms ?? this.symptoms,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      photoBefore: photoBefore ?? this.photoBefore,
      photoAfter: photoAfter ?? this.photoAfter,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      cropTitle: cropTitle ?? this.cropTitle,
      plotName: plotName ?? this.plotName,
    );
  }
}
