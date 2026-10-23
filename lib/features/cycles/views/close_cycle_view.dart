import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/validators.dart';
import '../../../core/widgets/form/choices.dart';
import '../../../core/widgets/form/date_fields.dart';
import '../../../core/widgets/form/fields.dart';
import '../../../core/widgets/form/form_scaffold.dart';
import '../controllers/cycle_controllers.dart';
import '../data/cycle_repository.dart';
import '../models/crop_cycle.dart';

/// Plantilla C: Cierre de Ciclo y Registro de Cosecha.
class CloseCycleView extends StatelessWidget {
  const CloseCycleView({super.key, required this.cycle});

  final CropCycle cycle;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => CloseCycleFormController(
        cycle,
        ctx.read<CycleRepository>(),
      ),
      child: const _CloseCycleContent(),
    );
  }
}

class _CloseCycleContent extends StatelessWidget {
  const _CloseCycleContent();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<CloseCycleFormController>();

    return FormScaffold(
      title: 'Cierre de ciclo y cosecha',
      subtitle: 'Registre el rendimiento final y la evaluación de la siembra',
      saveLabel: 'Finalizar ciclo de siembra',
      isDirty: controller.isDirty,
      isSaving: controller.isSaving,
      isReady: controller.isReady,
      onSave: controller.save,
      children: [
        // Rendimiento y calidad
        FormSection(
          title: 'Cosecha obtenida',
          children: [
            UnitField<YieldUnit>(
              label: 'Rendimiento total obtenido',
              controller: controller.yieldController,
              required: true,
              units: YieldUnit.values,
              unit: controller.selectedYieldUnit,
              onUnitChanged: controller.setYieldUnit,
              hint: 'ej. 85.5',
              validator: Validators.requiredPositive(
                'Falta el rendimiento cosechado. Escriba la cantidad obtenida.',
              ),
            ),
            AppChoiceChips<CropQuality>(
              label: 'Calidad general percibida',
              options: CropQuality.values,
              value: controller.selectedQuality,
              onChanged: (q) {
                if (q != null) controller.setQuality(q);
              },
              allowDeselect: false,
              required: true,
              helper: 'Evalúe la apariencia y valor comercial del producto cosechado.',
            ),
          ],
        ),

        // Período de cosecha
        FormSection(
          title: 'Fechas de corte o recolección',
          children: [
            DateChipsField(
              label: 'Fecha de inicio de cosecha',
              value: controller.harvestStart,
              onChanged: controller.setHarvestStart,
              required: true,
            ),
            DateChipsField(
              label: 'Fecha de fin de cosecha',
              value: controller.harvestEnd,
              onChanged: controller.setHarvestEnd,
              required: true,
            ),
          ],
        ),

        // Evaluación general del ciclo (cuaderno de aprendizaje)
        FormSection(
          title: 'Cuaderno de aprendizaje de la temporada',
          children: [
            AppTextField.notes(
              label: '¿Qué funcionó bien en este ciclo?',
              controller: controller.whatWorkedController,
              hint: 'ej. La fertilización foliar a los 25 días dio excelente vigor, el riego por goteo ahorró agua...',
              helper: 'Servirá para repetir el éxito en futuras temporadas.',
            ),
            AppTextField.notes(
              label: '¿Qué falló o se debe mejorar?',
              controller: controller.whatFailedController,
              hint: 'ej. Se descuidó el gusano cogollero la segunda semana, faltó aporco a tiempo...',
              helper: 'Lecciones aprendidas para no cometer los mismos errores.',
            ),
          ],
        ),
      ],
    );
  }
}
