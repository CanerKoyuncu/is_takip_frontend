import 'api_service.dart';
import 'token_storage_service.dart';

class AuthApiService {
  final ApiService _apiService;

  AuthApiService(this._apiService);

  /// Kullanıcı girişi yapar
  ///
  /// Backend'e login isteği gönderir. Tokens otomatik olarak cookies'de saklanır.
  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    try {
      final response = await _apiService.post(
        '/auth/login',
        data: {'username': username, 'password': password},
      );

      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;

        if (data['success'] == true && data['data'] != null) {
          final userData = data['user'] as Map<String, dynamic>;
          final tokenData = data['data'] as Map<String, dynamic>;

          // Tüm platformlarda (web dahil) token'ları token storage'a kaydet
          // Web'de hem cookie hem Authorization header'dan token gönderilir
          final tokenStorage = await TokenStorageService.getInstance();
          await tokenStorage.saveTokens(
            accessToken: tokenData['access_token'] as String,
            refreshToken: tokenData['refresh_token'] as String,
            username: userData['username'] as String?,
          );

          await _apiService.initializeAfterLogin();

          return {'success': true, 'user': userData};
        }
      }

      throw Exception('Login başarısız: Geçersiz yanıt');
    } catch (e) {
      throw Exception('Login başarısız: ${e.toString()}');
    }
  }

  /// Kullanıcı kaydı yapar
  ///
  /// Backend'e register isteği gönderir. Tokens otomatik olarak cookies'de saklanır.
  Future<Map<String, dynamic>> register({
    required String username,
    required String password,
    String? email,
    String? fullName,
  }) async {
    try {
      final response = await _apiService.post(
        '/auth/register',
        data: {
          'username': username,
          'password': password,
          if (email != null) 'email': email,
          if (fullName != null) 'fullName': fullName,
        },
      );

      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;

        if (data['success'] == true && data['data'] != null) {
          final userData = data['user'] as Map<String, dynamic>;
          final tokenData = data['data'] as Map<String, dynamic>;

          // Tüm platformlarda (web dahil) token'ları token storage'a kaydet
          // Web'de hem cookie hem Authorization header'dan token gönderilir
          final tokenStorage = await TokenStorageService.getInstance();
          await tokenStorage.saveTokens(
            accessToken: tokenData['access_token'] as String,
            refreshToken: tokenData['refresh_token'] as String,
            username: userData['username'] as String?,
          );

          await _apiService.initializeAfterLogin();

          return {'success': true, 'user': userData};
        }
      }

      throw Exception('Kayıt başarısız: Geçersiz yanıt');
    } catch (e) {
      throw Exception('Kayıt başarısız: ${e.toString()}');
    }
  }

  /// Token'ı yeniler
  ///
  /// Refresh token (cookies'den) kullanarak yeni access token alır.
  Future<Map<String, dynamic>> refreshToken() async {
    try {
      final response = await _apiService.post('/auth/refresh');

      if (response.data is Map<String, dynamic>) {
        // Yeni tokens otomatik olarak Set-Cookie headers ile gelmişir
        // Cookies tarafından otomatik olarak kaydedilir
        return {'success': true};
      }

      throw Exception('Token yenileme başarısız: Geçersiz yanıt');
    } catch (e) {
      throw Exception('Token yenileme başarısız: ${e.toString()}');
    }
  }

  /// Mevcut kullanıcı bilgilerini alır
  Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      final response = await _apiService.get('/auth/me');

      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }

      throw Exception('Kullanıcı bilgileri alınamadı');
    } catch (e) {
      throw Exception('Kullanıcı bilgileri alınamadı: ${e.toString()}');
    }
  }

  /// Çıkış yapar
  ///
  /// Backend logout endpoint'ini çağırır ve cookies'leri temizler.
  Future<void> logout() async {
    await _apiService.logout();
  }
}
