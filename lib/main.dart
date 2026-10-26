import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

import 'app/app_shell.dart';
import 'core/database/app_database.dart';
import 'core/database/data_changes.dart';
import 'core/design/app_theme.dart';
import 'core/services/location_service.dart';
import 'core/services/photo_storage_service.dart';
import 'core/services/reminder_service.dart';
import 'core/services/speech_service.dart';
import 'core/state/theme_controller.dart';
import 'core/widgets/animated_splash.dart';
import 'features/activities/data/activity_repository.dart';
import 'features/backup/services/backup_service.dart';
import 'features/costs/data/cost_repository.dart';
import 'features/cycles/data/cycle_repository.dart';
import 'features/field_log/data/application_repository.dart';
import 'features/field_log/views/follow_up_form_view.dart';
import 'features/history/data/history_repository.dart';
import 'features/plots/data/plot_repository.dart';
import 'features/tour/controllers/guided_tour_controller.dart';
import 'features/tour/views/guided_tour_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  AppDatabase? database;
  ThemeMode initialThemeMode = ThemeMode.system;
  PackageInfo? packageInfo;

  try {
    database = await AppDatabase.open();
    initialThemeMode = await ThemeController.getSavedThemeMode(database);
  } catch (_) {}

  try {
    packageInfo = await PackageInfo.fromPlatform();
  } catch (_) {}

  packageInfo ??= PackageInfo(
    appName: 'Tierra & Hoja',
    packageName: 'com.tierrayhoja.app',
    version: '1.1.3',
    buildNumber: '5',
  );

  runApp(
    TierraYHojaApp(
      database: database,
      initialThemeMode: initialThemeMode,
      packageInfo: packageInfo,
    ),
  );
}

class _AppBootstrapData {
  const _AppBootstrapData({
    required this.database,
    required this.reminderService,
    required this.photoService,
    required this.locationService,
    required this.speechService,
    required this.plotRepo,
    required this.cycleRepo,
    required this.appRepo,
    required this.activityRepo,
    required this.costRepo,
    required this.historyRepo,
    required this.tourController,
    required this.themeController,
    required this.packageInfo,
    required this.backupService,
  });

  final AppDatabase database;
  final ReminderService reminderService;
  final PhotoStorageService photoService;
  final LocationService locationService;
  final SpeechService speechService;
  final PlotRepository plotRepo;
  final CycleRepository cycleRepo;
  final ApplicationRepository appRepo;
  final ActivityRepository activityRepo;
  final CostRepository costRepo;
  final HistoryRepository historyRepo;
  final GuidedTourController tourController;
  final ThemeController themeController;
  final PackageInfo packageInfo;
  final BackupService backupService;
}

class TierraYHojaApp extends StatefulWidget {
  const TierraYHojaApp({
    super.key,
    this.database,
    this.initialThemeMode = ThemeMode.system,
    this.packageInfo,
  });

  final AppDatabase? database;
  final ThemeMode initialThemeMode;
  final PackageInfo? packageInfo;

  @override
  State<TierraYHojaApp> createState() => _TierraYHojaAppState();
}

class _TierraYHojaAppState extends State<TierraYHojaApp> {
  late final Future<void> _bootstrapFuture;
  _AppBootstrapData? _data;
  bool _splashFinished = false;
  late ThemeMode _splashThemeMode = widget.initialThemeMode;

  @override
  void initState() {
    super.initState();
    _bootstrapFuture = _init();
  }

  Future<void> _init() async {
    // 1. Base de datos SQLite local
    final database = widget.database ?? await AppDatabase.open();

    // 2. Inicializar servicio de recordatorios offline
    final reminderService = ReminderService();
    await reminderService.init();

    // 3. Servicios del dispositivo
    final photoService = PhotoStorageService();
    const locationService = LocationService();
    final speechService = SpeechService();

    // 4. Repositorios de datos
    final plotRepo = PlotRepository(database);
    final cycleRepo = CycleRepository(database);
    final appRepo = ApplicationRepository(database);
    final activityRepo = ActivityRepository(database);
    final costRepo = CostRepository(database);
    final historyRepo = HistoryRepository(database);

    // 5. Controlador de Tour Guiado (validación de primera vez)
    final tourController = GuidedTourController(database);
    await tourController.init();

    // 6. Controlador de tema con el modo ya cargado
    final themeController = ThemeController(database, widget.initialThemeMode);
    if (mounted && _splashThemeMode != themeController.themeMode) {
      setState(() {
        _splashThemeMode = themeController.themeMode;
      });
    }

    final packageInfo =
        widget.packageInfo ??
        await () async {
          try {
            return await PackageInfo.fromPlatform();
          } catch (_) {
            return PackageInfo(
              appName: 'Tierra & Hoja',
              packageName: 'com.tierrayhoja.app',
              version: '1.2.1',
              buildNumber: '8',
            );
          }
        }();

    final backupService = BackupService(
      database,
      photoService,
      packageInfo: packageInfo,
    );

    _data = _AppBootstrapData(
      database: database,
      reminderService: reminderService,
      photoService: photoService,
      locationService: locationService,
      speechService: speechService,
      plotRepo: plotRepo,
      cycleRepo: cycleRepo,
      appRepo: appRepo,
      activityRepo: activityRepo,
      costRepo: costRepo,
      historyRepo: historyRepo,
      tourController: tourController,
      themeController: themeController,
      packageInfo: packageInfo,
      backupService: backupService,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_splashFinished || _data == null) {
      return MaterialApp(
        title: 'Tierra & Hoja',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: _splashThemeMode,
        home: AnimatedSplash(
          ready: _bootstrapFuture,
          onDone: () {
            if (mounted) {
              setState(() => _splashFinished = true);
            }
          },
        ),
      );
    }

    final data = _data!;
    return MultiProvider(
      providers: [
        Provider<AppDatabase>.value(value: data.database),
        Provider<DataChanges>.value(value: data.database.changes),
        Provider<ReminderService>.value(value: data.reminderService),
        Provider<PhotoStorageService>.value(value: data.photoService),
        Provider<LocationService>.value(value: data.locationService),
        Provider<SpeechService>.value(value: data.speechService),
        Provider<PlotRepository>.value(value: data.plotRepo),
        Provider<CycleRepository>.value(value: data.cycleRepo),
        Provider<ApplicationRepository>.value(value: data.appRepo),
        Provider<ActivityRepository>.value(value: data.activityRepo),
        Provider<CostRepository>.value(value: data.costRepo),
        Provider<HistoryRepository>.value(value: data.historyRepo),
        ChangeNotifierProvider<ThemeController>.value(
          value: data.themeController,
        ),
        ChangeNotifierProvider<GuidedTourController>.value(
          value: data.tourController,
        ),
        Provider<PackageInfo>.value(value: data.packageInfo),
        Provider<BackupService>.value(value: data.backupService),
      ],
      child: const _AppContent(),
    );
  }
}

class _AppContent extends StatefulWidget {
  const _AppContent();

  @override
  State<_AppContent> createState() => _AppContentState();
}

class _AppContentState extends State<_AppContent> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  StreamSubscription<String>? _sub;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    final reminderService = context.read<ReminderService>();
    _sub = reminderService.taps.listen((payload) {
      reminderService.takeLaunchPayload();
      _handleNotificationPayload(payload);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final launchPayload = reminderService.takeLaunchPayload();
      if (launchPayload != null) {
        _handleNotificationPayload(launchPayload);
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _handleNotificationPayload(String payload) async {
    final id = int.tryParse(payload);
    if (id == null || _isNavigating) return;

    _isNavigating = true;
    try {
      final tourController = context.read<GuidedTourController>();
      if (!tourController.isCompleted) return;

      final appRepo = context.read<ApplicationRepository>();
      final app = await appRepo.getById(id);
      if (app != null && mounted) {
        if (_navigatorKey.currentState == null) {
          await Future<void>.delayed(const Duration(milliseconds: 250));
        }
        await _navigatorKey.currentState?.push(
          MaterialPageRoute<void>(
            builder: (_) => FollowUpFormView(application: app),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error abriendo revisión desde notificación: $e');
    } finally {
      _isNavigating = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeController = context.watch<ThemeController>();
    final tourController = context.watch<GuidedTourController>();

    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'Tierra & Hoja',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeController.themeMode,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('es', 'HN'), Locale('es', '')],
      home: !tourController.isLoaded
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : (tourController.isCompleted
                ? const AppShell()
                : const GuidedTourView(isRevisit: false)),
    );
  }
}
