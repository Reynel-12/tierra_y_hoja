import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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

/// Plantilla C: Formulario de Labor Cultural.
class TaskFormView extends StatelessWidget {
  const TaskFormView({
    super.key,
    this.taskToEdit,
    this.initialCycleId,
  });

  final CulturalTask? taskToEdit;
  final int? initialCycleId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => TaskFormController(
        ctx.read<ActivityRepository>(),
        ctx.read<CycleRepository>(),
        ctx.read<PhotoStorageService>(),
        initialTask: taskToEdit,
        preselectedCycleId: initialCycleId,
      ),
      child: const _TaskFormContent(),
    );
  }
}

class _TaskFormContent extends StatelessWidget {
  const _TaskFormContent();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<TaskFormController>();
    final isRiego = controller.selectedTaskType == TaskType.riego;

    return FormScaffold(
      title: controller.isEditing ? 'Editar labor cultural' : 'Nueva labor cultural',
      subtitle: 'Registre deshierbe, aporco, riegos, preparación y podas',
      saveLabel: controller.isEditing ? 'Guardar cambios' : 'Guardar labor',
      isDirty: controller.isDirty,
      isSaving: controller.isSaving,
      isReady: controller.isReady,
      onSave: controller.save,
      onDelete: controller.isEditing ? controller.delete : null,
      deleteTitle: '¿Eliminar esta labor?',
      deleteMessage: 'Se borrará permanentemente de la bitácora.',
      children: [
        // Siembra y tipo de labor
        FormSection(
          title: 'Labor realizada',
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
            AppChoiceChips<TaskType>(
              label: 'Tipo de labor cultural',
              options: TaskType.values,
              value: controller.selectedTaskType,
              onChanged: (t) => controller.setTaskType(t ?? TaskType.deshierbeChapea),
              allowDeselect: false,
              required: true,
            ),
            DateChipsField(
              label: 'Fecha de realización',
              value: controller.date,
              onChanged: controller.setDate,
              required: true,
            ),
          ],
        ),

        // Si es riego: campos específicos de horas o lámina
        if (isRiego)
          FormSection(
            title: 'Detalle del riego',
            children: [
              AppTextField.number(
                label: 'Duración del riego (horas)',
                controller: controller.irrigationHoursController,
                hint: 'ej. 3.5',
                validator: Validators.optionalNumber,
              ),
              AppTextField.number(
                label: 'Lámina de agua (mm / pulgadas, opcional)',
                controller: controller.irrigationMmController,
                hint: 'ej. 25',
                validator: Validators.optionalNumber,
              ),
            ],
          ),

        // Foto de la labor realizada
        FormSection(
          title: 'Foto del trabajo (opcional)',
          children: [
            PhotoField(
              label: 'Foto del terreno o cultivo tras la labor',
              path: controller.photoPath,
              onChanged: controller.setPhoto,
            ),
          ],
        ),

        // Detalles opcionales
        MoreDetails(
          label: 'Agregar método, jornales y notas',
          initiallyExpanded: controller.methodController.text.isNotEmpty ||
              controller.workersController.text.isNotEmpty ||
              controller.notesController.text.isNotEmpty,
          children: [
            AppTextField(
              label: 'Método o herramienta empleada',
              controller: controller.methodController,
              hint: 'ej. Manual con azadón, con tractor/arado, motodesbrozadora',
            ),
            AppTextField.number(
              label: 'Cantidad de personas o jornales que participaron',
              controller: controller.workersController,
              hint: 'ej. 4',
              validator: Validators.optionalNumber,
            ),
            AppTextField.notes(
              label: 'Notas adicionales de la labor',
              controller: controller.notesController,
              hint: 'Observaciones de cómo quedó el surco, condición del suelo...',
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
