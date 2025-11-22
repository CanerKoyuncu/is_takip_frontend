import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../core/services/api_service.dart';
import '../../../core/services/api_service_factory.dart';
import '../models/job_models.dart';
import '../services/photo_service.dart';

/// Widget for displaying task photos from API
/// Uses Dio to load images with authentication headers
class PhotoImageWidget extends StatefulWidget {
  const PhotoImageWidget({
    super.key,
    required this.photo,
    required this.jobId,
    required this.taskId,
    this.useThumbnail = false,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.onTap,
  });

  final TaskPhoto photo;
  final String jobId;
  final String taskId;
  final bool useThumbnail;
  final double? width;
  final double? height;
  final BoxFit fit;
  final VoidCallback? onTap;

  @override
  State<PhotoImageWidget> createState() => _PhotoImageWidgetState();
}

class _PhotoImageWidgetState extends State<PhotoImageWidget> {
  Uint8List? _imageBytes;
  bool _isLoading = true;
  String? _error;
  late final ApiService _apiService;

  @override
  void initState() {
    super.initState();
    _apiService = ApiServiceFactory.getApiService();
    _loadImage();
  }

  @override
  void didUpdateWidget(PhotoImageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.photo.id != widget.photo.id ||
        oldWidget.useThumbnail != widget.useThumbnail) {
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _imageBytes = null;
    });

    final photoUrl = PhotoService.getPhotoUrlFromConfig(
      widget.photo,
      jobId: widget.jobId,
      taskId: widget.taskId,
      thumbnail: widget.useThumbnail,
    );

    debugPrint('📸 PhotoImageWidget: photoUrl=$photoUrl');

    if (photoUrl == null) {
      debugPrint('⚠️ PhotoImageWidget: photoUrl is null!');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Fotoğraf URL\'si bulunamadı';
        });
      }
      return;
    }

    try {
      final response = await _apiService.getBytes(
        photoUrl,
        options: Options(
          headers: {'Accept': 'image/*'},
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        if (mounted) {
          setState(() {
            _imageBytes = response.data;
            _isLoading = false;
          });
        }
      } else {
        debugPrint('❌ PhotoImageWidget: HTTP ${response.statusCode}');
        if (mounted) {
          setState(() {
            _isLoading = false;
            _error = 'Fotoğraf yüklenemedi (${response.statusCode})';
          });
        }
      }
    } catch (e) {
      debugPrint('❌ PhotoImageWidget: Image load error: $e');
      debugPrint('❌ PhotoImageWidget: URL was: $photoUrl');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Fotoğraf yüklenirken hata oluştu';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Stack(
        children: [
          Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _isLoading
                  ? Center(child: CircularProgressIndicator(strokeWidth: 2))
                  : _error != null || _imageBytes == null
                  ? _buildErrorWidget(context)
                  : Image.memory(
                      _imageBytes!,
                      width: widget.width,
                      height: widget.height,
                      fit: widget.fit,
                    ),
            ),
          ),
          // Aşama badge'i (sağ üst köşede)
          if (widget.photo.stage != null)
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: widget.photo.stage!.toColor(context),
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Text(
                  widget.photo.stage!.label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: widget.photo.stage!.onColor(context),
                    fontWeight: FontWeight.w600,
                    fontSize: 9,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.broken_image_outlined,
            size: 32,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 8),
          Text(
            'Fotoğraf yüklenemedi',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
