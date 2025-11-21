import '../../../core/services/api_service.dart';

/// API service for archive operations
class ArchiveApiService {
  ArchiveApiService(this._apiService);

  final ApiService _apiService;

  /// Search photos with filters
  Future<Map<String, dynamic>> searchPhotos({
    String? jobId,
    String? taskId,
    String? photoType,
    DateTime? dateFrom,
    DateTime? dateTo,
    bool? archived,
    int limit = 100,
    int skip = 0,
  }) async {
    final queryParams = <String, dynamic>{'limit': limit, 'skip': skip};

    if (jobId != null) queryParams['job_id'] = jobId;
    if (taskId != null) queryParams['task_id'] = taskId;
    if (photoType != null) queryParams['photo_type'] = photoType;
    if (dateFrom != null) {
      queryParams['date_from'] = dateFrom.toIso8601String();
    }
    if (dateTo != null) {
      queryParams['date_to'] = dateTo.toIso8601String();
    }
    if (archived != null) queryParams['archived'] = archived;

    final response = await _apiService.get(
      '/archive/photos',
      queryParameters: queryParams,
    );

    return response.data as Map<String, dynamic>;
  }

  /// Get detailed metadata for a photo
  Future<Map<String, dynamic>> getPhotoMetadata({
    required String jobId,
    required String taskId,
    required String photoId,
  }) async {
    final response = await _apiService.get(
      '/archive/photos/$jobId/$taskId/$photoId/metadata',
    );

    return response.data['data'] as Map<String, dynamic>;
  }

  /// Archive a photo (move to archive directory)
  Future<void> archivePhoto({
    required String jobId,
    required String taskId,
    required String photoId,
    String reason = 'archived',
  }) async {
    await _apiService.post(
      '/archive/photos/$jobId/$taskId/$photoId/archive',
      queryParameters: {'reason': reason},
    );
  }

  /// Restore a photo from archive
  Future<void> restorePhoto({
    required String jobId,
    required String taskId,
    required String photoId,
  }) async {
    await _apiService.post('/archive/photos/$jobId/$taskId/$photoId/restore');
  }

  /// Create a backup of all photos
  Future<Map<String, dynamic>> createBackup({String? backupName}) async {
    final response = await _apiService.post(
      '/archive/backup',
      queryParameters: backupName != null ? {'backup_name': backupName} : null,
    );

    return response.data as Map<String, dynamic>;
  }

  /// Get archive statistics
  Future<Map<String, dynamic>> getArchiveStats() async {
    final response = await _apiService.get('/archive/stats');
    return response.data['data'] as Map<String, dynamic>;
  }
}
