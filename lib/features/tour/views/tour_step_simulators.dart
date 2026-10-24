import 'package:flutter/material.dart';

import '../../../core/design/app_colors.dart';
import '../../../core/design/app_icons.dart';
import '../../../core/design/app_tokens.dart';
import '../../../core/design/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/badges.dart';
import '../../../core/widgets/form/choices.dart';
import '../../../core/widgets/form/fields.dart';
import '../../../core/widgets/form/verdict_tiles.dart';
import '../../../features/cycles/models/crop_cycle.dart';
import '../../../features/plots/models/plot.dart';

/// Notificación visual de retroalimentación para acciones de prueba.
void showTourDemoFeedback(BuildContext context, String message) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          const Icon(
            AppIcons.checkCircle,
            color: Colors.white,
            size: AppSize.iconSm,
          ),
          const SizedBox(width: AppSpace.sm),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: context.c.primary,
      duration: const Duration(seconds: 2),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.control),
    ),
  );
}

/// Banner recordatorio de modo demostración que se muestra en cada simulador.
class DemoHeaderBadge extends StatelessWidget {
  const DemoHeaderBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final t = context.t;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.md,
        vertical: AppSpace.sm,
      ),
      decoration: BoxDecoration(
        color: c.accentSoft,
        borderRadius: AppRadius.control,
        border: Border.all(color: c.accent.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(AppIcons.info, size: AppSize.iconSm, color: c.accentText),
          const SizedBox(width: AppSpace.sm),
          Expanded(
            child: Text(
              'Modo Demostración · Puede interactuar con estos campos. Ningún dato se guardará en su teléfono.',
              style: t.caption.copyWith(
                color: c.accentText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// SIMULADOR 1: LOTES / PARCELAS
// =============================================================================
class PlotStepSimulator extends StatefulWidget {
  const PlotStepSimulator({super.key});

  @override
  State<PlotStepSimulator> createState() => _PlotStepSimulatorState();
}

class _PlotStepSimulatorState extends State<PlotStepSimulator> {
  final _nameCtrl = TextEditingController(text: 'El Rincón');
  final _areaCtrl = TextEditingController(text: '2.5');
  AreaUnit _unit = AreaUnit.manzanas;
  SoilTexture? _soil = SoilTexture.franco;
  WaterAccess? _water = WaterAccess.riegoGoteo;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _areaCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const DemoHeaderBadge(),
          const SizedBox(height: AppSpace.md),
          Text('Formulario de Nuevo Lote (Simulación)', style: t.title),
          const SizedBox(height: AppSpace.sm),
          AppTextField(
            label: 'Nombre o apodo del terreno',
            controller: _nameCtrl,
            required: true,
            hint: 'ej. El Rincón',
          ),
          UnitField<AreaUnit>(
            label: 'Área o extensión',
            controller: _areaCtrl,
            required: true,
            units: AreaUnit.values,
            unit: _unit,
            onUnitChanged: (u) => setState(() => _unit = u),
          ),
          const SizedBox(height: AppSpace.sm),
          AppChoiceChips<SoilTexture>(
            label: 'Tipo de textura del suelo',
            options: SoilTexture.values,
            value: _soil,
            onChanged: (val) => setState(() => _soil = val),
          ),
          const SizedBox(height: AppSpace.sm),
          AppChoiceChips<WaterAccess>(
            label: 'Acceso al agua',
            options: WaterAccess.values,
            value: _water,
            onChanged: (val) => setState(() => _water = val),
          ),
          const SizedBox(height: AppSpace.lg),
          AppButton.secondary(
            icon: AppIcons.check,
            label: 'Probar: Guardar lote de ejemplo',
            onPressed: () {
              showTourDemoFeedback(
                context,
                '✓ Lote "${_nameCtrl.text}" simulado correctamente. Listo para el paso 2.',
              );
            },
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// SIMULADOR 2: CICLOS DE SIEMBRA
// =============================================================================
class CycleStepSimulator extends StatefulWidget {
  const CycleStepSimulator({super.key});

  @override
  State<CycleStepSimulator> createState() => _CycleStepSimulatorState();
}

class _CycleStepSimulatorState extends State<CycleStepSimulator> {
  String _crop = 'Maíz';
  final _varietyCtrl = TextEditingController(text: 'Híbrido DK-7088');
  final _densityCtrl = TextEditingController(text: '25');
  CropStage _stage = CropStage.growth;

  @override
  void dispose() {
    _varietyCtrl.dispose();
    _densityCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final c = context.c;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const DemoHeaderBadge(),
          const SizedBox(height: AppSpace.md),
          Text('Formulario de Apertura de Siembra', style: t.title),
          const SizedBox(height: AppSpace.sm),

          // Lote asignado
          Container(
            padding: const EdgeInsets.all(AppSpace.md),
            decoration: BoxDecoration(
              color: c.surfaceAlt,
              borderRadius: AppRadius.control,
              border: Border.all(color: c.outline),
            ),
            child: Row(
              children: [
                Icon(AppIcons.plot, size: AppSize.iconSm, color: c.primary),
                const SizedBox(width: AppSpace.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Lote seleccionado para siembra:', style: t.caption),
                      Text(
                        'El Rincón · 2.5 Manzanas (Suelo Franco)',
                        style: t.label,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.md),

          // Cultivo
          const FieldLabel('Cultivo a sembrar', required: true),
          Wrap(
            spacing: AppSpace.xs,
            runSpacing: AppSpace.xs,
            children: ['Maíz', 'Frijol', 'Tomate', 'Café'].map((crop) {
              final isSel = _crop == crop;
              return ChoiceChip(
                label: Text(crop),
                selected: isSel,
                onSelected: (_) => setState(() => _crop = crop),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpace.sm),

          AppTextField(
            label: 'Variedad de semilla o híbrido',
            controller: _varietyCtrl,
            required: true,
            hint: 'ej. Híbrido DK-7088',
          ),

          AppTextField(
            label: 'Densidad sembrada',
            controller: _densityCtrl,
            keyboardType: TextInputType.number,
            hint: 'ej. 25 Libras de semilla',
          ),
          const SizedBox(height: AppSpace.sm),

          const FieldLabel(
            'Etapa biológica actual del cultivo',
            required: false,
          ),
          Wrap(
            spacing: AppSpace.xs,
            runSpacing: AppSpace.xs,
            children: CropStage.values.map((st) {
              final isSel = _stage == st;
              return FilterChip(
                avatar: Icon(st.icon, size: 16),
                label: Text(st.label),
                selected: isSel,
                onSelected: (_) => setState(() => _stage = st),
              );
            }).toList(),
          ),

          const SizedBox(height: AppSpace.lg),
          AppButton.secondary(
            icon: AppIcons.check,
            label: 'Probar: Abrir ciclo de siembra',
            onPressed: () {
              showTourDemoFeedback(
                context,
                '✓ Siembra de "$_crop ${_varietyCtrl.text}" simulada. Etapa: ${_stage.label}.',
              );
            },
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// SIMULADOR 3: APLICACIÓN DE INSUMOS
// =============================================================================
class ApplicationStepSimulator extends StatefulWidget {
  const ApplicationStepSimulator({super.key});

  @override
  State<ApplicationStepSimulator> createState() =>
      _ApplicationStepSimulatorState();
}

class _ApplicationStepSimulatorState extends State<ApplicationStepSimulator> {
  String _type = 'Fertilizante granular';
  final _productCtrl = TextEditingController(text: 'Urea 46%');
  final _doseCtrl = TextEditingController(text: '1.5');
  int _reminderDays = 5;

  @override
  void dispose() {
    _productCtrl.dispose();
    _doseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const DemoHeaderBadge(),
          const SizedBox(height: AppSpace.md),
          Text('Registro de Aplicación en Bitácora', style: t.title),
          const SizedBox(height: AppSpace.sm),

          const FieldLabel('Tipo de insumo', required: true),
          Wrap(
            spacing: AppSpace.xs,
            runSpacing: AppSpace.xs,
            children:
                [
                  'Fertilizante granular',
                  'Foliar',
                  'Insecticida',
                  'Fungicida',
                  'Bioestimulante',
                ].map((tName) {
                  final isSel = _type == tName;
                  return ChoiceChip(
                    label: Text(tName),
                    selected: isSel,
                    onSelected: (_) => setState(() => _type = tName),
                  );
                }).toList(),
          ),
          const SizedBox(height: AppSpace.sm),

          AppTextField(
            label: 'Nombre comercial del producto',
            controller: _productCtrl,
            required: true,
            hint: 'ej. Urea 46%',
          ),

          AppTextField(
            label: 'Dosis y método de aplicación',
            controller: _doseCtrl,
            required: true,
            hint: 'ej. 1.5 Quintales al pie',
          ),
          const SizedBox(height: AppSpace.sm),

          const FieldLabel(
            'Programar recordatorio de revisión',
            required: false,
          ),
          Wrap(
            spacing: AppSpace.sm,
            children: [3, 5, 7].map((days) {
              final isSel = _reminderDays == days;
              return ChoiceChip(
                avatar: const Icon(AppIcons.reminder, size: 16),
                label: Text('En $days días'),
                selected: isSel,
                onSelected: (_) => setState(() => _reminderDays = days),
              );
            }).toList(),
          ),

          const SizedBox(height: AppSpace.lg),
          AppButton.secondary(
            icon: AppIcons.check,
            label: 'Probar: Registrar aplicación',
            onPressed: () {
              showTourDemoFeedback(
                context,
                '✓ Aplicación de "${_productCtrl.text}" simulada con alerta en $_reminderDays días.',
              );
            },
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// SIMULADOR 4: SEGUIMIENTO Y VEREDICTO
// =============================================================================
class FollowUpStepSimulator extends StatefulWidget {
  const FollowUpStepSimulator({super.key});

  @override
  State<FollowUpStepSimulator> createState() => _FollowUpStepSimulatorState();
}

class _FollowUpStepSimulatorState extends State<FollowUpStepSimulator> {
  ReactionVerdict _verdict = ReactionVerdict.positive;
  final _notesCtrl = TextEditingController(
    text: 'Follaje con verde intenso a los 4 días. Buen vigor.',
  );

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final c = context.c;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const DemoHeaderBadge(),
          const SizedBox(height: AppSpace.md),
          Text('Seguimiento Post-Aplicación (Reacción)', style: t.title),
          const SizedBox(height: AppSpace.xs),
          Text('Producto evaluado: Urea 46% (hace 5 días)', style: t.caption),
          const SizedBox(height: AppSpace.md),

          const FieldLabel('Veredicto visual del agricultor', required: true),
          VerdictTiles(
            value: _verdict,
            onChanged: (v) {
              if (v != null) setState(() => _verdict = v);
            },
          ),
          const SizedBox(height: AppSpace.md),

          AppTextField(
            label: 'Síntomas y reacción observada',
            controller: _notesCtrl,
            maxLines: 2,
            hint: 'Describa el cambio en las hojas o dictelo por voz',
          ),
          const SizedBox(height: AppSpace.xs),

          // Botón de dictado por voz demostrativo
          OutlinedButton.icon(
            icon: Icon(AppIcons.microphone, color: c.primary),
            label: Text(
              'Dictar observaciones por voz (Demostración)',
              style: TextStyle(color: c.primary),
            ),
            onPressed: () {
              showTourDemoFeedback(
                context,
                '🎙️ Micrófono listo: Graba notas sin ensuciar la pantalla.',
              );
            },
          ),

          const SizedBox(height: AppSpace.lg),
          AppButton.secondary(
            icon: AppIcons.check,
            label: 'Probar: Guardar veredicto',
            onPressed: () {
              showTourDemoFeedback(
                context,
                '✓ Veredicto "${_verdict.label}" asentado en el historial de demostración.',
              );
            },
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// SIMULADOR 5: LABORES E INCIDENCIAS
// =============================================================================
class TaskIncidentStepSimulator extends StatefulWidget {
  const TaskIncidentStepSimulator({super.key});

  @override
  State<TaskIncidentStepSimulator> createState() =>
      _TaskIncidentStepSimulatorState();
}

class _TaskIncidentStepSimulatorState extends State<TaskIncidentStepSimulator> {
  int _tab = 0; // 0 = Labor, 1 = Plaga/Incidencia
  String _task = 'Deshierbe / Chapea';
  String _incident = 'Gusano cogollero';
  String _severity = 'Moderada';

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final c = context.c;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const DemoHeaderBadge(),
          const SizedBox(height: AppSpace.md),

          // Selector Labor vs Incidencia
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(
                value: 0,
                label: Text('Labor Cultural'),
                icon: Icon(AppIcons.task),
              ),
              ButtonSegment(
                value: 1,
                label: Text('Incidencia / Plaga'),
                icon: Icon(AppIcons.pest),
              ),
            ],
            selected: {_tab},
            onSelectionChanged: (val) => setState(() => _tab = val.first),
          ),
          const SizedBox(height: AppSpace.md),

          if (_tab == 0) ...[
            Text('Registro de Labor Cultural', style: t.title),
            const SizedBox(height: AppSpace.sm),
            const FieldLabel('Tipo de labor realizada', required: true),
            Wrap(
              spacing: AppSpace.xs,
              runSpacing: AppSpace.xs,
              children:
                  [
                    'Deshierbe / Chapea',
                    'Aporco',
                    'Riego por horas',
                    'Poda',
                  ].map((task) {
                    final isSel = _task == task;
                    return ChoiceChip(
                      label: Text(task),
                      selected: isSel,
                      onSelected: (_) => setState(() => _task = task),
                    );
                  }).toList(),
            ),
            const SizedBox(height: AppSpace.sm),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(AppSpace.md),
                    decoration: BoxDecoration(
                      color: c.surfaceAlt,
                      borderRadius: AppRadius.control,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Jornales trabajados', style: t.caption),
                        Text('3 Operarios', style: t.label),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: AppSpace.sm),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(AppSpace.md),
                    decoration: BoxDecoration(
                      color: c.surfaceAlt,
                      borderRadius: AppRadius.control,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Tiempo dedicado', style: t.caption),
                        Text('4 Horas de faena', style: t.label),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            Text('Registro de Plagas o Clima', style: t.title),
            const SizedBox(height: AppSpace.sm),
            const FieldLabel('Problema identificado', required: true),
            Wrap(
              spacing: AppSpace.xs,
              children:
                  ['Gusano cogollero', 'Roya de hoja', 'Sequía prolongada'].map(
                    (inc) {
                      final isSel = _incident == inc;
                      return ChoiceChip(
                        label: Text(inc),
                        selected: isSel,
                        onSelected: (_) => setState(() => _incident = inc),
                      );
                    },
                  ).toList(),
            ),
            const SizedBox(height: AppSpace.sm),
            const FieldLabel('Severidad en el lote', required: true),
            Wrap(
              spacing: AppSpace.xs,
              children: ['Leve', 'Moderada', 'Crítica'].map((sev) {
                final isSel = _severity == sev;
                return ChoiceChip(
                  label: Text(sev),
                  selected: isSel,
                  onSelected: (_) => setState(() => _severity = sev),
                );
              }).toList(),
            ),
          ],

          const SizedBox(height: AppSpace.lg),
          AppButton.secondary(
            icon: AppIcons.check,
            label: _tab == 0
                ? 'Probar: Guardar labor'
                : 'Probar: Registrar plaga',
            onPressed: () {
              showTourDemoFeedback(
                context,
                _tab == 0
                    ? '✓ Labor de "$_task" simulada correctamente.'
                    : '✓ Alerta de "$_incident ($_severity)" simulada.',
              );
            },
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// SIMULADOR 6: COSTOS Y VENTAS (FINANZAS)
// =============================================================================
class CostSaleStepSimulator extends StatefulWidget {
  const CostSaleStepSimulator({super.key});

  @override
  State<CostSaleStepSimulator> createState() => _CostSaleStepSimulatorState();
}

class _CostSaleStepSimulatorState extends State<CostSaleStepSimulator> {
  double _expenses = 5200.0;
  double _sales = 14000.0;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final c = context.c;
    final netProfit = _sales - _expenses;
    final roi = (_expenses > 0)
        ? ((netProfit / _expenses) * 100).toStringAsFixed(0)
        : '0';

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const DemoHeaderBadge(),
          const SizedBox(height: AppSpace.md),
          Text('Resumen Financiero y Rentabilidad', style: t.title),
          const SizedBox(height: AppSpace.md),

          // Tarjeta de balance
          Container(
            padding: const EdgeInsets.all(AppSpace.md),
            decoration: BoxDecoration(
              color: c.surfaceAlt,
              borderRadius: AppRadius.control,
              border: Border.all(color: c.outline),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Gastos totales invertidos:',
                        style: t.bodySm,
                      ),
                    ),
                    Text(Formatters.money(_expenses), style: t.label),
                  ],
                ),
                const SizedBox(height: AppSpace.xs),
                Row(
                  children: [
                    Expanded(
                      child: Text('Venta total de cosecha:', style: t.bodySm),
                    ),
                    Text(
                      Formatters.money(_sales),
                      style: t.label.copyWith(color: c.positive),
                    ),
                  ],
                ),
                const Divider(height: AppSpace.md),
                Row(
                  children: [
                    Expanded(
                      child: Text('Ganancia Neta Real:', style: t.title),
                    ),
                    Text(
                      Formatters.money(netProfit),
                      style: t.headline.copyWith(
                        color: c.positive,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    StatusBadge(
                      label: '+$roi% Rentabilidad',
                      icon: AppIcons.trendUp,
                      color: c.positive,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.md),

          Wrap(
            spacing: AppSpace.sm,
            children: [
              OutlinedButton.icon(
                icon: const Icon(AppIcons.add, size: 16),
                label: const Text('+ Gasto: L 800 (Flete)'),
                onPressed: () {
                  setState(() => _expenses += 800);
                  showTourDemoFeedback(
                    context,
                    '✓ Gasto de simulación agregado.',
                  );
                },
              ),
              OutlinedButton.icon(
                icon: const Icon(AppIcons.add, size: 16),
                label: const Text('+ Venta: L 2,000 (10 qq)'),
                onPressed: () {
                  setState(() => _sales += 2000);
                  showTourDemoFeedback(
                    context,
                    '✓ Venta de simulación agregada.',
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: AppSpace.lg),
          AppButton.secondary(
            icon: AppIcons.check,
            label: 'Probar: Balance financiero',
            onPressed: () {
              showTourDemoFeedback(
                context,
                '✓ Balance en vivo: Ganancia de ${Formatters.money(netProfit)} calculada.',
              );
            },
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// SIMULADOR 7: CIERRE DE CICLO Y COSECHA
// =============================================================================
class CloseCycleStepSimulator extends StatefulWidget {
  const CloseCycleStepSimulator({super.key});

  @override
  State<CloseCycleStepSimulator> createState() =>
      _CloseCycleStepSimulatorState();
}

class _CloseCycleStepSimulatorState extends State<CloseCycleStepSimulator> {
  final _yieldCtrl = TextEditingController(text: '180');
  String _quality = 'Primera calidad';

  @override
  void dispose() {
    _yieldCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const DemoHeaderBadge(),
          const SizedBox(height: AppSpace.md),
          Text('Cierre de Ciclo y Rendimiento de Cosecha', style: t.title),
          const SizedBox(height: AppSpace.sm),

          AppTextField(
            label: 'Rendimiento total obtenido',
            controller: _yieldCtrl,
            required: true,
            hint: 'ej. 180 Quintales',
          ),
          const SizedBox(height: AppSpace.sm),

          const FieldLabel('Calidad del grano o fruto', required: true),
          Wrap(
            spacing: AppSpace.xs,
            children: ['Primera calidad', 'Segunda calidad', 'Descarte / Merma']
                .map((q) {
                  final isSel = _quality == q;
                  return ChoiceChip(
                    label: Text(q),
                    selected: isSel,
                    onSelected: (_) => setState(() => _quality = q),
                  );
                })
                .toList(),
          ),
          const SizedBox(height: AppSpace.md),

          // Reflexiones
          Container(
            padding: const EdgeInsets.all(AppSpace.md),
            decoration: BoxDecoration(
              color: context.c.surfaceAlt,
              borderRadius: AppRadius.control,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('¿Qué funcionó bien?:', style: t.caption),
                Text(
                  'El riego por goteo temprano aumentó el peso del grano.',
                  style: t.bodySm,
                ),
                const SizedBox(height: AppSpace.sm),
                Text('¿Qué falló o debe mejorarse?:', style: t.caption),
                Text(
                  'Control de malezas en semana 3 debió ser más oportuno.',
                  style: t.bodySm,
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpace.lg),
          AppButton.secondary(
            icon: AppIcons.check,
            label: 'Probar: Cerrar siembra y cosechar',
            onPressed: () {
              showTourDemoFeedback(
                context,
                '✓ Cosecha de ${_yieldCtrl.text} quintales ($_quality) registrada en simulación.',
              );
            },
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// SIMULADOR 8: HISTORIAL Y MEMORIA AGRÍCOLA
// =============================================================================
class HistoryMemoryStepSimulator extends StatelessWidget {
  const HistoryMemoryStepSimulator({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final c = context.c;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const DemoHeaderBadge(),
          const SizedBox(height: AppSpace.md),
          Text('Memoria Histórica y Comparador', style: t.title),
          const SizedBox(height: AppSpace.md),

          // Demostración de comparativa de 2 siembras
          Container(
            padding: const EdgeInsets.all(AppSpace.md),
            decoration: BoxDecoration(
              color: c.surfaceAlt,
              borderRadius: AppRadius.control,
              border: Border.all(color: c.outline),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      AppIcons.scales,
                      size: AppSize.iconSm,
                      color: c.primary,
                    ),
                    const SizedBox(width: AppSpace.xs),
                    Flexible(
                      child: Text(
                        'Comparativa: Temporada A vs Temporada B',
                        style: t.label,
                      ),
                    ),
                  ],
                ),
                const Divider(height: AppSpace.md),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Maíz DK-7088 (Temporada A):',
                        style: t.caption,
                      ),
                    ),
                    Text(
                      '180 qq · Ganancia: L 8,800',
                      style: t.caption.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Maíz DK-7088 (Temporada B):',
                        style: t.caption,
                      ),
                    ),
                    Text('140 qq · Ganancia: L 4,500', style: t.caption),
                  ],
                ),
                const SizedBox(height: AppSpace.sm),
                Text(
                  'Conclusión: La aplicación fraccionada de nitrato incrementó el rendimiento en +40 quintales.',
                  style: t.caption.copyWith(
                    color: c.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          // const SizedBox(height: AppSpace.md),

          // OutlinedButton.icon(
          //   icon: const Icon(AppIcons.pdf),
          //   label: const Text('Probar: Vista previa de reporte PDF'),
          //   onPressed: () {
          //     showTourDemoFeedback(
          //       context,
          //       '✓ Reporte PDF generado listo para compartir por WhatsApp o imprimir.',
          //     );
          //   },
          // ),
        ],
      ),
    );
  }
}

// =============================================================================
// SIMULADOR 9: PANTALLA DE INICIO Y ACCESO RÁPIDO FAB
// =============================================================================
class HomeFabStepSimulator extends StatelessWidget {
  const HomeFabStepSimulator({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final c = context.c;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const DemoHeaderBadge(),
          const SizedBox(height: AppSpace.md),
          Text('Operación Diaria y Botón Flotante (+)', style: t.title),
          const SizedBox(height: AppSpace.sm),

          // Tarjeta de siembra activa simulada
          Container(
            padding: const EdgeInsets.all(AppSpace.md),
            decoration: BoxDecoration(
              color: c.primarySoft,
              borderRadius: AppRadius.control,
              border: Border.all(color: c.primary.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                CircleIcon(icon: AppIcons.plant, color: c.primary),
                const SizedBox(width: AppSpace.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Siembra en Curso · Lote El Rincón',
                        style: t.caption,
                      ),
                      Text('Maíz Híbrido DK-7088 (Día 38)', style: t.label),
                      const SizedBox(height: 2),
                      StatusBadge(
                        label: 'En desarrollo vegetativo',
                        icon: AppIcons.checkCircle,
                        color: c.positive,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.md),

          // Botones del FAB rápido interactivos
          Text('Acceso rápido desde cualquier parte con (+):', style: t.label),
          const SizedBox(height: AppSpace.sm),
          Wrap(
            spacing: AppSpace.xs,
            runSpacing: AppSpace.xs,
            children: [
              ActionChip(
                avatar: const Icon(AppIcons.application, size: 16),
                label: const Text('Insumo'),
                onPressed: () => showTourDemoFeedback(
                  context,
                  'Acceso directo a: Registrar Insumo.',
                ),
              ),
              ActionChip(
                avatar: const Icon(AppIcons.task, size: 16),
                label: const Text('Labor'),
                onPressed: () => showTourDemoFeedback(
                  context,
                  'Acceso directo a: Labor Cultural.',
                ),
              ),
              ActionChip(
                avatar: const Icon(AppIcons.incident, size: 16),
                label: const Text('Plaga'),
                onPressed: () => showTourDemoFeedback(
                  context,
                  'Acceso directo a: Registrar Incidencia.',
                ),
              ),
              ActionChip(
                avatar: const Icon(AppIcons.money, size: 16),
                label: const Text('Gasto'),
                onPressed: () => showTourDemoFeedback(
                  context,
                  'Acceso directo a: Registrar Gasto.',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
