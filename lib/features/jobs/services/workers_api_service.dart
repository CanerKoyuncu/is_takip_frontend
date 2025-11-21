/// Workers API Servisi
///
/// Backend'den personel listesini çeker ve personel yönetimi işlemlerini yapar.
import '../models/worker_model.dart';
import '../../../../core/services/api_service.dart';

class WorkersApiService {
  WorkersApiService({required ApiService apiService})
    : _apiService = apiService;

  final ApiService _apiService;

  /// Tüm personelleri getirir
  ///
  /// Backend'den personel listesini çeker.
  /// Döner: List<Worker> - Personel listesi
  ///
  /// Parametreler:
  /// - kioskMode: Kiosk modu için token gerektirmeyen endpoint kullan (varsayılan: false)
  Future<List<Worker>> getWorkers({bool kioskMode = false}) async {
    try {
      // Kiosk modu için token gerektirmeyen endpoint kullan
      final endpoint = kioskMode ? '/auth/workers' : '/auth/users';
      final response = await _apiService.get<List<dynamic>>(endpoint);
      return (response.data ?? [])
          .map((json) => Worker.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Personeller yüklenirken hata oluştu: $e');
    }
  }

  /// Yeni personel oluşturur
  ///
  /// Parametreler:
  /// - username: Kullanıcı adı
  /// - fullName: Tam ad (opsiyonel)
  /// - role: Rol (admin, manager, supervisor, worker)
  ///
  /// Döner: Worker - Oluşturulan personel
  ///
  /// Not:
  /// - Worker rolü için şifre oluşturulmaz, diğer roller için otomatik oluşturulur
  /// - Worker rolü için email gönderilmez (backend otomatik olarak None yapar)
  /// - Diğer roller için email gönderilebilir (opsiyonel)
  Future<Worker> createWorker({
    required String username,
    String? fullName,
    String? role,
  }) async {
    try {
      // Email göndermiyoruz - backend worker role'ü için otomatik None yapar
      // Diğer roller için de email opsiyonel, bu yüzden göndermiyoruz
      final response = await _apiService.post<Map<String, dynamic>>(
        '/auth/users',
        data: {
          'username': username,
          if (fullName != null) 'fullName': fullName,
          if (role != null) 'role': role,
          // Email gönderilmiyor - worker'lar için backend None yapar
        },
      );
      return Worker.fromJson(response.data!);
    } catch (e) {
      throw Exception('Personel oluşturulurken hata oluştu: $e');
    }
  }

  /// Personel bilgilerini günceller
  ///
  /// Parametreler:
  /// - workerId: Personel ID'si
  /// - username: Yeni kullanıcı adı (opsiyonel)
  /// - fullName: Yeni tam ad (opsiyonel)
  /// - password: Yeni şifre (opsiyonel)
  /// - role: Yeni rol (opsiyonel)
  ///
  /// Döner: Worker - Güncellenmiş personel
  ///
  /// Not: Email gönderilmiyor - worker role'ü için backend otomatik None yapar
  Future<Worker> updateWorker({
    required String workerId,
    String? username,
    String? fullName,
    String? password,
    String? role,
  }) async {
    try {
      // Email göndermiyoruz - backend worker role'ü için otomatik None yapar
      // Diğer roller için de email güncellemesi yapmıyoruz
      final response = await _apiService.put<Map<String, dynamic>>(
        '/auth/users/$workerId',
        data: {
          if (username != null) 'username': username,
          if (fullName != null) 'fullName': fullName,
          if (password != null && password.isNotEmpty) 'password': password,
          if (role != null) 'role': role,
          // Email gönderilmiyor - worker'lar için backend None yapar
        },
      );
      return Worker.fromJson(response.data!);
    } catch (e) {
      throw Exception('Personel güncellenirken hata oluştu: $e');
    }
  }

  /// Personel siler
  ///
  /// Parametreler:
  /// - workerId: Personel ID'si
  Future<void> deleteWorker(String workerId) async {
    try {
      await _apiService.delete('/auth/users/$workerId');
    } catch (e) {
      throw Exception('Personel silinirken hata oluştu: $e');
    }
  }
}
