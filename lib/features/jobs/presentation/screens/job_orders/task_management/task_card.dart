/// Task Card Widget
///
/// Görev kartı widget'ı.

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../../providers/jobs_provider.dart';
import '../../../../models/job_models.dart';
import '../../../../models/vehicle_area.dart';
import '../../../../../../core/widgets/error_snackbar.dart';
import '../../../../../../core/widgets/photo_picker_dialog.dart';
import '../../../../../../core/widgets/loading_snackbar.dart';
import '../../../../widgets/task_photos_list.dart';
import '../../../../widgets/task_photo_dialog.dart';
import '../../../../presentation/widgets/worker_select_dialog.dart';
import 'add_photo_dialog.dart';
import 'complete_task_dialog.dart';
import 'pause_task_dialog.dart';
import 'update_task_status_dialog.dart';

/// Task card widget'ı
///
/// Görev bilgilerini ve aksiyonları gösterir.
class TaskCard extends StatelessWidget {
  const TaskCard({
    super.key,
    required this.task,
    required this.jobId,
    this.isCompleted = false,
  });

  final JobTask task;
  final String jobId;
  final bool isCompleted;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final provider = context.read<JobsProvider>();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: task.operationType.category == TaskCategory.boya
                        ? scheme.primaryContainer
                        : task.operationType.category == TaskCategory.kaporta
                        ? scheme.tertiaryContainer
                        : scheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    task.operationType.icon,
                    size: 24,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.area.label,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        task.operationType.label,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      if (task.assignedWorkerId != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.person_outline,
                              size: 14,
                              color: scheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              task.assignedWorkerName ??
                                  'Personel ID: ${task.assignedWorkerId}',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: scheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: task.status.toColor(context),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    task.status.label,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: task.status.onColor(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            // Durum bilgileri
            Builder(
              builder: (context) {
                final job = provider.jobById(jobId);
                final hasBlockingReason = task.blockingReason != null;
                final isVehicleUnavailable =
                    job != null && !job.isVehicleAvailable;
                final isTaskUnavailable = !task.isTaskAvailable;

                if (!hasBlockingReason &&
                    !isVehicleUnavailable &&
                    !isTaskUnavailable) {
                  return const SizedBox.shrink();
                }

                return Column(
                  children: [
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: scheme.outlineVariant,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (hasBlockingReason) ...[
                            Row(
                              children: [
                                Icon(
                                  task.blockingReason!.icon,
                                  size: 18,
                                  color: Colors.orange,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  task.blockingReason!.label,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.orange.shade700,
                                      ),
                                ),
                              ],
                            ),
                            if (isVehicleUnavailable || isTaskUnavailable)
                              const SizedBox(height: 8),
                          ],
                          if (isVehicleUnavailable)
                            Row(
                              children: [
                                Icon(
                                  Icons.block_outlined,
                                  size: 18,
                                  color: Colors.red,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Araç üzerinde çalışılamaz',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.red.shade700,
                                      ),
                                ),
                              ],
                            ),
                          if (isTaskUnavailable) ...[
                            if (isVehicleUnavailable) const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.block_outlined,
                                  size: 18,
                                  color: Colors.red,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Görev üzerinde çalışılamaz',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.red.shade700,
                                      ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
            if (task.note != null && task.note!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.note_outlined,
                      size: 18,
                      color: scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        task.note!,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (task.startedAt != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.play_circle_outline,
                    size: 16,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Başlangıç: ${DateFormat('dd.MM.yyyy HH:mm').format(task.startedAt!)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
            if (task.completedAt != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 16,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Tamamlanma: ${DateFormat('dd.MM.yyyy HH:mm').format(task.completedAt!)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
            // Çalışanlar ve süreler
            if (task.workSessions.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: scheme.outlineVariant, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 18,
                          color: scheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Çalışanlar',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        Text(
                          'Toplam: ${task.totalWorkHours.toStringAsFixed(2)} saat',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: scheme.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...task.workerHours.entries.map((entry) {
                      final workerName = entry.key;
                      final hours = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Icon(
                              Icons.person_outline,
                              size: 14,
                              color: scheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                workerName,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                            Text(
                              '${hours.toStringAsFixed(2)} saat',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w500,
                                    color: scheme.primary,
                                  ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
            if (task.photos.isNotEmpty) ...[
              const SizedBox(height: 12),
              TaskPhotosList(
                photos: task.photos,
                jobId: jobId,
                taskId: task.id,
                showDownloadButton: false,
                height: 100,
                thumbnailSize: 100,
                onPhotoTap: (photo) => TaskPhotoDialog.show(
                  context,
                  photo: photo,
                  jobId: jobId,
                  taskId: task.id,
                  showDownloadButton: false,
                ),
              ),
            ],
            if (!isCompleted) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Durum güncelle butonu
                  OutlinedButton.icon(
                    onPressed: () async {
                      final result = await showDialog<Map<String, dynamic>?>(
                        context: context,
                        builder: (context) =>
                            UpdateTaskStatusDialog(task: task),
                      );
                      if (result != null && context.mounted) {
                        try {
                          LoadingSnackbar.show(
                            context,
                            message: 'Görev durumu güncelleniyor...',
                          );
                          await provider.updateTask(
                            jobId: jobId,
                            taskId: task.id,
                            blockingReason:
                                result['blockingReason'] as TaskBlockingReason?,
                            isTaskAvailable: result['isTaskAvailable'] as bool?,
                          );
                          if (context.mounted) {
                            LoadingSnackbar.hide(context);
                            ErrorSnackbar.showSuccess(
                              context,
                              'Görev durumu güncellendi',
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            LoadingSnackbar.hide(context);
                            ErrorSnackbar.showError(
                              context,
                              'Görev durumu güncellenirken hata: $e',
                            );
                          }
                        }
                      }
                    },
                    icon: const Icon(Icons.info_outline),
                    label: const Text('Durum'),
                  ),
                  const SizedBox(width: 8),
                  // Fotoğraf ekle butonu
                  OutlinedButton.icon(
                    onPressed: () async {
                      final result = await showDialog<TaskPhotoType?>(
                        context: context,
                        builder: (context) => const AddPhotoDialog(),
                      );
                      if (result != null && context.mounted) {
                        // Show source selection dialog
                        final source = await showPhotoPickerDialog(context);

                        if (source == null || !context.mounted) return;

                        final imagePicker = ImagePicker();
                        try {
                          final XFile? image = await imagePicker.pickImage(
                            source: source,
                            imageQuality: 85,
                            maxWidth: 1920,
                            maxHeight: 1920,
                          );

                          if (image != null && context.mounted) {
                            // Show loading
                            LoadingSnackbar.show(
                              context,
                              message: 'Fotoğraf yükleniyor...',
                            );

                            await provider.addDamagePhoto(
                              jobId: jobId,
                              taskId: task.id,
                              photoPath: image.path,
                              type: result,
                            );

                            if (context.mounted) {
                              LoadingSnackbar.hide(context);
                              ErrorSnackbar.showSuccess(
                                context,
                                'Fotoğraf başarıyla eklendi',
                              );
                            }
                          }
                        } catch (e) {
                          if (context.mounted) {
                            LoadingSnackbar.hide(context);
                            ErrorSnackbar.showError(
                              context,
                              'Fotoğraf eklenirken hata: ${e.toString()}',
                            );
                          }
                        }
                      }
                    },
                    icon: const Icon(Icons.add_photo_alternate),
                    label: const Text('Fotoğraf Ekle'),
                  ),
                  // Durum butonları
                  Row(
                    children: [
                      if (task.status == JobTaskStatus.pending)
                        Builder(
                          builder: (context) {
                            final job = provider.jobById(jobId);
                            final canStart =
                                (job?.isVehicleAvailable ?? true) &&
                                task.isTaskAvailable;

                            return FilledButton.icon(
                              onPressed: canStart
                                  ? () async {
                                      // Usta seçim dialogunu aç
                                      final selectedWorker =
                                          await WorkerSelectDialog.show(
                                            context,
                                            kioskMode:
                                                false, // Normal mod, token gerektirir
                                          );

                                      // Kullanıcı iptal ettiyse çık
                                      if (selectedWorker == null ||
                                          !context.mounted)
                                        return;

                                      try {
                                        LoadingSnackbar.show(
                                          context,
                                          message: 'Görev başlatılıyor...',
                                        );
                                        await provider.startTask(
                                          jobId: jobId,
                                          taskId: task.id,
                                          assignedWorkerId: selectedWorker.id,
                                        );
                                        if (context.mounted) {
                                          LoadingSnackbar.hide(context);
                                          ErrorSnackbar.showSuccess(
                                            context,
                                            'Görev başlatıldı',
                                          );
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          LoadingSnackbar.hide(context);
                                          ErrorSnackbar.showError(
                                            context,
                                            'Görev başlatılırken hata: $e',
                                          );
                                        }
                                      }
                                    }
                                  : null,
                              icon: const Icon(Icons.play_arrow),
                              label: const Text('Başlat'),
                            );
                          },
                        )
                      else if (task.status == JobTaskStatus.inProgress) ...[
                        FilledButton.icon(
                          onPressed: () async {
                            final note = await showDialog<String?>(
                              context: context,
                              builder: (context) => PauseTaskDialog(task: task),
                            );
                            if (context.mounted) {
                              try {
                                LoadingSnackbar.show(
                                  context,
                                  message: 'Görev duraklatılıyor...',
                                );
                                await provider.pauseTask(
                                  jobId: jobId,
                                  taskId: task.id,
                                  note: note,
                                );
                                if (context.mounted) {
                                  LoadingSnackbar.hide(context);
                                  ErrorSnackbar.showSuccess(
                                    context,
                                    'Görev duraklatıldı',
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  LoadingSnackbar.hide(context);
                                  ErrorSnackbar.showError(
                                    context,
                                    'Görev duraklatılırken hata: $e',
                                  );
                                }
                              }
                            }
                          },
                          icon: const Icon(Icons.pause),
                          label: const Text('Duraklat'),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton.icon(
                          onPressed: () async {
                            final result =
                                await showDialog<Map<String, dynamic>?>(
                                  context: context,
                                  builder: (context) =>
                                      CompleteTaskDialog(task: task),
                                );
                            if (result != null && context.mounted) {
                              await provider.completeTask(
                                jobId: jobId,
                                taskId: task.id,
                                note: result['note'] as String?,
                                completionPhotoPath:
                                    result['photoPath'] as String?,
                              );
                              if (context.mounted) {
                                ErrorSnackbar.showSuccess(
                                  context,
                                  'Görev tamamlandı',
                                );
                              }
                            }
                          },
                          icon: const Icon(Icons.check),
                          label: const Text('Tamamla'),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                        ),
                      ] else if (task.status == JobTaskStatus.paused)
                        // Duraklatılan görev bekleyen görev olarak gösterilir, tekrar başlatılabilir
                        Builder(
                          builder: (context) {
                            final job = provider.jobById(jobId);
                            final canStart =
                                (job?.isVehicleAvailable ?? true) &&
                                task.isTaskAvailable;

                            return FilledButton.icon(
                              onPressed: canStart
                                  ? () async {
                                      // Usta seçim dialogunu aç
                                      final selectedWorker =
                                          await WorkerSelectDialog.show(
                                            context,
                                            kioskMode: false,
                                          );

                                      // Kullanıcı iptal ettiyse çık
                                      if (selectedWorker == null ||
                                          !context.mounted)
                                        return;

                                      try {
                                        LoadingSnackbar.show(
                                          context,
                                          message: 'Görev başlatılıyor...',
                                        );
                                        // Duraklatılan görev resume ile başlatılır (workSessions korunur)
                                        await provider.resumeTask(
                                          jobId: jobId,
                                          taskId: task.id,
                                          assignedWorkerId: selectedWorker.id,
                                        );
                                        if (context.mounted) {
                                          LoadingSnackbar.hide(context);
                                          ErrorSnackbar.showSuccess(
                                            context,
                                            'Görev başlatıldı',
                                          );
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          LoadingSnackbar.hide(context);
                                          ErrorSnackbar.showError(
                                            context,
                                            'Görev başlatılırken hata: $e',
                                          );
                                        }
                                      }
                                    }
                                  : null,
                              icon: const Icon(Icons.play_arrow),
                              label: const Text('Başlat'),
                            );
                          },
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
