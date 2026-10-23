import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// Resultado de pedir la ubicación. El GPS funciona sin internet.
sealed class LocationResult {
  const LocationResult();
}

final class LocationFound extends LocationResult {
  const LocationFound(this.latitude, this.longitude);
  final double latitude;
  final double longitude;
}

final class LocationUnavailable extends LocationResult {
  const LocationUnavailable(this.message);
  final String message;
}

/// Obtiene coordenadas GPS opcionales. Nunca bloquea un guardado.
class LocationService {
  const LocationService();

  Future<LocationResult> current() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return const LocationUnavailable(
          'El GPS está apagado. Actívelo en el teléfono e intente de nuevo.',
        );
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        return const LocationUnavailable(
          'Sin permiso de ubicación. Puede guardar el lote sin coordenadas.',
        );
      }
      if (permission == LocationPermission.deniedForever) {
        return const LocationUnavailable(
          'El permiso de ubicación está bloqueado. Actívelo en los ajustes del teléfono.',
        );
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 30),
        ),
      );
      return LocationFound(position.latitude, position.longitude);
    } catch (e) {
      debugPrint('Error de ubicación: $e');
      return const LocationUnavailable(
        'No se encontró la señal GPS. Salga a cielo abierto e intente de nuevo.',
      );
    }
  }
}
