import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/services/photo_storage_service.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/form/choices.dart';
import '../../../core/widgets/form/fields.dart';
import '../../../core/widgets/form/form_scaffold.dart';
import '../../../core/widgets/form/location_field.dart';
import '../../../core/widgets/media/photo_widgets.dart';
import '../controllers/plot_controllers.dart';
import '../data/plot_repository.dart';
import '../models/plot.dart';

/// Plantilla C: Formulario de Nueva / Editar Parcela.
class PlotFormView extends StatelessWidget {
  const PlotFormView({super.key, this.plotToEdit});

  final Plot? plotToEdit;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => PlotFormController(
        ctx.read<PlotRepository>(),
        ctx.read<PhotoStorageService>(),
        initialPlot: plotToEdit,
      ),
      child: const _PlotFormContent(),
    );
  }
}

class _PlotFormContent extends StatelessWidget {
  const _PlotFormContent();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PlotFormController>();

    return FormScaffold(
      title: controller.isEditing ? 'Editar lote' : 'Nuevo lote o parcela',
      subtitle: 'Defina las condiciones de la tierra para sus cultivos',
      saveLabel: controller.isEditing ? 'Guardar cambios' : 'Registrar lote',
      isDirty: controller.isDirty,
      isSaving: controller.isSaving,
      isReady: controller.isReady,
      onSave: controller.save,
      onDelete: controller.isEditing ? controller.delete : null,
      deleteTitle: '¿Eliminar este lote?',
      deleteMessage: 'Se eliminarán también todos los ciclos y registros asociados a esta tierra.',
      children: [
        // Datos básicos obligatorios
        FormSection(
          title: 'Identificación y extensión',
          children: [
            AppTextField(
              label: 'Nombre o apodo del terreno',
              controller: controller.nameController,
              required: true,
              hint: 'ej. El Rincón, Lote Alto, La Vega',
              validator: Validators.required('Falta el nombre o apodo del lote. Escríbalo para identificarlo.'),
            ),
            UnitField<AreaUnit>(
              label: 'Área o extensión',
              controller: controller.areaController,
              required: true,
              units: AreaUnit.values,
              unit: controller.selectedAreaUnit,
              onUnitChanged: controller.setAreaUnit,
              hint: 'ej. 2.5',
              validator: Validators.requiredPositive('Falta el área del lote. Escriba una cantidad mayor a cero.'),
            ),
            PhotoField(
              label: 'Foto del lote (opcional)',
              path: controller.photoPath,
              onChanged: controller.setPhoto,
              helper: 'Una foto panorámica ayuda a recordar la ubicación y estado del terreno.',
            ),
          ],
        ),

        // Perfil del suelo y agua (en tarjeta principal o expandible según conveniencia)
        FormSection(
          title: 'Perfil del suelo y agua',
          children: [
            AppChoiceChips<SoilTexture>(
              label: 'Textura del suelo',
              options: SoilTexture.values,
              value: controller.selectedSoilTexture,
              onChanged: controller.setSoilTexture,
              helper: 'La textura determina la retención de agua y nutrientes.',
            ),
            AppChoiceChips<Topography>(
              label: 'Topografía',
              options: Topography.values,
              value: controller.selectedTopography,
              onChanged: controller.setTopography,
              helper: 'Influye en el drenaje y riesgo de erosión.',
            ),
            AppChoiceChips<WaterAccess>(
              label: 'Acceso a agua',
              options: WaterAccess.values,
              value: controller.selectedWaterAccess,
              onChanged: controller.setWaterAccess,
              helper: 'Seleccione la fuente principal de agua.',
            ),
          ],
        ),

        // Detalles opcionales ocultos tras "Agregar más detalles" (§7.3 y §8 Plantilla C)
        MoreDetails(
          label: 'Agregar ubicación GPS e historial previo',
          initiallyExpanded: controller.latitude != null ||
              (controller.previousCropsController.text.isNotEmpty),
          children: [
            LocationField(
              latitude: controller.latitude,
              longitude: controller.longitude,
              onChanged: controller.setLocation,
            ),
            AppTextField.notes(
              label: 'Historial previo (rotación de cultivos)',
              controller: controller.previousCropsController,
              hint: '¿Qué cultivo estuvo sembrado antes en esta tierra? Notas de plagas anteriores...',
              helper: 'Clave para planificar rotación y evitar enfermedades del suelo.',
            ),
          ],
        ),
      ],
    );
  }
}
