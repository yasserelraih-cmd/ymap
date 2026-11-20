import 'package:flutter_tts/flutter_tts.dart';

/// الصوت: يستخدم محرك النطق في الجوال/المتصفح (مجاني، يعمل بدون خادم).
/// لاحقاً نضيف أصواتاً مسجلة باللهجة السعودية والمصرية.
class Speaker {
  final _tts = FlutterTts();
  bool muted = false;
  String _lang = '';

  Future<void> setLanguage(String code) async {
    final tag = code == 'ar' ? 'ar-SA' : 'en-US';
    if (tag == _lang) return;
    _lang = tag;
    try {
      await _tts.setLanguage(tag);
      await _tts.setSpeechRate(code == 'ar' ? 0.5 : 0.52);
      await _tts.setVolume(1);
    } catch (_) {}
  }

  Future<void> say(String text) async {
    if (muted || text.isEmpty) return;
    try {
      await _tts.stop();
      await _tts.speak(text);
    } catch (_) {}
  }

  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }
}
