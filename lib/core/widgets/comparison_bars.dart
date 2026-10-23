import 'package:flutter/material.dart';

import '../design/app_colors.dart';
import '../design/app_tokens.dart';
import '../design/app_typography.dart';

/// Comparación de una métrica entre dos siembras con barras horizontales.
///
/// Serie A en `primary`, serie B en `accent`; además del color, cada barra
/// lleva su etiqueta en texto y el valor al final.
class ComparisonBars extends StatelessWidget {
  const ComparisonBars({
    super.key,
    required this.title,
    required this.labelA,
    required this.labelB,
    required this.valueA,
    required this.valueB,
    required this.format,
  });

  final String title;
  final String labelA;
  final String labelB;
  final double? valueA;
  final double? valueB;
  final String Function(double value) format;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final t = context.t;
    final a = valueA ?? 0;
    final b = valueB ?? 0;
    final maxValue = [a.abs(), b.abs(), 0.0001].reduce((x, y) => x > y ? x : y);

    return Semantics(
      label: '$title. $labelA: ${valueA == null ? 'sin dato' : format(a)}. '
          '$labelB: ${valueB == null ? 'sin dato' : format(b)}.',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: t.label),
          const SizedBox(height: AppSpace.sm),
          _Bar(
            tag: labelA,
            fraction: a.abs() / maxValue,
            color: c.primary,
            valueText: valueA == null ? 'Sin dato' : format(a),
          ),
          const SizedBox(height: AppSpace.sm),
          _Bar(
            tag: labelB,
            fraction: b.abs() / maxValue,
            color: c.accent,
            valueText: valueB == null ? 'Sin dato' : format(b),
          ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.tag,
    required this.fraction,
    required this.color,
    required this.valueText,
  });

  final String tag;
  final double fraction;
  final Color color;
  final String valueText;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final t = context.t;
    return Row(
      children: [
        SizedBox(
          width: 20,
          child: Text(tag, style: t.label),
        ),
        Expanded(
          child: Container(
            height: 20,
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: c.outline)),
            ),
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: fraction.clamp(0.02, 1),
              heightFactor: 1,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: const BorderRadius.horizontal(
                    right: Radius.circular(4),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpace.sm),
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 72),
          child: Text(
            valueText,
            style: t.label,
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}
