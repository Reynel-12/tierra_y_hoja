import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/database/data_changes.dart';
import '../../../core/database/db_schema.dart';
import '../../../core/design/app_colors.dart';
import '../../../core/design/app_icons.dart';
import '../../../core/design/app_tokens.dart';
import '../../../core/design/app_typography.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/badges.dart';
import '../../../core/widgets/dialogs.dart';
import '../../../core/widgets/feedback_states.dart';
import '../../../core/widgets/layout.dart';
import '../models/backup_models.dart';
import '../services/backup_service.dart';

/// Vista principal del módulo de Copias de Seguridad y Restauración de Datos.
/// Permite respaldar base de datos y fotos en un solo archivo comprimido,
/// configurar la ruta de guardado, compartir vía share_plus y restaurar verificando integridad.
class BackupRestoreView extends StatefulWidget {
  const BackupRestoreView({super.key});

  @override
  State<BackupRestoreView> createState() => _BackupRestoreViewState();
}

class _BackupRestoreViewState extends State<BackupRestoreView> {
  bool _isLoading = true;
  bool _isCreating = false;
  String _progressMessage = '';

  Directory? _currentDir;
  bool _isCustomDir = false;
  BackupContentStats _currentStats = const BackupContentStats();
  List<BackupFileItem> _backups = [];
  StreamSubscription<Set<DbTable>>? _dbSub;

  @override
  void initState() {
    super.initState();
    _loadData();
    _listenDataChanges();
  }

  void _listenDataChanges() {
    final changes = context.read<DataChanges?>();
    if (changes != null) {
      _dbSub = changes.stream.listen((_) {
        if (mounted && !_isCreating) {
          _reloadStatsOnly();
        }
      });
    }
  }

  @override
  void dispose() {
    _dbSub?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    final service = context.read<BackupService>();
    try {
      final dir = await service.getConfiguredBackupDirectory();
      final isCustom = await service.isCustomDirectoryConfigured();
      final stats = await service.getCurrentStats();
      final backups = await service.listBackups();

      if (mounted) {
        setState(() {
          _currentDir = dir;
          _isCustomDir = isCustom;
          _currentStats = stats;
          _backups = backups;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _reloadStatsOnly() async {
    final service = context.read<BackupService>();
    try {
      final stats = await service.getCurrentStats();
      final backups = await service.listBackups();
      if (mounted) {
        setState(() {
          _currentStats = stats;
          _backups = backups;
        });
      }
    } catch (_) {}
  }

  Future<void> _handleChangeDirectory() async {
    final service = context.read<BackupService>();
    try {
      final selectedPath = await FilePickerPlatform.instance.getDirectoryPath(
        dialogTitle: 'Seleccione la carpeta donde guardar los respaldos',
      );

      if (!mounted) return;

      if (selectedPath != null && selectedPath.trim().isNotEmpty) {
        await service.setConfiguredBackupDirectory(selectedPath);
        if (mounted) {
          AppToast.success(context, 'Carpeta de respaldos actualizada.');
          await _loadData();
        }
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, 'No se pudo seleccionar la carpeta: $e');
      }
      debugPrint('No se pudo seleccionar la carpeta: $e');
    }
  }

  Future<void> _handleResetDirectory() async {
    final service = context.read<BackupService>();
    await service.setConfiguredBackupDirectory(null);
    if (mounted) {
      AppToast.info(
        context,
        'Se restableció la ruta predeterminada de la app.',
      );
      await _loadData();
    }
  }

  // ==================== CREAR COPIA DE SEGURIDAD ====================

  Future<void> _handleCreateBackup() async {
    final service = context.read<BackupService>();
    setState(() {
      _isCreating = true;
      _progressMessage = 'Iniciando copia de seguridad...';
    });

    try {
      final backup = await service.createBackup(
        onProgress: (msg) {
          if (mounted) setState(() => _progressMessage = msg);
        },
      );

      if (mounted) {
        setState(() => _isCreating = false);
        await _loadData();
        _showBackupSuccessSheet(backup);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCreating = false);
        AppToast.error(context, 'Error al crear la copia de seguridad: $e');
      }
    }
  }

  void _showBackupSuccessSheet(BackupFileItem backup) {
    final c = context.c;
    final t = context.t;
    final stats = backup.manifest?.stats ?? _currentStats;

    showAppSheet<void>(
      context,
      title: 'Copia creada exitosamente',
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpace.lg),
              decoration: BoxDecoration(
                color: c.tint(c.positive),
                borderRadius: AppRadius.control,
                border: Border.all(color: c.positive.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    AppIcons.checkCircle,
                    color: c.positive,
                    size: AppSize.iconLg,
                  ),
                  const SizedBox(width: AppSpace.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Copia completa generada', style: t.titleSm),
                        Text(
                          'Base de datos y fotografías comprimidas correctamente.',
                          style: t.caption,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpace.lg),
            _DetailRow(
              label: 'Nombre del archivo:',
              value: backup.name,
              isMono: true,
            ),
            _DetailRow(label: 'Tamaño total:', value: backup.formattedSize),
            _DetailRow(label: 'Ubicación:', value: backup.path, isMono: true),
            const SizedBox(height: AppSpace.md),
            const Divider(),
            const SizedBox(height: AppSpace.sm),
            Text('Contenido respaldado:', style: t.label),
            const SizedBox(height: AppSpace.xs),
            Wrap(
              spacing: AppSpace.sm,
              runSpacing: AppSpace.xs,
              children: [
                InfoChip(
                  icon: AppIcons.plot,
                  label: '${stats.plots} lotes',
                  color: c.primary,
                  background: c.tint(c.primary),
                ),
                InfoChip(
                  icon: AppIcons.cycle,
                  label: '${stats.cycles} siembras',
                  color: c.primary,
                  background: c.tint(c.primary),
                ),
                InfoChip(
                  icon: AppIcons.application,
                  label: '${stats.totalRecords} registros',
                  color: c.primary,
                  background: c.tint(c.primary),
                ),
                InfoChip(
                  icon: AppIcons.photo,
                  label: '${stats.photos} fotos',
                  color: c.primary,
                  background: c.tint(c.primary),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.xxl),
            AppButton.primary(
              label: 'Compartir copia ahora',
              icon: AppIcons.share,
              onPressed: () {
                Navigator.of(sheetContext).pop();
                _handleShareBackup(backup.path);
              },
            ),
            const SizedBox(height: AppSpace.sm),
            AppButton.outline(
              label: 'Cerrar',
              onPressed: () => Navigator.of(sheetContext).pop(),
            ),
            const SizedBox(height: AppSpace.lg),
          ],
        ),
      ),
    );
  }

  // ==================== COMPARTIR COPIA ====================

  Future<void> _handleShareBackup(String filePath) async {
    final service = context.read<BackupService>();
    try {
      await service.shareBackup(filePath);
    } catch (e) {
      if (mounted) {
        AppToast.error(context, 'No se pudo compartir el archivo: $e');
      }
    }
  }

  // ==================== RESTAURAR COPIA ====================

  Future<void> _handlePickFileAndRestore() async {
    try {
      final result = await FilePickerPlatform.instance.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip', 'tyh'],
        dialogTitle: 'Seleccione el archivo de respaldo para restaurar',
      );

      if (!mounted || result.isEmpty) return;
      final path = result.first.path;
      if (path != null && path.isNotEmpty) {
        await _confirmAndRestore(path);
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, 'Error al seleccionar el archivo: $e');
      }
    }
  }

  Future<void> _confirmAndRestore(String filePath) async {
    final service = context.read<BackupService>();

    // 1. Mostrar diálogo de inspección mientras se lee el archivo
    _showProgressDialog('Inspeccionando archivo de respaldo...');
    final inspection = await service.inspectBackupFile(filePath);
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop(); // Cierra el progreso

    // 2. Si el archivo no es válido, alertar con el motivo
    if (!inspection.isValid) {
      _showInvalidBackupAlert(inspection.errorMessage ?? 'Archivo no válido.');
      return;
    }

    // 3. Confirmar con el usuario mostrando el desglose detallado
    final confirmed = await _showRestoreConfirmationDialog(inspection);
    if (!confirmed || !mounted) return;

    // 4. Proceder con la restauración segura
    _showProgressDialog('Restaurando base de datos y fotos...');
    try {
      final manifest = await service.restoreBackup(
        filePath,
        onProgress: (stepMsg) {
          // Si quisiéramos actualizar el mensaje del diálogo
        },
      );

      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop(); // Cierra progreso

      AppToast.success(
        context,
        '¡Restauración completada con éxito! Se cargaron los datos de ${manifest.app}.',
      );
      await _loadData();
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      AppToast.error(context, 'Error durante la restauración: $e');
    }
  }

  void _showProgressDialog(String message) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final c = ctx.c;
        final t = ctx.t;
        return PopScope(
          canPop: false,
          child: Dialog(
            child: Padding(
              padding: const EdgeInsets.all(AppSpace.xxl),
              child: Row(
                children: [
                  CircularProgressIndicator(color: c.primary),
                  const SizedBox(width: AppSpace.xl),
                  Expanded(child: Text(message, style: t.body)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showInvalidBackupAlert(String errorMsg) {
    final c = context.c;
    final t = context.t;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(AppIcons.warning, color: c.negative, size: AppSize.iconLg),
        title: Text('Copia no válida', style: t.title),
        content: Text(errorMsg, style: t.body),
        actions: [
          AppButton.primary(
            label: 'Entendido',
            onPressed: () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
    );
  }

  Future<bool> _showRestoreConfirmationDialog(
    BackupInspectionResult inspection,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final c = ctx.c;
        final t = ctx.t;
        final stats = inspection.manifest?.stats ?? const BackupContentStats();
        final photos = stats.photos > 0
            ? stats.photos
            : inspection.detectedPhotos;

        return Dialog(
          insetPadding: EdgeInsets.symmetric(
            horizontal: ctx.screenPadding,
            vertical: AppSpace.xxl,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(AppSpace.xxl),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        CircleIcon(
                          icon: AppIcons.warning,
                          size: AppSize.touch,
                          color: c.negative,
                        ),
                        const SizedBox(width: AppSpace.md),
                        Expanded(
                          child: Text('Confirmar Restauración', style: t.title),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpace.lg),

                    // Advertencia de sustitución
                    Container(
                      padding: const EdgeInsets.all(AppSpace.md),
                      decoration: BoxDecoration(
                        color: c.tint(c.negative),
                        borderRadius: AppRadius.control,
                        border: Border.all(
                          color: c.negative.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            AppIcons.info,
                            color: c.negative,
                            size: AppSize.iconSm,
                          ),
                          const SizedBox(width: AppSpace.sm),
                          Expanded(
                            child: Text(
                              'Esta acción reemplazará TODOS los datos actuales del teléfono con los de la copia de seguridad. Los cambios no guardados se perderán.',
                              style: t.bodySm.copyWith(color: c.ink),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpace.lg),

                    // Ficha de inspección
                    Text('Datos contenidos en el respaldo:', style: t.label),
                    const SizedBox(height: AppSpace.xs),
                    _DetailRow(
                      label: 'Fecha de la copia:',
                      value: inspection.formattedDate,
                    ),
                    _DetailRow(
                      label: 'Tamaño del archivo:',
                      value: inspection.formattedSize,
                    ),
                    _DetailRow(
                      label: 'Versión registrada:',
                      value: inspection.manifest?.version ?? '1.1.0',
                    ),
                    const SizedBox(height: AppSpace.sm),
                    const Divider(),
                    const SizedBox(height: AppSpace.sm),

                    Wrap(
                      spacing: AppSpace.sm,
                      runSpacing: AppSpace.xs,
                      children: [
                        InfoChip(
                          icon: AppIcons.plot,
                          label: '${stats.plots} lotes',
                          color: c.primary,
                          background: c.tint(c.primary),
                        ),
                        InfoChip(
                          icon: AppIcons.cycle,
                          label: '${stats.cycles} siembras',
                          color: c.primary,
                          background: c.tint(c.primary),
                        ),
                        InfoChip(
                          icon: AppIcons.application,
                          label: '${stats.totalRecords} registros',
                          color: c.primary,
                          background: c.tint(c.primary),
                        ),
                        InfoChip(
                          icon: AppIcons.photo,
                          label: '$photos fotos',
                          color: c.primary,
                          background: c.tint(c.primary),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpace.xxl),

                    if (ctx.isTiny) ...[
                      AppButton.destructive(
                        label: 'Reemplazar y restaurar',
                        icon: AppIcons.restore,
                        onPressed: () => Navigator.of(ctx).pop(true),
                      ),
                      const SizedBox(height: AppSpace.sm),
                      AppButton.outline(
                        label: 'Cancelar',
                        onPressed: () => Navigator.of(ctx).pop(false),
                      ),
                    ] else
                      Row(
                        children: [
                          Expanded(
                            child: AppButton.outline(
                              label: 'Cancelar',
                              onPressed: () => Navigator.of(ctx).pop(false),
                            ),
                          ),
                          const SizedBox(width: AppSpace.md),
                          Expanded(
                            child: AppButton.destructive(
                              label: 'Restaurar todo',
                              icon: AppIcons.restore,
                              onPressed: () => Navigator.of(ctx).pop(true),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    return result ?? false;
  }

  // ==================== ELIMINAR COPIA ====================

  Future<void> _handleDeleteBackup(String filePath) async {
    final service = context.read<BackupService>();
    final confirm = await showConfirmDialog(
      context,
      title: '¿Eliminar copia de seguridad?',
      message:
          'El archivo será borrado permanentemente de la carpeta de respaldos. Esta acción no se puede deshacer.',
      confirmLabel: 'Eliminar copia',
      destructive: true,
    );

    if (confirm && mounted) {
      await service.deleteBackup(filePath);
      if (mounted) {
        AppToast.info(context, 'Copia de seguridad eliminada.');
        await _loadData();
      }
    }
  }

  // ==================== CONSTRUCCIÓN DE LA VISTA ====================

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final t = context.t;
    final pad = context.screenPadding;

    if (_isLoading) {
      return Scaffold(
        appBar: const AppTopBar(title: 'Copias y Restauración'),
        body: Center(child: CircularProgressIndicator(color: c.primary)),
      );
    }

    return Scaffold(
      appBar: const AppTopBar(title: 'Copias y Restauración'),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(pad, AppSpace.sm, pad, AppSpace.x4),
        child: ContentWidth(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const ScreenTitle(
                'Copias y Restauración',
                subtitle:
                    'Respaldo completo de base de datos y fotografías sin conexión',
              ),
              const SizedBox(height: AppSpace.xl),

              // ================= SECCIÓN 1: RUTA DE ALMACENAMIENTO =================
              const SectionHeader(title: 'Ubicación de almacenamiento'),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (context.isTiny) ...[
                      Row(
                        children: [
                          CircleIcon(icon: AppIcons.folder, color: c.primary),
                          const SizedBox(width: AppSpace.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Carpeta de respaldos', style: t.titleSm),
                                Text(
                                  _isCustomDir
                                      ? 'Ubicación personalizada'
                                      : 'Ubicación predeterminada del teléfono',
                                  style: t.caption,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpace.xs),
                      StatusBadge(
                        label: _isCustomDir ? 'Personalizada' : 'Por defecto',
                        icon: _isCustomDir
                            ? AppIcons.edit
                            : AppIcons.checkCircle,
                        color: _isCustomDir ? c.accentText : c.positive,
                      ),
                    ] else
                      Row(
                        children: [
                          CircleIcon(icon: AppIcons.folder, color: c.primary),
                          const SizedBox(width: AppSpace.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Carpeta de respaldos', style: t.titleSm),
                                Text(
                                  _isCustomDir
                                      ? 'Ubicación personalizada'
                                      : 'Ubicación predeterminada del teléfono',
                                  style: t.caption,
                                ),
                              ],
                            ),
                          ),
                          StatusBadge(
                            label: _isCustomDir
                                ? 'Personalizada'
                                : 'Por defecto',
                            icon: _isCustomDir
                                ? AppIcons.edit
                                : AppIcons.checkCircle,
                            color: _isCustomDir ? c.accentText : c.positive,
                          ),
                        ],
                      ),
                    const SizedBox(height: AppSpace.md),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpace.md,
                        vertical: AppSpace.sm,
                      ),
                      decoration: BoxDecoration(
                        color: c.surfaceAlt,
                        borderRadius: AppRadius.control,
                        border: Border.all(color: c.outline),
                      ),
                      child: Text(
                        _currentDir?.path ?? 'Cargando ruta...',
                        style: t.bodySm.copyWith(
                          fontFamily: 'monospace',
                          color: c.ink,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpace.md),
                    Wrap(
                      spacing: AppSpace.sm,
                      runSpacing: AppSpace.xs,
                      children: [
                        AppButton.outline(
                          label: 'Cambiar carpeta',
                          icon: AppIcons.folderOpen,
                          expand: false,
                          onPressed: _handleChangeDirectory,
                        ),
                        if (_isCustomDir)
                          AppButton.text(
                            label: 'Restablecer por defecto',
                            icon: AppIcons.delete,
                            expand: false,
                            onPressed: _handleResetDirectory,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpace.section),

              // ================= SECCIÓN 2: CREAR COPIA =================
              const SectionHeader(title: 'Crear copia de seguridad'),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleIcon(icon: AppIcons.database, color: c.primary),
                        const SizedBox(width: AppSpace.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Respaldo completo', style: t.titleSm),
                              Text(
                                'Empaqueta base de datos y todas las fotografías',
                                style: t.caption,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpace.md),
                    Text(
                      'Esta función crea un único archivo (.tyh.zip) que contiene todos los lotes, ciclos de siembra, labores, insumos, costos y las fotos capturadas. Podrá compartirlo directamente por WhatsApp, guardarlo en Google Drive o enviarlo por correo.',
                      style: t.bodySm,
                    ),
                    const SizedBox(height: AppSpace.md),

                    // Resumen de datos actuales
                    Container(
                      padding: const EdgeInsets.all(AppSpace.md),
                      decoration: BoxDecoration(
                        color: c.surfaceAlt,
                        borderRadius: AppRadius.control,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Datos actuales a respaldar:', style: t.caption),
                          const SizedBox(height: AppSpace.xs),
                          Wrap(
                            spacing: AppSpace.sm,
                            runSpacing: AppSpace.xs,
                            children: [
                              InfoChip(
                                icon: AppIcons.plot,
                                label: '${_currentStats.plots} lotes',
                                color: c.ink,
                                background: c.surface,
                              ),
                              InfoChip(
                                icon: AppIcons.cycle,
                                label: '${_currentStats.cycles} siembras',
                                color: c.ink,
                                background: c.surface,
                              ),
                              InfoChip(
                                icon: AppIcons.application,
                                label:
                                    '${_currentStats.totalRecords} registros',
                                color: c.ink,
                                background: c.surface,
                              ),
                              InfoChip(
                                icon: AppIcons.photo,
                                label: '${_currentStats.photos} fotos',
                                color: c.ink,
                                background: c.surface,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpace.lg),

                    if (_isCreating) ...[
                      LinearProgressIndicator(color: c.primary),
                      const SizedBox(height: AppSpace.xs),
                      Text(_progressMessage, style: t.caption),
                      const SizedBox(height: AppSpace.md),
                    ],

                    AppButton.primary(
                      label: 'Crear copia de seguridad ahora',
                      icon: AppIcons.archive,
                      loading: _isCreating,
                      onPressed: _isCreating ? () {} : _handleCreateBackup,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpace.section),

              // ================= SECCIÓN 3: RESTAURAR COPIA =================
              const SectionHeader(title: 'Restaurar copia de seguridad'),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleIcon(icon: AppIcons.restore, color: c.accent),
                        const SizedBox(width: AppSpace.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Restaurar desde archivo', style: t.titleSm),
                              Text(
                                'Recupere una copia previa o transferida',
                                style: t.caption,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpace.md),
                    Text(
                      'Seleccione un archivo de respaldo guardado en su memoria o recibido por WhatsApp u otra aplicación. Se validará su contenido y se le pedirá confirmación antes de restaurar.',
                      style: t.bodySm,
                    ),
                    const SizedBox(height: AppSpace.md),
                    AppButton.outline(
                      label: 'Seleccionar archivo de respaldo...',
                      icon: AppIcons.search,
                      onPressed: _handlePickFileAndRestore,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpace.section),

              // ================= SECCIÓN 4: LISTA DE RESPALDOS DETECTADOS =================
              SectionHeader(title: 'Copias en la carpeta (${_backups.length})'),
              if (_backups.isEmpty)
                const AppCard(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpace.lg),
                    child: Center(
                      child: EmptyState(
                        icon: AppIcons.database,
                        title: 'Sin copias en esta carpeta',
                        message:
                            'Las copias que cree o mueva a su carpeta de respaldos aparecerán aquí para compartirlas o restaurarlas con un toque.',
                      ),
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _backups.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpace.sm),
                  itemBuilder: (context, index) {
                    final item = _backups[index];
                    return _BackupCard(
                      item: item,
                      onShare: () => _handleShareBackup(item.path),
                      onRestore: () => _confirmAndRestore(item.path),
                      onDelete: () => _handleDeleteBackup(item.path),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Fila simple de etiqueta y valor
class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.isMono = false,
  });

  final String label;
  final String value;
  final bool isMono;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final c = context.c;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 2, child: Text(label, style: t.caption)),
          const SizedBox(width: AppSpace.sm),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: isMono
                  ? t.caption.copyWith(fontFamily: 'monospace', color: c.ink)
                  : t.label,
            ),
          ),
        ],
      ),
    );
  }
}

/// Tarjeta individual para una copia de seguridad listada
class _BackupCard extends StatelessWidget {
  const _BackupCard({
    required this.item,
    required this.onShare,
    required this.onRestore,
    required this.onDelete,
  });

  final BackupFileItem item;
  final VoidCallback onShare;
  final VoidCallback onRestore;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final t = context.t;
    final manifest = item.manifest;

    return AppCard(
      padding: const EdgeInsets.all(AppSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleIcon(
                icon: AppIcons.database,
                size: AppSize.touch,
                color: c.primary,
              ),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: t.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${item.formattedDate} · ${item.formattedSize}',
                      style: t.caption,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  AppIcons.delete,
                  color: c.negative,
                  size: AppSize.iconSm,
                ),
                tooltip: 'Eliminar copia',
                onPressed: onDelete,
              ),
            ],
          ),
          if (manifest != null) ...[
            const SizedBox(height: AppSpace.sm),
            Wrap(
              spacing: AppSpace.xs,
              children: [
                Text(
                  '${manifest.stats.plots} lotes · ${manifest.stats.cycles} siembras · ${manifest.stats.photos} fotos',
                  style: t.caption.copyWith(color: c.inkSoft),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppSpace.md),
          const Divider(),
          const SizedBox(height: AppSpace.xs),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: AppSpace.sm,
            runSpacing: AppSpace.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              TextButton.icon(
                onPressed: onShare,
                icon: Icon(
                  AppIcons.share,
                  size: AppSize.iconSm,
                  color: c.primary,
                ),
                label: Text('Compartir', style: TextStyle(color: c.primary)),
              ),
              FilledButton.icon(
                onPressed: onRestore,
                style: FilledButton.styleFrom(
                  backgroundColor: c.primary,
                  foregroundColor: c.onPrimary,
                ),
                icon: Icon(
                  AppIcons.restore,
                  size: AppSize.iconSm,
                  color: c.onPrimary,
                ),
                label: Text(
                  'Restaurar',
                  style: TextStyle(
                    color: c.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
