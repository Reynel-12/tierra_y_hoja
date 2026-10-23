import 'package:flutter/widgets.dart';

import '../../../core/database/row_reader.dart';
import '../../../core/design/app_colors.dart';
import '../../../core/design/app_icons.dart';
import '../../../core/utils/choice_option.dart';
import '../../../core/utils/formatters.dart';

/// Estados del ciclo de siembra según el diseño §2.3.
enum CropStage implements ChoiceOption {
  prep('En preparación', AppIcons.task),
  growth('En desarrollo', AppIcons.cycle),
  flower('En floración', AppIcons.flower),
  harvest('En cosecha', AppIcons.harvest),
  done('Finalizado', AppIcons.checkCircle);

  const CropStage(this.label, this.icon);

  @override
  final String label;

  @override
  final IconData icon;

  Color color(AppColors c) => switch (this) {
        CropStage.prep => c.stagePrep,
        CropStage.growth => c.stageGrowth,
        CropStage.flower => c.stageFlower,
        CropStage.harvest => c.stageHarvest,
        CropStage.done => c.stageDone,
      };
}

/// Unidades de densidad de siembra.
enum DensityUnit implements ChoiceOption {
  libras('Libras de semilla', 'lb', AppIcons.grains),
  plantulas('Plántulas trasplantadas', 'plántulas', AppIcons.pottedPlant),
  sacos('Sacos de semilla', 'sacos', AppIcons.package),
  distanciaSurcos('Distanciamiento (m)', 'm', AppIcons.ruler);

  const DensityUnit(this.label, this.symbol, this.icon);

  @override
  final String label;

  final String symbol;

  @override
  final IconData icon;
}

/// Unidades de rendimiento de cosecha.
enum YieldUnit implements ChoiceOption {
  quintales('Quintales', 'qq', AppIcons.harvest),
  cajas('Cajas', 'cajas', AppIcons.package),
  sacos('Sacos', 'sacos', AppIcons.package),
  libras('Libras', 'lb', AppIcons.scales),
  toneladas('Toneladas', 't', AppIcons.truck);

  const YieldUnit(this.label, this.symbol, this.icon);

  @override
  final String label;

  final String symbol;

  @override
  final IconData icon;
}

/// Calidad general de la cosecha.
enum CropQuality implements ChoiceOption {
  primera('Primera (óptima)', AppIcons.checkCircle),
  segunda('Segunda (estándar)', AppIcons.minusCircle),
  descarte('Descarte / Merma', AppIcons.warning);

  const CropQuality(this.label, this.icon);

  @override
  final String label;

  @override
  final IconData icon;
}

/// Evento de hito de cambio de etapa en la vida del cultivo.
class StageEvent {
  const StageEvent({
    this.id,
    required this.cycleId,
    required this.stage,
    required this.date,
  });

  final int? id;
  final int cycleId;
  final CropStage stage;
  final DateTime date;

  factory StageEvent.fromRow(Map<String, Object?> row) {
    return StageEvent(
      id: row.integerOrNull('id'),
      cycleId: row.integer('cycle_id'),
      stage: enumFromName(CropStage.values, row['stage'], CropStage.prep),
      date: row.date('date'),
    );
  }

  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      'cycle_id': cycleId,
      'stage': stage.name,
      'date': date.millisecondsSinceEpoch,
    };
  }
}

/// Entidad inmutable que representa un ciclo de siembra o campaña agrícola.
class CropCycle {
  const CropCycle({
    this.id,
    required this.plotId,
    this.plotName = '',
    required this.crop,
    this.variety,
    required this.plantingDate,
    this.densityValue,
    this.densityUnit,
    this.densityNotes,
    required this.stage,
    this.harvestStart,
    this.harvestEnd,
    this.yieldValue,
    this.yieldUnit,
    this.quality,
    this.whatWorked,
    this.whatFailed,
    required this.createdAt,
    required this.updatedAt,
  });

  final int? id;
  final int plotId;
  final String plotName;
  final String crop;
  final String? variety;
  final DateTime plantingDate;
  final double? densityValue;
  final DensityUnit? densityUnit;
  final String? densityNotes;
  final CropStage stage;
  final DateTime? harvestStart;
  final DateTime? harvestEnd;
  final double? yieldValue;
  final YieldUnit? yieldUnit;
  final CropQuality? quality;
  final String? whatWorked;
  final String? whatFailed;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isClosed => stage == CropStage.done;

  /// Título compuesto: "Tomate pólder" o simplemente "Tomate".
  String get title => (variety == null || variety!.trim().isEmpty)
      ? crop
      : '$crop $variety';

  /// Días transcurridos desde la siembra hasta hoy o hasta la cosecha.
  int get daysSincePlanting {
    final endDate = harvestEnd ?? DateTime.now();
    return DateUtilsX.dayNumber(plantingDate, at: endDate).clamp(0, 9999);
  }

  /// Progreso estimado (0 a 1) para la barra de 4 px (§7.6).
  double get estimatedProgress => switch (stage) {
        CropStage.prep => 0.10,
        CropStage.growth => 0.40,
        CropStage.flower => 0.70,
        CropStage.harvest => 0.90,
        CropStage.done => 1.0,
      };

  String get densityDisplay {
    if (densityValue == null) return densityNotes ?? '';
    final val = Formatters.editable(densityValue);
    return '$val ${densityUnit?.label ?? ''}';
  }

  String get yieldDisplay {
    if (yieldValue == null) return '';
    final val = Formatters.editable(yieldValue);
    return '$val ${yieldUnit?.label ?? ''}';
  }

  factory CropCycle.fromRow(Map<String, Object?> row, {String plotName = ''}) {
    return CropCycle(
      id: row.integerOrNull('id'),
      plotId: row.integer('plot_id'),
      plotName: row.textOrNull('plot_name') ?? plotName,
      crop: row.text('crop'),
      variety: row.textOrNull('variety'),
      plantingDate: row.date('planting_date'),
      densityValue: row.decimalOrNull('density_value'),
      densityUnit: enumFromNameOrNull(DensityUnit.values, row['density_unit']),
      densityNotes: row.textOrNull('density_notes'),
      stage: enumFromName(CropStage.values, row['stage'], CropStage.growth),
      harvestStart: row.dateOrNull('harvest_start'),
      harvestEnd: row.dateOrNull('harvest_end'),
      yieldValue: row.decimalOrNull('yield_value'),
      yieldUnit: enumFromNameOrNull(YieldUnit.values, row['yield_unit']),
      quality: enumFromNameOrNull(CropQuality.values, row['quality']),
      whatWorked: row.textOrNull('what_worked'),
      whatFailed: row.textOrNull('what_failed'),
      createdAt: row.date('created_at'),
      updatedAt: row.date('updated_at'),
    );
  }

  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      'plot_id': plotId,
      'crop': crop,
      'variety': variety,
      'planting_date': plantingDate.millisecondsSinceEpoch,
      'density_value': densityValue,
      'density_unit': densityUnit?.name,
      'density_notes': densityNotes,
      'stage': stage.name,
      'harvest_start': harvestStart?.millisecondsSinceEpoch,
      'harvest_end': harvestEnd?.millisecondsSinceEpoch,
      'yield_value': yieldValue,
      'yield_unit': yieldUnit?.name,
      'quality': quality?.name,
      'what_worked': whatWorked,
      'what_failed': whatFailed,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  CropCycle copyWith({
    int? id,
    int? plotId,
    String? plotName,
    String? crop,
    String? variety,
    DateTime? plantingDate,
    double? densityValue,
    DensityUnit? densityUnit,
    String? densityNotes,
    CropStage? stage,
    DateTime? harvestStart,
    DateTime? harvestEnd,
    double? yieldValue,
    YieldUnit? yieldUnit,
    CropQuality? quality,
    String? whatWorked,
    String? whatFailed,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CropCycle(
      id: id ?? this.id,
      plotId: plotId ?? this.plotId,
      plotName: plotName ?? this.plotName,
      crop: crop ?? this.crop,
      variety: variety ?? this.variety,
      plantingDate: plantingDate ?? this.plantingDate,
      densityValue: densityValue ?? this.densityValue,
      densityUnit: densityUnit ?? this.densityUnit,
      densityNotes: densityNotes ?? this.densityNotes,
      stage: stage ?? this.stage,
      harvestStart: harvestStart ?? this.harvestStart,
      harvestEnd: harvestEnd ?? this.harvestEnd,
      yieldValue: yieldValue ?? this.yieldValue,
      yieldUnit: yieldUnit ?? this.yieldUnit,
      quality: quality ?? this.quality,
      whatWorked: whatWorked ?? this.whatWorked,
      whatFailed: whatFailed ?? this.whatFailed,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
