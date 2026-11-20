import 'dart:convert';

import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../search/place.dart';

/// مكان سيارتك المحفوظ.
class CarSpot {
  const CarSpot({required this.lat, required this.lon, required this.savedAt});
  final double lat;
  final double lon;
  final DateTime savedAt;

  Map<String, dynamic> toJson() =>
      {'lat': lat, 'lon': lon, 'savedAt': savedAt.toIso8601String()};

  static CarSpot fromJson(Map<String, dynamic> j) => CarSpot(
        lat: (j['lat'] as num).toDouble(),
        lon: (j['lon'] as num).toDouble(),
        savedAt: DateTime.parse(j['savedAt'] as String),
      );
}

/// الأماكن المحفوظة: البيت، العمل، المفضلة، ومكان السيارة.
/// تُحفظ على الجهاز الآن، وتُزامن مع حسابك عند إضافة الحسابات (المرحلة 2).
class SavedPlaces extends ChangeNotifier {
  static const _kHome = 'saved_home';
  static const _kWork = 'saved_work';
  static const _kFav = 'saved_favorites';
  static const _kCar = 'saved_car';

  Place? home;
  Place? work;
  List<Place> favorites = [];
  CarSpot? car;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    home = _readPlace(prefs.getString(_kHome));
    work = _readPlace(prefs.getString(_kWork));
    favorites = [
      for (final s in prefs.getStringList(_kFav) ?? const <String>[])
        ?_readPlace(s),
    ];
    final car = prefs.getString(_kCar);
    this.car = car == null
        ? null
        : CarSpot.fromJson(jsonDecode(car) as Map<String, dynamic>);
    notifyListeners();
  }

  bool isFavorite(Place p) => favorites.any((f) => f.key == p.key);

  Future<void> setHome(Place p) async {
    home = p;
    await _write(_kHome, jsonEncode(p.toJson()));
  }

  Future<void> setWork(Place p) async {
    work = p;
    await _write(_kWork, jsonEncode(p.toJson()));
  }

  Future<void> clearHome() async {
    home = null;
    await _write(_kHome, null);
  }

  Future<void> clearWork() async {
    work = null;
    await _write(_kWork, null);
  }

  Future<void> toggleFavorite(Place p) async {
    if (isFavorite(p)) {
      favorites = favorites.where((f) => f.key != p.key).toList();
    } else {
      favorites = [p, ...favorites];
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        _kFav, [for (final f in favorites) jsonEncode(f.toJson())]);
    notifyListeners();
  }

  Future<void> saveCar(double lat, double lon) async {
    car = CarSpot(lat: lat, lon: lon, savedAt: DateTime.now());
    await _write(_kCar, jsonEncode(car!.toJson()));
  }

  Future<void> clearCar() async {
    car = null;
    await _write(_kCar, null);
  }

  Future<void> _write(String key, String? value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value == null) {
      await prefs.remove(key);
    } else {
      await prefs.setString(key, value);
    }
    notifyListeners();
  }

  static Place? _readPlace(String? s) {
    if (s == null) return null;
    try {
      return Place.fromJson(jsonDecode(s) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }
}
