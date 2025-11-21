/// Task Photos List Widget
///
/// Görev fotoğraflarını liste halinde gösteren widget.
/// Horizontal scroll, thumbnail görüntüler ve indirme butonu içerir.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/job_models.dart';
import '../providers/jobs_provider.dart';
import '../widgets/photo_image_widget.dart';
import 'task_photo_dialog.dart';

/// Task photos list widget'ı
///
/// Görev fotoğraflarını horizontal scroll ile gösterir.
class TaskPhotosList extends StatelessWidget {
  const TaskPhotosList({
    super.key,
    required this.photos,
    required this.jobId,
    required this.taskId,
    this.showDownloadButton = true,
    this.onPhotoTap,
    this.height = 80,
    this.thumbnailSize = 80,
  });

  /// Fotoğraflar
  final List<TaskPhoto> photos;

  /// İş emri ID'si
  final String jobId;

  /// Görev ID'si
  final String taskId;

  /// İndirme butonu göster? (varsayılan: true)
  final bool showDownloadButton;

  /// Fotoğraf tıklama callback'i (opsiyonel, varsayılan: dialog açma)
  final void Function(TaskPhoto)? onPhotoTap;

  /// Liste yüksekliği (varsayılan: 80)
  final double height;

  /// Thumbnail boyutu (varsayılan: 80)
  final double thumbnailSize;

  @override
  Widget build(BuildContext context) {
    if (photos.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with download button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Fotoğraflar (${photos.length})',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (showDownloadButton)
              IconButton(
                icon: const Icon(Icons.download_outlined),
                tooltip: 'Görev fotoğraflarını indir (ZIP)',
                onPressed: () => _downloadPhotos(context),
              ),
          ],
        ),
        const SizedBox(height: 8),
        // Photo list
        SizedBox(
          height: height,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: photos.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final photo = photos[index];
              return PhotoImageWidget(
                photo: photo,
                jobId: jobId,
                taskId: taskId,
                useThumbnail: true,
                width: thumbnailSize,
                height: thumbnailSize,
                onTap: () {
                  if (onPhotoTap != null) {
                    onPhotoTap!(photo);
                  } else {
                    TaskPhotoDialog.show(
                      context,
                      photo: photo,
                      jobId: jobId,
                      taskId: taskId,
                      showDownloadButton: showDownloadButton,
                    );
                  }
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _downloadPhotos(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final provider = Provider.of<JobsProvider>(context, listen: false);
      final downloadPath = await provider.downloadTaskPhotosZip(
        jobId: jobId,
        taskId: taskId,
      );
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            downloadPath == null
                ? 'Görev fotoğrafları indirilmeye başlandı.'
                : 'Görev fotoğrafları indirildi: $downloadPath',
          ),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Görev fotoğrafları indirilirken hata oluştu: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
