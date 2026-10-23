import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../design/app_colors.dart';
import '../../design/app_icons.dart';
import '../../design/app_tokens.dart';
import '../../design/app_typography.dart';
import '../../services/location_service.dart';
import '../app_button.dart';
import 'fields.dart';

/// GPS opcional: botón "Usar mi ubicación" con explicación breve.
/// Nunca bloquea el guardado.
class LocationField extends StatefulWidget {
  const LocationField({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.onChanged,
  });

  final double? latitude;
  final double? longitude;
  final void Function(double? latitude, double? longitude) onChanged;

  @override
  State<LocationField> createState() => _LocationFieldState();
}

class _LocationFieldState extends State<LocationField> {
  bool _loading = false;
  String? _message;

  Future<void> _locate() async {
    setState(() {
      _loading = true;
      _message = null;
    });
    final result = await context.read<LocationService>().current();
    if (!mounted) return;
    setState(() => _loading = false);
    switch (result) {
      case LocationFound(:final latitude, :final longitude):
        widget.onChanged(latitude, longitude);
      case LocationUnavailable(:final message):
        setState(() => _message = message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final t = context.t;
    final hasLocation = widget.latitude != null && widget.longitude != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const FieldLabel('Ubicación'),
        if (hasLocation) ...[
          Container(
            padding: const EdgeInsets.all(AppSpace.md),
            decoration: BoxDecoration(
              color: c.infoSoft,
              borderRadius: AppRadius.control,
            ),
            child: Row(
              children: [
                Icon(AppIcons.location, color: c.info),
                const SizedBox(width: AppSpace.md),
                Expanded(
                  child: Text(
                    '${widget.latitude!.toStringAsFixed(5)}, '
                    '${widget.longitude!.toStringAsFixed(5)}',
                    style: t.body,
                  ),
                ),
                IconButton(
                  tooltip: 'Quitar ubicación',
                  icon: const Icon(AppIcons.close),
                  onPressed: () => widget.onChanged(null, null),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.sm),
        ],
        AppButton.outline(
          label: hasLocation ? 'Actualizar ubicación' : 'Usar mi ubicación',
          icon: AppIcons.crosshair,
          loading: _loading,
          onPressed: _locate,
        ),
        Padding(
          padding: const EdgeInsets.only(top: AppSpace.xs),
          child: Text(
            _message ??
                'Opcional. Funciona sin internet; el teléfono le pedirá permiso de ubicación.',
            style: _message == null ? t.caption : t.bodySm.copyWith(color: c.ink),
          ),
        ),
      ],
    );
  }
}
