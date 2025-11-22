import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../models/job_models.dart';
import '../../../models/job_task_draft.dart';
import '../../../models/vehicle_area.dart';
import '../../../providers/jobs_provider.dart';
import '../../../utils/vehicle_part_mapper.dart';
import '../../widgets/vehicle_damage_map.dart';

class CreateJobOrderScreen extends StatefulWidget {
  const CreateJobOrderScreen({
    super.key,
    required this.selections,
    required this.parts,
  });

  final VehiclePartSelections selections;
  final List<VehiclePart> parts;

  @override
  State<CreateJobOrderScreen> createState() => _CreateJobOrderScreenState();
}

class _CreateJobOrderScreenState extends State<CreateJobOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _plateController = TextEditingController();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _notesController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  final Map<String, List<String>> _taskPhotos = {}; // taskId -> photo paths

  bool _isCreating = false;

  String _getDraftKey(JobTaskDraft draft) {
    return '${draft.area.name}_${draft.operationType.name}';
  }

  List<String> _getDraftPhotos(JobTaskDraft draft) {
    return _taskPhotos[_getDraftKey(draft)] ?? [];
  }

  Future<void> _addPhotoToDraft(JobTaskDraft draft) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (image == null || !mounted) return;

      final draftKey = _getDraftKey(draft);
      setState(() {
        _taskPhotos.putIfAbsent(draftKey, () => []).add(image.path);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Fotoğraf eklendi'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fotoğraf eklenirken hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _plateController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _createJobOrder() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isCreating = true;
    });

    try {
      var taskDrafts = VehiclePartMapper.selectionsToTaskDrafts(
        widget.selections,
        widget.parts,
      );

      // Add photos to task drafts
      taskDrafts = taskDrafts.map((draft) {
        // Create a unique key for this draft (area + operationType)
        final draftKey = '${draft.area.name}_${draft.operationType.name}';
        final photos = _taskPhotos[draftKey] ?? [];
        return draft.copyWith(photoPaths: photos);
      }).toList();

      if (taskDrafts.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'En az bir geçerli görev seçilmelidir. "Temizle" işlemleri görev oluşturmaz.',
            ),
          ),
        );
        setState(() {
          _isCreating = false;
        });
        return;
      }

      final vehicle = VehicleInfo(
        plate: _plateController.text.trim(),
        brand: _brandController.text.trim(),
        model: _modelController.text.trim(),
      );

      final provider = context.read<JobsProvider>();
      await provider.createJob(
        vehicle: vehicle,
        taskDrafts: taskDrafts,
        generalNotes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('İş emri başarıyla oluşturuldu!'),
          backgroundColor: Colors.green,
        ),
      );

      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final taskDrafts = VehiclePartMapper.selectionsToTaskDrafts(
      widget.selections,
      widget.parts,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Yeni İş Emri Oluştur')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Vehicle Damage Map Preview
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
                          'Seçilen Parçalar',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: scheme.primaryContainer,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            '${widget.selections.length} parça seçildi',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: scheme.onPrimaryContainer,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: scheme.outlineVariant,
                          width: 1,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: AspectRatio(
                          aspectRatio: 1668 / 1160,
                          child: VehicleDamageMap(
                            parts: widget.parts,
                            initialSelections: widget.selections,
                            readOnly: true,
                            showActionSheet: false,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (taskDrafts.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: scheme.errorContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.warning_outlined,
                              color: scheme.onErrorContainer,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Geçerli görev bulunamadı. "Temizle" işlemleri görev oluşturmaz.',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: scheme.onErrorContainer),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Oluşturulacak Görevler (${taskDrafts.length})',
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          ...taskDrafts.map((draft) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: scheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: scheme.outlineVariant,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color:
                                          draft.operationType.category ==
                                              TaskCategory.boya
                                          ? scheme.primaryContainer
                                          : draft.operationType.category ==
                                                TaskCategory.kaporta
                                          ? scheme.tertiaryContainer
                                          : scheme.secondaryContainer,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Icon(
                                      draft.operationType.icon,
                                      size: 20,
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          draft.area.label,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyLarge
                                              ?.copyWith(
                                                fontWeight: FontWeight.w500,
                                              ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          draft.operationType.label,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: scheme.onSurfaceVariant,
                                              ),
                                        ),
                                        if (draft.note != null &&
                                            draft.note!.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            draft.note!,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color:
                                                      scheme.onSurfaceVariant,
                                                ),
                                          ),
                                        ],
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            OutlinedButton.icon(
                                              onPressed: () =>
                                                  _addPhotoToDraft(draft),
                                              icon: const Icon(
                                                Icons.camera_alt,
                                                size: 16,
                                              ),
                                              label: const Text(
                                                'Fotoğraf Ekle',
                                              ),
                                              style: OutlinedButton.styleFrom(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 8,
                                                    ),
                                              ),
                                            ),
                                            if (_getDraftPhotos(
                                              draft,
                                            ).isNotEmpty) ...[
                                              const SizedBox(width: 8),
                                              Chip(
                                                label: Text(
                                                  '${_getDraftPhotos(draft).length} fotoğraf',
                                                ),
                                                avatar: const Icon(
                                                  Icons.photo,
                                                  size: 16,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Vehicle Information
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Araç Bilgileri',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _plateController,
                      decoration: const InputDecoration(
                        labelText: 'Plaka',
                        hintText: '34 ABC 123',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Plaka gerekli';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _brandController,
                      decoration: const InputDecoration(
                        labelText: 'Marka',
                        hintText: 'Toyota',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Marka gerekli';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _modelController,
                      decoration: const InputDecoration(
                        labelText: 'Model',
                        hintText: 'Corolla',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Model gerekli';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // General Notes
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Genel Notlar',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Notlar (Opsiyonel)',
                        hintText: 'Ek bilgiler...',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 4,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Create Button
            FilledButton(
              onPressed: _isCreating ? null : _createJobOrder,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                minimumSize: const Size(double.infinity, 56),
              ),
              child: _isCreating
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      'İş Emri Oluştur',
                      style: TextStyle(fontSize: 16),
                    ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
