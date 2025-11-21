import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/jobs_provider.dart';
import '../../../models/job_models.dart';
import '../../../../../core/widgets/error_state.dart';
import '../../../../../core/widgets/loading_indicator.dart';
import 'task_management/task_list.dart';

class JobTaskManagementScreen extends StatelessWidget {
  const JobTaskManagementScreen({super.key, required this.jobId});

  final String jobId;

  IconData _getVehicleStageIcon(String? stage) {
    switch (stage) {
      case 'insurance_approval_waiting':
        return Icons.verified_user_outlined;
      case 'expert_waiting':
        return Icons.person_search_outlined;
      case 'part_waiting':
        return Icons.inventory_2_outlined;
      default:
        return Icons.info_outline;
    }
  }

  Color _getVehicleStageColor(String? stage) {
    switch (stage) {
      case 'insurance_approval_waiting':
        return Colors.blue;
      case 'expert_waiting':
        return Colors.orange;
      case 'part_waiting':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _getVehicleStageLabel(String? stage) {
    switch (stage) {
      case 'insurance_approval_waiting':
        return 'Sigorta onayı bekleniyor olarak işaretlendi';
      case 'expert_waiting':
        return 'Eksper bekleniyor olarak işaretlendi';
      case 'part_waiting':
        return 'Parça bekleniyor olarak işaretlendi';
      default:
        return 'Araç aşaması kaldırıldı';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<JobsProvider>(
      builder: (context, provider, child) {
        final job = provider.jobById(jobId);

        // If job not found, try to load from API
        if (job == null) {
          // Trigger load if not already loading
          if (!provider.isLoading) {
            Future.microtask(() => provider.loadJobById(jobId));
          }

          return Scaffold(
            appBar: AppBar(title: const Text('Görev Yönetimi')),
            body: provider.isLoading
                ? const LoadingIndicator()
                : ErrorState(
                    message: provider.errorMessage ?? 'İş emri bulunamadı',
                    onRetry: () => provider.loadJobById(jobId),
                  ),
          );
        }

        // Duraklatılan görevler bekleyen görevler olarak gösterilir
        final pendingTasks = job.tasks
            .where(
              (task) =>
                  task.status == JobTaskStatus.pending ||
                  task.status == JobTaskStatus.paused,
            )
            .toList();
        final inProgressTasks = job.tasks
            .where((task) => task.status == JobTaskStatus.inProgress)
            .toList();
        final completedTasks = job.tasks
            .where((task) => task.status == JobTaskStatus.completed)
            .toList();

        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Görev Yönetimi'),
                Text(
                  '${job.vehicle.plate} - ${job.vehicle.brand} ${job.vehicle.model}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            actions: [
              // Araç aşaması seçim butonu
              PopupMenuButton<String>(
                tooltip: 'Araç Aşaması',
                icon: Icon(
                  _getVehicleStageIcon(job.vehicleStage),
                  color: _getVehicleStageColor(job.vehicleStage),
                ),
                onSelected: (String? value) async {
                  try {
                    await provider.updateJobVehicleStage(
                      jobId: jobId,
                      vehicleStage: value,
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(_getVehicleStageLabel(value)),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Hata: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                itemBuilder: (BuildContext context) => [
                  const PopupMenuItem<String>(
                    value: null,
                    child: Text('Aşama Yok'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'insurance_approval_waiting',
                    child: Text('Sigorta Onayı Bekleniyor'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'expert_waiting',
                    child: Text('Eksper Bekleniyor'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'part_waiting',
                    child: Text('Parça Bekleniyor'),
                  ),
                ],
              ),
              // Araç durumu güncelleme butonu
              IconButton(
                tooltip: job.isVehicleAvailable
                    ? 'Araç üzerinde çalışılamaz olarak işaretle'
                    : 'Araç üzerinde çalışılabilir olarak işaretle',
                icon: Icon(
                  job.isVehicleAvailable
                      ? Icons.check_circle_outline
                      : Icons.block_outlined,
                  color: job.isVehicleAvailable ? Colors.green : Colors.red,
                ),
                onPressed: () async {
                  final newStatus = !job.isVehicleAvailable;
                  try {
                    await provider.updateJobVehicleAvailability(
                      jobId: jobId,
                      isVehicleAvailable: newStatus,
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            newStatus
                                ? 'Araç üzerinde çalışılabilir olarak işaretlendi'
                                : 'Araç üzerinde çalışılamaz olarak işaretlendi',
                          ),
                          backgroundColor: newStatus
                              ? Colors.green
                              : Colors.orange,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Hata: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
              ),
            ],
          ),
          body: DefaultTabController(
            length: 3,
            child: Column(
              children: [
                // Araç aşaması bilgisi
                if (job.vehicleStage != null && job.vehicleStage != 'none')
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getVehicleStageColor(
                        job.vehicleStage,
                      ).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _getVehicleStageColor(job.vehicleStage),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _getVehicleStageIcon(job.vehicleStage),
                          color: _getVehicleStageColor(job.vehicleStage),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _getVehicleStageLabel(job.vehicleStage),
                            style: TextStyle(
                              color: _getVehicleStageColor(job.vehicleStage),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                TabBar(
                  tabs: [
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Beklemede'),
                          if (pendingTasks.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${pendingTasks.length}',
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onPrimary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Devam Ediyor'),
                          if (inProgressTasks.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${inProgressTasks.length}',
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onPrimary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Tamamlandı'),
                          if (completedTasks.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${completedTasks.length}',
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onPrimary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      TaskList(
                        tasks: pendingTasks,
                        jobId: jobId,
                        emptyMessage: 'Bekleyen görev bulunmuyor',
                      ),
                      TaskList(
                        tasks: inProgressTasks,
                        jobId: jobId,
                        emptyMessage: 'Devam eden görev bulunmuyor',
                      ),
                      TaskList(
                        tasks: completedTasks,
                        jobId: jobId,
                        emptyMessage: 'Tamamlanan görev bulunmuyor',
                        isCompleted: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Eski widget'lar kaldırıldı - artık job_orders/task_management/ klasöründeki widget'lar kullanılıyor
