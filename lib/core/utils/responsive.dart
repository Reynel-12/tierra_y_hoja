import 'package:flutter/widgets.dart';

import '../design/app_tokens.dart';

/// Ayudas para adaptar la interfaz a teléfonos pequeños, grandes y tabletas.
extension ResponsiveX on BuildContext {
  double get screenWidth => MediaQuery.sizeOf(this).width;

  /// Teléfonos angostos (≤ 360 dp, ej. 320–360).
  bool get isCompact => screenWidth < 361;

  /// Teléfonos muy pequeños (< 340 dp).
  bool get isTiny => screenWidth < 340;

  /// Tabletas u horizontal amplio.
  bool get isWide => screenWidth >= 600;

  /// Margen horizontal de pantalla según el ancho.
  double get screenPadding =>
      isTiny ? AppSpace.screenHCompact : AppSpace.screenH;
}

/// Centra el contenido y limita el ancho en pantallas grandes, para que las
/// listas y formularios no se estiren en tabletas u horizontal.
class ContentWidth extends StatelessWidget {
  const ContentWidth({
    super.key,
    required this.child,
    this.maxWidth = AppSize.maxContentWidth,
    this.alignment = Alignment.topCenter,
    this.heightFactor = 1.0,
  });

  final Widget child;
  final double maxWidth;
  final AlignmentGeometry alignment;
  final double? heightFactor;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      heightFactor: heightFactor,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
