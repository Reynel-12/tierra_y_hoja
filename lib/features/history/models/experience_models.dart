import 'package:flutter/widgets.dart';

import '../../../core/design/app_colors.dart';
import '../../../core/design/app_icons.dart';
import '../../../core/utils/choice_option.dart';
import '../../activities/models/activity_models.dart';
import '../../cycles/models/crop_cycle.dart';
import '../../field_log/models/input_application.dart';

/// Tipos de eventos que integran la bitácora unificada.
enum TimelineEventType implements ChoiceOption {
  todos('Todos los eventos', AppIcons.filter),
  insumo('Insumos y foliares', AppIcons.application),
  labor('Labores culturales', AppIcons.task),
  plaga('Plagas y clima', AppIcons.incident),
  etapa('Hitos de etapa', AppIcons.cycle),
  cosecha('Cosechas y cierres', AppIcons.harvest);

  const TimelineEventType(this.label, this.icon);

  @override
  final String label;

  @override
  final IconData icon;
}

/// Registro unificado cronológico para la línea de tiempo.
class UnifiedTimelineItem {
  const UnifiedTimelineItem({
    required this.id,
    required this.type,
    required this.cycleId,
    required this.title,
    this.subtitle,
    required this.date,
    this.photoBefore,
    this.photoAfter,
    this.badgeText,
    this.notes,
    this.application,
    this.task,
    this.incident,
    this.stageEvent,
    this.cropTitle,
    this.plotName,
  });

  final int id;
  final TimelineEventType type;
  final int cycleId;
  final String title;
  final String? subtitle;
  final DateTime date;
  final String? photoBefore;
  final String? photoAfter;
  final String? badgeText;
  final String? notes;

  final InputApplication? application;
  final CulturalTask? task;
  final Incident? incident;
  final StageEvent? stageEvent;
  final String? cropTitle;
  final String? plotName;

  IconData get icon => switch (type) {
    TimelineEventType.insumo => AppIcons.application,
    TimelineEventType.labor => AppIcons.task,
    TimelineEventType.plaga => AppIcons.incident,
    TimelineEventType.etapa => AppIcons.cycle,
    TimelineEventType.cosecha => AppIcons.harvest,
    _ => AppIcons.leaf,
  };

  bool get hasPhotos =>
      (photoBefore != null && photoBefore!.trim().isNotEmpty) ||
      (photoAfter != null && photoAfter!.trim().isNotEmpty);
}

/// Resultado paginado genérico para consultas de historial y memoria.
class PaginatedResult<T> {
  const PaginatedResult({
    required this.items,
    required this.totalCount,
    required this.hasMore,
  });

  final List<T> items;
  final int totalCount;
  final bool hasMore;
}

/// Registro consolidado para la búsqueda de aprendizajes previos y memoria general.
class LearningResult {
  const LearningResult({
    required this.crop,
    required this.plotName,
    required this.date,
    required this.title,
    required this.category,
    this.verdict,
    this.observation,
    this.photoPath,
    this.type = TimelineEventType.todos,
    this.id,
    this.cycleId,
    this.application,
    this.task,
    this.incident,
    this.stageEvent,
    this.whatWorked,
    this.whatFailed,
    this.yieldValue,
    this.yieldUnit,
    this.quality,
    this.variety,
    this.notes,
    this.method,
    this.weather,
    this.timeOfDay,
    this.doseDisplay,
    this.photoBefore,
    this.photoAfter,
    this.symptoms,
    this.reactionNotes,
    this.reviewDueAt,
    this.reviewedAt,
    this.actionTaken,
    this.workers,
    this.irrigationHours,
    this.irrigationMm,
  });

  final String crop;
  final String plotName;
  final DateTime date;
  final String title;
  final String category;
  final String? verdict;
  final String? observation;
  final String? photoPath;
  final TimelineEventType type;
  final int? id;
  final int? cycleId;

  // Modelos y campos detallados para visualización exhaustiva
  final InputApplication? application;
  final CulturalTask? task;
  final Incident? incident;
  final StageEvent? stageEvent;
  final String? whatWorked;
  final String? whatFailed;
  final double? yieldValue;
  final String? yieldUnit;
  final String? quality;
  final String? variety;
  final String? notes;
  final String? method;
  final WeatherCondition? weather;
  final TimeOfDayChoice? timeOfDay;
  final String? doseDisplay;
  final String? photoBefore;
  final String? photoAfter;
  final String? symptoms;
  final String? reactionNotes;
  final DateTime? reviewDueAt;
  final DateTime? reviewedAt;
  final String? actionTaken;
  final int? workers;
  final double? irrigationHours;
  final double? irrigationMm;

  IconData get icon => switch (type) {
    TimelineEventType.insumo => AppIcons.application,
    TimelineEventType.labor => AppIcons.task,
    TimelineEventType.plaga => AppIcons.incident,
    TimelineEventType.etapa => AppIcons.cycle,
    TimelineEventType.cosecha => AppIcons.harvest,
    _ => AppIcons.leaf,
  };

  Color color(AppColors c) => switch (type) {
    TimelineEventType.insumo => c.primary,
    TimelineEventType.labor => c.accentText,
    TimelineEventType.plaga => c.negative,
    TimelineEventType.etapa => c.info,
    TimelineEventType.cosecha => c.positive,
    _ => c.primary,
  };

  /// Convierte este resultado de memoria en un [UnifiedTimelineItem] completo
  /// para reusar el visualizador de eventos y modales de detalle.
  UnifiedTimelineItem toTimelineItem() {
    return UnifiedTimelineItem(
      id: id ?? 0,
      type: type,
      cycleId: cycleId ?? 0,
      title: title,
      subtitle: switch (type) {
        TimelineEventType.insumo =>
          (application?.doseDisplay.isNotEmpty == true
              ? 'Dosis: ${application!.doseDisplay}'
              : (doseDisplay != null && doseDisplay!.isNotEmpty
                    ? 'Dosis: $doseDisplay'
                    : null)),
        TimelineEventType.labor =>
          (task?.peopleCount != null
              ? '${task!.peopleCount} personas'
              : (workers != null && workers! > 0 ? '$workers personas' : null)),
        TimelineEventType.plaga =>
          (incident?.actionTaken != null && incident!.actionTaken!.isNotEmpty
              ? 'Acción: ${incident!.actionTaken}'
              : (actionTaken != null && actionTaken!.isNotEmpty
                    ? 'Acción: $actionTaken'
                    : verdict)),
        TimelineEventType.cosecha =>
          (yieldValue != null
              ? 'Rendimiento: ${yieldValue == yieldValue!.roundToDouble() ? yieldValue!.toInt() : yieldValue} ${yieldUnit ?? ''}'
              : verdict),
        _ => null,
      },
      date: date,
      photoBefore: photoBefore ?? photoPath,
      photoAfter: photoAfter,
      badgeText: verdict,
      notes: notes ?? observation,
      application: application,
      task: task,
      incident: incident,
      stageEvent: stageEvent,
      cropTitle: crop,
      plotName: plotName,
    );
  }
}
