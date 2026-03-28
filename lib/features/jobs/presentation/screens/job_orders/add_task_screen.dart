import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../../providers/jobs_provider.dart';
import '../../../models/job_models.dart';
import '../../../models/vehicle_area.dart';
import '../../../utils/vehicle_part_mapper.dart';
import 'package:vehicle_damage_map/vehicle_damage_map.dart';

class AddTaskToJobScreen extends StatefulWidget {
  const AddTaskToJobScreen({super.key, required this.jobId});

  final String jobId;

  @override
  State<AddTaskToJobScreen> createState() => _AddTaskToJobScreenState();
}

class _AddTaskToJobScreenState extends State<AddTaskToJobScreen> {
  VehiclePartSelections _selections = {};
  PartSparePartsMap _sparePartsSelections = {};
  List<VehiclePart>? _parts;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _loadError;

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
      debugPrint('Error loading vehicle parts: $e');
      setState(() {
        _loadError = e.toString();
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Araç parçaları yüklenemedi: ${_loadError ?? "Bilinmeyen hata"}',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      final taskDrafts = VehiclePartMapper.selectionsToTaskDrafts(
        _selections,
        _parts!,
        sparePartsSelections: _sparePartsSelections,
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

        // Parça adını bul (sokTak işlemi ise backend'e gönderilecek)
        String? partName;
        final part = _parts?.firstWhere(
          (p) => VehiclePartMapper.partIdToVehicleArea(p.id) == draft.area,
          orElse: () =>
              _parts!.first, // Fallback (aslında area eşleşmesi beklenir)
        );
        if (part != null) {
          partName = part.displayName;
        }

        await provider.addTaskToJob(
          jobId: widget.jobId,
          task: task.copyWith(spareParts: draft.spareParts),
          partName: partName,
        );
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
      debugPrint('Error adding tasks: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Görev eklenirken hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yeni Görev Ekle'),
        actions: [
          if (_isLoading || _isSaving)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
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
                    assetName: 'assets/car-cutout-grouped.svg',
                    initialSelections: _selections,
                    initialSparePartsSelections: _sparePartsSelections,
                    availableActions: workOrderDamageOperations,
                    onSelectionsChanged: (updated) {
                      setState(() {
                        _selections = updated;
                      });
                    },
                    onSparePartsChanged: (updated) {
                      setState(() {
                        _sparePartsSelections = updated;
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
                        'Seçilen: ${_selections.length} Bölge, ${_sparePartsSelections.values.expand((e) => e).length} Parça',
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
