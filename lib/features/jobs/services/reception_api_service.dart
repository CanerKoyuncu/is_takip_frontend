/// Araç Kabul API Servisi
///
/// Backend ile reception (araç kabul) formları için iletişim kurar.
/// Kaydetme, listeleme ve detay getirme işlemlerini içerir.
import '../../../core/services/api_service.dart';

/// Araç kabul API servis sınıfı
class ReceptionApiService {
  ReceptionApiService(this._apiService);

  final ApiService _apiService;

  /// Kabul formunu backend'e kaydeder.
  ///
  /// Döner: Kaydedilen formun MongoDB ID'si.
  Future<String> saveForm({
    required String plate,
    required String brand,
    required String model,
    required Map<String, List<String>> selections,
    required List<Map<String, dynamic>> photos,
    String? generalNotes,
    List<String> requiredParts = const [],
  }) async {
    final response = await _apiService.post(
      '/reception/save',
      data: {
        'plate': plate,
        'brand': brand,
        'model': model,
        'selections': selections,
        'photos': photos,
        'general_notes': generalNotes,
        'required_parts': requiredParts,
      },
    );
    final data = response.data;
    if (data is Map<String, dynamic> && data['success'] == true) {
      return (data['data'] as Map<String, dynamic>)['inserted_id'] as String;
    }
    throw Exception('Kabul formu kaydedilemedi');
  }

  /// Kaydedilmiş kabul formlarını listeler.
  Future<List<Map<String, dynamic>>> listForms({
    String? search,
    int limit = 50,
    int skip = 0,
  }) async {
    final queryParams = <String, dynamic>{
      'limit': limit,
      'skip': skip,
    };
    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }

    final response = await _apiService.get(
      '/reception/list',
      queryParameters: queryParams,
    );
    final data = response.data;
    if (data is Map<String, dynamic> && data['success'] == true) {
      return List<Map<String, dynamic>>.from(data['data'] as List);
    }
    throw Exception('Kabul formları listelenemedi');
  }

  /// Tek bir kabul formunun detayını getirir.
  Future<Map<String, dynamic>> getFormById(String id) async {
    final response = await _apiService.get('/reception/$id');
    final data = response.data;
    if (data is Map<String, dynamic> && data['success'] == true) {
      return data['data'] as Map<String, dynamic>;
    }
    throw Exception('Kabul formu bulunamadı');
  }
}
