import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Fotoğraf cache servisi
/// In-memory ve disk cache kullanır
class PhotoCacheService {
  PhotoCacheService._();
  static final PhotoCacheService instance = PhotoCacheService._();

  // In-memory cache
  final Map<String, Uint8List> _memoryCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};

  // Cache ayarları
  static const Duration _cacheExpiry = Duration(hours: 24);
  static const int _maxMemoryCacheSize = 20; // Maksimum 20 fotoğraf

  /// Cache key oluşturur
  String _getCacheKey(String url, {bool thumbnail = false}) {
    final key = '$url${thumbnail ? '_thumb' : '_full'}';
    final bytes = utf8.encode(key);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Fotoğrafı cache'den alır
  Future<Uint8List?> getCachedPhoto(
    String url, {
    bool thumbnail = false,
  }) async {
    final cacheKey = _getCacheKey(url, thumbnail: thumbnail);

    // Önce in-memory cache'den kontrol et
    if (_memoryCache.containsKey(cacheKey)) {
      final timestamp = _cacheTimestamps[cacheKey];
      if (timestamp != null &&
          DateTime.now().difference(timestamp) < _cacheExpiry) {
        debugPrint('📸 PhotoCache: Memory cache hit for $cacheKey');
        return _memoryCache[cacheKey];
      } else {
        // Expired, remove from memory
        _memoryCache.remove(cacheKey);
        _cacheTimestamps.remove(cacheKey);
      }
    }

    // Disk cache'den kontrol et
    try {
      final file = await _getCacheFile(cacheKey);
      if (await file.exists()) {
        final stat = await file.stat();
        final age = DateTime.now().difference(stat.modified);
        if (age < _cacheExpiry) {
          final bytes = await file.readAsBytes();
          // Memory cache'e de ekle
          _addToMemoryCache(cacheKey, bytes);
          debugPrint('📸 PhotoCache: Disk cache hit for $cacheKey');
          return bytes;
        } else {
          // Expired, delete
          await file.delete();
        }
      }
    } catch (e) {
      debugPrint('⚠️ PhotoCache: Error reading disk cache: $e');
    }

    return null;
  }

  /// Fotoğrafı cache'e kaydeder
  Future<void> cachePhoto(
    String url,
    Uint8List bytes, {
    bool thumbnail = false,
  }) async {
    final cacheKey = _getCacheKey(url, thumbnail: thumbnail);

    // Memory cache'e ekle
    _addToMemoryCache(cacheKey, bytes);

    // Disk cache'e kaydet
    try {
      final file = await _getCacheFile(cacheKey);
      await file.writeAsBytes(bytes);
      debugPrint(
        '📸 PhotoCache: Cached photo $cacheKey (${bytes.length} bytes)',
      );
    } catch (e) {
      debugPrint('⚠️ PhotoCache: Error writing to disk cache: $e');
    }
  }

  /// Memory cache'e ekler (size limit kontrolü ile)
  void _addToMemoryCache(String key, Uint8List bytes) {
    // Size limit kontrolü
    if (_memoryCache.length >= _maxMemoryCacheSize) {
      // En eski entry'yi sil
      String? oldestKey;
      DateTime? oldestTime;
      for (final entry in _cacheTimestamps.entries) {
        if (oldestTime == null || entry.value.isBefore(oldestTime)) {
          oldestTime = entry.value;
          oldestKey = entry.key;
        }
      }
      if (oldestKey != null) {
        _memoryCache.remove(oldestKey);
        _cacheTimestamps.remove(oldestKey);
      }
    }

    _memoryCache[key] = bytes;
    _cacheTimestamps[key] = DateTime.now();
  }

  /// Cache dosyası path'ini alır
  Future<File> _getCacheFile(String cacheKey) async {
    final cacheDir = await _getCacheDirectory();
    return File('${cacheDir.path}/photo_$cacheKey.cache');
  }

  /// Cache dizinini alır
  Future<Directory> _getCacheDirectory() async {
    if (kIsWeb) {
      // Web için geçici dizin (aslında kullanılmayacak)
      throw UnsupportedError('Disk cache not supported on web');
    }

    final appDir = await getApplicationDocumentsDirectory();
    final cacheDir = Directory('${appDir.path}/photo_cache');
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    return cacheDir;
  }

  /// Cache'i temizler
  Future<void> clearCache() async {
    _memoryCache.clear();
    _cacheTimestamps.clear();

    try {
      final cacheDir = await _getCacheDirectory();
      if (await cacheDir.exists()) {
        await cacheDir.delete(recursive: true);
        await cacheDir.create(recursive: true);
      }
      debugPrint('📸 PhotoCache: Cache cleared');
    } catch (e) {
      debugPrint('⚠️ PhotoCache: Error clearing cache: $e');
    }
  }

  /// Belirli bir fotoğrafı cache'den siler
  Future<void> removeFromCache(String url, {bool thumbnail = false}) async {
    final cacheKey = _getCacheKey(url, thumbnail: thumbnail);

    // Memory cache'den sil
    _memoryCache.remove(cacheKey);
    _cacheTimestamps.remove(cacheKey);

    // Disk cache'den sil
    try {
      final file = await _getCacheFile(cacheKey);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('⚠️ PhotoCache: Error removing from cache: $e');
    }
  }

  /// Cache boyutunu alır
  Future<int> getCacheSize() async {
    int size = 0;
    try {
      final cacheDir = await _getCacheDirectory();
      if (await cacheDir.exists()) {
        await for (final entity in cacheDir.list(recursive: true)) {
          if (entity is File) {
            size += await entity.length();
          }
        }
      }
    } catch (e) {
      debugPrint('⚠️ PhotoCache: Error calculating cache size: $e');
    }
    return size;
  }
}
