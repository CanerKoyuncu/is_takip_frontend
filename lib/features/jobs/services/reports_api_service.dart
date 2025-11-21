/// Reports API Servisi
///
/// Backend'den rapor verilerini çeker.
import '../../../../core/services/api_service.dart';
import '../models/worker_hours_model.dart';

class ReportsApiService {
  ReportsApiService({required ApiService apiService})
    : _apiService = apiService;

  final ApiService _apiService;

  /// İşçi mesai saatleri raporunu getirir
  ///
  /// Backend'den belirli bir işçinin araç bazında mesai saatlerini çeker.
  ///
  /// Parametreler:
  /// - workerId: İşçi ID'si
  /// - startDate: Başlangıç tarihi (opsiyonel)
  /// - endDate: Bitiş tarihi (opsiyonel)
  ///
  /// Döner: WorkerHoursReport - İşçi mesai saatleri raporu
  Future<WorkerHoursReport> getWorkerHours({
    required String workerId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{};

      if (startDate != null) {
        // YYYY-MM-DD formatında gönder
        queryParams['start_date'] =
            '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}';
      }

      if (endDate != null) {
        // YYYY-MM-DD formatında gönder
        queryParams['end_date'] =
            '${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}';
      }

      final response = await _apiService.get<Map<String, dynamic>>(
        '/reports/workers/$workerId/hours',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      return WorkerHoursReport.fromJson(response.data!);
    } catch (e) {
      throw Exception('İşçi mesai saatleri yüklenirken hata oluştu: $e');
    }
  }

  /// Tüm işçilerin mesai saatleri raporunu getirir
  ///
  /// Backend'den tüm işçilerin araç bazında toplam mesai saatlerini çeker.
  ///
  /// Parametreler:
  /// - startDate: Başlangıç tarihi (opsiyonel)
  /// - endDate: Bitiş tarihi (opsiyonel)
  ///
  /// Döner: WorkerHoursReport - Tüm işçilerin mesai saatleri raporu
  Future<WorkerHoursReport> getAllWorkersHours({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{};

      if (startDate != null) {
        // YYYY-MM-DD formatında gönder
        queryParams['start_date'] =
            '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}';
      }

      if (endDate != null) {
        // YYYY-MM-DD formatında gönder
        queryParams['end_date'] =
            '${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}';
      }

      final response = await _apiService.get<Map<String, dynamic>>(
        '/reports/workers/all/hours',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      return WorkerHoursReport.fromJson(response.data!);
    } catch (e) {
      throw Exception(
        'Tüm işçilerin mesai saatleri yüklenirken hata oluştu: $e',
      );
    }
  }
}
