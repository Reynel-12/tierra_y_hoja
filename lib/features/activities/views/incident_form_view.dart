import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/design/app_colors.dart';
import '../../../core/services/photo_storage_service.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/form/choices.dart';
import '../../../core/widgets/form/date_fields.dart';
import '../../../core/widgets/form/fields.dart';
import '../../../core/widgets/form/form_scaffold.dart';
import '../../../core/widgets/media/photo_widgets.dart';
import '../../cycles/data/cycle_repository.dart';
import '../../cycles/models/crop_cycle.dart';
import '../controllers/activity_controllers.dart';
import '../data/activity_repository.dart';
import '../models/activity_models.dart';

/// Plantilla C: Formulario de Incidencia / Plaga / Evento Climático.
class IncidentFormView extends StatelessWidget {
  const IncidentFormView({
    super.key,
    this.incidentToEdit,
    this.initialCycleId,
  });

  final Incident? incidentToEdit;
  final int? initialCycleId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => IncidentFormController(
        ctx.read<ActivityRepository>(),
        ctx.read<CycleRepository>(),
        ctx.read<PhotoStorageService>(),
        initialIncident: incidentToEdit,
        preselectedCycleId: initialCycleId,
      ),
      child: const _IncidentFormContent(),
    );
  }
}

class _IncidentFormContent extends StatelessWidget {
  const _IncidentFormContent();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<IncidentFormController>();
    final c = context.c;

    return FormScaffold(
      title: controller.isEditing ? 'Editar incidencia' : 'Nueva incidencia o plaga',
      subtitle: 'Registre plagas, enfermedades o eventos climáticos adversos',
      saveLabel: controller.isEditing ? 'Guardar cambios' : 'Guardar incidencia',
      isDirty: controller.isDirty,
      isSaving: controller.isSaving,
      isReady: controller.isReady,
      onSave: controller.save,
      onDelete: controller.isEditing ? controller.delete : null,
      deleteTitle: '¿Eliminar esta incidencia?',
      deleteMessage: 'Se borrará permanentemente de la bitácora.',
      children: [
        // Siembra y tipo
        FormSection(
          title: 'Tipo de incidencia',
          children: [
            if (controller.availableCycles.isEmpty)
              const FieldError(
                message: 'No hay siembras abiertas. Primero abra un ciclo en la sección de Siembras.',
              )
            else
              _CyclePickerField(
                cycles: controller.availableCycles,
                selectedCycleId: controller.selectedCycleId,
                onChanged: controller.setCycle,
              ),
            AppChoiceChips<IncidentKind>(
              label: 'Clasificación de la incidencia',
              options: IncidentKind.values,
              value: controller.selectedKind,
              onChanged: (k) {
                if (k != null) controller.setKind(k);
              },
              allowDeselect: false,
              required: true,
              helper: 'Plagas (insectos), enfermedades (hongos) o clima (sequía, granizo).',
            ),
            AppTextField(
              label: switch (controller.selectedKind) {
                IncidentKind.plaga => 'Nombre de la plaga detectada',
                IncidentKind.enfermedad => 'Nombre de la enfermedad',
                IncidentKind.clima => 'Evento climático adverso',
              },
              controller: controller.nameController,
              required: true,
              hint: switch (controller.selectedKind) {
                IncidentKind.plaga => 'ej. Gusano cogollero, Mosca blanca, Pulgón, Babosa',
                IncidentKind.enfermedad => 'ej. Roya, Tizón tardío, Mancha de asfalto, Antracnosis',
                IncidentKind.clima => 'ej. Sequía prolongada, Exceso de lluvia, Granizada, Viento fuerte',
              },
              validator: Validators.required('Falta el nombre o descripción de la incidencia.'),
            ),
          ],
        ),

        // Severidad y Fecha
        FormSection(
          title: 'Nivel de daño y fecha',
          children: [
            AppChoiceChips<IncidentSeverity>(
              label: 'Severidad del daño o impacto',
              options: IncidentSeverity.values,
              value: controller.selectedSeverity,
              onChanged: (s) {
                if (s != null) controller.setSeverity(s);
              },
              allowDeselect: false,
              required: true,
              iconColorOf: (s) => s.color(c),
              helper: 'Leve: manchas aisladas o daño menor. Crítica: pone en riesgo la cosecha.',
            ),
            DateChipsField(
              label: 'Fecha de detección u ocurrencia',
              value: controller.date,
              onChanged: controller.setDate,
              required: true,
            ),
          ],
        ),

        // Foto del daño o plaga
        FormSection(
          title: 'Foto de evidencia (opcional)',
          children: [
            PhotoField(
              label: 'Foto de la hoja dañada, insecto o daño climático',
              path: controller.photoPath,
              onChanged: controller.setPhoto,
              helper: 'Muy útil para mostrar a técnicos agrícolas o peritos.',
            ),
          ],
        ),

        // Acción tomada y notas expandibles
        MoreDetails(
          label: 'Agregar acción tomada y notas',
          initiallyExpanded: controller.actionTakenController.text.isNotEmpty ||
              controller.notesController.text.isNotEmpty,
          children: [
            AppTextField.notes(
              label: 'Acción tomada o manejo de rescate',
              controller: controller.actionTakenController,
              hint: 'ej. Se aplicó insecticida de choque, se abrieron zanjas de drenaje...',
              helper: 'Describa qué hizo para controlar la situación.',
            ),
            AppTextField.notes(
              label: 'Notas adicionales',
              controller: controller.notesController,
              hint: 'Porcentaje aproximado del lote afectado, surcos con mayor daño...',
            ),
          ],
        ),
      ],
    );
  }
}

class _CyclePickerField extends StatelessWidget {
  const _CyclePickerField({
    required this.cycles,
    required this.selectedCycleId,
    required this.onChanged,
  });

  final List<CropCycle> cycles;
  final int? selectedCycleId;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    final validValue = cycles.any((c) => c.id == selectedCycleId)
        ? selectedCycleId
        : (cycles.isNotEmpty ? cycles.first.id : null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FieldLabel('Siembra / Campaña', required: true),
        DropdownButtonFormField<int>(
          key: ValueKey(validValue),
          initialValue: validValue,
          isExpanded: true,
          items: [
            for (final cycle in cycles)
              DropdownMenuItem(
                value: cycle.id,
                child: Text('${cycle.title} · ${cycle.plotName}'),
              ),
          ],
          onChanged: onChanged,
          validator: (val) => val == null ? 'Seleccione la siembra correspondiente' : null,
          decoration: const InputDecoration(
            hintText: 'Seleccione la siembra...',
          ),
        ),
      ],
    );
  }
}
