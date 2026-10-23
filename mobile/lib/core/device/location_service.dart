import 'package:geolocator/geolocator.dart';

import '../../features/requests/domain/request_models.dart';

enum LocationFailure { serviceDisabled, denied, deniedForever, unavailable }

class LocationResult {
  const LocationResult.success(GeoPoint this.point) : failure = null;
  const LocationResult.failed(LocationFailure this.failure) : point = null;

  final GeoPoint? point;
  final LocationFailure? failure;
}

/// One-off "use my current location". Never tracks in the background.
abstract class LocationService {
  Future<LocationResult> current();
}

class DeviceLocationService implements LocationService {
  @override
  Future<LocationResult> current() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return const LocationResult.failed(LocationFailure.serviceDisabled);
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        return const LocationResult.failed(LocationFailure.deniedForever);
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.unableToDetermine) {
        return const LocationResult.failed(LocationFailure.denied);
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
      return LocationResult.success(
        GeoPoint(position.latitude, position.longitude),
      );
    } catch (_) {
      return const LocationResult.failed(LocationFailure.unavailable);
    }
  }
}
