import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/services/photo_storage_service.dart';
import '../../../core/services/reminder_service.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/form/choices.dart';
import '../../../core/widgets/form/date_fields.dart';
import '../../../core/widgets/form/fields.dart';
import '../../../core/widgets/form/form_scaffold.dart';
import '../../../core/widgets/media/photo_widgets.dart';
import '../../cycles/data/cycle_repository.dart';
import '../../cycles/models/crop_cycle.dart';
import '../controllers/application_controllers.dart';
import '../data/application_repository.dart';
import '../models/input_application.dart';

/// Plantilla C: Registro de Aplicación de Insumos.
class ApplicationFormView extends StatelessWidget {
  const ApplicationFormView({
    super.key,
    this.applicationToEdit,
    this.initialCycleId,
  });

  final InputApplication? applicationToEdit;
  final int? initialCycleId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => ApplicationFormController(
        ctx.read<ApplicationRepository>(),
        ctx.read<CycleRepository>(),
        ctx.read<PhotoStorageService>(),
        ctx.read<ReminderService>(),
        initialApp: applicationToEdit,
        preselectedCycleId: initialCycleId,
      ),
      child: const _ApplicationFormContent(),
    );
  }
}

class _ApplicationFormContent extends StatelessWidget {
  const _ApplicationFormContent();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ApplicationFormController>();

    return FormScaffold(
      title: controller.isEditing
          ? 'Editar aplicación'
          : 'Nueva aplicación de insumo',
      subtitle: 'Registre fertilizantes, foliares, insecticidas y enmiendas',
      saveLabel: controller.isEditing
          ? 'Guardar cambios'
          : 'Guardar aplicación',
      isDirty: controller.isDirty,
      isSaving: controller.isSaving,
      isReady: controller.isReady,
      onSave: controller.save,
      onDelete: controller.isEditing ? controller.delete : null,
      deleteTitle: '¿Eliminar esta aplicación?',
      deleteMessage: 'Se borrará permanentemente de la bitácora.',
      children: [
        // Siembra e Insumo principal
        FormSection(
          title: 'Cultivo e insumo aplicado',
          children: [
            if (controller.availableCycles.isEmpty)
              const FieldError(
                message:
                    'No hay siembras abiertas. Primero abra un ciclo en la sección de Siembras.',
              )
            else
              _CyclePickerField(
                cycles: controller.availableCycles,
                selectedCycleId: controller.selectedCycleId,
                onChanged: controller.setCycle,
              ),
            AppChoiceChips<InputType>(
              label: 'Tipo de insumo',
              options: InputType.values,
              value: controller.selectedInputType,
              onChanged: (type) => controller.setInputType(
                type ?? InputType.fertilizanteGranular,
              ),
              allowDeselect: false,
              required: true,
            ),
            AppTextField(
              label: 'Nombre comercial o compuesto',
              controller: controller.productNameController,
              required: true,
              hint: 'ej. Urea 46%, Nitrato de calcio, Foligán, Cipermetrina',
              validator: Validators.required(
                'Falta el nombre del insumo o producto aplicado.',
              ),
            ),
          ],
        ),

        // Dosis y Fecha
        FormSection(
          title: 'Dosis y momento de aplicación',
          children: [
            UnitField<DoseUnit>(
              label: 'Dosis aplicada',
              controller: controller.doseValueController,
              units: DoseUnit.values,
              unit: controller.selectedDoseUnit,
              onUnitChanged: controller.setDoseUnit,
              hint: 'ej. 2',
              validator: Validators.optionalNumber,
            ),
            DateChipsField(
              label: 'Fecha de aplicación',
              value: controller.appliedAt,
              onChanged: controller.setAppliedAt,
              required: true,
            ),
            AppChoiceChips<TimeOfDayChoice>(
              label: 'Hora del día',
              options: TimeOfDayChoice.values,
              value: controller.selectedTimeOfDay ?? TimeOfDayChoice.morning,
              onChanged: (time) {
                if (time != null) controller.setTimeOfDay(time);
              },
              allowDeselect: false,
              helper:
                  'Importante: aplicar con sol fuerte puede causar quemaduras en la hoja.',
            ),
          ],
        ),

        // Recordatorio de revisión y foto
        FormSection(
          title: 'Recordatorio de seguimiento',
          children: [
            const FieldLabel('¿Cuándo desea revisar la reacción del cultivo?'),
            Wrap(
              spacing: 8,
              children: [
                for (final opt in ReminderOption.values)
                  AppChip(
                    label: opt.label,
                    selected: controller.selectedReminder == opt,
                    onTap: () => controller.setReminder(opt),
                  ),
              ],
            ),
            PhotoField(
              label: 'Foto de la planta "antes" de aplicar (opcional)',
              path: controller.photoBefore,
              onChanged: controller.setPhotoBefore,
              helper:
                  'Servirá para comparar el antes y después en el seguimiento.',
            ),
          ],
        ),

        // Detalles adicionales expandibles
        MoreDetails(
          label: 'Agregar método, clima y notas',
          initiallyExpanded:
              controller.methodController.text.isNotEmpty ||
              controller.notesController.text.isNotEmpty,
          children: [
            AppTextField(
              label: 'Método de aplicación',
              controller: controller.methodController,
              hint:
                  'ej. Al pie de la planta, bomba de mochila al follaje, fertirriego',
            ),
            AppChoiceChips<WeatherCondition>(
              label: 'Condición climática',
              options: WeatherCondition.values,
              value: controller.selectedWeather,
              onChanged: controller.setWeather,
            ),
            AppTextField.notes(
              label: 'Notas de la aplicación',
              controller: controller.notesController,
              hint: 'Observaciones sobre la mezcla, estado general del lote...',
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
          validator: (val) =>
              val == null ? 'Seleccione la siembra correspondiente' : null,
          decoration: const InputDecoration(
            hintText: 'Seleccione la siembra...',
          ),
        ),
      ],
    );
  }
}
