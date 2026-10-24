import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/design/app_colors.dart';
import '../../../core/design/app_tokens.dart';
import '../../../core/design/app_typography.dart';
import '../../../core/services/photo_storage_service.dart';
import '../../../core/services/reminder_service.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/form/fields.dart';
import '../../../core/widgets/form/form_scaffold.dart';
import '../../../core/widgets/form/verdict_tiles.dart';
import '../../../core/widgets/media/photo_widgets.dart';
import '../controllers/application_controllers.dart';
import '../data/application_repository.dart';
import '../models/input_application.dart';

/// Pantilla C (Corta): Seguimiento y Registro de Reacción Post-Aplicación.
class FollowUpFormView extends StatelessWidget {
  const FollowUpFormView({super.key, required this.application});

  final InputApplication application;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => FollowUpFormController(
        application,
        ctx.read<ApplicationRepository>(),
        ctx.read<PhotoStorageService>(),
        ctx.read<ReminderService>(),
      ),
      child: _FollowUpFormContent(application: application),
    );
  }
}

class _FollowUpFormContent extends StatelessWidget {
  const _FollowUpFormContent({required this.application});

  final InputApplication application;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<FollowUpFormController>();
    final c = context.c;
    final t = context.t;

    return FormScaffold(
      title: 'Revisión de reacción',
      subtitle: 'Evalúe cómo respondió el cultivo al insumo aplicado',
      saveLabel: 'Guardar veredicto',
      isDirty: controller.isDirty,
      isSaving: controller.isSaving,
      isReady: controller.isReady,
      onSave: controller.save,
      children: [
        // Resumen de la aplicación original
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('APLICACIÓN REALIZADA', style: t.overline),
              const SizedBox(height: AppSpace.xs),
              Text(application.productName, style: t.title),
              const SizedBox(height: 2),
              Text(
                'Aplicado el ${Formatters.date(application.appliedAt)} · Dosis: ${application.doseDisplay}',
                style: t.bodySm,
              ),
              if (application.photoBefore != null) ...[
                const SizedBox(height: AppSpace.md),
                Row(
                  children: [
                    PhotoThumb(
                      path: application.photoBefore!,
                      size: 64,
                      semanticLabel: 'Foto antes de aplicar',
                    ),
                    const SizedBox(width: AppSpace.md),
                    Expanded(
                      child: Text(
                        'Foto tomada el día de la aplicación para comparar.',
                        style: t.caption.copyWith(color: c.ink),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),

        // Veredicto grande con los 3 botones principales
        FormSection(
          title: 'Respuesta observada en la planta',
          children: [
            VerdictTiles(
              value: controller.selectedVerdict,
              onChanged: controller.setVerdict,
              selectedSymptoms: controller.selectedSymptoms,
              onSymptomsChanged: controller.setSymptoms,
              symptomsController: controller.symptomsDetailsController,
              required: true,
            ),
            AppTextField.notes(
              label: 'Descripción de la reacción',
              controller: controller.reactionNotesController,
              hint: 'ej. Follaje notablemente más verde y con vigor nuevo...',
              helper:
                  'Puede tocar el micrófono para dictar sus observaciones con la voz.',
            ),
          ],
        ),

        // Foto comparativa del "después"
        FormSection(
          title: 'Foto del "después"',
          children: [
            PhotoField(
              label: 'Foto del cultivo después de la aplicación',
              path: controller.photoAfter,
              onChanged: controller.setPhotoAfter,
              helper:
                  'Permitirá ver la comparación antes/después en el cuaderno de aprendizaje.',
            ),
            if (application.photoBefore != null &&
                controller.photoAfter != null) ...[
              const SizedBox(height: AppSpace.md),
              const FieldLabel('Vista previa de la comparación:'),
              BeforeAfterPhotos(
                before: application.photoBefore,
                after: controller.photoAfter,
                beforeDate: application.appliedAt,
                afterDate: DateTime.now(),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
