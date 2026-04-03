/// Müsait Görevler Ekranı
///
/// Personelin henüz atanmamış görevleri görmesini ve almasını sağlar.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'dart:typed_data';

import '../../../providers/jobs_provider.dart';
import '../../../models/job_models.dart';
import '../../../../../core/widgets/error_state.dart';
import '../../../../../core/widgets/loading_indicator.dart';
import '../../../../../core/widgets/error_snackbar.dart';
import '../../../../../core/widgets/loading_snackbar.dart';
import '../../../models/vehicle_area.dart';
import '../../../utils/vehicle_part_mapper.dart';
import '../../../utils/svg_vehicle_part_loader.dart';
import '../../../utils/damage_map_image_generator.dart';
import 'package:vehicle_damage_map/vehicle_damage_map.dart'
    show PartSupplyStatus;

class AvailableTasksScreen extends StatefulWidget {
  const AvailableTasksScreen({super.key});

  @override
  State<AvailableTasksScreen> createState() => _AvailableTasksScreenState();
}

/// Not içindeki `- [ ]` / `- [x]` satırlarını pasif checklist olarak gösterir.
class _ChecklistNotePreview extends StatelessWidget {
  const _ChecklistNotePreview({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lines = text.split('\n');

    final children = <Widget>[];
    for (final line in lines) {
      final trimmed = line.trimLeft();
      final match = RegExp(r'^-\s*\[( |x|X)\]\s*(.*)$').firstMatch(trimmed);
      if (match != null) {
        final checked = match.group(1)!.toLowerCase() == 'x';
        final label = match.group(2) ?? '';
        children.add(
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: checked,
                onChanged: null, // sadece görüntüleme
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        );
      } else if (line.isNotEmpty) {
        children.add(
          Text(
            line,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        );
      }
    }

    // Eğer checklist bulunmadıysa metni olduğu gibi göster
    if (children.isEmpty) {
      return Text(
        text,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }
}

class _AvailableTasksScreenState extends State<AvailableTasksScreen> {
  bool _hasUndeliveredParts(JobTask task) {
    if (task.spareParts.isEmpty) return false;
    return task.spareParts.any(
      (part) =>
          part.status != PartSupplyStatus.geldi &&
          part.status != PartSupplyStatus.takildi,
    );
  }

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final provider = context.read<JobsProvider>();
    await provider.loadAvailableTasks();
  }

  Future<void> _assignTask(String jobId, String taskId) async {
    final provider = context.read<JobsProvider>();

    // Check if we're in kiosk mode (no user logged in, token-based)
    final isKioskMode =
        ModalRoute.of(context)?.settings.name?.startsWith('/kiosk') ?? false;

    try {
      LoadingSnackbar.show(context, message: 'Görev alınıyor...');

      if (isKioskMode) {
        // In kiosk mode, auto-select a worker
        final workers = await _getAvailableWorkers();
        if (workers.isEmpty) {
          if (mounted) {
            LoadingSnackbar.hide(context);
            ErrorSnackbar.showError(context, 'Usta bulunamadı');
          }
          return;
        }

        // Select the first available worker
        final selectedWorker = workers.first;
        await provider.startTask(
          jobId: jobId,
          taskId: taskId,
          assignedWorkerId: selectedWorker['id'] as String,
        );
      } else {
        // In normal mode, use the old assignTask method
        await provider.assignTask(jobId: jobId, taskId: taskId);
      }

      if (mounted) {
        LoadingSnackbar.hide(context);
        ErrorSnackbar.showSuccess(context, 'Görev başarıyla alındı');
        _loadTasks(); // Refresh the list
      }
    } catch (e) {
      if (mounted) {
        LoadingSnackbar.hide(context);
        ErrorSnackbar.showError(context, 'Görev alınırken hata: $e');
      }
    }
  }

  Future<List<Map<String, dynamic>>> _getAvailableWorkers() async {
    try {
      final provider = context.read<JobsProvider>();
      // This will call the new API endpoint
      final response = await provider.getAvailableWorkers();
      return response;
    } catch (e) {
      debugPrint('Usta listesi alınırken hata: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<JobsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Müsait Görevler'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTasks,
            tooltip: 'Yenile',
          ),
        ],
      ),
      body: provider.isLoading
          ? const LoadingIndicator()
          : provider.errorMessage != null
          ? ErrorState(message: provider.errorMessage!, onRetry: _loadTasks)
          : RefreshIndicator(
              onRefresh: _loadTasks,
              child: _buildTasksList(provider),
            ),
    );
  }

  Widget _buildTasksList(JobsProvider provider) {
    final jobs = provider.availableTasks;

    if (jobs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.task_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Müsait görev bulunamadı',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tüm görevler atanmış veya tamamlanmış',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: jobs.length,
      itemBuilder: (context, index) {
        final job = jobs[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ExpansionTile(
            leading: Icon(
              Icons.directions_car,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: Text(
              '${job.vehicle.plate} - ${job.vehicle.brand} ${job.vehicle.model}',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${job.tasks.length} müsait görev',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            trailing: _buildDamageMapThumbnail(job),
            children: job.tasks.map((task) {
              final hasUndeliveredParts = _hasUndeliveredParts(task);
              return ListTile(
                leading: Icon(
                  Icons.task_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: Text(
                  '${task.area.label} - ${task.operationType.label}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (task.note != null && task.note!.isNotEmpty)
                      _ChecklistNotePreview(text: task.note!),
                    if (hasUndeliveredParts)
                      Text(
                        'Parça teslimi tamamlanmadan görev alınamaz',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
                trailing: FilledButton.icon(
                  onPressed: hasUndeliveredParts
                      ? null
                      : () => _assignTask(job.id, task.id),
                  icon: const Icon(Icons.add_task, size: 18),
                  label: const Text('Al'),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  /// Hasar haritası thumbnail widget'ı oluşturur
  Widget _buildDamageMapThumbnail(JobOrder job) {
    return FutureBuilder<Uint8List?>(
      future: _generateDamageMapThumbnail(job),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            width: 80,
            height: 60,
            child: Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          return const SizedBox(width: 80, height: 60);
        }

        return Container(
          width: 80,
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(snapshot.data!, fit: BoxFit.cover),
          ),
        );
      },
    );
  }

  /// Hasar haritası thumbnail görseli oluşturur
  Future<Uint8List?> _generateDamageMapThumbnail(JobOrder job) async {
    try {
      // Vehicle parts yükle
      final parts = await SvgVehiclePartLoader.instance.load();
      if (parts.isEmpty) return null;

      // Tasks'ı selections'a dönüştür
      final selections = VehiclePartMapper.tasksToSelections(job.tasks);
      if (selections.isEmpty) return null;

      // Küçük thumbnail görseli oluştur
      return await DamageMapImageGenerator.instance.generateDamageMapImage(
        parts: parts,
        selections: selections,
        size: const Size(160, 120), // 2x thumbnail size for better quality
      );
    } catch (e) {
      debugPrint('Hasar haritası thumbnail oluşturma hatası: $e');
      return null;
    }
  }
}
