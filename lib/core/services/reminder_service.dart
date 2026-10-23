import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Recordatorios locales (sin internet) para revisar el cultivo después de
/// una aplicación.
class ReminderService {
  ReminderService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  /// Hora del día en que suena el recordatorio (mañana fresca).
  static const reminderHour = 7;

  static const _channelId = 'revisiones';
  static const _channelName = 'Revisiones del cultivo';
  static const _channelDescription =
      'Le recuerda revisar cómo reaccionó el cultivo después de una aplicación.';

  final FlutterLocalNotificationsPlugin _plugin;
  final _taps = StreamController<String>.broadcast();
  bool _ready = false;
  String? _launchPayload;

  /// Payloads de notificaciones tocadas mientras la app está abierta.
  Stream<String> get taps => _taps.stream;

  /// Payload de la notificación que abrió la app (se consume una sola vez).
  String? takeLaunchPayload() {
    final payload = _launchPayload;
    _launchPayload = null;
    return payload;
  }

  Future<void> init() async {
    try {
      tz_data.initializeTimeZones();
      try {
        final zone = await FlutterTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(zone.identifier));
      } catch (e) {
        debugPrint('Zona horaria desconocida, se usa UTC-6: $e');
        tz.setLocalLocation(tz.getLocation('America/Tegucigalpa'));
      }

      await _plugin.initialize(
        settings: InitializationSettings(
          android: const AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: const DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
          macOS: const DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
          linux: LinuxInitializationSettings(
            defaultActionName: 'Open notification',
            defaultIcon: AssetsLinuxIcon('assets/icons/icon_ochre.png'),
          ),
        ),
        onDidReceiveNotificationResponse: (response) {
          final payload = response.payload;
          if (payload != null) _taps.add(payload);
        },
      );

      final launch = await _plugin.getNotificationAppLaunchDetails();
      if (launch?.didNotificationLaunchApp ?? false) {
        _launchPayload = launch?.notificationResponse?.payload;
      }
      _ready = true;
    } catch (e) {
      debugPrint('Notificaciones no disponibles: $e');
    }
  }

  /// Pide permiso para mostrar notificaciones (Android 13+ / iOS).
  Future<bool> requestPermission() async {
    if (!_ready) return false;
    try {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (android != null) {
        return await android.requestNotificationsPermission() ?? false;
      }
      final ios = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      if (ios != null) {
        return await ios.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            ) ??
            false;
      }
    } catch (e) {
      debugPrint('No se pudo pedir permiso de notificaciones: $e');
    }
    return false;
  }

  /// Programa un recordatorio. Si la fecha ya pasó, no hace nada.
  Future<void> schedule({
    required int id,
    required DateTime at,
    required String title,
    required String body,
    required String payload,
  }) async {
    if (!_ready || at.isBefore(DateTime.now())) return;
    try {
      await _plugin.zonedSchedule(
        id: id,
        scheduledDate: tz.TZDateTime.from(at, tz.local),
        notificationDetails: NotificationDetails(
          android: const AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDescription,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
          ),
          iOS: const DarwinNotificationDetails(),
          macOS: const DarwinNotificationDetails(),
          linux: LinuxNotificationDetails(
            icon: AssetsLinuxIcon('assets/icons/icon_ochre.png'),
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        title: title,
        body: body,
        payload: payload,
      );
    } catch (e) {
      debugPrint('No se pudo programar el recordatorio $id: $e');
    }
  }

  Future<void> cancel(int id) async {
    if (!_ready) return;
    try {
      await _plugin.cancel(id: id);
    } catch (e) {
      debugPrint('No se pudo cancelar el recordatorio $id: $e');
    }
  }

  Future<void> cancelAll(Iterable<int> ids) async {
    for (final id in ids) {
      await cancel(id);
    }
  }
}
