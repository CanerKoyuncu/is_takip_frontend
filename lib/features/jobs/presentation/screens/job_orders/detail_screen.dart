import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../providers/jobs_provider.dart';
import '../../../models/job_models.dart';
import '../../../../auth/providers/auth_provider.dart';
import '../../../models/vehicle_area.dart';
import '../../../utils/vehicle_part_mapper.dart';
import '../../../utils/svg_vehicle_part_loader.dart';
import '../../../services/job_order_pdf_service.dart';
import '../../../../../core/services/api_service_factory.dart';
import '../../../../../core/widgets/error_state.dart';
import '../../../../../core/widgets/loading_indicator.dart';
import '../../widgets/vehicle_damage_map.dart';
import '../../../widgets/task_list_item.dart';
import '../../../widgets/task_photo_dialog.dart';
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
                    // Get JobsApiService for backend PDF generation
                    final jobsApiService =
                        ApiServiceFactory.getJobsApiService();
                    await JobOrderPdfService.instance.previewAndShare(
                      job,
                      context: context,
                      jobsApiService: jobsApiService,
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
                    context.push('/dashboard/job-orders/${widget.jobId}/add-data');
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
                      FutureBuilder<List<VehiclePart>>(
                        future: SvgVehiclePartLoader.instance.load(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const SizedBox(
                              height: 300,
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }

                          if (snapshot.hasError || !snapshot.hasData) {
                            return SizedBox(
                              height: 300,
                              child: Center(
                                child: Text(
                                  'Araç şeması yüklenemedi',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                      ),
                                ),
                              ),
                            );
                          }

                          final parts = snapshot.data!;
                          final selections =
                              VehiclePartMapper.tasksToSelections(job.tasks);

                          return VehicleDamageMap(
                            parts: parts,
                            initialSelections: selections,
                            readOnly: true,
                            showActionSheet: false,
                            onPartTap: (part) {
                              // Parça ID'sinden VehicleArea'ya dönüştür
                              final area =
                                  VehiclePartMapper.partIdToVehicleArea(
                                    part.id,
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

                              // Fotoğrafı olan ilk görevi bul
                              final taskWithPhotos = tasksForPart.firstWhere(
                                (task) => task.photos.isNotEmpty,
                                orElse: () => tasksForPart.first,
                              );

                              // Eğer fotoğraf varsa ilk fotoğrafı göster
                              if (taskWithPhotos.photos.isNotEmpty) {
                                TaskPhotoDialog.show(
                                  context,
                                  photo: taskWithPhotos.photos.first,
                                  jobId: widget.jobId,
                                  taskId: taskWithPhotos.id,
                                  showDownloadButton: true,
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '${taskWithPhotos.area.label} - ${taskWithPhotos.operationType.label}\nBu görevde fotoğraf bulunmuyor',
                                    ),
                                  ),
                                );
                              }
                            },
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
                        ...job.tasks.map(
                          (task) {
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
                          },
                        ),
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
    return Consumer<JobsProvider>(
      builder: (context, provider, child) {
        final generalNote = provider.generalNoteForJob(widget.jobId);
        final job = provider.jobById(widget.jobId);
        _syncController(generalNote?.content ?? job?.generalNotes);

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
            TextField(
              controller: _controller,
              focusNode: _focusNode,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Bu iş emri için genel notlar...',
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
    final taskMap = {
      for (final task in job.tasks) task.id: task,
    };
    final legacyList = job.tasks
        .where(
          (task) =>
              (task.note?.trim().isNotEmpty ?? false) &&
              taskNotes.every(
                (note) => note.taskId == null || note.taskId != task.id,
              ),
        )
        .toList();
    final List<Widget> noteWidgets = [];

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
        if (taskNotes.isEmpty && legacyList.isEmpty)
          Text(
            'Henüz görev notu eklenmemiş.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          )
        else
          Column(
            children: () {
              for (var i = 0; i < taskNotes.length; i++) {
                final note = taskNotes[i];
                final task = note.taskId != null ? taskMap[note.taskId] : null;
                noteWidgets.add(
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      Icons.note_alt_outlined,
                      color: theme.colorScheme.primary,
                    ),
                    title: Text(
                      task != null
                          ? '${task.area.label} - ${task.operationType.label}'
                          : 'Görev Notu',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      note.content,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                );
                final hasMore =
                    i < taskNotes.length - 1 || legacyList.isNotEmpty;
                if (hasMore) {
                  noteWidgets.add(const Divider(height: 12, thickness: 0.5));
                }
              }
              for (var i = 0; i < legacyList.length; i++) {
                final task = legacyList[i];
                noteWidgets.add(
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      Icons.history_edu_outlined,
                      color: theme.colorScheme.secondary,
                    ),
                    title: Text(
                      '${task.area.label} - ${task.operationType.label}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      task.note ?? '',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                );
                if (i < legacyList.length - 1) {
                  noteWidgets.add(const Divider(height: 12, thickness: 0.5));
                }
              }
              return noteWidgets;
            }(),
          ),
      ],
    );
  }
}
