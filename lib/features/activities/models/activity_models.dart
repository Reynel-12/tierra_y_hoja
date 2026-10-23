import 'package:flutter/widgets.dart';

import '../../../core/database/row_reader.dart';
import '../../../core/design/app_colors.dart';
import '../../../core/design/app_icons.dart';
import '../../../core/utils/choice_option.dart';

/// Tipos de labores culturales mecánicas o manuales.
enum TaskType implements ChoiceOption {
  preparacionTierra('Preparación de tierra', AppIcons.tractor),
  deshierbeChapea('Deshierbe o chapea', AppIcons.scissors),
  aporco('Aporco', AppIcons.task),
  deschuponadoTutorado('Deschuponado o tutorado', AppIcons.tree),
  riego('Riego realizado', AppIcons.water),
  poda('Poda o raleo', AppIcons.scissors),
  otra('Otra labor', AppIcons.task);

  const TaskType(this.label, this.icon);

  @override
  final String label;

  @override
  final IconData icon;
}

/// Registro de una labor cultural.
class CulturalTask {
  const CulturalTask({
    this.id,
    required this.cycleId,
    required this.taskType,
    this.method,
    required this.date,
    this.irrigationHours,
    this.irrigationMm,
    this.workers,
    this.notes,
    this.photoPath,
    required this.createdAt,
    this.cropTitle = '',
    this.plotName = '',
  });

  final int? id;
  final int cycleId;
  final TaskType taskType;
  final String? method;
  final DateTime date;
  final double? irrigationHours;
  final double? irrigationMm;
  final int? workers;
  final String? notes;
  final String? photoPath;
  final DateTime createdAt;

  final String cropTitle;
  final String plotName;

  int? get peopleCount => workers;
  String? get photoBefore => photoPath;
  String? get photoAfter => null;

  factory CulturalTask.fromRow(
    Map<String, Object?> row, {
    String cropTitle = '',
    String plotName = '',
  }) {
    return CulturalTask(
      id: row.integerOrNull('id'),
      cycleId: row.integer('cycle_id'),
      taskType: enumFromName(TaskType.values, row['task_type'], TaskType.preparacionTierra),
      method: row.textOrNull('method'),
      date: row.date('date'),
      irrigationHours: row.decimalOrNull('irrigation_hours'),
      irrigationMm: row.decimalOrNull('irrigation_mm'),
      workers: row.integerOrNull('workers'),
      notes: row.textOrNull('notes'),
      photoPath: row.textOrNull('photo_path'),
      createdAt: row.date('created_at'),
      cropTitle: row.textOrNull('crop_title') ?? cropTitle,
      plotName: row.textOrNull('plot_name') ?? plotName,
    );
  }

  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      'cycle_id': cycleId,
      'task_type': taskType.name,
      'method': method,
      'date': date.millisecondsSinceEpoch,
      'irrigation_hours': irrigationHours,
      'irrigation_mm': irrigationMm,
      'workers': workers,
      'notes': notes,
      'photo_path': photoPath,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }
}

/// Tipo de incidencia: plaga, enfermedad o clima adverso.
enum IncidentKind implements ChoiceOption {
  plaga('Plaga de insectos', AppIcons.pest),
  enfermedad('Enfermedad o hongo', AppIcons.disease),
  clima('Clima o evento adverso', AppIcons.climate);

  const IncidentKind(this.label, this.icon);

  @override
  final String label;

  @override
  final IconData icon;
}

/// Severidad de la plaga o evento climático (§8 y §4):
/// Leve -> Moderada -> Crítica con iconos de barras y colores correspondientes.
enum IncidentSeverity implements ChoiceOption {
  leve('Leve', AppIcons.severityLow),
  moderada('Moderada', AppIcons.severityMedium),
  critica('Crítica', AppIcons.severityHigh);

  const IncidentSeverity(this.label, this.icon);

  @override
  final String label;

  @override
  final IconData icon;

  Color color(AppColors c) => switch (this) {
        IncidentSeverity.leve => c.neutral,
        IncidentSeverity.moderada => c.accentText,
        IncidentSeverity.critica => c.negative,
      };
}

/// Registro de una incidencia, plaga o evento climático.
class Incident {
  const Incident({
    this.id,
    required this.cycleId,
    required this.kind,
    required this.name,
    required this.severity,
    required this.date,
    this.actionTaken,
    this.notes,
    this.photoPath,
    required this.createdAt,
    this.cropTitle = '',
    this.plotName = '',
  });

  final int? id;
  final int cycleId;
  final IncidentKind kind;
  final String name;
  final IncidentSeverity severity;
  final DateTime date;
  final String? actionTaken;
  final String? notes;
  final String? photoPath;
  final DateTime createdAt;

  final String cropTitle;
  final String plotName;

  String get title => name;
  String? get description => notes;

  factory Incident.fromRow(
    Map<String, Object?> row, {
    String cropTitle = '',
    String plotName = '',
  }) {
    return Incident(
      id: row.integerOrNull('id'),
      cycleId: row.integer('cycle_id'),
      kind: enumFromName(IncidentKind.values, row['kind'], IncidentKind.plaga),
      name: row.text('name'),
      severity: enumFromName(IncidentSeverity.values, row['severity'], IncidentSeverity.moderada),
      date: row.date('date'),
      actionTaken: row.textOrNull('action_taken'),
      notes: row.textOrNull('notes'),
      photoPath: row.textOrNull('photo_path'),
      createdAt: row.date('created_at'),
      cropTitle: row.textOrNull('crop_title') ?? cropTitle,
      plotName: row.textOrNull('plot_name') ?? plotName,
    );
  }

  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      'cycle_id': cycleId,
      'kind': kind.name,
      'name': name,
      'severity': severity.name,
      'date': date.millisecondsSinceEpoch,
      'action_taken': actionTaken,
      'notes': notes,
      'photo_path': photoPath,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }
}
