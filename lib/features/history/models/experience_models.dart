import 'package:flutter/widgets.dart';

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
  etapa('Hitos de etapa', AppIcons.cycle);

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

  IconData get icon => switch (type) {
        TimelineEventType.insumo => AppIcons.application,
        TimelineEventType.labor => AppIcons.task,
        TimelineEventType.plaga => AppIcons.incident,
        TimelineEventType.etapa => AppIcons.cycle,
        _ => AppIcons.leaf,
      };

  bool get hasPhotos => photoBefore != null || photoAfter != null;
}

/// Registro consolidado para la búsqueda de aprendizajes previos.
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
  });

  final String crop;
  final String plotName;
  final DateTime date;
  final String title;
  final String category;
  final String? verdict;
  final String? observation;
  final String? photoPath;
}
