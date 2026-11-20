import 'package:geolocator/geolocator.dart';

enum LocationStatus { granted, denied, deniedForever, serviceOff }

/// طلب صلاحية الموقع وقراءة الموقع الحالي.
class LocationService {
  Future<LocationStatus> ensurePermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return LocationStatus.serviceOff;
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return switch (permission) {
      LocationPermission.always ||
      LocationPermission.whileInUse =>
        LocationStatus.granted,
      LocationPermission.deniedForever => LocationStatus.deniedForever,
      _ => LocationStatus.denied,
    };
  }

  Future<Position?> current() async {
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          timeLimit: Duration(seconds: 15),
        ),
      );
    } catch (_) {
      return Geolocator.getLastKnownPosition();
    }
  }
}
