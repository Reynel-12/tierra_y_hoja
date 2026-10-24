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
        TimelineEventType.cosecha => AppIcons.harvest,
        _ => AppIcons.leaf,
      };

  bool get hasPhotos => photoBefore != null || photoAfter != null;
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
}

