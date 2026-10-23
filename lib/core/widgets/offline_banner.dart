import 'package:flutter/material.dart';

import '../design/app_colors.dart';
import '../design/app_icons.dart';
import '../design/app_tokens.dart';
import '../design/app_typography.dart';
import '../utils/responsive.dart';

/// Franja de estado 100% offline según el diseño §7.12.
/// Se muestra en la parte superior para recordar al productor que sus datos
/// están completamente seguros en el dispositivo.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({
    super.key,
    this.message = '100% sin conexión · Sus registros se guardan en el teléfono',
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final t = context.t;
    final pad = context.screenPadding;

    return Container(
      width: double.infinity,
      color: c.infoSoft,
      padding: EdgeInsets.symmetric(horizontal: pad, vertical: AppSpace.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(AppIcons.offline, size: AppSize.iconSm, color: c.info),
          const SizedBox(width: AppSpace.sm),
          Flexible(
            child: Text(
              message,
              style: t.caption.copyWith(
                color: c.ink,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
