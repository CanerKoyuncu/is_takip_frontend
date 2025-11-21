import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../../providers/jobs_provider.dart';
import '../../../models/job_models.dart';
import '../../../models/vehicle_area.dart';
import '../../../utils/vehicle_part_mapper.dart';
import '../../../utils/svg_vehicle_part_loader.dart';
import '../../widgets/vehicle_damage_map.dart';

class AddTaskToJobScreen extends StatefulWidget {
  const AddTaskToJobScreen({super.key, required this.jobId});

  final String jobId;

  @override
  State<AddTaskToJobScreen> createState() => _AddTaskToJobScreenState();
}

class _AddTaskToJobScreenState extends State<AddTaskToJobScreen> {
  VehiclePartSelections _selections = {};
  List<VehiclePart>? _parts;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadParts();
  }

  Future<void> _loadParts() async {
    try {
      final parts = await SvgVehiclePartLoader.instance.load();
      setState(() {
        _parts = parts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _addTasks() async {
    if (_selections.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen en az bir parça seçin ve işlem belirleyin'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_parts == null) {
      return;
    }

    try {
      final taskDrafts = VehiclePartMapper.selectionsToTaskDrafts(
        _selections,
        _parts!,
      );

      if (taskDrafts.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Geçerli görev bulunamadı. "Temizle" işlemleri görev oluşturmaz.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final provider = context.read<JobsProvider>();
      final uuid = const Uuid();

      for (final draft in taskDrafts) {
        final task = JobTask(
          id: uuid.v4(),
          area: draft.area,
          operationType: draft.operationType,
          note: draft.note,
          status: JobTaskStatus.pending,
        );

        await provider.addTaskToJob(jobId: widget.jobId, task: task);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Görevler başarıyla eklendi'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Görev eklenirken hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yeni Görev Ekle'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _addTasks,
            tooltip: 'Görevleri Ekle',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _parts == null
          ? const Center(child: Text('Parçalar yüklenemedi'))
          : Column(
              children: [
                Expanded(
                  child: VehicleDamageMap(
                    parts: _parts!,
                    initialSelections: _selections,
                    onSelectionsChanged: (updated) {
                      setState(() {
                        _selections = Map<String, List<String>>.from(
                          updated.map(
                            (key, value) =>
                                MapEntry(key, List<String>.from(value)),
                          ),
                        );
                      });
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Seçilen Parçalar: ${_selections.length}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      FilledButton.icon(
                        onPressed: _addTasks,
                        icon: const Icon(Icons.add_task),
                        label: const Text('Görevleri Ekle'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
