import 'package:flutter_test/flutter_test.dart';
import 'package:ymap/navigation/geo.dart';
import 'package:ymap/routing/route.dart';

void main() {
  test('بقية المسار تبدأ من موقعك', () {
    const pts = [GeoPoint(24.70, 46.68), GeoPoint(24.71, 46.68), GeoPoint(24.72, 46.68)];
    final rest = remainingFrom(pts, 1665); // ~1.5 قطعة
    expect(rest.length, 2);
    expect(rest.first.lat, closeTo(24.715, 0.0003));
    expect(rest.last.lat, 24.72);
    expect(remainingFrom(pts, 0).length, 3);
    expect(remainingFrom(pts, 99999).length, 2);
  });
}
