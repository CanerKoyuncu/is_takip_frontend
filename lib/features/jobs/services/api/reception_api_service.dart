/// Araç Kabul API Servisi
///
/// Backend ile reception (araç kabul) formları için iletişim kurar.
/// Kaydetme, listeleme ve detay getirme işlemlerini içerir.
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/config/api_config.dart';
import '../../../../core/services/api_service.dart';

class ReceptionUploadedPhoto {
  const ReceptionUploadedPhoto({required this.photoId, required this.path});

  final String photoId;
  final String path;
}

/// Araç kabul API servis sınıfı
class ReceptionApiService {
  ReceptionApiService(this._apiService);

  final ApiService _apiService;

  /// Reception fotoğrafını backend'e güvenli şekilde yükler.
  Future<ReceptionUploadedPhoto> uploadReceptionPhoto({
    required String plate,
    required String imagePath,
    required String variant,
  }) async {
    final bytes = await _readPhotoBytes(imagePath);
    if (bytes == null || bytes.isEmpty) {
      throw Exception('Fotoğraf okunamadı: $imagePath');
    }

    String fileName = imagePath.split('/').last;
    if (fileName.isEmpty ||
        fileName.startsWith('blob:') ||
        !fileName.contains('.')) {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      fileName = 'reception_${variant}_$timestamp.jpg';
    }

    final multipart = MultipartFile.fromBytes(bytes, filename: fileName);
    final formData = FormData.fromMap({
      'plate': plate,
      'variant': variant,
      'file': multipart,
    });

    final response = await _apiService.post(
      '/reception/photos/upload',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );

    final data = response.data;
    if (data is Map<String, dynamic> && data['success'] == true) {
      final payload = data['data'] as Map<String, dynamic>;
      final photoId = (payload['photoId'] ?? '').toString().trim();
      final path = (payload['path'] ?? '').toString().trim();
      if (photoId.isEmpty || path.isEmpty) {
        throw Exception('Reception fotoğrafı yanıtı eksik: photoId/path');
      }
      return ReceptionUploadedPhoto(photoId: photoId, path: path);
    }

    throw Exception('Reception fotoğrafı yüklenemedi');
  }

  /// Relative reception fotoğraf yolunu görüntülenebilir API URL'ine çevirir.
  static String resolvePhotoPath(String rawPath) {
    final trimmed = rawPath.trim();
    if (trimmed.isEmpty) return trimmed;

    if (trimmed.startsWith('http://') ||
        trimmed.startsWith('https://') ||
        trimmed.startsWith('data:') ||
        trimmed.startsWith('blob:')) {
      return trimmed;
    }

    if (!trimmed.startsWith('reception/') &&
        !trimmed.startsWith('uploads/reception/')) {
      return trimmed;
    }

    String normalized = trimmed;
    if (normalized.startsWith('uploads/')) {
      normalized = normalized.substring('uploads/'.length);
    }

    final parts = normalized.split('/').where((p) => p.isNotEmpty).toList();
    if (parts.length == 4 && parts.first == 'reception') {
      final plateSlug = Uri.encodeComponent(parts[1]);
      final variant = Uri.encodeComponent(parts[2]);
      final filename = Uri.encodeComponent(parts[3]);
      return '${ApiConfig.baseUrl}/reception/photos/$plateSlug/$variant/$filename';
    }

    // Backward-compatible fallback for unexpected legacy path shapes.
    final encoded = Uri.encodeQueryComponent(normalized);
    return '${ApiConfig.baseUrl}/reception/photos/file?path=$encoded';
  }

  static String resolvePhotoById(String photoId) {
    final id = photoId.trim();
    if (id.isEmpty) return id;
    return '${ApiConfig.baseUrl}/reception/photos/id/${Uri.encodeComponent(id)}';
  }

  Future<List<int>?> _readPhotoBytes(String imagePath) async {
    if (imagePath.startsWith('data:image')) {
      final uri = Uri.tryParse(imagePath);
      final bytes = uri?.data?.contentAsBytes();
      return bytes;
    }

    final file = XFile(imagePath);
    return file.readAsBytes();
  }

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
    String? deliveredBy,
    String? receivedBy,
    String? defects,
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
        'delivered_by': deliveredBy,
        'received_by': receivedBy,
        'defects': defects,
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
    final queryParams = <String, dynamic>{'limit': limit, 'skip': skip};
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
