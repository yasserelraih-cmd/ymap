import 'dart:typed_data';
import 'dart:ui' as ui;

/// أيقونات الخريطة نرسمها بأنفسنا (هوية YMAP، بدون صور خارجية).
class MapIcons {
  static const puck = 'ymap-puck';
  static const chevron = 'ymap-chevron';

  /// سهم السيارة: أبيض بحافة، داخله أزرق، يشير للأعلى.
  static Future<Uint8List> puckPng() async {
    const s = 96.0;
    final rec = ui.PictureRecorder();
    final c = ui.Canvas(rec);
    // ظل خفيف
    final shadow = ui.Paint()
      ..color = const ui.Color(0x55000000)
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 5);
    final path = ui.Path()
      ..moveTo(s / 2, 8)
      ..lineTo(s - 14, s - 12)
      ..lineTo(s / 2, s - 30)
      ..lineTo(14, s - 12)
      ..close();
    c.drawPath(path.shift(const ui.Offset(0, 3)), shadow);
    c.drawPath(
        path,
        ui.Paint()
          ..color = const ui.Color(0xFFFFFFFF)
          ..style = ui.PaintingStyle.stroke
          ..strokeWidth = 10
          ..strokeJoin = ui.StrokeJoin.round);
    c.drawPath(path, ui.Paint()..color = const ui.Color(0xFF1F8FFF));
    // لمعة على النصف الأيمن
    final half = ui.Path()
      ..moveTo(s / 2, 8)
      ..lineTo(s - 14, s - 12)
      ..lineTo(s / 2, s - 30)
      ..close();
    c.drawPath(half, ui.Paint()..color = const ui.Color(0xFF0B5FC4));
    return _png(rec, s.toInt(), s.toInt());
  }

  /// شيفرون أبيض صغير يُكرر على خط المسار لإظهار الاتجاه.
  static Future<Uint8List> chevronPng() async {
    const w = 28.0, h = 28.0;
    final rec = ui.PictureRecorder();
    final c = ui.Canvas(rec);
    // يشير لليمين (اتجاه رسم الخط)، والخريطة تديره مع الخط.
    final p = ui.Path()
      ..moveTo(8, 5)
      ..lineTo(20, 14)
      ..lineTo(8, 23);
    c.drawPath(
        p,
        ui.Paint()
          ..color = const ui.Color(0xFFFFFFFF)
          ..style = ui.PaintingStyle.stroke
          ..strokeWidth = 4.5
          ..strokeCap = ui.StrokeCap.round
          ..strokeJoin = ui.StrokeJoin.round);
    return _png(rec, w.toInt(), h.toInt());
  }

  static Future<Uint8List> _png(ui.PictureRecorder rec, int w, int h) async {
    final img = await rec.endRecording().toImage(w, h);
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  }
}
