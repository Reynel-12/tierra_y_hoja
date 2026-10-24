import 'package:flutter/material.dart';

import '../../../core/design/app_colors.dart';
import '../../../core/design/app_icons.dart';
import '../../../core/design/app_tokens.dart';
import '../../../core/design/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/badges.dart';
import '../../../core/widgets/dialogs.dart';
import '../../../core/widgets/media/photo_widgets.dart';
import '../../cycles/views/cycle_detail_view.dart';
import '../../field_log/models/input_application.dart';
import '../../field_log/views/follow_up_form_view.dart';
import '../models/experience_models.dart';

/// Modal bottom sheet con la información exhaustiva y completa de cualquier
/// evento de la bitácora o memoria (insumos, labores, plagas, cosechas).
///
/// Optimiza el espacio de las tarjetas y permite consultar todos los campos
/// registrados (método, clima, momento, dosis, notas iniciales, veredicto,
/// síntomas observados, notas de reacción, fecha de evaluación y fotos comparativas).
class EventDetailSheet extends StatelessWidget {
  const EventDetailSheet({
    super.key,
    required this.item,
    this.showCycleNavigation = true,
  });

  final UnifiedTimelineItem item;
  final bool showCycleNavigation;

  /// Abre el bottom sheet de detalle completo para un [UnifiedTimelineItem]
  /// o para un [LearningResult].
  static Future<void> show(
    BuildContext context, {
    UnifiedTimelineItem? item,
    LearningResult? learningResult,
    bool showCycleNavigation = true,
  }) {
    final effectiveItem = item ?? learningResult?.toTimelineItem();
    if (effectiveItem == null) return Future.value();

    return showAppSheet<void>(
      context,
      title: 'Detalle del evento',
      builder: (_) => EventDetailSheet(
        item: effectiveItem,
        showCycleNavigation: showCycleNavigation,
      ),
    );
  }

  Color _getEventColor(AppColors c) => switch (item.type) {
    TimelineEventType.insumo => c.primary,
    TimelineEventType.labor => c.accentText,
    TimelineEventType.plaga => c.negative,
    TimelineEventType.etapa => c.info,
    TimelineEventType.cosecha => c.positive,
    _ => c.primary,
  };

  String _getCategoryLabel() => switch (item.type) {
    TimelineEventType.insumo => 'APLICACIÓN DE INSUMO O FOLIAR',
    TimelineEventType.labor => 'LABOR CULTURAL AGRÍCOLA',
    TimelineEventType.plaga => 'INCIDENCIA, PLAGA O CLIMA',
    TimelineEventType.etapa => 'HITO DE ETAPA FENOLÓGICA',
    TimelineEventType.cosecha => 'COSECHA Y CIERRE DE CICLO',
    _ => 'EVENTO DE CAMPO',
  };

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final t = context.t;
    final eventColor = _getEventColor(c);

    final app = item.application;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. Cabecera contextual destacada
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleIcon(icon: item.icon, color: eventColor, size: 48),
            const SizedBox(width: AppSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getCategoryLabel(),
                    style: t.overline.copyWith(color: eventColor),
                  ),
                  const SizedBox(height: 2),
                  Text(item.title, style: t.title),
                  if (item.cropTitle != null || item.plotName != null) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          AppIcons.leaf,
                          size: AppSize.iconSm,
                          color: c.inkMuted,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            [
                              if (item.cropTitle != null &&
                                  item.cropTitle!.isNotEmpty)
                                item.cropTitle,
                              if (item.plotName != null &&
                                  item.plotName!.isNotEmpty)
                                'Lote: ${item.plotName}',
                            ].join(' · '),
                            style: t.bodySm.copyWith(color: c.inkMuted),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        AppIcons.calendar,
                        size: AppSize.iconSm,
                        color: c.inkMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(Formatters.date(item.date), style: t.caption),
                      if (app?.timeOfDay != null) ...[
                        const SizedBox(width: AppSpace.sm),
                        Icon(
                          app!.timeOfDay!.icon,
                          size: AppSize.iconSm,
                          color: c.inkMuted,
                        ),
                        const SizedBox(width: 4),
                        Text(app.timeOfDay!.label, style: t.caption),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: AppSpace.lg),
        const Divider(height: 1),
        const SizedBox(height: AppSpace.lg),

        // 2. Ficha de Datos Técnicos y Condiciones
        _buildTechnicalDataSection(context, c, t, eventColor),

        // 3. Notas y Observaciones iniciales de campo
        if (item.notes != null && item.notes!.isNotEmpty) ...[
          const SizedBox(height: AppSpace.md),
          _buildNotesSection(
            context,
            c,
            t,
            title: app != null
                ? 'Notas iniciales de la aplicación'
                : 'Notas registradas en campo',
            icon: AppIcons.note,
            notes: item.notes!,
          ),
        ],

        // 4. Sección especial de Seguimiento y Reacción Post-Insumo
        if (app != null) ...[
          const SizedBox(height: AppSpace.lg),
          _buildReactionFollowUpSection(context, c, t, app),
        ],

        // 5. Evidencias fotográficas (Antes / Después o evidencia única)
        if (item.hasPhotos) ...[
          const SizedBox(height: AppSpace.lg),
          _buildPhotoEvidenceSection(context, c, t),
        ],

        // 6. Cierre de siembra / cosechas (¿Qué funcionó? y ¿Qué falló?)
        if (item.type == TimelineEventType.cosecha) ...[
          const SizedBox(height: AppSpace.lg),
          _buildHarvestLessonsSection(context, c, t),
        ],

        const SizedBox(height: AppSpace.xl),

        // 7. Acciones del pie
        Row(
          children: [
            if (showCycleNavigation && item.cycleId > 0) ...[
              Expanded(
                child: AppButton.secondary(
                  label: 'Ver siembra completa',
                  icon: AppIcons.cycle,
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => CycleDetailView(cycleId: item.cycleId),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: AppSpace.md),
            ],
            Expanded(
              child: AppButton.outline(
                label: 'Cerrar',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Construye la cuadrícula de datos técnicos según el tipo de evento
  Widget _buildTechnicalDataSection(
    BuildContext context,
    AppColors c,
    AppTypography t,
    Color accentColor,
  ) {
    final app = item.application;
    final task = item.task;
    final incident = item.incident;

    return Container(
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: BoxDecoration(
        color: c.surfaceRaised,
        borderRadius: AppRadius.card,
        border: Border.all(color: c.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(AppIcons.info, size: AppSize.iconSm, color: accentColor),
              const SizedBox(width: AppSpace.xs),
              Text(
                'DATOS Y CONDICIONES DEL REGISTRO',
                style: t.overline.copyWith(color: accentColor),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.md),

          // En caso de Aplicación de Insumo
          if (app != null) ...[
            _DataRow(
              icon: app.inputType.icon,
              label: 'Tipo de insumo',
              value: app.inputType.label,
            ),
            const SizedBox(height: AppSpace.sm),
            _DataRow(
              icon: AppIcons.package,
              label: 'Producto aplicado',
              value: app.productName,
            ),
            if (app.doseDisplay.isNotEmpty) ...[
              const SizedBox(height: AppSpace.sm),
              _DataRow(
                icon: AppIcons.sprayBottle,
                label: 'Dosis / Dilución',
                value: app.doseDisplay,
                isHighlight: true,
              ),
            ],
            if (app.method != null && app.method!.isNotEmpty) ...[
              const SizedBox(height: AppSpace.sm),
              _DataRow(
                icon: AppIcons.tractor,
                label: 'Método de aplicación',
                value: app.method!,
              ),
            ],
            if (app.weather != null) ...[
              const SizedBox(height: AppSpace.sm),
              _DataRow(
                icon: app.weather!.icon,
                label: 'Clima observado',
                value: app.weather!.label,
              ),
            ],
            if (app.timeOfDay != null) ...[
              const SizedBox(height: AppSpace.sm),
              _DataRow(
                icon: app.timeOfDay!.icon,
                label: 'Momento del día',
                value: app.timeOfDay!.label,
              ),
            ],
          ],

          // En caso de Labor Cultural
          if (task != null) ...[
            _DataRow(
              icon: task.taskType.icon,
              label: 'Tipo de labor',
              value: task.taskType.label,
            ),
            if (task.method != null && task.method!.isNotEmpty) ...[
              const SizedBox(height: AppSpace.sm),
              _DataRow(
                icon: AppIcons.task,
                label: 'Método empleado',
                value: task.method!,
              ),
            ],
            if (task.peopleCount != null) ...[
              const SizedBox(height: AppSpace.sm),
              _DataRow(
                icon: AppIcons.users,
                label: 'Personal / Mano de obra',
                value: '${task.peopleCount} personas',
              ),
            ],
            if (task.irrigationHours != null || task.irrigationMm != null) ...[
              const SizedBox(height: AppSpace.sm),
              _DataRow(
                icon: AppIcons.water,
                label: 'Riego aplicado',
                value: [
                  if (task.irrigationHours != null)
                    '${task.irrigationHours} horas',
                  if (task.irrigationMm != null) '(${task.irrigationMm} mm)',
                ].join(' '),
              ),
            ],
          ],

          // En caso de Incidencia / Plaga
          if (incident != null) ...[
            _DataRow(
              icon: incident.kind.icon,
              label: 'Clasificación',
              value: incident.kind.label,
            ),
            const SizedBox(height: AppSpace.sm),
            _DataRow(
              icon: incident.severity.icon,
              label: 'Severidad',
              value: incident.severity.label,
              badgeColor: incident.severity.color(c),
            ),
            if (incident.actionTaken != null &&
                incident.actionTaken!.isNotEmpty) ...[
              const SizedBox(height: AppSpace.sm),
              _DataRow(
                icon: AppIcons.check,
                label: 'Acción de control tomada',
                value: incident.actionTaken!,
                isHighlight: true,
              ),
            ],
          ],

          // En caso de Hito o Cosecha
          if (app == null && task == null && incident == null) ...[
            if (item.subtitle != null && item.subtitle!.isNotEmpty) ...[
              _DataRow(
                icon: item.icon,
                label: 'Información del evento',
                value: item.subtitle!,
              ),
            ],
            if (item.badgeText != null && item.badgeText!.isNotEmpty) ...[
              const SizedBox(height: AppSpace.sm),
              _DataRow(
                icon: AppIcons.checkCircle,
                label: 'Estado / Veredicto',
                value: item.badgeText!,
                badgeColor: accentColor,
              ),
            ],
          ],
        ],
      ),
    );
  }

  /// Sección de Notas de campo con estilo de caja destacada
  Widget _buildNotesSection(
    BuildContext context,
    AppColors c,
    AppTypography t, {
    required String title,
    required IconData icon,
    required String notes,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: AppRadius.card,
        border: Border.all(color: c.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: AppSize.iconSm, color: c.inkSoft),
              const SizedBox(width: AppSpace.xs),
              Text(title, style: t.label),
            ],
          ),
          const SizedBox(height: AppSpace.xs),
          Text(notes, style: t.body),
        ],
      ),
    );
  }

  /// Sección detallada de Seguimiento y Reacción Posterior para Insumos
  Widget _buildReactionFollowUpSection(
    BuildContext context,
    AppColors c,
    AppTypography t,
    InputApplication app,
  ) {
    if (app.hasReviewed) {
      final verdict = app.verdict!;
      final verdictColor = verdict.color(c);

      return Container(
        padding: const EdgeInsets.all(AppSpace.md),
        decoration: BoxDecoration(
          color: verdictColor.withValues(alpha: 0.06),
          borderRadius: AppRadius.card,
          border: Border.all(color: verdictColor.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(verdict.icon, size: AppSize.iconMd, color: verdictColor),
                const SizedBox(width: AppSpace.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'EVALUACIÓN Y REACCIÓN OBSERVADA',
                        style: t.overline.copyWith(color: verdictColor),
                      ),
                      Text(
                        'Respuesta: ${verdict.label}',
                        style: t.titleSm.copyWith(color: verdictColor),
                      ),
                    ],
                  ),
                ),
                StatusBadge(
                  label: verdict.label,
                  icon: verdict.icon,
                  color: verdictColor,
                ),
              ],
            ),
            if (app.reviewedAt != null) ...[
              const SizedBox(height: AppSpace.xs),
              Text(
                'Evaluación efectuada el ${Formatters.date(app.reviewedAt!)}',
                style: t.caption.copyWith(color: c.inkMuted),
              ),
            ],

            // Síntomas observados
            if (app.symptoms != null && app.symptoms!.isNotEmpty) ...[
              const SizedBox(height: AppSpace.md),
              Text('Síntomas manifestados por el cultivo:', style: t.label),
              const SizedBox(height: AppSpace.xs),
              Wrap(
                spacing: AppSpace.xs,
                runSpacing: AppSpace.xs,
                children: app.symptoms!
                    .split(',')
                    .map((s) => s.trim())
                    .where((s) => s.isNotEmpty)
                    .map(
                      (symptom) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: c.surface,
                          borderRadius: AppRadius.pill,
                          border: Border.all(color: c.outline),
                        ),
                        child: Text(symptom, style: t.caption),
                      ),
                    )
                    .toList(),
              ),
            ],

            // Descripción de la reacción
            if (app.reactionNotes != null && app.reactionNotes!.isNotEmpty) ...[
              const SizedBox(height: AppSpace.md),
              Text('Descripción detallada de la reacción:', style: t.label),
              const SizedBox(height: AppSpace.xs),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpace.sm),
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: AppRadius.control,
                  border: Border.all(color: c.outline),
                ),
                child: Text(app.reactionNotes!, style: t.bodySm),
              ),
            ],

            const SizedBox(height: AppSpace.md),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                icon: const Icon(AppIcons.edit, size: AppSize.iconSm),
                label: const Text('Actualizar evaluación'),
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => FollowUpFormView(application: app),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
    } else {
      // Aún pendiente de evaluación
      final isDue = app.isDueTodayOrPast;

      return Container(
        padding: const EdgeInsets.all(AppSpace.md),
        decoration: BoxDecoration(
          color: c.accentSoft,
          borderRadius: AppRadius.card,
          border: Border.all(color: c.accent.withValues(alpha: 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(AppIcons.clock, size: AppSize.iconMd, color: c.accentText),
                const SizedBox(width: AppSpace.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isDue
                            ? '¡RECORDATORIO DE EVALUACIÓN VENCIDO!'
                            : 'EVALUACIÓN DE REACCIÓN PENDIENTE',
                        style: t.overline.copyWith(
                          color: isDue ? c.negative : c.accentText,
                        ),
                      ),
                      Text(
                        app.reviewDueAt != null
                            ? 'Programada para el ${Formatters.date(app.reviewDueAt!)}'
                            : 'Pendiente de registrar en la bitácora',
                        style: t.titleSm,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.xs),
            Text(
              'Evalúe la respuesta de la planta (follaje, vigor o toxicidad) para completar el ciclo de aprendizaje de este insumo.',
              style: t.bodySm,
            ),
            const SizedBox(height: AppSpace.md),
            AppButton.primary(
              label: 'Registrar evaluación de reacción',
              icon: AppIcons.check,
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => FollowUpFormView(application: app),
                  ),
                );
              },
            ),
          ],
        ),
      );
    }
  }

  /// Sección de Evidencias Fotográficas
  Widget _buildPhotoEvidenceSection(
    BuildContext context,
    AppColors c,
    AppTypography t,
  ) {
    final before = item.photoBefore;
    final after = item.photoAfter;
    final app = item.application;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(AppIcons.photo, size: AppSize.iconSm, color: c.inkSoft),
            const SizedBox(width: AppSpace.xs),
            Text('EVIDENCIA FOTOGRÁFICA', style: t.overline),
          ],
        ),
        const SizedBox(height: AppSpace.sm),

        // Si tenemos fotos del Antes y Después:
        if (before != null && after != null) ...[
          BeforeAfterPhotos(
            before: before,
            after: after,
            beforeDate: item.date,
            afterDate: app?.reviewedAt,
          ),
          const SizedBox(height: AppSpace.xs),
          Center(
            child: Text(
              'Toque una foto para comparar interactivamente con pantalla dividida.',
              style: t.caption.copyWith(color: c.inkMuted),
            ),
          ),
        ] else if (before != null || after != null) ...[
          _SinglePhotoCard(photoPath: before ?? after!),
        ],
      ],
    );
  }

  /// Sección de Lecciones de Cosecha
  Widget _buildHarvestLessonsSection(
    BuildContext context,
    AppColors c,
    AppTypography t,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: BoxDecoration(
        color: c.positive.withValues(alpha: 0.05),
        borderRadius: AppRadius.card,
        border: Border.all(color: c.positive.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(AppIcons.harvest, size: AppSize.iconSm, color: c.positive),
              const SizedBox(width: AppSpace.xs),
              Text(
                'LECCIONES DE LA COSECHA',
                style: t.overline.copyWith(color: c.positive),
              ),
            ],
          ),
          if (item.notes != null && item.notes!.isNotEmpty) ...[
            const SizedBox(height: AppSpace.sm),
            Text(item.notes!, style: t.body),
          ],
        ],
      ),
    );
  }
}

class _SinglePhotoCard extends StatelessWidget {
  const _SinglePhotoCard({required this.photoPath});

  final String photoPath;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final t = context.t;

    return GestureDetector(
      onTap: () => PhotoViewerPage.open(context, before: photoPath),
      child: Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: AppRadius.card,
          border: Border.all(color: c.outline),
        ),
        child: ClipRRect(
          borderRadius: AppRadius.card,
          child: Stack(
            fit: StackFit.expand,
            children: [
              PhotoBanner(
                path: photoPath,
                aspectRatio: 16 / 9,
                radius: AppRadius.md,
                semanticLabel: 'Foto del evento',
              ),
              Positioned(
                bottom: AppSpace.sm,
                right: AppSpace.sm,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: c.ink.withValues(alpha: 0.75),
                    borderRadius: AppRadius.pill,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(AppIcons.search, size: 14, color: c.bg),
                      const SizedBox(width: 4),
                      Text(
                        'Ver completa',
                        style: t.caption.copyWith(color: c.bg),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DataRow extends StatelessWidget {
  const _DataRow({
    required this.icon,
    required this.label,
    required this.value,
    this.badgeColor,
    this.isHighlight = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? badgeColor;
  final bool isHighlight;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final t = context.t;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: AppSize.iconSm, color: badgeColor ?? c.inkSoft),
        const SizedBox(width: AppSpace.sm),
        SizedBox(
          width: 130,
          child: Text(label, style: t.caption.copyWith(color: c.inkMuted)),
        ),
        const SizedBox(width: AppSpace.xs),
        Expanded(
          child: badgeColor != null
              ? Align(
                  alignment: Alignment.centerLeft,
                  child: StatusBadge(
                    label: value,
                    icon: icon,
                    color: badgeColor!,
                  ),
                )
              : Text(
                  value,
                  style: isHighlight
                      ? t.titleSm.copyWith(color: c.primary)
                      : t.bodySm.copyWith(color: c.ink),
                ),
        ),
      ],
    );
  }
}
