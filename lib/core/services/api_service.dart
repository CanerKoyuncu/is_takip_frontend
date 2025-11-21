/// Temel API Servis Sınıfı
///
/// Bu sınıf, backend API ile HTTP iletişimini yönetir.
/// Dio kütüphanesini kullanarak REST API istekleri yapar ve
/// hata yönetimi sağlar.
///
/// Özellikler:
/// - GET, POST, PUT, PATCH, DELETE metodları
/// - Otomatik API key ekleme (tüm isteklere X-API-Key header'ı eklenir)
/// - JWT token desteği (HttpOnly cookies ve Authorization header)
/// - Hata yönetimi ve Türkçe hata mesajları
/// - Request/Response logging (debug modunda)
/// - Timeout yönetimi
/// - Cookie yönetimi (HttpOnly cookie desteği)
library;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' as io show HttpClient;
import 'package:dio/io.dart' as dio_io;

import 'token_storage_service.dart';

/// Temel API servis sınıfı
///
/// Tüm HTTP istekleri bu sınıf üzerinden yapılır.
/// Dio instance'ı kullanarak backend API ile iletişim kurar.
/// Cookies otomatik olarak yönetilir.
class ApiService {
  /// Constructor
  ///
  /// Dio instance'ını yapılandırır ve interceptor'ları ekler.
  ///
  /// Parametreler:
  /// - baseUrl: Backend API'nin temel adresi
  /// - headers: Ek HTTP header'ları
  /// - apiKey: API kimlik doğrulama anahtarı
  ApiService({String? baseUrl, Map<String, String>? headers, String? apiKey})
    : _apiKey = apiKey,
      _dio = _createDio(baseUrl, headers, apiKey) {
    // Cookie yönetimi - Dio native cookie desteği
    // Cookies otomatik olarak yönetilir (Set-Cookie ve Cookie headers)
    if (kDebugMode) {
      print('🍪 Cookies will be managed automatically by Dio');
    }

    // API Key ve request/response logging interceptor'ı ekle
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // X-API-Key her zaman eklenmeli
          final apiKey = _apiKey;
          if (apiKey != null && apiKey.isNotEmpty) {
            options.headers['X-API-Key'] = apiKey;
          }

          final pathLower = options.path.toLowerCase();

          // Web platformunda cookies üzerinden kimlik doğrulama
          // Cookie'ler tarayıcı tarafından otomatik gönderilir, withCredentials ayarlanmalı
          if (kIsWeb) {
            // Web'de her request'te withCredentials ayarla (cookie'lerin gönderilmesi için)
            options.extra['withCredentials'] = true;
            // Web'de hem cookie hem Authorization header'dan token gönderilir
            final tokenStorage = await TokenStorageService.getInstance();
            if (pathLower.contains('/auth/refresh')) {
              final refreshToken = tokenStorage.getRefreshToken();
              if (refreshToken != null && refreshToken.isNotEmpty) {
                options.headers['Authorization'] = 'Bearer $refreshToken';
              }
            } else if (!pathLower.contains('/auth/login') &&
                !pathLower.contains('/auth/register')) {
              final accessToken = tokenStorage.getAccessToken();
              if (accessToken != null && accessToken.isNotEmpty) {
                options.headers['Authorization'] = 'Bearer $accessToken';
              }
            }
          } else {
            // Mobil/desktop platformlarında bearer token kullan (Authorization header)
            final tokenStorage = await TokenStorageService.getInstance();
            if (pathLower.contains('/auth/refresh')) {
              final refreshToken = tokenStorage.getRefreshToken();
              if (refreshToken != null && refreshToken.isNotEmpty) {
                options.headers['Authorization'] = 'Bearer $refreshToken';
              }
            } else if (!pathLower.contains('/auth/login') &&
                !pathLower.contains('/auth/register')) {
              final accessToken = tokenStorage.getAccessToken();
              if (accessToken != null && accessToken.isNotEmpty) {
                options.headers['Authorization'] = 'Bearer $accessToken';
              }
            }
          }

          if (kDebugMode) {
            print('🔄 Request: ${options.method} ${options.path}');
          }

          handler.next(options);
        },
        onError: (error, handler) async {
          // 401 hatası alındığında token'ı yenilemeyi dene
          // Ancak user management endpoint'leri için token güncelleme yapma
          // (Başka kullanıcı oluştururken mevcut kullanıcının token'ı güncellenmemeli)
          final requestPath = error.requestOptions.path.toLowerCase();
          final isUserManagementEndpoint =
              requestPath.contains('/auth/users') ||
              requestPath.contains('/auth/user/');

          if (error.response?.statusCode == 401 && !isUserManagementEndpoint) {
            if (kDebugMode) {
              print('⚠️ 401 Unauthorized - Attempting token refresh');
            }

            try {
              // Refresh endpoint'e istek gönder
              // Web'de cookie'ler otomatik olarak gönderilir
              // Mobil/desktop'ta Authorization header ile gönderilir
              Response<dynamic>? refreshResponse;

              if (kIsWeb) {
                // Web'de sadece cookie ile gönder (cookie'ler otomatik gönderilir)
                refreshResponse = await _dio.post('/auth/refresh');
              } else {
                // Mobil/desktop'ta Authorization header ile gönder
                final tokenStorage = await TokenStorageService.getInstance();
                final refreshToken = tokenStorage.getRefreshToken();
                if (refreshToken == null || refreshToken.isEmpty) {
                  if (kDebugMode) {
                    print('❌ Refresh token bulunamadı (mobil)');
                  }
                  return handler.next(error);
                }
                refreshResponse = await _dio.post(
                  '/auth/refresh',
                  options: Options(
                    headers: {'Authorization': 'Bearer $refreshToken'},
                  ),
                );
              }

              if (refreshResponse.statusCode == 200) {
                // Mobil/desktop'ta yeni token'ları token storage'a kaydet
                // Web'de cookie'ler otomatik olarak güncellenir
                if (!kIsWeb) {
                  final data = refreshResponse.data;
                  if (data is Map<String, dynamic>) {
                    final newAccessToken = data['access_token'] as String?;
                    final newRefreshToken = data['refresh_token'] as String?;
                    final tokenStorage =
                        await TokenStorageService.getInstance();
                    if (newAccessToken != null && newRefreshToken != null) {
                      await tokenStorage.saveTokens(
                        accessToken: newAccessToken,
                        refreshToken: newRefreshToken,
                      );
                    }
                  }
                }
                // Yeni tokens Set-Cookie ile gelmişir
                if (kDebugMode) {
                  print('✅ Token refreshed successfully');
                }

                // Orijinal isteği tekrar dene
                final retryResponse = await _dio.fetch(error.requestOptions);
                if (kDebugMode) {
                  print('✅ Retry successful');
                }
                return handler.resolve(retryResponse);
              } else {
                if (kDebugMode) {
                  print(
                    '❌ Token refresh failed: ${refreshResponse.statusCode}',
                  );
                }
              }
            } catch (refreshError) {
              if (kDebugMode) {
                print('❌ Token refresh error: $refreshError');
              }
            }
          }

          // Tüm hataları işle
          handler.next(error);
        },
      ),
    );

    // Log interceptor'ı ekle
    // Debug modunda tüm request ve response'ları loglar
    _dio.interceptors.add(
      LogInterceptor(requestBody: true, responseBody: true, error: true),
    );
  }

  // Dio instance - HTTP istekleri için kullanılır
  final Dio _dio;
  // API key - kimlik doğrulama için (fallback)
  final String? _apiKey;

  /// GET isteği gönderir
  ///
  /// Sunucudan veri almak için kullanılır.
  ///
  /// Parametreler:
  /// - path: API endpoint yolu
  /// - queryParameters: URL query parametreleri
  /// - options: Ek Dio seçenekleri
  ///
  /// Döner: Response<T> - Sunucudan gelen yanıt
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      // Hata oluşursa Türkçe hata mesajına dönüştür
      throw _handleError(e);
    }
  }

  /// POST isteği gönderir
  ///
  /// Sunucuya yeni veri göndermek için kullanılır.
  ///
  /// Parametreler:
  /// - path: API endpoint yolu
  /// - data: Gönderilecek veri (genellikle JSON)
  /// - queryParameters: URL query parametreleri
  /// - options: Ek Dio seçenekleri
  ///
  /// Döner: Response<T> - Sunucudan gelen yanıt
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// PUT isteği gönderir
  ///
  /// Mevcut veriyi tamamen güncellemek için kullanılır.
  ///
  /// Parametreler:
  /// - path: API endpoint yolu
  /// - data: Güncellenecek veri
  /// - queryParameters: URL query parametreleri
  /// - options: Ek Dio seçenekleri
  ///
  /// Döner: Response<T> - Sunucudan gelen yanıt
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// PATCH isteği gönderir
  ///
  /// Mevcut verinin bir kısmını güncellemek için kullanılır.
  ///
  /// Parametreler:
  /// - path: API endpoint yolu
  /// - data: Güncellenecek veri (kısmi)
  /// - queryParameters: URL query parametreleri
  /// - options: Ek Dio seçenekleri
  ///
  /// Döner: Response<T> - Sunucudan gelen yanıt
  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.patch<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// DELETE isteği gönderir
  ///
  /// Sunucudan veri silmek için kullanılır.
  ///
  /// Parametreler:
  /// - path: API endpoint yolu
  /// - data: Silme işlemi için ek veri (opsiyonel)
  /// - queryParameters: URL query parametreleri
  /// - options: Ek Dio seçenekleri
  ///
  /// Döner: Response<T> - Sunucudan gelen yanıt
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Login işleminin ardından gerekli kurulumları yap
  ///
  /// Web platformunda token storage kullanılmadığından bu metod sadece
  /// genel kurulumları yapar. Cookies otomatik olarak yönetilir.
  Future<void> initializeAfterLogin() async {
    if (kDebugMode) {
      print(
        '🔐 Authentication initialized - cookies will be managed automatically',
      );
    }
    // Cookies CookieManager tarafından otomatik olarak yönetilir
  }

  /// Logout işlemi (cleanup)
  ///
  /// Backend logout endpoint'i çağrılır ve cookies silinir.
  Future<void> logout() async {
    try {
      await post('/auth/logout');
      if (kDebugMode) {
        print('✅ Logout successful - cookies cleared');
      }
      if (!kIsWeb) {
        final tokenStorage = await TokenStorageService.getInstance();
        await tokenStorage.clearTokens();
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Logout error: $e');
      }
    }
  }

  /// API key'i ayarla
  ///
  /// Runtime'da API key'i değiştirmek için kullanılır.
  void setApiKey(String apiKey) {
    _dio.options.headers['X-API-Key'] = apiKey;
  }

  /// API key'i temizle
  ///
  /// API key'i header'dan kaldırır.
  void clearApiKey() {
    _dio.options.headers.remove('X-API-Key');
  }

  /// DioException'ı Türkçe Exception'a dönüştürür
  ///
  /// Farklı hata tiplerine göre kullanıcı dostu Türkçe hata mesajları üretir.
  ///
  /// Hata Tipleri:
  /// - connectionTimeout: Bağlantı zaman aşımı
  /// - sendTimeout: İstek gönderme zaman aşımı
  /// - receiveTimeout: Yanıt alma zaman aşımı
  /// - badResponse: HTTP hata kodları (400, 401, 403, 404, 500 vb.)
  /// - cancel: İstek iptal edildi
  /// - connectionError: Bağlantı hatası
  /// - unknown: Bilinmeyen hata
  Exception _handleError(DioException error) {
    if (kDebugMode) {
      print('❌ Error: ${error.type} - ${error.message}');
    }

    switch (error.type) {
      // Bağlantı zaman aşımı - sunucuya bağlanılamadı
      case DioExceptionType.connectionTimeout:
        if (kDebugMode) print('  ➜ Connection timeout');
        return Exception(
          'Bağlantı zaman aşımına uğradı. Lütfen tekrar deneyin.',
        );
      // İstek gönderme zaman aşımı - istek gönderilemedi
      case DioExceptionType.sendTimeout:
        if (kDebugMode) print('  ➜ Send timeout');
        return Exception(
          'İstek gönderilirken zaman aşımına uğradı. Lütfen tekrar deneyin.',
        );
      // Yanıt alma zaman aşımı - sunucu yanıt vermedi
      case DioExceptionType.receiveTimeout:
        if (kDebugMode) print('  ➜ Receive timeout');
        return Exception(
          'Yanıt alınırken zaman aşımına uğradı. Lütfen tekrar deneyin.',
        );
      // HTTP hata yanıtı - sunucu hata döndü
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final responseData = error.response?.data;
        String message;

        // Sunucudan gelen hata mesajını al
        if (responseData is Map<String, dynamic>) {
          message =
              responseData['message'] as String? ??
              responseData['detail'] as String? ??
              'Bilinmeyen hata';
        } else {
          message = 'Bilinmeyen hata';
        }

        if (kDebugMode) print('  ➜ HTTP $statusCode: $message');

        // HTTP status code'a göre özel mesajlar
        switch (statusCode) {
          case 400: // Bad Request - Geçersiz istek
            return Exception('Geçersiz istek: $message');
          case 401: // Unauthorized - Yetkilendirme hatası
            return Exception(
              'Yetkilendirme hatası. API anahtarı geçersiz veya eksik.',
            );
          case 403: // Forbidden - Erişim reddedildi
            return Exception('Erişim reddedildi. Bu işlem için yetkiniz yok.');
          case 404: // Not Found - Kaynak bulunamadı
            return Exception('İstenen kaynak bulunamadı.');
          case 500: // Internal Server Error - Sunucu hatası
            return Exception(
              'Sunucu hatası. Lütfen daha sonra tekrar deneyin.',
            );
          default: // Diğer HTTP hata kodları
            return Exception('Hata ($statusCode): $message');
        }
      case DioExceptionType.cancel: // İstek iptal edildi
        if (kDebugMode) print('  ➜ Request cancelled');
        return Exception('İstek iptal edildi');
      case DioExceptionType.connectionError: // Bağlantı hatası
        if (kDebugMode) print('  ➜ Connection error');
        return Exception(
          'Sunucuya bağlanılamıyor. İnternet bağlantınızı kontrol edin.',
        );
      case DioExceptionType.unknown: // Bilinmeyen hata
        // SocketException kontrolü - internet bağlantısı yoksa
        if (error.message?.contains('SocketException') ?? false) {
          if (kDebugMode) print('  ➜ Socket exception (no internet)');
          return Exception(
            'İnternet bağlantısı yok. Lütfen bağlantınızı kontrol edin.',
          );
        }
        if (kDebugMode) print('  ➜ Unknown error');
        return Exception(
          'Bağlantı hatası: ${error.message ?? 'Bilinmeyen hata'}',
        );
      default: // Varsayılan hata mesajı
        if (kDebugMode) print('  ➜ Unhandled error type');
        return Exception(
          'Bilinmeyen hata: ${error.message ?? 'Bir hata oluştu'}',
        );
    }
  }

  /// Dio instance'ını oluştur ve yapılandır
  ///
  /// Development ortamında SSL verification'ı bypass eder
  /// (Web ve test için self-signed sertifikalar kabul etmek için)
  static Dio _createDio(
    String? baseUrl,
    Map<String, String>? headers,
    String? apiKey,
  ) {
    final dio = Dio(
      BaseOptions(
        // Backend API'nin temel adresi
        baseUrl: baseUrl ?? 'http://localhost/api',
        // Varsayılan HTTP header'ları
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          // API key varsa header'a ekle
          if (apiKey != null) 'X-API-Key': apiKey,
          // Ek header'ları ekle
          ...?headers,
        },
        // Bağlantı timeout'u (30 saniye)
        connectTimeout: const Duration(seconds: 30),
        // Yanıt alma timeout'u (30 saniye)
        receiveTimeout: const Duration(seconds: 30),
        // Tüm status kodlarını kabul et (hata yönetimi için)
        validateStatus: (status) => true,
        // CORS için credentials gönder
        // Dio automatically handles cookies, but we ensure credentials are sent
        followRedirects: true,
        // Web'de cross-origin isteklerde cookie'lerin gönderilmesi için
        extra: kIsWeb ? {'withCredentials': true} : {},
      ),
    );

    // Development ortamında SSL bypass (self-signed sertifikalar için)
    // Web platform'u dart:io desteklemediğinden sadece mobile/desktop'ta çalışır
    if (kDebugMode && !kIsWeb) {
      // HttpClient'ı SSL verification olmadan ayarla
      final httpClient = io.HttpClient()
        ..badCertificateCallback = (cert, host, port) => true; // SSL bypass

      dio.httpClientAdapter = dio_io.IOHttpClientAdapter(
        createHttpClient: () => httpClient,
      );
    }

    return dio;
  }
}
