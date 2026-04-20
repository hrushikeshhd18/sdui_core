import 'dart:convert';

import 'package:sdui_core/sdui_core.dart' show SduiScreen;
import 'package:sdui_core/src/utils/sdui_logger.dart';
import 'package:sdui_core/src/widgets/sdui_screen.dart' show SduiScreen;
import 'package:shared_preferences/shared_preferences.dart';

/// Stale-while-revalidate cache for SDUI JSON payloads.
///
/// Initialise once at app startup:
/// ```dart
/// void main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   SduiCache.instance = await SduiCache.init();
///   runApp(const MyApp());
/// }
/// ```
///
/// [SduiScreen] uses the cache automatically when `enableCache` is `true`
/// (the default). On first load the cached value is returned immediately
/// while a fresh fetch runs in the background; if the fresh payload differs
/// from the cached one the screen updates automatically.
final class SduiCache {
  SduiCache._(SharedPreferences prefs) : _prefs = prefs;

  static const String _prefix = 'sdui_cache_';
  static const String _tsPrefix = 'sdui_ts_';

  final SharedPreferences _prefs;

  /// The global cache instance. Must be set before use via [init].
  static late final SduiCache instance;

  /// Initialises the cache and sets [instance].
  static Future<SduiCache> init() async {
    final prefs = await SharedPreferences.getInstance();
    return instance = SduiCache._(prefs);
  }

  /// Returns the cached payload for [url], or `null` if not cached.
  Future<Map<String, Object?>?> get(String url) async {
    final raw = _prefs.getString('$_prefix${_key(url)}');
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        SduiLogger.cache('HIT for $url');
        return Map<String, Object?>.from(decoded);
      }
    } on Exception catch (e) {
      SduiLogger.warn('Cache: failed to decode entry for $url', error: e);
    }
    return null;
  }

  /// Stores [payload] for [url] with the current timestamp.
  Future<void> set(String url, Map<String, Object?> payload) async {
    final k = _key(url);
    await _prefs.setString('$_prefix$k', jsonEncode(payload));
    await _prefs.setInt('$_tsPrefix$k', DateTime.now().millisecondsSinceEpoch);
    SduiLogger.cache('SET for $url');
  }

  /// Returns `true` if the cached entry for [url] is older than [maxAge].
  Future<bool> isStale(
    String url, {
    Duration maxAge = const Duration(minutes: 5),
  }) async {
    final ts = _prefs.getInt('$_tsPrefix${_key(url)}');
    if (ts == null) return true;
    final age =
        DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(ts));
    return age > maxAge;
  }

  /// Removes the cache entry for [url].
  Future<void> invalidate(String url) async {
    final k = _key(url);
    await _prefs.remove('$_prefix$k');
    await _prefs.remove('$_tsPrefix$k');
    SduiLogger.cache('INVALIDATED $url');
  }

  /// Clears all cached payloads managed by this library.
  Future<void> clear() async {
    final keys = _prefs.getKeys();
    final toRemove = keys
        .where((k) => k.startsWith(_prefix) || k.startsWith(_tsPrefix))
        .toList();
    for (final k in toRemove) {
      await _prefs.remove(k);
    }
    SduiLogger.cache('CLEARED (${toRemove.length} entries)');
  }

  static String _key(String url) =>
      url.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
}
