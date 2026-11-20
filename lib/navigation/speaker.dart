import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_tts/flutter_tts.dart';

/// الصوت: يستخدم محرك النطق في الجوال/المتصفح (مجاني، يعمل بدون خادم).
/// نختار أفضل صوت عربي موجود في جهازك (المحسّن/Enhanced إن وُجد).
class Speaker {
  final _tts = FlutterTts();
  bool muted = false;
  String _lang = '';

  /// اسم الصوت المختار (للعرض في الإعدادات).
  String? voiceName;

  Future<void> setLanguage(String code) async {
    final tag = code == 'ar' ? 'ar-SA' : 'en-US';
    if (tag == _lang) return;
    _lang = tag;
    try {
      await _tts.setLanguage(tag);
      await _pickVoice(code);
      // في المتصفح 1.0 = السرعة الطبيعية؛ في التطبيق 0.5 = الطبيعية.
      await _tts.setSpeechRate(kIsWeb ? 0.95 : 0.5);
      await _tts.setPitch(1.0);
      await _tts.setVolume(1);
    } catch (_) {}
  }

  Future<void> _pickVoice(String code) async {
    final raw = await _tts.getVoices;
    if (raw is! List) return;
    final voices = [
      for (final v in raw)
        if (v is Map) {'name': '${v['name']}', 'locale': '${v['locale']}'},
    ].where((v) => v['locale']!.toLowerCase().startsWith(code)).toList();
    if (voices.isEmpty) return;
    int score(Map<String, String> v) {
      final n = v['name']!.toLowerCase();
      final l = v['locale']!.toLowerCase();
      var s = 0;
      if (l == 'ar-sa' || l == 'ar_sa' || l == 'en-us') s += 3;
      for (final good in ['premium', 'enhanced', 'neural', 'natural', 'siri', 'google', 'online']) {
        if (n.contains(good)) s += 5;
      }
      if (n.contains('compact')) s -= 4;
      return s;
    }

    voices.sort((a, b) => score(b).compareTo(score(a)));
    final best = voices.first;
    voiceName = best['name'];
    await _tts.setVoice({'name': best['name']!, 'locale': best['locale']!});
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
