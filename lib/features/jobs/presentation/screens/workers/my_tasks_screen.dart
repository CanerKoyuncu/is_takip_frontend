/// Personel Görevlerim Ekranı
///
/// Personelin kendisine atanmış görevleri gösterir.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'dart:typed_data';

import '../../../providers/jobs_provider.dart';
import '../../../models/job_models.dart';
import '../../../../../core/widgets/error_state.dart';
import '../../../../../core/widgets/loading_indicator.dart';
import '../../../utils/vehicle_part_mapper.dart';
import '../../../utils/svg_vehicle_part_loader.dart';
import '../../../utils/damage_map_image_generator.dart';

class MyTasksScreen extends StatefulWidget {
  const MyTasksScreen({super.key});

  @override
  State<MyTasksScreen> createState() => _MyTasksScreenState();
}

class _MyTasksScreenState extends State<MyTasksScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _statusFilter;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          switch (_tabController.index) {
            case 0:
              _statusFilter = null; // Tümü
              break;
            case 1:
              _statusFilter = 'pending'; // Bekleyen
              break;
            case 2:
              _statusFilter = 'in_progress'; // Devam Eden
              break;
          }
        });
        _loadTasks();
      }
    });
    _loadTasks();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTasks() async {
    final provider = context.read<JobsProvider>();
    await provider.loadMyTasks(statusFilter: _statusFilter);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<JobsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Görevlerim'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Tümü'),
            Tab(text: 'Bekleyen'),
            Tab(text: 'Devam Eden'),
          ],
        ),
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
    final jobs = provider.myTasks;

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
              'Görev bulunamadı',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _statusFilter == null
                  ? 'Size atanmış görev bulunmuyor'
                  : _statusFilter == 'pending'
                  ? 'Bekleyen görev bulunmuyor'
                  : 'Devam eden görev bulunmuyor',
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
          child: InkWell(
            onTap: () {
              context.push('/dashboard/job-orders/${job.id}/tasks');
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${job.vehicle.plate} - ${job.vehicle.brand} ${job.vehicle.model}',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${job.tasks.length} görev',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  _buildDamageMapThumbnail(job),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
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
