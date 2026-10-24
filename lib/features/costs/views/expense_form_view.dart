import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/validators.dart';
import '../../../core/widgets/form/choices.dart';
import '../../../core/widgets/form/date_fields.dart';
import '../../../core/widgets/form/fields.dart';
import '../../../core/widgets/form/form_scaffold.dart';
import '../../cycles/data/cycle_repository.dart';
import '../../cycles/models/crop_cycle.dart';
import '../controllers/cost_controllers.dart';
import '../data/cost_repository.dart';
import '../models/cost_models.dart';

/// Plantilla C: Registro de Gasto o Compra Invertida.
class ExpenseFormView extends StatelessWidget {
  const ExpenseFormView({super.key, this.expenseToEdit, this.initialCycleId});

  final Expense? expenseToEdit;
  final int? initialCycleId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => ExpenseFormController(
        ctx.read<CostRepository>(),
        ctx.read<CycleRepository>(),
        initialExpense: expenseToEdit,
        preselectedCycleId: initialCycleId,
      ),
      child: const _ExpenseFormContent(),
    );
  }
}

class _ExpenseFormContent extends StatelessWidget {
  const _ExpenseFormContent();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ExpenseFormController>();

    return FormScaffold(
      title: controller.isEditing ? 'Editar gasto' : 'Registrar gasto o compra',
      subtitle: 'Insumos, semilla, jornales, maquinaria y fletes',
      saveLabel: controller.isEditing ? 'Guardar cambios' : 'Guardar gasto',
      isDirty: controller.isDirty,
      isSaving: controller.isSaving,
      isReady: controller.isReady,
      onSave: controller.save,
      onDelete: controller.isEditing
          ? () async {
              await controller.performSave(); // fallback
              return true;
            }
          : null,
      deleteTitle: '¿Eliminar este gasto?',
      deleteMessage: 'Se borrará permanentemente de las cuentas.',
      children: [
        // Siembra y categoría
        FormSection(
          title: 'Origen del gasto',
          children: [
            if (controller.availableCycles.isEmpty)
              const FieldError(
                message:
                    'No hay siembras registradas. Primero registre una siembra.',
              )
            else
              _CyclePicker(
                cycles: controller.availableCycles,
                selectedCycleId: controller.selectedCycleId,
                onChanged: controller.setCycle,
              ),
            AppChoiceChips<ExpenseCategory>(
              label: 'Categoría de gasto',
              options: ExpenseCategory.values,
              value: controller.selectedCategory,
              onChanged: (cat) =>
                  controller.setCategory(cat ?? ExpenseCategory.insumos),
              allowDeselect: false,
              required: true,
            ),
            AppTextField(
              label: 'Descripción o concepto',
              controller: controller.descriptionController,
              hint: 'ej. 3 sacos de fórmula 18-46-0, 4 jornales de chapea',
            ),
          ],
        ),

        // Monto y Fecha
        FormSection(
          title: 'Monto y cálculo',
          children: [
            AppTextField(
              label: 'Monto total invertido',
              controller: controller.amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              prefixText: 'L ',
              required: true,
              hint: '0.00',
              validator: Validators.requiredMoney(
                'Ingrese el monto gastado en Lempiras.',
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    label: 'Cantidad (opcional)',
                    controller: controller.quantityController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    hint: 'ej. 3',
                    validator: Validators.optionalNumber,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppTextField(
                    label: 'Precio unitario (L)',
                    controller: controller.unitPriceController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    prefixText: 'L ',
                    hint: 'ej. 650',
                    validator: Validators.optionalNumber,
                  ),
                ),
              ],
            ),
            DateChipsField(
              label: 'Fecha del gasto',
              value: controller.date,
              onChanged: controller.setDate,
              required: true,
            ),
          ],
        ),

        // Notas expandibles
        MoreDetails(
          label: 'Agregar notas u observaciones',
          initiallyExpanded: controller.notesController.text.isNotEmpty,
          children: [
            AppTextField.notes(
              label: 'Notas del gasto',
              controller: controller.notesController,
              hint:
                  'ej. Comprado en Agrocomercial El Triunfo, con factura #1042',
            ),
          ],
        ),
      ],
    );
  }
}

class _CyclePicker extends StatelessWidget {
  const _CyclePicker({
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
        const FieldLabel('Siembra / Lote vinculado', required: true),
        DropdownButtonFormField<int>(
          key: ValueKey(validValue),
          initialValue: validValue,
          isExpanded: true,
          items: [
            for (final c in cycles)
              DropdownMenuItem(
                value: c.id,
                child: Text('${c.title} (${c.plotName})'),
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
