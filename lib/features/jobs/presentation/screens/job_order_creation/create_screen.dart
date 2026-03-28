import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:is_takip/core/widgets/platform_image.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'package:is_takip/features/jobs/models/reception_models.dart';
import 'package:is_takip/features/jobs/services/job_creation_cache_service.dart';
import '../../../models/job_models.dart';
import '../../../models/job_task_draft.dart';
import '../../../providers/jobs_provider.dart';
import '../../../utils/task_category_styles.dart';
import '../../../utils/vehicle_part_mapper.dart';
import 'package:vehicle_damage_map/vehicle_damage_map.dart';

class CreateJobOrderScreen extends StatefulWidget {
  const CreateJobOrderScreen({super.key});

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
  final _cacheService = JobCreationCacheService();

  // Local state for selections
  VehiclePartSelections _selections = {};
  Map<String, List<SparePartItem>> _sparePartsSelections = {};

  final Map<String, List<String>> _taskPhotos = {}; // taskId -> photo paths
  List<ReceptionPhoto> _receptionPhotos = [];
  List<String> _requiredParts = [];
  final _requiredPartController = TextEditingController();

  bool _isCreating = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _loadDraft();
  }

  Future<void> _loadDraft() async {
    final draft = await _cacheService.loadDraft();
    if (draft != null && mounted) {
      setState(() {
        _plateController.text = draft['plate'] ?? '';
        _brandController.text = draft['brand'] ?? '';
        _modelController.text = draft['model'] ?? '';
        _notesController.text = draft['generalNotes'] ?? '';
        _selections = draft['selections'] ?? {};
        _sparePartsSelections = draft['spareParts'] ?? {};
        _receptionPhotos = draft['receptionPhotos'] ?? [];
        _requiredParts = draft['requiredParts'] ?? [];
        _isInitialized = true;
      });
    } else {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  Future<void> _saveDraft() async {
    if (!_isInitialized) return;
    await _cacheService.saveDraft(
      plate: _plateController.text,
      brand: _brandController.text,
      model: _modelController.text,
      selections: _selections,
      spareParts: _sparePartsSelections,
      receptionPhotos: _receptionPhotos,
      generalNotes: _notesController.text,
      requiredParts: _requiredParts,
    );
  }

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
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (image == null || !mounted) return;

      final draftKey = _getDraftKey(draft);
      setState(() {
        _taskPhotos.putIfAbsent(draftKey, () => []).add(image.path);
      });
      _saveDraft();

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

  Future<void> _addReceptionPhoto() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (image == null || !mounted) return;

      setState(() {
        _receptionPhotos.add(ReceptionPhoto(originalPath: image.path));
      });
      _saveDraft();
    } catch (e) {
      debugPrint('Reception photo error: $e');
    }
  }

  @override
  void dispose() {
    _plateController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _notesController.dispose();
    _requiredPartController.dispose();
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
        _selections,
        [], // parts list is no longer required in the mapper for draft creation
        sparePartsSelections: _sparePartsSelections,
      );

      // Add photos to task drafts
      taskDrafts = taskDrafts.map((draft) {
        // Create a unique key for this draft (area + operationType)
        final draftKey = _getDraftKey(draft);
        final photos = _taskPhotos[draftKey] ?? [];
        return draft.copyWith(photoPaths: photos);
      }).toList();

      // Add reception task if photos exist
      if (_receptionPhotos.isNotEmpty) {
        taskDrafts.add(
          JobTaskDraft(
            area: VehicleArea.hood, // General marker
            operationType: JobOperationType.reception,
            photoPaths: _receptionPhotos.map((p) => p.displayPath).toList(),
            note: 'Araç teslim alma fotoğrafları',
          ),
        );
      }

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
        requiredParts: _requiredParts,
      );

      await _cacheService.clearDraft();

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
      _selections,
      [],
      sparePartsSelections: _sparePartsSelections,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Yeni İş Emri Oluştur'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Taslağı Temizle'),
                  content: const Text(
                    'Tüm form verileri silinecek. Emin misiniz?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('İPTAL'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('TEMİZLE'),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await _cacheService.clearDraft();
                if (mounted) {
                  setState(() {
                    _plateController.clear();
                    _brandController.clear();
                    _modelController.clear();
                    _notesController.clear();
                    _selections = {};
                    _sparePartsSelections = {};
                    _receptionPhotos = [];
                    _taskPhotos.clear();
                    _requiredParts = [];
                  });
                }
              }
            },
            tooltip: 'Taslağı Temizle',
          ),
        ],
      ),
      body: !_isInitialized
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Reception Photos
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
                                'Teslim Alma Fotoğrafları',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              IconButton.filledTonal(
                                onPressed: _addReceptionPhoto,
                                icon: const Icon(Icons.add_a_photo),
                                tooltip: 'Fotoğraf Ekle',
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Aracı teslim alırken çekilen genel kontrol fotoğrafları.',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                          if (_receptionPhotos.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 100,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _receptionPhotos.length,
                                itemBuilder: (context, index) {
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          child: PlatformImage(
                                            path: _receptionPhotos[index]
                                                .displayPath,
                                            width: 100,
                                            height: 100,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                        Positioned(
                                          top: 4,
                                          right: 4,
                                          child: GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                _receptionPhotos.removeAt(
                                                  index,
                                                );
                                              });
                                              _saveDraft();
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.all(2),
                                              decoration: const BoxDecoration(
                                                color: Colors.black54,
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.close,
                                                size: 16,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Interactive Vehicle Damage Map
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
                                'Hasar Haritası',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              if (_selections.isNotEmpty)
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
                                    '${_selections.length} parça seçildi',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
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
                                  assetName: 'assets/car-cutout-grouped.svg',
                                  initialSelections: _selections,
                                  availableActions: workOrderDamageOperations,
                                  onSelectionsChanged: (updated) {
                                    setState(() => _selections = updated);
                                    _saveDraft();
                                  },
                                  onSparePartsChanged: (updated) {
                                    setState(
                                      () => _sparePartsSelections = updated,
                                    );
                                    _saveDraft();
                                  },
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (taskDrafts.isEmpty)
                            Container(
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
                                  Icon(
                                    Icons.info_outline,
                                    color: scheme.onSurfaceVariant,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'İş emri oluşturmak için harita üzerinden parça ve işlem seçiniz.',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: scheme.onSurfaceVariant,
                                          ),
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
                                  final draftCategoryColor =
                                      TaskCategoryStyles.containerColor(
                                        context,
                                        draft.operationType.category,
                                      );
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
                                            color: draftCategoryColor,
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
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
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                draft.operationType.label,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall
                                                    ?.copyWith(
                                                      color: scheme
                                                          .onSurfaceVariant,
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
                                                        color: scheme
                                                            .onSurfaceVariant,
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
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _plateController,
                            decoration: const InputDecoration(
                              labelText: 'Plaka',
                              hintText: '34 ABC 123',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (_) => _saveDraft(),
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
                            onChanged: (_) => _saveDraft(),
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
                            onChanged: (_) => _saveDraft(),
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
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
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
                            onChanged: (_) => _saveDraft(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Required Parts / Materials
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sarf Malzemeler / Gerekli Parçalar',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'İş emri için gerekli genel malzemeleri buraya ekleyebilirsiniz.',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _requiredPartController,
                                  decoration: const InputDecoration(
                                    labelText: 'Parça/Malzeme Adı',
                                    hintText: 'Örn: Antifriz, Cam Suyu...',
                                    border: OutlineInputBorder(),
                                  ),
                                  onSubmitted: (_) {
                                    if (_requiredPartController
                                        .text
                                        .isNotEmpty) {
                                      setState(() {
                                        _requiredParts.add(
                                          _requiredPartController.text.trim(),
                                        );
                                        _requiredPartController.clear();
                                      });
                                      _saveDraft();
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton.filledTonal(
                                onPressed: () {
                                  if (_requiredPartController.text.isNotEmpty) {
                                    setState(() {
                                      _requiredParts.add(
                                        _requiredPartController.text.trim(),
                                      );
                                      _requiredPartController.clear();
                                    });
                                    _saveDraft();
                                  }
                                },
                                icon: const Icon(Icons.add),
                              ),
                            ],
                          ),
                          if (_requiredParts.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _requiredParts.asMap().entries.map((
                                entry,
                              ) {
                                return Chip(
                                  label: Text(entry.value),
                                  onDeleted: () {
                                    setState(() {
                                      _requiredParts.removeAt(entry.key);
                                    });
                                    _saveDraft();
                                  },
                                );
                              }).toList(),
                            ),
                          ],
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
