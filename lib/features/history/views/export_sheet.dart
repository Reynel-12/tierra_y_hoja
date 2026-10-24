import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/design/app_colors.dart';
import '../../../core/design/app_icons.dart';
import '../../../core/design/app_tokens.dart';
import '../../../core/design/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/dialogs.dart';
import '../../costs/data/cost_repository.dart';
import '../../cycles/models/crop_cycle.dart';
import '../data/history_repository.dart';
import '../services/export_service.dart';

class ExportSheet extends StatefulWidget {
  const ExportSheet({super.key, required this.cycle});

  final CropCycle cycle;

  static Future<void> show(BuildContext context, CropCycle cycle) {
    return showAppSheet<void>(
      context,
      title: 'Exportar bitácora de campo',
      builder: (_) => ExportSheet(cycle: cycle),
    );
  }

  @override
  State<ExportSheet> createState() => _ExportSheetState();
}

class _ExportSheetState extends State<ExportSheet> {
  bool _isGenerating = false;

  Future<void> _generateAndShare(BuildContext context) async {
    setState(() => _isGenerating = true);

    try {
      final historyRepo = context.read<HistoryRepository>();
      final costRepo = context.read<CostRepository>();
      const exportService = ExportService();

      final events = await historyRepo.getTimelineForCycle(widget.cycle.id!);
      final summary = await costRepo.getSummaryForCycle(widget.cycle.id!);

      final file = await exportService.generateCyclePdf(
        cycle: widget.cycle,
        events: events,
        summary: summary,
      );

      if (mounted) setState(() => _isGenerating = false);

      if (context.mounted) {
        await exportService.shareFile(
          file,
          subject: 'Bitácora Agrícola - ${widget.cycle.title}',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isGenerating = false);
        if (context.mounted) {
          AppToast.error(context, 'No se pudo generar el reporte PDF.');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final t = context.t;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        AppCard(
          color: c.surfaceRaised,
          child: Row(
            children: [
              Icon(AppIcons.export, size: AppSize.iconLg, color: c.primary),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Reporte oficial de campo en PDF', style: t.titleSm),
                    const SizedBox(height: 2),
                    Text(
                      'Documento limpio con fondo blanco y tablas claras, ideal para imprimir o enviar por WhatsApp a técnicos y cooperativas.',
                      style: t.caption,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.lg),
        AppButton.primary(
          label: _isGenerating ? 'Generando PDF...' : 'Generar y Compartir PDF',
          icon: AppIcons.share,
          loading: _isGenerating,
          onPressed: _isGenerating ? null : () => _generateAndShare(context),
        ),
        const SizedBox(height: AppSpace.sm),
        AppButton.ghost(
          label: 'Cerrar',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
