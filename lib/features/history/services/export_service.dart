import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../../../core/utils/formatters.dart';
import '../../costs/models/cost_models.dart';
import '../../cycles/models/crop_cycle.dart';
import '../models/experience_models.dart';

class ExportService {
  const ExportService();

  /// Genera un documento PDF estructurado de la bitácora según el diseño §7.16
  /// y abre la hoja de compartir del sistema (WhatsApp, Guardar, Correo).
  Future<File> generateCyclePdf({
    required CropCycle cycle,
    required List<UnifiedTimelineItem> events,
    required FinancialSummary summary,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.all(36),
        build: (context) => [
          // Encabezado
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Tierra & Hoja',
                    style: pw.TextStyle(
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.green900,
                    ),
                  ),
                  pw.Text(
                    'Bitácora de Campo y Registro Productivo',
                    style: const pw.TextStyle(
                      fontSize: 12,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'Emisión: ${Formatters.date(DateTime.now())}',
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey600,
                    ),
                  ),
                  pw.Text(
                    '100% Registro Offline',
                    style: const pw.TextStyle(
                      fontSize: 9,
                      color: PdfColors.grey500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Divider(thickness: 1, color: PdfColors.grey400),
          pw.SizedBox(height: 12),

          // Ficha de la siembra
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Cultivo: ${cycle.title}',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Lote / Parcela: ${cycle.plotName}',
                      style: const pw.TextStyle(fontSize: 11),
                    ),
                    pw.Text(
                      'Fecha de siembra: ${Formatters.date(cycle.plantingDate)}',
                      style: const pw.TextStyle(fontSize: 11),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Estado actual: ${cycle.stage.label}',
                      style: const pw.TextStyle(fontSize: 11),
                    ),
                    if (cycle.densityDisplay.isNotEmpty)
                      pw.Text(
                        'Densidad: ${cycle.densityDisplay}',
                        style: const pw.TextStyle(fontSize: 11),
                      ),
                    if (cycle.yieldDisplay.isNotEmpty)
                      pw.Text(
                        'Rendimiento: ${cycle.yieldDisplay}',
                        style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 20),

          // Balance económico
          pw.Text(
            'Resumen Económico (Lempiras)',
            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          pw.Row(
            children: [
              _buildMetricBox(
                'Total Invertido',
                Formatters.money(summary.totalExpenses),
              ),
              pw.SizedBox(width: 12),
              _buildMetricBox(
                'Total Cosechado / Vendido',
                Formatters.money(summary.totalSales),
              ),
              pw.SizedBox(width: 12),
              _buildMetricBox(
                'Balance Neto',
                Formatters.money(summary.netProfit),
                isHighlight: true,
              ),
            ],
          ),
          pw.SizedBox(height: 20),

          // Tabla de eventos y actividades
          pw.Text(
            'Historial de Bitácora y Aplicaciones',
            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),

          if (events.isEmpty)
            pw.Text(
              'No hay eventos registrados en esta siembra.',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
            )
          else
            pw.TableHelper.fromTextArray(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              headerStyle: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.black,
              ),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.grey200,
              ),
              cellStyle: const pw.TextStyle(fontSize: 9),
              cellHeight: 24,
              headers: [
                'Fecha',
                'Tipo',
                'Detalle / Insumo',
                'Notas / Resultado',
              ],
              data: [
                for (final ev in events)
                  [
                    Formatters.date(ev.date),
                    ev.type.label,
                    ev.title,
                    [
                      if (ev.subtitle != null) ev.subtitle,
                      if (ev.badgeText != null) 'Resultado: ${ev.badgeText}',
                      if (ev.notes != null) ev.notes,
                    ].join(' - '),
                  ],
              ],
            ),

          if (cycle.isClosed &&
              ((cycle.whatWorked != null && cycle.whatWorked!.isNotEmpty) ||
                  (cycle.whatFailed != null &&
                      cycle.whatFailed!.isNotEmpty))) ...[
            pw.SizedBox(height: 20),
            pw.Text(
              'Lecciones y Aprendizajes de la Cosecha',
              style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 6),
            if (cycle.whatWorked != null && cycle.whatWorked!.isNotEmpty)
              pw.Paragraph(
                text: '¿Qué funcionó bien?: ${cycle.whatWorked!}',
                style: const pw.TextStyle(fontSize: 10),
              ),
            if (cycle.whatFailed != null && cycle.whatFailed!.isNotEmpty)
              pw.Paragraph(
                text: '¿Qué falló o debe mejorarse?: ${cycle.whatFailed!}',
                style: const pw.TextStyle(fontSize: 10),
              ),
          ],
        ],
      ),
    );

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/bitacora_${cycle.crop}_${cycle.id}.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  pw.Widget _buildMetricBox(
    String title,
    String value, {
    bool isHighlight = false,
  }) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(8),
        decoration: pw.BoxDecoration(
          color: isHighlight ? PdfColors.green50 : PdfColors.grey100,
          border: pw.Border.all(
            color: isHighlight ? PdfColors.green300 : PdfColors.grey300,
          ),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              title,
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: isHighlight ? PdfColors.green900 : PdfColors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> shareFile(File file, {String? subject}) async {
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        subject: subject ?? 'Bitácora Agrícola',
      ),
    );
  }
}
