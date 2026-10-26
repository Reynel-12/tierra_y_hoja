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
  final Map<int, Timer> _activeTimers = {};
  bool _ready = false;
  String? _launchPayload;

  NotificationDetails _getNotificationDetails({String? title, String? body}) =>
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          // largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
          playSound: true,
          enableVibration: true,
          channelShowBadge: true,
          styleInformation: (body != null && body.isNotEmpty)
              ? BigTextStyleInformation(
                  body,
                  contentTitle: title,
                  htmlFormatContent: false,
                  htmlFormatTitle: false,
                )
              : null,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          presentBanner: true,
          presentList: true,
        ),
        macOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          presentBanner: true,
          presentList: true,
        ),
        linux: LinuxNotificationDetails(
          icon: AssetsLinuxIcon('assets/icons/icon_ochre.png'),
        ),
      );

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
          if (payload != null) {
            _launchPayload ??= payload;
            _taps.add(payload);
          }
        },
      );

      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (android != null) {
        await android.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelId,
            _channelName,
            description: _channelDescription,
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
            showBadge: true,
          ),
        );
      }

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
        final granted = await android.requestNotificationsPermission() ?? false;
        try {
          await android.requestExactAlarmsPermission();
        } catch (_) {}
        return granted;
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

  /// Muestra una notificación inmediatamente.
  Future<void> show({
    required int id,
    required String title,
    required String body,
    required String payload,
  }) async {
    if (!_ready) return;
    try {
      await _plugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: _getNotificationDetails(title: title, body: body),
        payload: payload,
      );
    } catch (e) {
      debugPrint('No se pudo mostrar la notificación inmediata $id: $e');
    }
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

    // Si es un intervalo corto (ej. prueba de 10s mientras el usuario está en la app),
    // programamos un Timer en memoria como respaldo para asegurar que se muestre en tiempo real.
    final diff = at.difference(DateTime.now());
    if (diff.inSeconds <= 120) {
      _activeTimers[id]?.cancel();
      _activeTimers[id] = Timer(
        diff.isNegative ? Duration.zero : diff,
        () async {
          _activeTimers.remove(id);
          await show(id: id, title: title, body: body, payload: payload);
        },
      );
    }

    try {
      await _plugin.zonedSchedule(
        id: id,
        scheduledDate: tz.TZDateTime.from(at, tz.local),
        notificationDetails: _getNotificationDetails(title: title, body: body),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        title: title,
        body: body,
        payload: payload,
      );
    } catch (e) {
      debugPrint('Fallo con exactAllowWhileIdle, reintentando con inexact: $e');
      try {
        await _plugin.zonedSchedule(
          id: id,
          scheduledDate: tz.TZDateTime.from(at, tz.local),
          notificationDetails: _getNotificationDetails(title: title, body: body),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          title: title,
          body: body,
          payload: payload,
        );
      } catch (e2) {
        debugPrint('No se pudo programar el recordatorio $id: $e2');
      }
    }
  }

  Future<void> cancel(int id) async {
    _activeTimers[id]?.cancel();
    _activeTimers.remove(id);
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
