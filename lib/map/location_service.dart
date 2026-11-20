import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:geolocator/geolocator.dart';

enum LocationStatus { granted, denied, deniedForever, serviceOff }

/// طلب صلاحية الموقع وقراءة الموقع الحالي.
class LocationService {
  Position? _lastWeb;

  Future<LocationStatus> ensurePermission() async {
    // في المتصفح (خصوصاً آيفون): لا نعتمد على «فحص الصلاحية» لأن Safari وChrome
    // قد يرجعانها «مرفوضة» قبل أن يسألاك أصلاً. طلب الموقع مباشرة هو ما يُظهر
    // رسالة «السماح بالوصول لموقعك».
    if (kIsWeb) {
      try {
        _lastWeb = await _webFix();
        return LocationStatus.granted;
      } on PermissionDeniedException {
        return LocationStatus.denied;
      } on LocationServiceDisabledException {
        return LocationStatus.serviceOff;
      } catch (_) {
        // انتهاء المهلة أو تعذّر تحديد الموقع: الصلاحية موجودة لكن الإشارة ضعيفة.
        return _lastWeb != null ? LocationStatus.granted : LocationStatus.serviceOff;
      }
    }

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

  /// قراءة الموقع في المتصفح مع مهلة حقيقية.
  /// (مكتبة الويب تحسب المهلة خطأً فقد تنتظر ساعات، فنضع مهلتنا.)
  /// نقبل قراءة عمرها حتى 30 ثانية لتسريع حساب المسار.
  Future<Position> _webFix() => Geolocator.getCurrentPosition(
        locationSettings: WebSettings(
          accuracy: LocationAccuracy.high,
          maximumAge: const Duration(seconds: 30),
        ),
      ).timeout(const Duration(seconds: 20));

  Future<Position?> current() async {
    // في المتصفح: إن قرأنا موقعك قبل ثوانٍ (أثناء طلب الصلاحية) نستخدمه مباشرة.
    final last = _lastWeb;
    if (kIsWeb &&
        last != null &&
        DateTime.now().difference(last.timestamp).inSeconds < 15) {
      return last;
    }
    try {
      if (kIsWeb) return _lastWeb = await _webFix();
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          timeLimit: Duration(seconds: 15),
        ),
      );
    } catch (_) {
      if (kIsWeb) return _lastWeb;
      return Geolocator.getLastKnownPosition();
    }
  }
}
