/// Task Photo Dialog Widget
///
/// Görev fotoğrafı için detaylı dialog widget'ı.
/// Fotoğraf, bilgileri (tip, aşama, tarih) ve indirme butonu içerir.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../models/job_models.dart';
import '../providers/jobs_provider.dart';
import '../widgets/photo_image_widget.dart';
import '../../../../core/widgets/info_row.dart';

/// Task photo dialog widget'ı
///
/// Görev fotoğrafını ve detaylarını gösterir.
class TaskPhotoDialog extends StatelessWidget {
  const TaskPhotoDialog({
    super.key,
    required this.photo,
    required this.jobId,
    required this.taskId,
    this.showDownloadButton = true,
  });

  /// Fotoğraf
  final TaskPhoto photo;

  /// İş emri ID'si
  final String jobId;

  /// Görev ID'si
  final String taskId;

  /// İndirme butonu göster? (varsayılan: true)
  final bool showDownloadButton;

  @override
  Widget build(BuildContext context) {
    final messenger = ScaffoldMessenger.of(context);

    return Dialog(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Fotoğraf
          PhotoImageWidget(
            photo: photo,
            jobId: jobId,
            taskId: taskId,
            useThumbnail: false,
          ),
          // Fotoğraf bilgileri
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Fotoğraf tipi
                InfoRow(
                  icon: photo.type == TaskPhotoType.damage
                      ? Icons.broken_image
                      : Icons.check_circle,
                  label: 'Fotoğraf Tipi',
                  value: photo.type.label,
                ),
                // Aşama bilgisi
                if (photo.stage != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: photo.stage!.toColor(context),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Aşama: ${photo.stage!.label}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ],
                // Tarih
                const SizedBox(height: 8),
                InfoRow(
                  icon: Icons.access_time,
                  label: 'Tarih',
                  value: DateFormat('dd.MM.yyyy HH:mm').format(photo.createdAt),
                ),
              ],
            ),
          ),
          // İndirme butonu (opsiyonel)
          if (showDownloadButton) ...[
            const Divider(height: 1),
            ButtonBar(
              alignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.download_outlined),
                  label: const Text('İndir'),
                  onPressed: () async {
                    final navigator = Navigator.of(context);
                    try {
                      final downloadPath =
                          await Provider.of<JobsProvider>(
                            context,
                            listen: false,
                          ).downloadTaskPhoto(
                            jobId: jobId,
                            taskId: taskId,
                            photoId: photo.id,
                          );
                      if (navigator.mounted && navigator.canPop()) {
                        navigator.pop();
                      }
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(
                            downloadPath == null
                                ? 'Fotoğraf indirilmeye başlandı.'
                                : 'Fotoğraf indirildi: $downloadPath',
                          ),
                        ),
                      );
                    } catch (e) {
                      if (navigator.mounted && navigator.canPop()) {
                        navigator.pop();
                      }
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(
                            'Fotoğraf indirilirken hata oluştu: $e',
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Kapat'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Dialog'u gösterir
  static void show(
    BuildContext context, {
    required TaskPhoto photo,
    required String jobId,
    required String taskId,
    bool showDownloadButton = true,
  }) {
    showDialog(
      context: context,
      builder: (context) => TaskPhotoDialog(
        photo: photo,
        jobId: jobId,
        taskId: taskId,
        showDownloadButton: showDownloadButton,
      ),
    );
  }
}
