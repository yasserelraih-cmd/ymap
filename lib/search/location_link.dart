import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

import 'place.dart';

/// يفهم المواقع التي يرسلها الناس: روابط Google Maps وApple Maps
/// وOpenStreetMap والمواقع المرسلة في واتساب، والإحداثيات المكتوبة.
class LocationLink {
  /// هل النص رابط مختصر يحتاج فتحه أولاً (مثل maps.app.goo.gl)؟
  static bool isShortLink(String text) {
    final t = text.trim().toLowerCase();
    return RegExp(r'(maps\.app\.goo\.gl|goo\.gl/maps|g\.co/kgs|maps\.apple/p/)').hasMatch(t);
  }

  /// يحاول قراءة موقع من النص مباشرة (بدون إنترنت).
  static Place? parse(String text) {
    var s = _westernDigits(text.trim());
    if (s.isEmpty) return null;
    try {
      s = Uri.decodeFull(s.replaceAll('+', ' '));
    } catch (_) {}

    // 1) روابط Google لمكان محدد: !3dLAT!4dLON (أدق من موقع الكاميرا @).
    final pin = RegExp(r'!3d(-?\d+\.\d+)!4d(-?\d+\.\d+)').firstMatch(s);
    if (pin != null) return _place(pin.group(1)!, pin.group(2)!, _googleName(s));

    // 1ب) رابط YMAP: ?p=lat,lon&n=الاسم
    final ymap = RegExp(r'[?&]p=(-?\d{1,2}\.\d+)\s*,\s*(-?\d{1,3}\.\d+)').firstMatch(s);
    if (ymap != null) {
      final n = RegExp(r'[?&]n=([^&#]+)').firstMatch(s)?.group(1)?.trim();
      return _place(ymap.group(1)!, ymap.group(2)!, (n == null || n.isEmpty) ? null : n);
    }

    // 2) معاملات الرابط: q= query= ll= destination= daddr= center=
    final param = RegExp(
      r'[?&](?:q|query|ll|sll|destination|daddr|center|loc)=(?:loc:)?(-?\d{1,2}\.\d+)\s*,\s*(-?\d{1,3}\.\d+)',
    ).firstMatch(s);
    if (param != null) return _place(param.group(1)!, param.group(2)!, _googleName(s));

    // 3) OpenStreetMap: mlat=..&mlon=..  أو  #map=z/lat/lon
    final mlat = RegExp(r'mlat=(-?\d+\.\d+)').firstMatch(s);
    final mlon = RegExp(r'mlon=(-?\d+\.\d+)').firstMatch(s);
    if (mlat != null && mlon != null) {
      return _place(mlat.group(1)!, mlon.group(1)!, null);
    }
    final osm = RegExp(r'#map=\d+/(-?\d+\.\d+)/(-?\d+\.\d+)').firstMatch(s);
    if (osm != null) return _place(osm.group(1)!, osm.group(2)!, null);

    // 4) geo:lat,lon
    final geo = RegExp(r'geo:(-?\d+\.\d+),(-?\d+\.\d+)').firstMatch(s);
    if (geo != null) return _place(geo.group(1)!, geo.group(2)!, null);

    // 5) Google @lat,lon (موقع الكاميرا في الرابط)
    final at = RegExp(r'@(-?\d+\.\d+),(-?\d+\.\d+)').firstMatch(s);
    if (at != null) return _place(at.group(1)!, at.group(2)!, _googleName(s));

    // 6) إحداثيات مكتوبة: "24.6907, 46.6851" أو "24.6907 46.6851"
    final plain = RegExp(r'^\s*(-?\d{1,2}\.\d{3,})\s*[,،\s]\s*(-?\d{1,3}\.\d{3,})\s*$')
        .firstMatch(s);
    if (plain != null) return _place(plain.group(1)!, plain.group(2)!, null);

    return null;
  }

  /// يفتح الرابط المختصر ويقرأ الموقع من الرابط الكامل.
  /// في تطبيق الجوال يعمل مباشرة. في المتصفح يمنعه نظام الأمان (CORS)
  /// فيرجع null ونطلب من المستخدم لصق الرابط الكامل.
  static Future<Place?> resolveShortLink(String text, {http.Client? client}) async {
    if (kIsWeb) return null;
    final c = client ?? http.Client();
    var url = Uri.tryParse(text.trim());
    for (var i = 0; i < 5 && url != null; i++) {
      final req = http.Request('GET', url)..followRedirects = false;
      final res = await c.send(req).timeout(const Duration(seconds: 10));
      final location = res.headers['location'];
      final found = parse(location ?? url.toString());
      if (found != null) return found;
      if (location == null) {
        final body = await res.stream.bytesToString();
        return parse(body);
      }
      url = url.resolve(location);
    }
    return null;
  }

  /// رابط Google Maps لأي موقع (يفتح في Google Maps أو المتصفح، ويُشارك بسهولة).
  /// رابط YMAP قابل للمشاركة يفتح المكان مباشرة في التطبيق.
  static Uri ymap(double lat, double lon, {String? name}) => Uri.parse(ymapBase).replace(
        queryParameters: {
          'p': '${lat.toStringAsFixed(6)},${lon.toStringAsFixed(6)}',
          if (name != null && name.isNotEmpty) 'n': name,
        },
      );

  static const ymapBase = 'https://yasserelraih-cmd.github.io/ymap/';

  static Uri googleMaps(double lat, double lon) => Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${lat.toStringAsFixed(6)},${lon.toStringAsFixed(6)}');

  /// رابط Waze للملاحة لنفس الموقع.
  static Uri waze(double lat, double lon) => Uri.parse(
      'https://waze.com/ul?ll=${lat.toStringAsFixed(6)},${lon.toStringAsFixed(6)}&navigate=yes');

  static Place? _place(String lat, String lon, String? name) {
    final la = double.tryParse(lat);
    final lo = double.tryParse(lon);
    if (la == null || lo == null || la.abs() > 90 || lo.abs() > 180) return null;
    // \u202A…\u202C يثبت ترتيب «خط العرض، خط الطول» داخل النص العربي.
    final coords = '\u202A${la.toStringAsFixed(5)}, ${lo.toStringAsFixed(5)}\u202C';
    return Place(
      name: (name == null || name.isEmpty) ? coords : name,
      subtitle: coords,
      lat: la,
      lon: lo,
      osmKey: 'link',
    );
  }

  /// اسم المكان من رابط Google: /maps/place/<الاسم>/@...
  static String? _googleName(String s) {
    final m = RegExp(r'/maps/place/([^/@?]+)').firstMatch(s);
    final name = m?.group(1)?.trim();
    if (name == null || RegExp(r'^-?\d+\.\d+').hasMatch(name)) return null;
    return name;
  }

  /// يحول الأرقام العربية (٠١٢٣) والفاصلة العشرية العربية إلى الشكل الغربي.
  static String _westernDigits(String s) {
    const ar = '٠١٢٣٤٥٦٧٨٩';
    final b = StringBuffer();
    for (final ch in s.split('')) {
      final i = ar.indexOf(ch);
      b.write(i >= 0 ? '$i' : (ch == '٫' ? '.' : ch));
    }
    return b.toString();
  }
}
