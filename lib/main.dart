import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
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
import 'features/activities/data/activity_repository.dart';
import 'features/costs/data/cost_repository.dart';
import 'features/cycles/data/cycle_repository.dart';
import 'features/field_log/data/application_repository.dart';
import 'features/history/data/history_repository.dart';
import 'features/plots/data/plot_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Inicializar base de datos SQLite local
  final database = await AppDatabase.open();

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

  runApp(
    MultiProvider(
      providers: [
        Provider<AppDatabase>.value(value: database),
        Provider<DataChanges>.value(value: database.changes),
        Provider<ReminderService>.value(value: reminderService),
        Provider<PhotoStorageService>.value(value: photoService),
        Provider<LocationService>.value(value: locationService),
        Provider<SpeechService>.value(value: speechService),
        Provider<PlotRepository>.value(value: plotRepo),
        Provider<CycleRepository>.value(value: cycleRepo),
        Provider<ApplicationRepository>.value(value: appRepo),
        Provider<ActivityRepository>.value(value: activityRepo),
        Provider<CostRepository>.value(value: costRepo),
        Provider<HistoryRepository>.value(value: historyRepo),
        ChangeNotifierProvider(create: (_) => ThemeController(database)),
      ],
      child: const TierraYHojaApp(),
    ),
  );
}

class TierraYHojaApp extends StatelessWidget {
  const TierraYHojaApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = context.watch<ThemeController>();

    return MaterialApp(
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
      supportedLocales: const [
        Locale('es', 'HN'),
        Locale('es', ''),
      ],
      home: const AppShell(),
    );
  }
}
