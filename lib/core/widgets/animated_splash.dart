// lib/core/widgets/animated_splash.dart
//
// Splash animado "Tierra & Hoja".
// Usa EXACTAMENTE los mismos paths, medidas y colores de splash_screen.svg
// (lienzo de 1024 x 1024). El último fotograma es idéntico al SVG original.
//
// Secuencia (1200 ms en total):
//   0 - 600 ms   la hoja crece desde su base (se estira y se abre, con un
//                leve giro que se asienta)
//   380 - 820 ms la vena se dibuja desde la base hacia la punta
//   700 - 1100ms el nombre aparece con fundido y un pequeño ascenso
//
// El splash NO añade espera: la inicialización de la app corre en paralelo
// (`ready`) y se pasa a la app apenas terminen la animación Y la carga.

import 'dart:math' as math;
import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';

import '../design/app_colors.dart';
import '../design/app_typography.dart';

class AnimatedSplash extends StatefulWidget {
  const AnimatedSplash({
    super.key,
    required this.ready,
    required this.onDone,
    this.backgroundColor,
    this.color,
  });

  /// Tu inicialización (abrir base de datos, leer sesión, preferencias...).
  /// Se ejecuta mientras suena la animación.
  final Future<void> ready;

  /// Se llama cuando terminaron la animación y la inicialización.
  final VoidCallback onDone;

  /// Color de fondo opcional. Si es nulo, usa `context.c.bg` del tema activo.
  final Color? backgroundColor;

  /// Color de la hoja y el texto opcional. Si es nulo, usa `context.c.primary`.
  final Color? color;

  @override
  State<AnimatedSplash> createState() => _AnimatedSplashState();
}

class _AnimatedSplashState extends State<AnimatedSplash>
    with SingleTickerProviderStateMixin {
  static const _duration = Duration(milliseconds: 1200);

  late final AnimationController _controller =
      AnimationController(vsync: this, duration: _duration);

  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _run(reduceMotion: MediaQuery.disableAnimationsOf(context));
  }

  Future<void> _run({required bool reduceMotion}) async {
    final Future<void> animation;
    if (reduceMotion) {
      // Sin movimiento: se muestra el diseño final una fracción de segundo.
      _controller.value = 1;
      animation = Future<void>.delayed(const Duration(milliseconds: 300));
    } else {
      animation = _controller.forward();
    }

    try {
      await Future.wait<void>([animation, widget.ready]);
    } catch (_) {
      // El manejo de errores de arranque va dentro de tu `ready`;
      // aquí nunca se deja al usuario atrapado en el splash.
    }

    if (!mounted) return;
    widget.onDone();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final side = MediaQuery.sizeOf(context).shortestSide;
    final colors = context.c;
    final bgColor = widget.backgroundColor ?? colors.bg;
    final primaryColor = widget.color ?? colors.primary;

    return Scaffold(
      backgroundColor: bgColor,
      body: Center(
        child: SizedBox.square(
          dimension: side,
          child: FittedBox(
            child: SizedBox.square(
              dimension: 1024,
              child: _SplashArt(
                animation: _controller,
                color: primaryColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SplashArt extends StatelessWidget {
  const _SplashArt({
    required this.animation,
    required this.color,
  });

  final Animation<double> animation;
  final Color color;

  static double _phase(double t, double begin, double end, Curve curve) =>
      curve.transform(((t - begin) / (end - begin)).clamp(0.0, 1.0));

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final t = animation.value;
        final length = _phase(t, 0.00, 0.50, Curves.easeOutCubic);
        final width = _phase(t, 0.00, 0.58, Curves.easeOutCubic);
        final vein = _phase(t, 0.32, 0.68, Curves.easeInOutCubic);
        final name = _phase(t, 0.58, 0.92, Curves.easeOutCubic);

        return Semantics(
          label: 'Tierra & Hoja',
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: _LeafPainter(
                      length: length,
                      width: width,
                      vein: vein,
                      color: color,
                    ),
                  ),
                ),
              ),
              // Mismo texto del SVG: centrado en x = 512, línea base en y = 880.
              Positioned(
                left: 0,
                top: 0,
                width: 1024,
                child: ExcludeSemantics(
                  child: Baseline(
                    baseline: 880,
                    baselineType: TextBaseline.alphabetic,
                    child: Opacity(
                      opacity: name,
                      child: Transform.translate(
                        offset: Offset(0, (1 - name) * 14),
                        child: SizedBox(
                          width: 1024,
                          child: Text(
                            'Tierra & Hoja',
                            textAlign: TextAlign.center,
                            softWrap: false,
                            textScaler: TextScaler.noScaling,
                            style: TextStyle(
                              fontFamily: AppTypography.fontSerif,
                              fontSize: 92,
                              fontWeight: FontWeight.w600,
                              color: color,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LeafPainter extends CustomPainter {
  _LeafPainter({
    required this.length,
    required this.width,
    required this.vein,
    required this.color,
  }) : _leafPaint = Paint()
         ..color = color
         ..isAntiAlias = true;

  /// 0..1 crecimiento a lo largo del eje de la hoja (base -> punta).
  final double length;

  /// 0..1 crecimiento a lo ancho (va un poco por detrás del largo).
  final double width;

  /// 0..1 avance del corte de la vena.
  final double vein;

  final Color color;

  // Base de la hoja: de aquí "nace".
  static const _anchor = Offset(270, 735);

  // Paths copiados tal cual del SVG.
  static final Path _leaf = Path()
    ..moveTo(270, 735)
    ..cubicTo(292, 590, 356, 411, 718, 277)
    ..cubicTo(701, 470, 563, 644, 270, 735)
    ..close();

  static final Path _vein = Path()
    ..moveTo(283, 720)
    ..cubicTo(355, 585, 459, 451, 624, 365);

  static final PathMetric _veinMetric = _vein.computeMetrics().first;

  // Ángulo del eje base -> punta (≈ -45.6°).
  static final double _axis = math.atan2(277 - 735, 718 - 270);

  final Paint _leafPaint;

  // La vena es un recorte (espacio negativo), igual que la máscara del SVG.
  static final Paint _cutPaint = Paint()
    ..blendMode = BlendMode.clear
    ..style = PaintingStyle.stroke
    ..strokeWidth = 34
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..isAntiAlias = true;

  @override
  void paint(Canvas canvas, Size size) {
    if (length <= 0 || width <= 0) return;

    // Giro inicial leve (más erguida) que se asienta en la posición final.
    final swing = -(1 - length) * 0.16;

    canvas.saveLayer(Offset.zero & size, Paint());

    // Escala anisotrópica anclada en la base, alineada al eje de la hoja.
    // Con length = width = 1 y swing = 0 la transformación es la identidad.
    canvas.translate(_anchor.dx, _anchor.dy);
    canvas.rotate(_axis + swing);
    canvas.scale(length, width);
    canvas.rotate(-_axis);
    canvas.translate(-_anchor.dx, -_anchor.dy);

    canvas.drawPath(_leaf, _leafPaint);

    if (vein > 0.001) {
      canvas.drawPath(
        _veinMetric.extractPath(0, _veinMetric.length * vein),
        _cutPaint,
      );
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(_LeafPainter old) =>
      old.length != length ||
      old.width != width ||
      old.vein != vein ||
      old.color != color;
}

// ---------------------------------------------------------------------------
// Ejemplo de uso (pégalo en tu raíz, p. ej. lib/app_root.dart)
// ---------------------------------------------------------------------------
//
// class AppRoot extends StatefulWidget {
//   const AppRoot({super.key});
//
//   @override
//   State<AppRoot> createState() => _AppRootState();
// }
//
// class _AppRootState extends State<AppRoot> {
//   late final Future<void> _init = _bootstrap();
//   bool _done = false;
//
//   Future<void> _bootstrap() async {
//     // Abrir SQLite / Supabase, leer sesión, cargar preferencias...
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return AnimatedSwitcher(
//       duration: const Duration(milliseconds: 250),
//       child: _done
//           ? const TuPantallaInicial(key: ValueKey('home'))
//           : AnimatedSplash(
//               key: const ValueKey('splash'),
//               ready: _init,
//               onDone: () => setState(() => _done = true),
//             ),
//     );
//   }
// }
