/// Token Storage Service
///
/// JWT token'ları güvenli bir şekilde saklamak ve yönetmek için kullanılır.
/// shared_preferences kullanarak token'ları local storage'da saklar.
/// Web platformunda shared_preferences başarısız olursa in-memory storage kullanır.
///
/// Özellikler:
/// - Access token saklama ve alma
/// - Refresh token saklama ve alma
/// - Token'ları temizleme
/// - Async işlemler
/// - Web platformu için fallback mekanizması
library;

import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dart:async';

class TokenStorageService {
  // Singleton instance
  static TokenStorageService? _instance;
  static SharedPreferences? _prefs;
  static Completer<SharedPreferences?>? _initCompleter;
  static bool _isInitializing = false;

  // In-memory fallback storage (web için) - static olmalı
  static final Map<String, String> _memoryStorage = {};

  // Token key'leri
  static const String _accessTokenKey = 'jwt_access_token';
  static const String _refreshTokenKey = 'jwt_refresh_token';
  static const String _usernameKey = 'username';

  // Private constructor
  TokenStorageService._();

  /// Singleton instance'ı al
  ///
  /// shared_preferences başarısız olursa in-memory storage kullanır.
  /// Web platformunda shared_preferences'ı tamamen atlar.
  static Future<TokenStorageService> getInstance() async {
    _instance ??= TokenStorageService._();

    // Web platformunda da shared_preferences kullan (localStorage kullanır)
    // Sadece başlatma işlemini atlamayalım

    // Eğer zaten başlatılıyorsa, mevcut completer'ı bekle
    if (_isInitializing && _initCompleter != null) {
      await _initCompleter!.future;
      return _instance!;
    }

    // Eğer zaten başlatıldıysa, direkt dön
    if (_prefs != null) {
      return _instance!;
    }

    // Başlatma işlemini başlat
    _isInitializing = true;
    _initCompleter = Completer<SharedPreferences?>();

    try {
      // shared_preferences'i başlat
      _prefs = await SharedPreferences.getInstance();
      _initCompleter!.complete(_prefs);
      if (kDebugMode) {
        print('✅ SharedPreferences initialized successfully');
      }
    } on MissingPluginException catch (e) {
      // Plugin bulunamadığında in-memory storage kullan
      if (kDebugMode) {
        print('⚠️ SharedPreferences plugin not available: $e');
        print('💡 Using in-memory storage as fallback');
      }
      _prefs = null;
      _initCompleter!.complete(null);
    } catch (e) {
      // Diğer hatalar için de in-memory storage kullan
      if (kDebugMode) {
        print('⚠️ SharedPreferences initialization failed: $e');
        print('💡 Using in-memory storage as fallback');
      }
      _prefs = null;
      _initCompleter!.complete(null);
    } finally {
      _isInitializing = false;
    }

    return _instance!;
  }

  /// Access token'ı kaydet
  Future<void> saveAccessToken(String token) async {
    if (_prefs != null) {
      try {
        await _prefs!.setString(_accessTokenKey, token);
      } catch (e) {
        // Hata durumunda in-memory storage'a kaydet
        _memoryStorage[_accessTokenKey] = token;
        if (kDebugMode) {
          print(
            '⚠️ Failed to save access token to SharedPreferences, using memory: $e',
          );
        }
      }
    } else {
      _memoryStorage[_accessTokenKey] = token;
    }
  }

  /// Access token'ı al
  String? getAccessToken() {
    if (_prefs != null) {
      try {
        return _prefs!.getString(_accessTokenKey);
      } catch (e) {
        // Hata durumunda in-memory storage'dan al
        if (kDebugMode) {
          print(
            '⚠️ Failed to get access token from SharedPreferences, using memory: $e',
          );
        }
        return _memoryStorage[_accessTokenKey];
      }
    }
    return _memoryStorage[_accessTokenKey];
  }

  /// Refresh token'ı kaydet
  Future<void> saveRefreshToken(String token) async {
    if (_prefs != null) {
      try {
        await _prefs!.setString(_refreshTokenKey, token);
      } catch (e) {
        // Hata durumunda in-memory storage'a kaydet
        _memoryStorage[_refreshTokenKey] = token;
        if (kDebugMode) {
          print(
            '⚠️ Failed to save refresh token to SharedPreferences, using memory: $e',
          );
        }
      }
    } else {
      _memoryStorage[_refreshTokenKey] = token;
    }
  }

  /// Refresh token'ı al
  String? getRefreshToken() {
    if (_prefs != null) {
      try {
        return _prefs!.getString(_refreshTokenKey);
      } catch (e) {
        // Hata durumunda in-memory storage'dan al
        if (kDebugMode) {
          print(
            '⚠️ Failed to get refresh token from SharedPreferences, using memory: $e',
          );
        }
        return _memoryStorage[_refreshTokenKey];
      }
    }
    return _memoryStorage[_refreshTokenKey];
  }

  /// Kullanıcı adını kaydet
  Future<void> saveUsername(String username) async {
    if (_prefs != null) {
      try {
        await _prefs!.setString(_usernameKey, username);
      } catch (e) {
        // Hata durumunda in-memory storage'a kaydet
        _memoryStorage[_usernameKey] = username;
        if (kDebugMode) {
          print(
            '⚠️ Failed to save username to SharedPreferences, using memory: $e',
          );
        }
      }
    } else {
      _memoryStorage[_usernameKey] = username;
    }
  }

  /// Kullanıcı adını al
  String? getUsername() {
    if (_prefs != null) {
      try {
        return _prefs!.getString(_usernameKey);
      } catch (e) {
        // Hata durumunda in-memory storage'dan al
        if (kDebugMode) {
          print(
            '⚠️ Failed to get username from SharedPreferences, using memory: $e',
          );
        }
        return _memoryStorage[_usernameKey];
      }
    }
    return _memoryStorage[_usernameKey];
  }

  /// Tüm token'ları kaydet
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    String? username,
  }) async {
    await saveAccessToken(accessToken);
    await saveRefreshToken(refreshToken);
    if (username != null) {
      await saveUsername(username);
    }
  }

  /// Tüm token'ları temizle
  Future<void> clearTokens() async {
    if (_prefs != null) {
      try {
        await _prefs!.remove(_accessTokenKey);
        await _prefs!.remove(_refreshTokenKey);
        await _prefs!.remove(_usernameKey);
      } catch (e) {
        // Hata durumunda in-memory storage'ı temizle
        if (kDebugMode) {
          print(
            '⚠️ Failed to clear tokens from SharedPreferences, clearing memory: $e',
          );
        }
        _memoryStorage.remove(_accessTokenKey);
        _memoryStorage.remove(_refreshTokenKey);
        _memoryStorage.remove(_usernameKey);
      }
    } else {
      _memoryStorage.remove(_accessTokenKey);
      _memoryStorage.remove(_refreshTokenKey);
      _memoryStorage.remove(_usernameKey);
    }
  }

  /// Kullanıcının giriş yapıp yapmadığını kontrol et
  bool isAuthenticated() {
    return getAccessToken() != null && getRefreshToken() != null;
  }
}
