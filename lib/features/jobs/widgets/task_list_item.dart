/// Task List Item Widget
///
/// Görev listesi item widget'ı. Görev bilgilerini gösterir.
/// Job order detail ve task management ekranlarında kullanılır.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/job_models.dart';
import '../models/vehicle_area.dart';
import '../providers/jobs_provider.dart';
import 'task_status_chip.dart';
import 'task_photos_list.dart';
import 'task_photo_dialog.dart';
import '../../../../core/widgets/error_snackbar.dart';
import '../../../../core/widgets/loading_snackbar.dart';
import '../presentation/screens/job_orders/task_management/complete_task_dialog.dart';
import '../presentation/widgets/worker_select_dialog.dart';

/// Task list item widget'ı
///
/// Görev bilgilerini gösterir. Icon, area, operation type, status ve fotoğraflar ile.
class TaskListItem extends StatelessWidget {
  const TaskListItem({
    super.key,
    required this.task,
    required this.jobId,
    this.onTap,
    this.onPhotoTap,
    this.showPhotos = true,
    this.showDownloadButton = true,
    this.showDetailedDialog = true,
    this.showActionButtons = false,
    this.assignedWorkerId,
  });

  /// Görev
  final JobTask task;

  /// İş emri ID'si
  final String jobId;

  /// Tıklama callback'i (opsiyonel)
  final VoidCallback? onTap;

  /// Fotoğraf tıklama callback'i (opsiyonel)
  final void Function(TaskPhoto)? onPhotoTap;

  /// Fotoğrafları göster? (varsayılan: true)
  final bool showPhotos;

  /// Download butonu göster? (varsayılan: true)
  final bool showDownloadButton;

  /// Detaylı dialog göster? (varsayılan: true)
  /// false ise sadece fotoğraf gösterilir, bilgiler gösterilmez
  final bool showDetailedDialog;

  /// Başlatma/durdurma butonları göster? (varsayılan: false)
  final bool showActionButtons;

  /// Kiosk modunda kullanılacak personel ID'si (opsiyonel)
  /// Eğer verilirse, görev başlatırken personel seçim dialog'u açılmaz
  final String? assignedWorkerId;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    Widget content = Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Operation type icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: task.operationType == JobOperationType.paint
                      ? scheme.primaryContainer
                      : task.operationType == JobOperationType.bodyRepair
                      ? scheme.tertiaryContainer
                      : scheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  task.operationType.icon,
                  size: 20,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 12),
              // Task info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.area.label,
                      style: textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      task.operationType.label,
                      style: textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    if (task.assignedWorkerId != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.person_outline,
                            size: 12,
                            color: scheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            task.assignedWorkerName ??
                                'Personel ID: ${task.assignedWorkerId}',
                            style: textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                    // Durum bilgileri
                    Builder(
                      builder: (context) {
                        final provider = context.read<JobsProvider>();
                        final job = provider.jobById(jobId);
                        final hasBlockingReason = task.blockingReason != null;
                        final isVehicleUnavailable =
                            job != null && !job.isVehicleAvailable;

                        if (!hasBlockingReason && !isVehicleUnavailable) {
                          return const SizedBox.shrink();
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            if (hasBlockingReason)
                              Row(
                                children: [
                                  Icon(
                                    task.blockingReason!.icon,
                                    size: 12,
                                    color: Colors.orange,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    task.blockingReason!.label,
                                    style: textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.orange.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            if (hasBlockingReason && isVehicleUnavailable)
                              const SizedBox(height: 2),
                            if (isVehicleUnavailable)
                              Row(
                                children: [
                                  Icon(
                                    Icons.block_outlined,
                                    size: 12,
                                    color: Colors.red,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Araç üzerinde çalışılamaz',
                                    style: textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.red.shade700,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        );
                      },
                    ),
                    if (task.note != null && task.note!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        task.note!,
                        style: textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Status badge
              TaskStatusChip(status: task.status),
            ],
          ),
          // Başlangıç ve bitiş zamanları
          if (task.startedAt != null || task.completedAt != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                if (task.startedAt != null) ...[
                  Icon(
                    Icons.play_circle_outline,
                    size: 14,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Başlangıç: ${DateFormat('dd.MM.yyyy HH:mm').format(task.startedAt!)}',
                    style: textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
                if (task.startedAt != null && task.completedAt != null)
                  const SizedBox(width: 12),
                if (task.completedAt != null) ...[
                  Icon(
                    Icons.check_circle_outline,
                    size: 14,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Bitiş: ${DateFormat('dd.MM.yyyy HH:mm').format(task.completedAt!)}',
                    style: textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ],
          // Atanan personel bilgisi
          if (task.assignedWorkerId != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.person_outline,
                  size: 14,
                  color: scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  'Personel ID: ${task.assignedWorkerId}',
                  style: textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
          // Action buttons
          if (showActionButtons && task.status != JobTaskStatus.completed) ...[
            const SizedBox(height: 12),
            Builder(
              builder: (context) {
                final provider = context.read<JobsProvider>();
                final job = provider.jobById(jobId);
                final canStart = job?.isVehicleAvailable ?? true;

                return Row(
                  children: [
                    if (task.status == JobTaskStatus.pending)
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: canStart
                              ? () => _startTask(context)
                              : null,
                          icon: const Icon(Icons.play_arrow, size: 18),
                          label: const Text('Başlat'),
                        ),
                      )
                    else if (task.status == JobTaskStatus.inProgress)
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => _completeTask(context),
                          icon: const Icon(Icons.check, size: 18),
                          label: const Text('Tamamla'),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                        ),
                      )
                    else if (task.status == JobTaskStatus.paused)
                      // Duraklatılan görev bekleyen görev olarak gösterilir, tekrar başlatılabilir
                      Expanded(
                        child: Builder(
                          builder: (context) {
                            final canStart = job?.isVehicleAvailable ?? true;
                            return FilledButton.icon(
                              onPressed: canStart
                                  ? () => _resumeTask(context)
                                  : null,
                              icon: const Icon(Icons.play_arrow, size: 18),
                              label: const Text('Başlat'),
                            );
                          },
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
          // Photos section
          if (showPhotos && task.photos.isNotEmpty) ...[
            const SizedBox(height: 12),
            TaskPhotosList(
              photos: task.photos,
              jobId: jobId,
              taskId: task.id,
              showDownloadButton: showDownloadButton,
              onPhotoTap:
                  onPhotoTap ??
                  (showDetailedDialog
                      ? (photo) => TaskPhotoDialog.show(
                          context,
                          photo: photo,
                          jobId: jobId,
                          taskId: task.id,
                          showDownloadButton: showDownloadButton,
                        )
                      : null),
            ),
          ],
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: content,
      );
    }

    return content;
  }

  Future<void> _startTask(BuildContext context) async {
    String? workerId = assignedWorkerId;

    // Eğer kiosk modunda değilse (assignedWorkerId yoksa), personel seçim dialog'unu aç
    if (workerId == null) {
      // Kiosk modunda olup olmadığını kontrol et
      final isKioskMode =
          ModalRoute.of(context)?.settings.name?.startsWith('/kiosk') ?? false;
      final selectedWorker = await WorkerSelectDialog.show(
        context,
        kioskMode: isKioskMode,
      );

      // Kullanıcı iptal ettiyse çık
      if (selectedWorker == null || !context.mounted) return;

      workerId = selectedWorker.id;
    }

    final provider = context.read<JobsProvider>();
    try {
      LoadingSnackbar.show(context, message: 'Görev başlatılıyor...');
      await provider.startTask(
        jobId: jobId,
        taskId: task.id,
        assignedWorkerId: workerId,
      );
      if (context.mounted) {
        LoadingSnackbar.hide(context);
        ErrorSnackbar.showSuccess(
          context,
          assignedWorkerId == null ? 'Görev başlatıldı' : 'Görev başlatıldı',
        );
      }
    } catch (e) {
      if (context.mounted) {
        LoadingSnackbar.hide(context);
        ErrorSnackbar.showError(context, 'Görev başlatılırken hata: $e');
      }
    }
  }

  Future<void> _completeTask(BuildContext context) async {
    final provider = context.read<JobsProvider>();
    final result = await showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (context) => CompleteTaskDialog(task: task),
    );
    if (result != null && context.mounted) {
      try {
        LoadingSnackbar.show(context, message: 'Görev tamamlanıyor...');
        await provider.completeTask(
          jobId: jobId,
          taskId: task.id,
          note: result['note'] as String?,
          completionPhotoPath: result['photoPath'] as String?,
        );
        if (context.mounted) {
          LoadingSnackbar.hide(context);
          ErrorSnackbar.showSuccess(context, 'Görev tamamlandı');
        }
      } catch (e) {
        if (context.mounted) {
          LoadingSnackbar.hide(context);
          ErrorSnackbar.showError(context, 'Görev tamamlanırken hata: $e');
        }
      }
    }
  }

  Future<void> _resumeTask(BuildContext context) async {
    final provider = context.read<JobsProvider>();
    final workerId = await WorkerSelectDialog.show(context, kioskMode: false);

    if (workerId == null || !context.mounted) return;

    try {
      LoadingSnackbar.show(context, message: 'Görev devam ettiriliyor...');
      await provider.resumeTask(
        jobId: jobId,
        taskId: task.id,
        assignedWorkerId: workerId.id,
      );
      if (context.mounted) {
        LoadingSnackbar.hide(context);
        ErrorSnackbar.showSuccess(context, 'Görev devam ettirildi');
      }
    } catch (e) {
      if (context.mounted) {
        LoadingSnackbar.hide(context);
        ErrorSnackbar.showError(context, 'Görev devam ettirilirken hata: $e');
      }
    }
  }
}
