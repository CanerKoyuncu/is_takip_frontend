/// API Servis Factory Sınıfı
///
/// Bu sınıf, API servislerinin oluşturulmasını ve yönetilmesini sağlar.
/// Singleton pattern kullanarak her servis tipi için tek bir instance oluşturur.
///
/// Avantajları:
/// - Tek instance garantisi (memory efficient)
/// - Merkezi yönetim
/// - Kolay test edilebilirlik (reset metodu ile)
library;

import '../config/api_config.dart';
import 'api_service.dart';
import '../../features/jobs/services/jobs_api_service.dart';
import '../../features/jobs/services/archive_api_service.dart';

/// API servis factory sınıfı
///
/// Singleton pattern kullanarak API servislerinin tek instance'ını sağlar.
/// Bu sayede aynı servis birden fazla kez oluşturulmaz ve memory tasarrufu sağlanır.
class ApiServiceFactory {
  // Private constructor - bu sınıf singleton pattern kullanır
  ApiServiceFactory._();

  // Singleton instance'lar - lazy initialization ile oluşturulur
  static ApiService? _apiService;
  static JobsApiService? _jobsApiService;
  static ArchiveApiService? _archiveApiService;

  /// ApiService instance'ını al veya oluştur
  ///
  /// Eğer daha önce oluşturulmamışsa yeni bir instance oluşturur,
  /// varsa mevcut instance'ı döndürür.
  static ApiService getApiService() {
    // Lazy initialization - sadece gerektiğinde oluştur
    _apiService ??= ApiService(
      baseUrl: ApiConfig.baseUrl,
      apiKey: ApiConfig.apiKey,
    );
    return _apiService!;
  }

  /// JobsApiService instance'ını al veya oluştur
  ///
  /// İş emirleri ile ilgili API işlemleri için kullanılır.
  /// ApiService'i dependency olarak alır.
  static JobsApiService getJobsApiService() {
    // Lazy initialization - sadece gerektiğinde oluştur
    _jobsApiService ??= JobsApiService(getApiService());
    return _jobsApiService!;
  }

  /// Get or create ArchiveApiService instance
  /// TODO: Bu servis şu anda hiçbir yerde kullanılmıyor. Gelecekte arşiv özellikleri eklendiğinde kullanılabilir.
  static ArchiveApiService getArchiveApiService() {
    _archiveApiService ??= ArchiveApiService(getApiService());
    return _archiveApiService!;
  }

  /// Tüm servis instance'larını sıfırla
  ///
  /// Bu metod test ortamında veya yapılandırma değişikliklerinde kullanılır.
  /// Tüm singleton instance'ları null yaparak bir sonraki çağrıda
  /// yeni instance'lar oluşturulmasını sağlar.
  static void reset() {
    _apiService = null;
    _jobsApiService = null;
    _archiveApiService = null;
  }
}
