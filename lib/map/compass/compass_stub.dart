class Compass {
  /// يبدأ القراءة (في آيفون يطلب الإذن، فيجب استدعاؤه بعد ضغطة منك).
  static Future<bool> start() async => false;

  /// آخر اتجاه معروف، أو null.
  static double? get heading => null;

  static bool get needsPermission => false;
}
