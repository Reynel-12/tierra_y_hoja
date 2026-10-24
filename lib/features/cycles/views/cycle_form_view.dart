import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/validators.dart';
import '../../../core/widgets/form/choices.dart';
import '../../../core/widgets/form/date_fields.dart';
import '../../../core/widgets/form/fields.dart';
import '../../../core/widgets/form/form_scaffold.dart';
import '../../plots/data/plot_repository.dart';
import '../../plots/models/plot.dart';
import '../controllers/cycle_controllers.dart';
import '../data/cycle_repository.dart';
import '../models/crop_cycle.dart';

/// Plantilla C: Formulario de Apertura / Edición de Siembra.
class CycleFormView extends StatelessWidget {
  const CycleFormView({
    super.key,
    this.cycleToEdit,
    this.initialPlotId,
  });

  final CropCycle? cycleToEdit;
  final int? initialPlotId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => CycleFormController(
        ctx.read<CycleRepository>(),
        ctx.read<PlotRepository>(),
        initialCycle: cycleToEdit,
        preselectedPlotId: initialPlotId,
      ),
      child: const _CycleFormContent(),
    );
  }
}

class _CycleFormContent extends StatelessWidget {
  const _CycleFormContent();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<CycleFormController>();

    return FormScaffold(
      title: controller.isEditing ? 'Editar siembra' : 'Apertura de siembra',
      subtitle: 'Registre el inicio de una nueva campaña productiva',
      saveLabel: controller.isEditing ? 'Guardar cambios' : 'Abrir siembra',
      isDirty: controller.isDirty,
      isSaving: controller.isSaving,
      isReady: controller.isReady,
      onSave: controller.save,
      children: [
        // Selección del lote y cultivo
        FormSection(
          title: 'Terreno y cultivo',
          children: [
            if (controller.availablePlots.isEmpty)
              const FieldError(
                message: 'No hay parcelas creadas. Primero registre un lote en la sección de Parcelas.',
              )
            else
              _PlotPickerField(
                plots: controller.availablePlots,
                selectedPlotId: controller.selectedPlotId,
                onChanged: controller.setPlot,
              ),
            AppTextField(
              label: 'Cultivo',
              controller: controller.cropController,
              required: true,
              hint: 'ej. Maíz, Frijol, Tomate, Chile jalapeño, Café',
              validator: Validators.required('Falta el nombre del cultivo. Escríbalo para comenzar.'),
            ),
            AppTextField(
              label: 'Variedad o híbrido (opcional)',
              controller: controller.varietyController,
              hint: 'ej. Pólder, Rojo seda, HB-104, Catuaí',
              helper: 'Especificar la variedad ayuda a comparar qué semilla rinde mejor.',
            ),
          ],
        ),

        // Fecha de siembra y estado
        FormSection(
          title: 'Fecha y estado inicial',
          children: [
            DateChipsField(
              label: 'Fecha exacta de siembra o trasplante',
              value: controller.plantingDate,
              onChanged: controller.setPlantingDate,
              required: true,
            ),
            AppChoiceChips<CropStage>(
              label: 'Estado inicial del ciclo',
              options: CropStage.values.where((s) => s != CropStage.done).toList(),
              value: controller.selectedStage,
              onChanged: (stage) {
                if (stage != null) controller.setStage(stage);
              },
              allowDeselect: false,
              required: true,
              helper: 'Seleccione la etapa en la que se encuentra actualmente el cultivo.',
            ),
          ],
        ),

        // Densidad y detalles
        MoreDetails(
          label: 'Agregar densidad o cantidad sembrada',
          initiallyExpanded: controller.densityValueController.text.isNotEmpty ||
              controller.densityNotesController.text.isNotEmpty,
          children: [
            UnitField<DensityUnit>(
              label: 'Cantidad sembrada (densidad)',
              controller: controller.densityValueController,
              units: DensityUnit.values,
              unit: controller.selectedDensityUnit,
              onUnitChanged: controller.setDensityUnit,
              hint: 'ej. 25',
              validator: Validators.optionalNumber,
            ),
            AppTextField.notes(
              label: 'Notas de distanciamiento o siembra',
              controller: controller.densityNotesController,
              hint: 'ej. 0.80 m entre surcos, 0.20 m entre plantas, 2 semillas por postura...',
            ),
          ],
        ),
      ],
    );
  }
}

class _PlotPickerField extends StatelessWidget {
  const _PlotPickerField({
    required this.plots,
    required this.selectedPlotId,
    required this.onChanged,
  });

  final List<Plot> plots;
  final int? selectedPlotId;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    // Asegurar elementos únicos por ID para evitar duplicados en el dropdown
    final uniquePlots = <int, Plot>{};
    for (final plot in plots) {
      if (plot.id != null) {
        uniquePlots[plot.id!] = plot;
      }
    }
    final distinctPlots = uniquePlots.values.toList();

    final validValue = distinctPlots.any((p) => p.id == selectedPlotId)
        ? selectedPlotId
        : (distinctPlots.isNotEmpty ? distinctPlots.first.id : null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FieldLabel('Parcela o lote', required: true),
        DropdownButtonFormField<int>(
          key: ValueKey(validValue),
          initialValue: validValue,
          isExpanded: true,
          items: [
            for (final plot in distinctPlots)
              DropdownMenuItem(
                value: plot.id,
                child: Text('${plot.name} (${plot.areaDisplay})'),
              ),
          ],
          onChanged: onChanged,
          validator: (val) => val == null ? 'Seleccione un lote para la siembra' : null,
          decoration: const InputDecoration(
            hintText: 'Seleccione el lote...',
          ),
        ),
      ],
    );
  }
}

