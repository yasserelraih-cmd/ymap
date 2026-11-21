import 'dart:typed_data';
import 'dart:ui' as ui;

/// أيقونات الخريطة نرسمها بأنفسنا (هوية YMAP، بدون صور خارجية).
class MapIcons {
  static const puck = 'ymap-puck';
  static const chevron = 'ymap-chevron';
  static const cone = 'ymap-cone';
  static const car = 'ymap-car';
  static const turnHead = 'ymap-turn-head';

  /// مخروط الاتجاه حول نقطة موقعك: مروحة متدرجة تشير للأعلى من المركز.
  static Future<Uint8List> conePng() async {
    const s = 160.0;
    final rec = ui.PictureRecorder();
    final c = ui.Canvas(rec);
    const center = ui.Offset(s / 2, s / 2);
    final rect = ui.Rect.fromCircle(center: center, radius: s / 2);
    final paint = ui.Paint()
      ..shader = ui.Gradient.radial(
        center,
        s / 2,
        const [ui.Color(0xF01F8FFF), ui.Color(0x101F8FFF)],
      );
    // زاوية 70° حول الأعلى (-90°).
    const sweep = 70 * 3.14159265 / 180;
    c.drawArc(rect, -3.14159265 / 2 - sweep / 2, sweep, true, paint);
    return _png(rec, s.toInt(), s.toInt());
  }

  /// سيارة من الأعلى (تصميم YMAP): جسم أبيض، زجاج داكن، ظل.
  static Future<Uint8List> carPng() async {
    const w = 72.0, h = 128.0;
    final rec = ui.PictureRecorder();
    final c = ui.Canvas(rec);
    final body = ui.RRect.fromRectAndRadius(
        const ui.Rect.fromLTWH(10, 8, w - 20, h - 16), const ui.Radius.circular(22));
    c.drawRRect(
        body.shift(const ui.Offset(0, 4)),
        ui.Paint()
          ..color = const ui.Color(0x66000000)
          ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 6));
    // حافة داكنة حتى تظهر السيارة فوق سهم الالتفاف الأبيض.
    c.drawRRect(
        body.inflate(2.5),
        ui.Paint()..color = const ui.Color(0xFF16324F));
    c.drawRRect(
        body,
        ui.Paint()
          ..shader = ui.Gradient.linear(const ui.Offset(10, 0), const ui.Offset(w - 10, 0), const [
            ui.Color(0xFFDDE3EA),
            ui.Color(0xFFFFFFFF),
            ui.Color(0xFFDDE3EA),
          ], const [0, 0.5, 1]));
    final glass = ui.Paint()..color = const ui.Color(0xFF1C2733);
    // الزجاج الأمامي (أعلى الصورة = مقدمة السيارة)
    c.drawRRect(
        ui.RRect.fromRectAndRadius(const ui.Rect.fromLTWH(17, 34, w - 34, 22), const ui.Radius.circular(8)),
        glass);
    // السقف
    c.drawRRect(
        ui.RRect.fromRectAndRadius(const ui.Rect.fromLTWH(18, 58, w - 36, 34), const ui.Radius.circular(6)),
        ui.Paint()..color = const ui.Color(0xFFF2F5F8));
    // الزجاج الخلفي
    c.drawRRect(
        ui.RRect.fromRectAndRadius(const ui.Rect.fromLTWH(19, 94, w - 38, 14), const ui.Radius.circular(6)),
        glass);
    // أنوار أمامية وخلفية
    final front = ui.Paint()..color = const ui.Color(0xFFFFF3B0);
    c.drawCircle(const ui.Offset(20, 16), 4, front);
    c.drawCircle(const ui.Offset(w - 20, 16), 4, front);
    final rear = ui.Paint()..color = const ui.Color(0xFFE5484D);
    c.drawRRect(ui.RRect.fromRectAndRadius(const ui.Rect.fromLTWH(16, h - 14, 12, 4), const ui.Radius.circular(2)), rear);
    c.drawRRect(ui.RRect.fromRectAndRadius(const ui.Rect.fromLTWH(w - 28, h - 14, 12, 4), const ui.Radius.circular(2)), rear);
    return _png(rec, w.toInt(), h.toInt());
  }

  /// رأس سهم الالتفاف (يشير للأعلى): أبيض بحافة زرقاء.
  static Future<Uint8List> turnHeadPng() async {
    const s = 96.0;
    final rec = ui.PictureRecorder();
    final c = ui.Canvas(rec);
    final p = ui.Path()
      ..moveTo(s / 2, 6)
      ..lineTo(s - 8, s - 16)
      ..lineTo(8, s - 16)
      ..close();
    c.drawPath(
        p,
        ui.Paint()
          ..color = const ui.Color(0xFF0A4FB0)
          ..style = ui.PaintingStyle.stroke
          ..strokeWidth = 12
          ..strokeJoin = ui.StrokeJoin.round);
    c.drawPath(p, ui.Paint()..color = const ui.Color(0xFFFFFFFF));
    return _png(rec, s.toInt(), s.toInt());
  }

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
