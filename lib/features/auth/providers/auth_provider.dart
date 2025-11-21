/// Kimlik Doğrulama Provider'ı
///
/// Bu sınıf, kullanıcı kimlik doğrulama işlemlerini yönetir.
/// ChangeNotifier kullanarak state değişikliklerini dinleyicilere bildirir.
///
/// Özellikler:
/// - Kullanıcı giriş/çıkış işlemleri
/// - Giriş durumu takibi
/// - Hata mesajı yönetimi
/// - Son giriş zamanı takibi
/// - JWT token yönetimi (HttpOnly cookies tarafından yönetilir)
/// - Otomatik token yenileme

import 'package:flutter/foundation.dart';
import '../../../core/services/auth_api_service.dart';

/// Kimlik doğrulama provider sınıfı
///
/// Kullanıcının giriş durumunu yönetir ve state değişikliklerini
/// dinleyicilere bildirir (ChangeNotifier pattern).
/// Tokens artık HttpOnly cookies tarafından yönetilir.
class AuthProvider extends ChangeNotifier {
  final AuthApiService _authApiService;

  AuthProvider({required AuthApiService authApiService})
    : _authApiService = authApiService;

  // Kullanıcının giriş yapıp yapmadığını tutar
  bool _isAuthenticated = false;
  // Giriş işleminin devam edip etmediğini tutar
  bool _isLoading = false;
  // Hata mesajı (giriş başarısız olduğunda)
  String? _errorMessage;
  // Son başarılı giriş zamanı
  DateTime? _lastLoginAt;
  // Kullanıcı bilgileri
  Map<String, dynamic>? _user;

  // Giriş durumu getter'ı
  bool get isAuthenticated => _isAuthenticated;
  // Yükleme durumu getter'ı
  bool get isLoading => _isLoading;
  // Hata mesajı getter'ı
  String? get errorMessage => _errorMessage;
  // Son giriş zamanı getter'ı
  DateTime? get lastLoginAt => _lastLoginAt;
  // Kullanıcı bilgileri getter'ı
  Map<String, dynamic>? get user => _user;

  // Kullanıcı rolü getter'ı
  String? get userRole => _user?['role'] as String?;

  // Admin kontrolü
  bool get isAdmin => userRole == 'admin';

  // Manager kontrolü
  bool get isManager => userRole == 'manager';

  // Supervisor kontrolü
  bool get isSupervisor => userRole == 'supervisor';

  // Worker kontrolü
  bool get isWorker => userRole == 'worker' || userRole == null;

  // Panel kullanıcısı kontrolü (admin, manager, supervisor)
  bool get isPanelUser => isAdmin || isManager || isSupervisor;

  // İş emri oluşturma yetkisi (supervisor, manager, admin)
  bool get canCreateJob => isSupervisor || isManager || isAdmin;

  /// Uygulama başlatıldığında mevcut token'ı kontrol et
  ///
  /// Cookies'de geçerli bir token varsa kullanıcıyı otomatik olarak giriş yapmış sayar.
  Future<void> checkAuthStatus() async {
    try {
      // API'ye istek gönder - cookie mevcutsa otomatik olarak gönderilir
      final userData = await _authApiService.getCurrentUser();
      _user = userData;
      _isAuthenticated = true;
      notifyListeners();
    } catch (e) {
      // Token geçersiz veya yok, kullanıcı giriş yapmamış
      _isAuthenticated = false;
      _user = null;
      notifyListeners();
      if (kDebugMode) {
        print('Not authenticated: ${e.toString()}');
      }
    }
  }

  /// Kullanıcı girişi yapar
  ///
  /// Backend API'ye login isteği gönderir ve token'ları saklar.
  ///
  /// Parametreler:
  /// - username: Kullanıcı adı
  /// - password: Şifre
  ///
  /// Döner: bool - Giriş başarılı ise true, değilse false
  Future<bool> login({
    required String username,
    required String password,
  }) async {
    // Eğer zaten bir giriş işlemi devam ediyorsa, yeni isteği reddet
    if (_isLoading) return false;

    // Yükleme durumunu aktif et
    _setLoading(true);
    _errorMessage = null;
    notifyListeners();

    try {
      // Backend'e login isteği gönder
      final result = await _authApiService.login(
        username: username.trim(),
        password: password,
      );

      if (result['success'] == true) {
        // Giriş başarılı
        _isAuthenticated = true;
        _user = result['user'] as Map<String, dynamic>?;
        _errorMessage = null;
        _lastLoginAt = DateTime.now();
        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        // Giriş başarısız
        _errorMessage = 'Giriş başarısız';
        _isAuthenticated = false;
        _user = null;
        _setLoading(false);
        notifyListeners();
        return false;
      }
    } catch (e) {
      // Hata oluştu
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isAuthenticated = false;
      _user = null;
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  /// Kullanıcı kaydı yapar
  ///
  /// Backend API'ye register isteği gönderir ve token'ları saklar.
  ///
  /// Parametreler:
  /// - username: Kullanıcı adı
  /// - password: Şifre
  /// - email: Email adresi (opsiyonel)
  /// - fullName: Tam ad (opsiyonel)
  ///
  /// Döner: bool - Kayıt başarılı ise true, değilse false
  Future<bool> register({
    required String username,
    required String password,
    String? email,
    String? fullName,
  }) async {
    // Eğer zaten bir işlem devam ediyorsa, yeni isteği reddet
    if (_isLoading) return false;

    // Yükleme durumunu aktif et
    _setLoading(true);
    _errorMessage = null;
    notifyListeners();

    try {
      // Backend'e register isteği gönder
      final result = await _authApiService.register(
        username: username.trim(),
        password: password,
        email: email?.trim(),
        fullName: fullName?.trim(),
      );

      if (result['success'] == true) {
        // Kayıt başarılı
        _isAuthenticated = true;
        _user = result['user'] as Map<String, dynamic>?;
        _errorMessage = null;
        _lastLoginAt = DateTime.now();
        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        // Kayıt başarısız
        _errorMessage = 'Kayıt başarısız';
        _isAuthenticated = false;
        _user = null;
        _setLoading(false);
        notifyListeners();
        return false;
      }
    } catch (e) {
      // Hata oluştu
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isAuthenticated = false;
      _user = null;
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  /// Kullanıcı çıkışı yapar
  ///
  /// Backend logout endpoint'ini çağırır ve tüm state'i temizler.
  Future<void> logout() async {
    if (kDebugMode) {
      print('🚪 Logging out user...');
    }

    try {
      await _authApiService.logout();
      if (kDebugMode) {
        print('✅ Logout successful');
      }
    } catch (e) {
      // Logout hatası olsa bile state'i temizle
      if (kDebugMode) {
        print('⚠️ Logout error: $e');
      }
    }

    // Tüm state'i temizle
    _isAuthenticated = false;
    _user = null;
    _errorMessage = null;
    _lastLoginAt = null;
    notifyListeners();
  }

  /// Hata mesajını temizler
  ///
  /// Kullanıcı yeni bir giriş denemesi yaptığında hata mesajını kaldırır.
  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      // State değişikliğini dinleyicilere bildir
      notifyListeners();
    }
  }

  /// Yükleme durumunu ayarlar
  ///
  /// Private metod - sadece bu sınıf içinden çağrılır.
  /// Yükleme durumunu günceller ve dinleyicilere bildirir.
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
