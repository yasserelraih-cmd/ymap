import 'dart:js_interop';

@JS('ymapCompass.start')
external JSPromise<JSBoolean> _start();

@JS('ymapCompass.heading')
external JSNumber? get _heading;

@JS('ymapCompass.needsPermission')
external JSBoolean _needsPermission();

@JS('ymapCompass')
external JSObject? get _compass;

class Compass {
  static Future<bool> start() async {
    if (_compass == null) return false;
    try {
      return (await _start().toDart).toDart;
    } catch (_) {
      return false;
    }
  }

  static double? get heading {
    if (_compass == null) return null;
    try {
      return _heading?.toDartDouble;
    } catch (_) {
      return null;
    }
  }

  static bool get needsPermission {
    if (_compass == null) return false;
    try {
      return _needsPermission().toDart;
    } catch (_) {
      return false;
    }
  }
}
