import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../design/app_colors.dart';
import '../../design/app_icons.dart';
import '../../design/app_tokens.dart';
import '../../design/app_typography.dart';
import '../../services/photo_storage_service.dart';
import '../../utils/formatters.dart';
import '../app_top_bar.dart';
import '../dialogs.dart';
import '../form/fields.dart';

/// Miniatura de foto desde archivo local. Decodifica al tamaño mostrado
/// para ahorrar memoria.
class PhotoThumb extends StatelessWidget {
  const PhotoThumb({
    super.key,
    required this.path,
    this.size = AppSize.thumb,
    this.aspectRatio = 1,
    this.radius = AppRadius.xs,
    this.semanticLabel = 'Foto',
  });

  final String? path;
  final double size;
  final double aspectRatio;
  final double radius;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    if (path == null || path!.trim().isEmpty) {
      return SizedBox(width: size, height: size / aspectRatio);
    }
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final c = context.c;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: size,
        height: size / aspectRatio,
        child: Image.file(
          File(path!),
          fit: BoxFit.cover,
          cacheWidth: (size * dpr).round(),
          semanticLabel: semanticLabel,
          errorBuilder: (_, _, _) => ColoredBox(
            color: c.surfaceAlt,
            child: Icon(AppIcons.image, color: c.inkMuted),
          ),
        ),
      ),
    );
  }
}

/// Miniatura compacta con etiqueta pill ("Antes" / "Después") y marco sutil.
/// Al tocar abre el visor completo o ejecuta su callback.
class PhotoPreviewThumb extends StatelessWidget {
  const PhotoPreviewThumb({
    super.key,
    required this.path,
    required this.label,
    this.size = 56,
    this.onTap,
  });

  final String path;
  final String label;
  final double size;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final t = context.t;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.xs),
          border: Border.all(color: c.outline, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            PhotoThumb(
              path: path,
              size: size,
              radius: AppRadius.xs,
              semanticLabel: 'Foto $label',
            ),
            Container(
              width: size,
              padding: const EdgeInsets.symmetric(vertical: 2),
              color: c.ink.withValues(alpha: 0.75),
              child: Text(
                label,
                style: t.caption.copyWith(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Foto a lo ancho (cabeceras 16:9) con decodificación ajustada.
class PhotoBanner extends StatelessWidget {
  const PhotoBanner({
    super.key,
    required this.path,
    this.aspectRatio = 16 / 9,
    this.radius = 0,
    this.semanticLabel = 'Foto',
  });

  final String path;
  final double aspectRatio;
  final double radius;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => PhotoThumb(
        path: path,
        size: constraints.maxWidth,
        aspectRatio: aspectRatio,
        radius: radius,
        semanticLabel: semanticLabel,
      ),
    );
  }
}

/// Pide al usuario elegir cámara o galería y guarda la foto comprimida.
Future<String?> pickPhoto(BuildContext context) async {
  final source = await showAppSheet<PhotoSource>(
    context,
    title: 'Agregar foto',
    builder: (sheetContext) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _SourceTile(
          icon: AppIcons.photo,
          label: 'Tomar foto',
          caption: 'Se guarda también en el álbum "Tierra y Hoja".',
          onTap: () => Navigator.of(sheetContext).pop(PhotoSource.camera),
        ),
        const SizedBox(height: AppSpace.sm),
        _SourceTile(
          icon: AppIcons.gallery,
          label: 'Elegir de la galería',
          caption: 'Use una foto que ya tiene en el teléfono.',
          onTap: () => Navigator.of(sheetContext).pop(PhotoSource.gallery),
        ),
      ],
    ),
  );
  if (source == null || !context.mounted) return null;
  try {
    return await context.read<PhotoStorageService>().pick(source);
  } on PhotoException catch (e) {
    if (context.mounted) AppToast.error(context, e.message);
    return null;
  }
}

class _SourceTile extends StatelessWidget {
  const _SourceTile({
    required this.icon,
    required this.label,
    required this.caption,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String caption;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final t = context.t;
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.control,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppSize.quickAddTile),
        child: Row(
          children: [
            Container(
              width: AppSize.touch,
              height: AppSize.touch,
              decoration: BoxDecoration(
                color: c.primarySoft,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: c.onPrimarySoft),
            ),
            const SizedBox(width: AppSpace.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label, style: t.title),
                  Text(caption, style: t.bodySm),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Campo de una foto: botón para agregar o miniatura con cambiar/quitar.
class PhotoField extends StatelessWidget {
  const PhotoField({
    super.key,
    required this.label,
    required this.path,
    required this.onChanged,
    this.helper,
  });

  final String label;
  final String? path;
  final ValueChanged<String?> onChanged;
  final String? helper;

  Future<void> _add(BuildContext context) async {
    final picked = await pickPhoto(context);
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final t = context.t;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        FieldLabel(label),
        if (path == null)
          Semantics(
            button: true,
            label: 'Agregar foto: $label',
            excludeSemantics: true,
            child: InkWell(
              onTap: () => _add(context),
              borderRadius: AppRadius.control,
              child: Container(
                height: 96,
                decoration: BoxDecoration(
                  color: c.surfaceAlt,
                  borderRadius: AppRadius.control,
                  border: Border.all(color: c.outlineStrong, width: 1.5),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      AppIcons.photo,
                      color: c.primary,
                      size: AppSize.iconLg,
                    ),
                    const SizedBox(height: AppSpace.xs),
                    Text('Agregar foto', style: t.label),
                  ],
                ),
              ),
            ),
          )
        else
          Row(
            children: [
              GestureDetector(
                onTap: () => PhotoViewerPage.open(context, before: path),
                child: PhotoThumb(
                  path: path!,
                  size: 96,
                  radius: AppRadius.md,
                  semanticLabel: label,
                ),
              ),
              const SizedBox(width: AppSpace.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextButton.icon(
                      onPressed: () => _add(context),
                      icon: const Icon(AppIcons.photo, size: AppSize.iconSm),
                      label: const Text('Cambiar foto'),
                    ),
                    TextButton.icon(
                      onPressed: () => onChanged(null),
                      style: TextButton.styleFrom(foregroundColor: c.negative),
                      icon: const Icon(AppIcons.delete, size: AppSize.iconSm),
                      label: const Text('Quitar'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        if (helper != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpace.xs),
            child: Text(helper!, style: t.caption),
          ),
      ],
    );
  }
}

/// Fotos antes / después: dos miniaturas 1:1 con etiqueta en pill y fecha.
/// Tocar abre la vista completa con deslizador de comparación.
class BeforeAfterPhotos extends StatelessWidget {
  const BeforeAfterPhotos({
    super.key,
    required this.before,
    required this.after,
    this.beforeDate,
    this.afterDate,
  });

  final String? before;
  final String? after;
  final DateTime? beforeDate;
  final DateTime? afterDate;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _LabeledPhoto(
            path: before,
            label: 'Antes',
            date: beforeDate,
            onTap: () =>
                PhotoViewerPage.open(context, before: before, after: after),
          ),
        ),
        const SizedBox(width: AppSpace.md),
        Expanded(
          child: _LabeledPhoto(
            path: after,
            label: 'Después',
            date: afterDate,
            onTap: () =>
                PhotoViewerPage.open(context, before: before, after: after),
          ),
        ),
      ],
    );
  }
}

class _LabeledPhoto extends StatelessWidget {
  const _LabeledPhoto({
    required this.path,
    required this.label,
    required this.date,
    required this.onTap,
  });

  final String? path;
  final String label;
  final DateTime? date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final t = context.t;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: path == null
              ? Container(
                  decoration: BoxDecoration(
                    color: c.surfaceAlt,
                    borderRadius: AppRadius.control,
                  ),
                  alignment: Alignment.center,
                  child: Text('Sin foto', style: t.caption),
                )
              : GestureDetector(
                  onTap: onTap,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      PhotoBanner(
                        path: path!,
                        aspectRatio: 1,
                        radius: AppRadius.md,
                        semanticLabel: 'Foto de $label',
                      ),
                      Positioned(
                        left: AppSpace.sm,
                        top: AppSpace.sm,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpace.sm + 2,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: c.ink.withValues(alpha: 0.8),
                            borderRadius: AppRadius.pill,
                          ),
                          child: Text(
                            label,
                            style: t.caption.copyWith(color: c.bg),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
        if (date != null) ...[
          const SizedBox(height: AppSpace.xs),
          Text(Formatters.date(date!), style: t.caption),
        ],
      ],
    );
  }
}

/// Vista completa de foto. Con dos fotos muestra un deslizador de
/// comparación antes/después.
class PhotoViewerPage extends StatefulWidget {
  const PhotoViewerPage({super.key, this.before, this.after});

  final String? before;
  final String? after;

  static Future<void> open(
    BuildContext context, {
    String? before,
    String? after,
  }) {
    if (before == null && after == null) return Future.value();
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PhotoViewerPage(before: before, after: after),
      ),
    );
  }

  @override
  State<PhotoViewerPage> createState() => _PhotoViewerPageState();
}

class _PhotoViewerPageState extends State<PhotoViewerPage> {
  double _split = 0.5;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final c = context.c;
    final before = widget.before;
    final after = widget.after;
    final compare = before != null && after != null;

    final Widget content;
    if (before != null && after != null) {
      content = LayoutBuilder(
        builder: (context, constraints) => Stack(
          fit: StackFit.expand,
          children: [
            Image.file(
              File(after),
              fit: BoxFit.contain,
              semanticLabel: 'Foto después',
              errorBuilder: (_, _, _) => Center(
                child: Icon(AppIcons.image, size: 48, color: c.inkMuted),
              ),
            ),
            ClipRect(
              clipper: _SplitClipper(_split),
              child: Image.file(
                File(before),
                fit: BoxFit.contain,
                semanticLabel: 'Foto antes',
                errorBuilder: (_, _, _) => Center(
                  child: Icon(AppIcons.image, size: 48, color: c.inkMuted),
                ),
              ),
            ),
            Positioned(
              left: constraints.maxWidth * _split - 1,
              top: 0,
              bottom: 0,
              child: Container(width: 2, color: c.surface),
            ),
          ],
        ),
      );
    } else {
      content = InteractiveViewer(
        maxScale: 4,
        child: Center(
          child: Image.file(
            File(before ?? after ?? ''),
            fit: BoxFit.contain,
            semanticLabel: 'Foto',
            errorBuilder: (_, _, _) => Center(
              child: Icon(AppIcons.image, size: 48, color: c.inkMuted),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppTopBar(title: compare ? 'Antes y después' : 'Foto'),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: content),
            if (compare)
              Padding(
                padding: const EdgeInsets.all(AppSpace.lg),
                child: Row(
                  children: [
                    Text('Antes', style: t.label),
                    Expanded(
                      child: Slider(
                        value: _split,
                        onChanged: (v) => setState(() => _split = v),
                        semanticFormatterCallback: (v) =>
                            'Comparación ${(v * 100).round()} %',
                      ),
                    ),
                    Text('Después', style: t.label),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SplitClipper extends CustomClipper<Rect> {
  const _SplitClipper(this.fraction);

  final double fraction;

  @override
  Rect getClip(Size size) =>
      Rect.fromLTWH(0, 0, size.width * fraction, size.height);

  @override
  bool shouldReclip(_SplitClipper oldClipper) =>
      oldClipper.fraction != fraction;
}
