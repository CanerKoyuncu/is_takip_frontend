import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../providers/jobs_provider.dart';
import '../../../models/job_models.dart';
import '../../../../auth/providers/auth_provider.dart';
import '../../../models/vehicle_area.dart';
import '../../../utils/duration_formatter.dart';
import '../../../utils/vehicle_part_mapper.dart';
import '../../../services/pdf/pdf_job_order_service.dart';
import '../../../../../core/widgets/error_state.dart';
import '../../../../../core/widgets/loading_indicator.dart';
import 'package:vehicle_damage_map/vehicle_damage_map.dart';
import '../../../widgets/task_list_item.dart';
import '../../../../../core/widgets/error_snackbar.dart';

class JobOrderDetailScreen extends StatefulWidget {
  const JobOrderDetailScreen({super.key, required this.jobId});

  final String jobId;

  @override
  State<JobOrderDetailScreen> createState() => _JobOrderDetailScreenState();
}

class _JobOrderDetailScreenState extends State<JobOrderDetailScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      final provider = context.read<JobsProvider>();
      provider.ensureJobNotesLoaded(widget.jobId);
    });
  }

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
        return 'Sigorta Onayı Bekleniyor';
      case 'expert_waiting':
        return 'Eksper Bekleniyor';
      case 'part_waiting':
        return 'Parça Bekleniyor';
      default:
        return 'Aşama Yok';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<JobsProvider>(
      builder: (context, provider, child) {
        final jobsProvider = provider;
        final job = jobsProvider.jobById(widget.jobId);

        // If job not found, try to load from API
        if (job == null) {
          // Trigger load if not already loading
          if (!jobsProvider.isLoading) {
            Future.microtask(() => jobsProvider.loadJobById(widget.jobId));
          }

          return Scaffold(
            appBar: AppBar(title: const Text('İş Emri Detayı')),
            body: jobsProvider.isLoading
                ? const LoadingIndicator()
                : ErrorState(
                    message: jobsProvider.errorMessage ?? 'İş emri bulunamadı',
                    onRetry: () => jobsProvider.loadJobById(widget.jobId),
                  ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  job.vehicle.plate,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${job.vehicle.brand} ${job.vehicle.model}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.picture_as_pdf_outlined),
                tooltip: 'PDF Önizleme ve Paylaş',
                onPressed: () async {
                  try {
                    await JobOrderPdfService.instance.previewAndShare(
                      job,
                      context: context,
                    );
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('PDF oluşturulurken hata: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.download_outlined),
                tooltip: 'Tüm Fotoğrafları İndir (ZIP)',
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  try {
                    final downloadPath = await jobsProvider
                        .downloadJobPhotosZip(jobId: widget.jobId);
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          downloadPath == null
                              ? 'Fotoğraflar indirilmeye başlandı.'
                              : 'Fotoğraflar indirildi: $downloadPath',
                        ),
                      ),
                    );
                  } catch (e) {
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          'Fotoğraflar indirilirken hata oluştu: $e',
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
              ),
              // Araç aşaması seçim butonu (supervisor ve üzeri)
              if (context.watch<AuthProvider>().isPanelUser)
                PopupMenuButton<String>(
                  tooltip: 'Araç Aşaması',
                  icon: Icon(
                    _getVehicleStageIcon(job.vehicleStage),
                    color: _getVehicleStageColor(job.vehicleStage),
                  ),
                  onSelected: (String? value) async {
                    try {
                      await provider.updateJobVehicleStage(
                        jobId: widget.jobId,
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
              // Sadece admin'ler görebilir
              if (context.watch<AuthProvider>().isAdmin) ...[
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  tooltip: 'Veri Ekle',
                  onPressed: () {
                    context.push(
                      '/dashboard/job-orders/${widget.jobId}/add-data',
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.assignment_outlined),
                  tooltip: 'Görev Yönetimi',
                  onPressed: () {
                    context.push('/dashboard/job-orders/${widget.jobId}/tasks');
                  },
                ),
              ],
            ],
          ),
          body: ListView(
            key: PageStorageKey('job-order-detail-${job.id}'),
            padding: const EdgeInsets.all(16),
            children: [
              // Status Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // İş Emri Durumu ve Görev Sayısı
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Durum',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.labelMedium,
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: job.status.toColor(context),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    job.status.label,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          color: job.status.onColor(context),
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Görevler',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.labelMedium,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${job.tasks.length} görev',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 32),
                      // Araç Aşaması
                      InkWell(
                        onTap: context.watch<AuthProvider>().isPanelUser
                            ? () async {
                                // Aşama seçim dialogu göster
                                final selectedStage = await showDialog<String>(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: const Text('Araç Aşaması Seç'),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          ListTile(
                                            title: const Text('Aşama Yok'),
                                            leading: Radio<String?>(
                                              value: null,
                                              groupValue: job.vehicleStage,
                                              onChanged: (String? value) {
                                                Navigator.of(
                                                  context,
                                                ).pop(value);
                                              },
                                            ),
                                          ),
                                          ListTile(
                                            title: const Text(
                                              'Sigorta Onayı Bekleniyor',
                                            ),
                                            leading: Radio<String?>(
                                              value:
                                                  'insurance_approval_waiting',
                                              groupValue: job.vehicleStage,
                                              onChanged: (String? value) {
                                                Navigator.of(
                                                  context,
                                                ).pop(value);
                                              },
                                            ),
                                          ),
                                          ListTile(
                                            title: const Text(
                                              'Eksper Bekleniyor',
                                            ),
                                            leading: Radio<String?>(
                                              value: 'expert_waiting',
                                              groupValue: job.vehicleStage,
                                              onChanged: (String? value) {
                                                Navigator.of(
                                                  context,
                                                ).pop(value);
                                              },
                                            ),
                                          ),
                                          ListTile(
                                            title: const Text(
                                              'Parça Bekleniyor',
                                            ),
                                            leading: Radio<String?>(
                                              value: 'part_waiting',
                                              groupValue: job.vehicleStage,
                                              onChanged: (String? value) {
                                                Navigator.of(
                                                  context,
                                                ).pop(value);
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                          child: const Text('İptal'),
                                        ),
                                      ],
                                    );
                                  },
                                );

                                if (context.mounted) {
                                  try {
                                    await provider.updateJobVehicleStage(
                                      jobId: widget.jobId,
                                      vehicleStage: selectedStage,
                                    );
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            _getVehicleStageLabel(
                                              selectedStage,
                                            ),
                                          ),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text('Hata: $e'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                }
                              }
                            : null,
                        child: Row(
                          children: [
                            Icon(
                              _getVehicleStageIcon(job.vehicleStage),
                              color:
                                  (job.vehicleStage != null &&
                                      job.vehicleStage != 'none')
                                  ? _getVehicleStageColor(job.vehicleStage)
                                  : Colors.grey,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Araç Aşaması',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.labelMedium,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    (job.vehicleStage != null &&
                                            job.vehicleStage != 'none')
                                        ? _getVehicleStageLabel(
                                            job.vehicleStage,
                                          )
                                        : 'Aşama Yok',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color:
                                              (job.vehicleStage != null &&
                                                  job.vehicleStage != 'none')
                                              ? _getVehicleStageColor(
                                                  job.vehicleStage,
                                                )
                                              : Colors.grey,
                                          fontWeight: FontWeight.w500,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            if (context.watch<AuthProvider>().isPanelUser)
                              Icon(
                                Icons.edit_outlined,
                                size: 18,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Araç Durumu (tıklanabilir - düzenlenebilir)
                      InkWell(
                        onTap: context.watch<AuthProvider>().isPanelUser
                            ? () async {
                                final newStatus = !job.isVehicleAvailable;
                                try {
                                  await provider.updateJobVehicleAvailability(
                                    jobId: widget.jobId,
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
                              }
                            : null,
                        child: Row(
                          children: [
                            Icon(
                              job.isVehicleAvailable
                                  ? Icons.check_circle_outline
                                  : Icons.block_outlined,
                              color: job.isVehicleAvailable
                                  ? Colors.green
                                  : Colors.red,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Araç Durumu',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.labelMedium,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    job.isVehicleAvailable
                                        ? 'Araç üzerinde çalışılabilir'
                                        : 'Araç üzerinde çalışılamaz',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: job.isVehicleAvailable
                                              ? Colors.green
                                              : Colors.red,
                                          fontWeight: FontWeight.w500,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            if (context.watch<AuthProvider>().isPanelUser)
                              Icon(
                                Icons.edit_outlined,
                                size: 18,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Required Parts Card
              if (job.requiredParts.isNotEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.inventory_2_outlined,
                              size: 20,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Gelecek Parçalar',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: job.requiredParts.map((part) {
                            return Chip(
                              label: Text(part),
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.secondaryContainer.withOpacity(0.5),
                              side: BorderSide.none,
                              labelStyle: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSecondaryContainer,
                                fontSize: 13,
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
              if (job.requiredParts.isNotEmpty) const SizedBox(height: 16),

              // Comprehensive Spare Parts Summary Card
              if (job.allSpareParts.isNotEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.inventory_2_outlined,
                                  size: 20,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Yedek Parça Özeti',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            Text(
                              '${job.allSpareParts.length} Parça',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: job.allSpareParts.length,
                          separatorBuilder: (context, index) => const Divider(),
                          itemBuilder: (context, index) {
                            final item = job.allSpareParts[index];
                            final isInsurance =
                                item.supplySource == PartSupplySource.sigorta;
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.name,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w500,
                                              ),
                                        ),
                                        if (item.partCode != null &&
                                            item.partCode!.isNotEmpty)
                                          Text(
                                            'Parça Kodu: ${item.partCode}',
                                            style: Theme.of(
                                              context,
                                            ).textTheme.bodySmall,
                                          ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isInsurance
                                          ? Colors.blue.withOpacity(0.1)
                                          : Colors.teal.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          isInsurance
                                              ? Icons.security
                                              : Icons.shopping_cart,
                                          size: 14,
                                          color: isInsurance
                                              ? Colors.blue
                                              : Colors.teal,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          isInsurance ? 'Sigorta' : 'Kendi',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: isInsurance
                                                    ? Colors.blue
                                                    : Colors.teal,
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              if (job.allSpareParts.isNotEmpty) const SizedBox(height: 16),

              // Vehicle Damage Map
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Araç Hasar Haritası',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      Builder(
                        builder: (context) {
                          final selections =
                              VehiclePartMapper.tasksToSelections(job.tasks);

                          return AspectRatio(
                            aspectRatio: 1668 / 1160,
                            child: VehicleDamageMap(
                              assetName: 'assets/car-cutout-grouped.svg',
                              initialSelections: selections,
                              availableActions: workOrderDamageOperations,
                              readOnly: true,
                              showActionSheet: false,
                              onPartTapped: (partId) {
                                // Parça ID'sinden VehicleArea'ya dönüştür
                                final area =
                                    VehiclePartMapper.partIdToVehicleArea(
                                      partId,
                                    );
                                if (area == null) return;

                                // Bu parçaya ait görevleri bul
                                final tasksForPart = job.tasks
                                    .where((task) => task.area == area)
                                    .toList();

                                if (tasksForPart.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Bu parça için görev bulunamadı',
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                // Görevleri gösteren bir dialog aç
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text('${area.label} Görevleri'),
                                    content: SizedBox(
                                      width: double.maxFinite,
                                      child: ListView.builder(
                                        shrinkWrap: true,
                                        itemCount: tasksForPart.length,
                                        itemBuilder: (context, index) {
                                          final task = tasksForPart[index];
                                          return TaskListItem(
                                            task: task,
                                            jobId: widget.jobId,
                                          );
                                        },
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Kapat'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Tasks List
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Görevler',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              context.push(
                                '/dashboard/job-orders/${widget.jobId}/tasks',
                              );
                            },
                            icon: const Icon(Icons.arrow_forward),
                            label: const Text('Yönet'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (job.tasks.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Center(
                            child: Text(
                              'Bu iş emrinde görev bulunmuyor',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ),
                        )
                      else
                        ...job.tasks.map((task) {
                          final overrideNote = provider
                              .taskNoteForJob(widget.jobId, task.id)
                              ?.content;
                          return TaskListItem(
                            task: task,
                            jobId: widget.jobId,
                            showActionButtons: true,
                            showPhotos: true,
                            allowInlineNoteEdit: true,
                            noteOverride: overrideNote,
                            onTap: () {
                              // Görev yönetimine git
                              context.push(
                                '/dashboard/job-orders/${widget.jobId}/tasks',
                              );
                            },
                          );
                        }),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // General Notes (view & edit inline)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _GeneralNotesSection(jobId: widget.jobId),
                ),
              ),
              const SizedBox(height: 16),

              // Araçta Çalışan Ustalar Özeti
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _WorkerSummarySection(job: job),
                ),
              ),
              const SizedBox(height: 16),

              // Task Notes Overview
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _TaskNotesSection(job: job),
                ),
              ),
              const SizedBox(height: 16),

              // Created Date
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 20,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Oluşturulma: ${DateFormat('dd.MM.yyyy HH:mm').format(job.createdAt)}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GeneralNotesSection extends StatefulWidget {
  const _GeneralNotesSection({required this.jobId});

  final String jobId;

  @override
  State<_GeneralNotesSection> createState() => _GeneralNotesSectionState();
}

class _GeneralNotesSectionState extends State<_GeneralNotesSection> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final provider = context.read<JobsProvider>();
    setState(() => _isSaving = true);
    try {
      await provider.upsertJobNote(
        jobId: widget.jobId,
        content: _controller.text.trim(),
      );
      if (mounted) {
        ErrorSnackbar.showSuccess(context, 'Genel notlar güncellendi');
      }
    } catch (e) {
      if (mounted) {
        ErrorSnackbar.showError(
          context,
          'Genel notlar güncellenirken hata: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _syncController(String? notes) {
    final text = notes?.trim() ?? '';
    if (!_focusNode.hasFocus && !_isSaving && _controller.text != text) {
      _controller.text = text;
      _controller.selection = TextSelection.collapsed(offset: text.length);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAdmin = context.watch<AuthProvider>().isAdmin;
    return Consumer<JobsProvider>(
      builder: (context, provider, child) {
        final generalNote = provider.generalNoteForJob(widget.jobId);
        final job = provider.jobById(widget.jobId);
        final rawNotes = (generalNote?.content ?? job?.generalNotes)?.trim();
        _syncController(rawNotes);

        // Ayrı başlıklarla göstermek için parçalara ayır
        String? boyaNotes;
        String? kaportaNotes;
        String? digerNotes;
        String? otherGeneral;

        if (rawNotes != null && rawNotes.isNotEmpty) {
          // Bilinen başlıkları satır bazında yakala
          final lines = rawNotes.split('\n');
          String? currentSection;
          final bufferMap = <String, List<String>>{
            'boya': [],
            'kaporta': [],
            'diger': [],
            'other': [],
          };

          for (final line in lines) {
            final trimmed = line.trim();
            if (trimmed.isEmpty) {
              // Boş satırları mevcut bölüme ekle
              if (currentSection != null) {
                bufferMap[currentSection]!.add('');
              } else {
                bufferMap['other']!.add('');
              }
              continue;
            }

            if (trimmed.startsWith('Boya Notları')) {
              currentSection = 'boya';
              continue;
            }
            if (trimmed.startsWith('Kaporta Notları')) {
              currentSection = 'kaporta';
              continue;
            }
            if (trimmed.startsWith('Diğer Notlar')) {
              currentSection = 'diger';
              continue;
            }

            // İçeriği aktif bölüme veya diğerine ekle
            if (currentSection != null) {
              bufferMap[currentSection]!.add(trimmed);
            } else {
              bufferMap['other']!.add(trimmed);
            }
          }

          String _join(List<String> items) {
            final text = items.join('\n').trim();
            return text.isEmpty ? '' : text;
          }

          final boyaText = _join(bufferMap['boya']!);
          final kaportaText = _join(bufferMap['kaporta']!);
          final digerText = _join(bufferMap['diger']!);
          final otherText = _join(bufferMap['other']!);

          boyaNotes = boyaText.isNotEmpty ? boyaText : null;
          kaportaNotes = kaportaText.isNotEmpty ? kaportaText : null;
          digerNotes = digerText.isNotEmpty ? digerText : null;
          otherGeneral = otherText.isNotEmpty ? otherText : null;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Genel Notlar',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (isAdmin) ...[
              TextField(
                controller: _controller,
                focusNode: _focusNode,
                maxLines: 6,
                decoration: const InputDecoration(
                  hintText:
                      'Bu iş emri için genel notlar...\n(Boya / Kaporta / Diğer notlar da buraya kaydedilir)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: _isSaving ? null : _save,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save),
                  label: Text(_isSaving ? 'Kaydediliyor...' : 'Kaydet'),
                ),
              ),
            ] else ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (otherGeneral != null) ...[
                      SelectableText(
                        otherGeneral,
                        style: theme.textTheme.bodyMedium,
                      ),
                      if (boyaNotes != null ||
                          kaportaNotes != null ||
                          digerNotes != null)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Divider(height: 16, thickness: 0.5),
                        ),
                    ],
                    if (boyaNotes != null) ...[
                      Text(
                        'Boya Notları',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      SelectableText(
                        boyaNotes,
                        style: theme.textTheme.bodyMedium,
                      ),
                      if (kaportaNotes != null || digerNotes != null)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Divider(height: 16, thickness: 0.5),
                        ),
                    ],
                    if (kaportaNotes != null) ...[
                      Text(
                        'Kaporta Notları',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      SelectableText(
                        kaportaNotes,
                        style: theme.textTheme.bodyMedium,
                      ),
                      if (digerNotes != null)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Divider(height: 16, thickness: 0.5),
                        ),
                    ],
                    if (digerNotes != null) ...[
                      Text(
                        'Diğer Notlar',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      SelectableText(
                        digerNotes,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                    if (otherGeneral == null &&
                        boyaNotes == null &&
                        kaportaNotes == null &&
                        digerNotes == null)
                      SelectableText(
                        'Genel not bulunmuyor.',
                        style: theme.textTheme.bodyMedium,
                      ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _TaskNotesSection extends StatelessWidget {
  const _TaskNotesSection({required this.job});

  final JobOrder job;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<JobsProvider>();
    final notes = provider.jobNotesForJob(job.id);
    final taskNotes = notes.where((note) => note.taskId != null).toList();

    // Görev bazında notları grupla
    final Map<String, List<String>> taskNotesMap = {};

    // Önce görevlerdeki notları ekle (iş emri oluşturulurken girilen notlar)
    for (final task in job.tasks) {
      if (task.note != null && task.note!.isNotEmpty) {
        taskNotesMap.putIfAbsent(task.id, () => []).add(task.note!);
      }
    }

    // Sonra JobNote tablosundaki notları ekle (sonradan eklenen notlar)
    for (final note in taskNotes) {
      if (note.taskId != null) {
        taskNotesMap.putIfAbsent(note.taskId!, () => []).add(note.content);
      }
    }

    // Sadece notu olan görevleri filtrele
    final tasksWithNotes = job.tasks
        .where((task) => taskNotesMap.containsKey(task.id))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Görev Notları',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (tasksWithNotes.isEmpty)
          Text(
            'Henüz görev notu eklenmemiş.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          )
        else
          Column(
            children: [
              for (var i = 0; i < tasksWithNotes.length; i++) ...[
                Builder(
                  builder: (context) {
                    final task = tasksWithNotes[i];
                    final taskNoteList = taskNotesMap[task.id] ?? [];
                    return Container(
                      margin: EdgeInsets.only(
                        bottom: i < tasksWithNotes.length - 1 ? 12 : 0,
                      ),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Görev başlığı
                          Row(
                            children: [
                              Icon(
                                Icons.note_alt_outlined,
                                size: 20,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${task.area.label} - ${task.operationType.label}',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Görev notları (giriş yapıldığı şekilde, ayrı ayrı)
                          ...taskNoteList.map((noteContent) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: SelectableText(
                                noteContent,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
      ],
    );
  }
}

/// Araç üzerinde çalışan ustaların özetini gösteren bölüm
class _WorkerSummarySection extends StatelessWidget {
  const _WorkerSummarySection({required this.job});

  final JobOrder job;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    // Tüm görevlerdeki workSessions üzerinden usta bazlı toplam saatleri topla
    final Map<String, double> workerHours = {};
    for (final task in job.tasks) {
      for (final session in task.workSessions) {
        final name = session.workerName ?? session.workerId ?? 'Bilinmeyen';
        final seconds =
            session.durationSeconds ??
            (session.endTime != null
                ? session.endTime!.difference(session.startTime).inSeconds
                : DateTime.now().difference(session.startTime).inSeconds);
        final hours = seconds / 3600.0;
        workerHours[name] = (workerHours[name] ?? 0) + hours;
      }
    }

    if (workerHours.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Araçta Çalışan Ustalar',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Bu araç üzerinde kayıtlı çalışma oturumu bulunmuyor.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Araçta Çalışan Ustalar',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Bu iş emrinde, kayıtlı çalışma oturumlarına göre araç üzerinde çalışmış olan ustalar:',
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        ...workerHours.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        Icons.person_outline,
                        size: 18,
                        color: scheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          entry.key,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  DurationFormatter.longFromHours(entry.value),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: scheme.primary,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
