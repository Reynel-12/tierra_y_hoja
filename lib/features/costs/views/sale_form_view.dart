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

/// Plantilla C: Registro de Venta de Cosecha.
class SaleFormView extends StatelessWidget {
  const SaleFormView({super.key, this.saleToEdit, this.initialCycleId});

  final Sale? saleToEdit;
  final int? initialCycleId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => SaleFormController(
        ctx.read<CostRepository>(),
        ctx.read<CycleRepository>(),
        initialSale: saleToEdit,
        preselectedCycleId: initialCycleId,
      ),
      child: const _SaleFormContent(),
    );
  }
}

class _SaleFormContent extends StatelessWidget {
  const _SaleFormContent();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<SaleFormController>();

    return FormScaffold(
      title: controller.isEditing
          ? 'Editar venta'
          : 'Registrar venta de cosecha',
      subtitle: 'Ingresos obtenidos por la comercialización de la producción',
      saveLabel: controller.isEditing ? 'Guardar cambios' : 'Guardar venta',
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
      deleteTitle: '¿Eliminar esta venta?',
      deleteMessage: 'Se borrará permanentemente de las cuentas.',
      children: [
        // Siembra
        FormSection(
          title: 'Origen de la cosecha',
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
            AppTextField(
              label: 'Comprador o destino (opcional)',
              controller: controller.buyerController,
              hint: 'ej. Mercado Central, Don Pedro, Exportadora del Valle',
            ),
          ],
        ),

        // Cantidad, precio y total
        FormSection(
          title: 'Volumen y liquidación',
          children: [
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: AppTextField(
                    label: 'Cantidad cosechada',
                    controller: controller.quantityController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    hint: 'ej. 50',
                    validator: Validators.optionalNumber,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: AppTextField(
                    label: 'Unidad',
                    controller: controller.unitController,
                    hint: 'Quintales',
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    label: 'Precio por unidad (L)',
                    controller: controller.unitPriceController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    prefixText: 'L ',
                    hint: 'ej. 850',
                    validator: Validators.optionalNumber,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppTextField(
                    label: 'Total cobrado (L)',
                    controller: controller.amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    prefixText: 'L ',
                    required: true,
                    hint: '0.00',
                    validator: Validators.requiredMoney(
                      'Ingrese el total de la venta.',
                    ),
                  ),
                ),
              ],
            ),
            DateChipsField(
              label: 'Fecha de entrega o venta',
              value: controller.date,
              onChanged: controller.setDate,
              required: true,
            ),
          ],
        ),

        // Notas expandibles
        MoreDetails(
          label: 'Agregar notas de entrega o calidad',
          initiallyExpanded: controller.notesController.text.isNotEmpty,
          children: [
            AppTextField.notes(
              label: 'Notas de la venta',
              controller: controller.notesController,
              hint: 'ej. Pagado de contado, grano con 12% de humedad...',
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
