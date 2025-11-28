import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'package:is_takip/core/widgets/error_snackbar.dart';

import '../../../models/job_models.dart';
import '../../../models/job_task_draft.dart';
import '../../../models/vehicle_area.dart';
import '../../../providers/jobs_provider.dart';
import '../../../utils/damage_action_styles.dart';
import '../../../utils/svg_vehicle_part_loader.dart';
import '../../../utils/task_category_styles.dart';
import '../../../utils/vehicle_part_mapper.dart';
import '../../widgets/vehicle_damage_map.dart';
import '../../widgets/vehicle_damage_map/vehicle_action_sheet.dart';

/// İş Emri Oluşturma Sayfası
/// Araç hasar haritası, araç/müşteri bilgileri ve notlar tek sayfada
class VehiclePartsScreen extends StatefulWidget {
  const VehiclePartsScreen({super.key});

  @override
  State<VehiclePartsScreen> createState() => _VehiclePartsScreenState();
}

class _VehiclePartsScreenState extends State<VehiclePartsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _plateController = TextEditingController();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _generalNotesController = TextEditingController();
  final _paintNotesController = TextEditingController();
  final _bodyRepairNotesController = TextEditingController();
  final _otherNotesController = TextEditingController();

  final ImagePicker _imagePicker = ImagePicker();
  final Map<String, List<String>> _taskPhotos = {}; // draftKey -> photo paths
  final Map<String, TextEditingController> _taskNoteControllers =
      {}; // draftKey -> controller
  final TextEditingController _partSearchController = TextEditingController();
  final Map<String, VehicleSvgPartConfig> _allPartConfigs =
      SvgVehiclePartLoader.partConfigs;
  static const List<String> _partSectionOrder = <String>[
    'Ön',
    'Sol',
    'Sağ',
    'Arka',
    'Tavan / Cam',
    'Diğer',
  ];

  VehiclePartSelections _selections = {};
  List<VehiclePart>? _parts;
  String? _selectedPartId;
  bool _isLoading = false;
  bool _isCreating = false;
  String _partSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _partSearchController.addListener(_onPartSearchChanged);
    _loadParts();
  }

  Future<void> _loadParts() async {
    setState(() => _isLoading = true);
    try {
      final parts = await SvgVehiclePartLoader.instance.load();
      if (mounted) {
        setState(() {
          _parts = parts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ErrorSnackbar.showError(context, 'Parçalar yüklenemedi: $e');
      }
    }
  }

  String _getDraftKey(JobTaskDraft draft) {
    return '${draft.area.name}_${draft.operationType.name}';
  }

  List<String> _getDraftPhotos(JobTaskDraft draft) {
    return _taskPhotos[_getDraftKey(draft)] ?? [];
  }

  TextEditingController _getDraftNoteController(JobTaskDraft draft) {
    final draftKey = _getDraftKey(draft);
    if (!_taskNoteControllers.containsKey(draftKey)) {
      _taskNoteControllers[draftKey] = TextEditingController();
    }
    return _taskNoteControllers[draftKey]!;
  }

  void _disposeTaskNoteControllers() {
    for (final controller in _taskNoteControllers.values) {
      controller.dispose();
    }
    _taskNoteControllers.clear();
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
        ErrorSnackbar.showSuccess(context, 'Fotoğraf eklendi');
      }
    } catch (e) {
      if (mounted) {
        ErrorSnackbar.showError(context, 'Fotoğraf eklenirken hata: $e');
      }
    }
  }

  Future<void> _createJobOrder() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_parts == null) {
      ErrorSnackbar.showError(context, 'Parçalar yüklenemedi');
      return;
    }

    setState(() => _isCreating = true);

    try {
      debugPrint(
        '[VehiclePartsScreen] Creating job order with ${_selections.length} selections',
      );
      debugPrint('[VehiclePartsScreen] Selections: $_selections');
      var taskDrafts = VehiclePartMapper.selectionsToTaskDrafts(
        _selections,
        _parts!,
      );
      debugPrint(
        '[VehiclePartsScreen] Generated ${taskDrafts.length} task drafts',
      );

      // Add photos and notes to task drafts
      taskDrafts = taskDrafts.map((draft) {
        final draftKey = _getDraftKey(draft);
        final photos = _taskPhotos[draftKey] ?? [];
        final noteController = _taskNoteControllers[draftKey];
        final note = noteController?.text.trim();

        // Combine operation-specific notes with task note
        String? combinedNote = draft.note;
        if (note != null && note.isNotEmpty) {
          combinedNote = combinedNote != null && combinedNote.isNotEmpty
              ? '$combinedNote\n\n$note'
              : note;
        }

        // Add operation-specific notes
        final category = draft.operationType.category;
        final categoryController = category == TaskCategory.boya
            ? _paintNotesController
            : _bodyRepairNotesController;
        final noteText = categoryController.text.trim();
        if (noteText.isNotEmpty) {
          final categoryNote = _formatCategoryNote(
            category: category,
            area: draft.area,
            operationType: draft.operationType,
            baseNote: noteText,
          );
          combinedNote = combinedNote != null && combinedNote.isNotEmpty
              ? '$combinedNote\n\n$categoryNote'
              : categoryNote;
        }

        return draft.copyWith(photoPaths: photos, note: combinedNote);
      }).toList();

      if (taskDrafts.isEmpty) {
        if (!mounted) return;
        ErrorSnackbar.showError(
          context,
          'En az bir geçerli görev seçilmelidir. "Temizle" işlemleri görev oluşturmaz.',
        );
        setState(() => _isCreating = false);
        return;
      }

      final vehicle = VehicleInfo(
        plate: _plateController.text.trim(),
        brand: _brandController.text.trim(),
        model: _modelController.text.trim(),
      );

      // Combine general notes with operation-specific notes
      String? generalNotes = _generalNotesController.text.trim();
      if (generalNotes.isEmpty) generalNotes = null;

      // Add other notes if exists
      if (_otherNotesController.text.trim().isNotEmpty) {
        final otherNote = 'Diğer Notlar: ${_otherNotesController.text.trim()}';
        generalNotes = generalNotes != null
            ? '$generalNotes\n\n$otherNote'
            : otherNote;
      }

      final provider = context.read<JobsProvider>();
      await provider.createJob(
        vehicle: vehicle,

        taskDrafts: taskDrafts,
        generalNotes: generalNotes,
      );

      if (!mounted) return;

      ErrorSnackbar.showSuccess(context, 'İş emri başarıyla oluşturuldu!');
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ErrorSnackbar.showError(context, 'Hata: $e');
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  @override
  void dispose() {
    _plateController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _generalNotesController.dispose();
    _paintNotesController.dispose();
    _bodyRepairNotesController.dispose();
    _otherNotesController.dispose();
    _disposeTaskNoteControllers();
    _partSearchController.dispose();
    super.dispose();
  }

  void _onPartSearchChanged() {
    setState(() {
      _partSearchQuery = _partSearchController.text;
    });
  }

  Map<String, List<String>> _cloneSelections(Map<String, List<String>> source) {
    return source.map((key, value) => MapEntry(key, List<String>.from(value)));
  }

  List<String> _normalizedActions(List<String>? actions) {
    if (actions == null || actions.isEmpty) {
      return const [];
    }
    final normalized = <String>[];
    for (final action in damageActionPriority) {
      if (actions.contains(action)) {
        normalized.add(action);
      }
    }
    return normalized;
  }

  List<_PartListItem> _filteredParts() {
    final partMap = {
      for (final part in (_parts ?? const <VehiclePart>[])) part.id: part,
    };
    final configs = _allPartConfigs.values.toList()
      ..sort(
        (a, b) =>
            a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()),
      );

    final query = _partSearchQuery.trim().toLowerCase();
    final items = configs.map((config) {
      final svgPart = partMap[config.id];
      return _PartListItem(
        id: config.id,
        displayName: config.displayName,
        part: svgPart,
      );
    }).toList();

    if (query.isEmpty) {
      return items;
    }

    return items
        .where(
          (item) =>
              item.displayName.toLowerCase().contains(query) ||
              item.id.toLowerCase().contains(query),
        )
        .toList();
  }

  List<_PartListEntry> _buildPartListEntries(List<_PartListItem> parts) {
    final grouped = <String, List<_PartListItem>>{};
    for (final part in parts) {
      final section = _sectionForPart(part.id);
      grouped.putIfAbsent(section, () => []).add(part);
    }

    final sortedKeys = grouped.keys.toList()
      ..sort((a, b) => _sectionSortIndex(a).compareTo(_sectionSortIndex(b)));

    final entries = <_PartListEntry>[];
    for (final key in sortedKeys) {
      final sectionParts = grouped[key]!
        ..sort(
          (a, b) => a.displayName.toLowerCase().compareTo(
            b.displayName.toLowerCase(),
          ),
        );
      entries.add(_PartListEntry.header(key));
      entries.addAll(sectionParts.map(_PartListEntry.part));
    }
    return entries;
  }

  int _sectionSortIndex(String section) {
    final index = _partSectionOrder.indexOf(section);
    return index >= 0 ? index : _partSectionOrder.length;
  }

  String _sectionForPart(String partId) {
    final normalized = _normalizeId(partId);
    if (normalized.contains('cam') ||
        normalized.contains('sunroof') ||
        normalized.contains('tavan')) {
      return 'Tavan / Cam';
    }
    if (normalized.contains('sol')) return 'Sol';
    if (normalized.contains('sag')) return 'Sağ';
    if (normalized.contains('arka') || normalized.contains('yakit')) {
      return 'Arka';
    }
    if (normalized.contains('on')) return 'Ön';
    return 'Diğer';
  }

  String _normalizeId(String input) {
    const replacements = {
      'ı': 'i',
      'ğ': 'g',
      'ü': 'u',
      'ş': 's',
      'ö': 'o',
      'ç': 'c',
    };
    var value = input.toLowerCase();
    replacements.forEach((src, target) {
      value = value.replaceAll(src, target);
    });
    return value;
  }

  Future<void> _showPartActionSheet(VehiclePart part) async {
    final currentActions = List<String>.from(_selections[part.id] ?? []);
    final updatedActions = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      builder: (context) =>
          VehicleActionSheet(part: part, selectedActions: currentActions),
    );

    if (!mounted || updatedActions == null) {
      return;
    }

    setState(() {
      final next = _cloneSelections(_selections);
      if (updatedActions.isEmpty) {
        next.remove(part.id);
      } else {
        next[part.id] = List<String>.from(updatedActions);
      }
      _selections = next;
      _selectedPartId = part.id;
    });
  }

  void _clearPartSelection(VehiclePart part) {
    if (!_selections.containsKey(part.id)) return;
    setState(() {
      final next = _cloneSelections(_selections);
      next.remove(part.id);
      _selections = next;
      if (_selectedPartId == part.id) {
        _selectedPartId = null;
      }
    });
  }

  String _formatCategoryNote({
    required TaskCategory category,
    required VehicleArea area,
    required JobOperationType operationType,
    required String baseNote,
  }) {
    final prefix = TaskCategoryStyles.noteTitle(category);
    final header =
        '$prefix · ${area.label} (${operationType.label.toLowerCase()})';
    final normalizedLines = baseNote
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    if (normalizedLines.isEmpty) {
      return header;
    }

    if (normalizedLines.length == 1) {
      return '$header\n${normalizedLines.first}';
    }

    final bullets = normalizedLines.map((line) => '• $line').join('\n');
    return '$header\n$bullets';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final taskDrafts = _parts != null
        ? VehiclePartMapper.selectionsToTaskDrafts(_selections, _parts!)
        : <JobTaskDraft>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Yeni İş Emri Oluştur'),
        actions: [
          if (!_isCreating)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _createJobOrder,
              tooltip: 'İş Emri Oluştur',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _parts == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48),
                  const SizedBox(height: 16),
                  const Text('Parçalar yüklenemedi'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadParts,
                    child: const Text('Tekrar Dene'),
                  ),
                ],
              ),
            )
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Vehicle Damage Map
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
                                'Araç Hasar Haritası',
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
                          AspectRatio(
                            aspectRatio: 1668 / 1160,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: scheme.outlineVariant,
                                  width: 1,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: VehicleDamageMap(
                                  parts: _parts,
                                  initialSelections: _selections,
                                  selectedPartId: _selectedPartId,
                                  onSelectionsChanged: (updated) {
                                    debugPrint(
                                      '[VehiclePartsScreen] Selections updated: ${updated.length} parts',
                                    );
                                    setState(() {
                                      _selections = _cloneSelections(updated);
                                    });
                                    debugPrint(
                                      '[VehiclePartsScreen] _selections state updated: ${_selections.length} parts',
                                    );
                                  },
                                  onPartTap: (part) {
                                    setState(() {
                                      _selectedPartId = part.id;
                                    });
                                  },
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (_parts != null)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Parça Listesi',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _partSearchController,
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.search),
                                suffixIcon: _partSearchQuery.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear),
                                        onPressed: () {
                                          _partSearchController.clear();
                                          _onPartSearchChanged();
                                        },
                                      )
                                    : null,
                                hintText: 'Parça ara (örn. kapı, tampon)',
                                border: const OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildPartList(context),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),

                  // Warning if selections exist but no tasks
                  if (_selections.isNotEmpty && taskDrafts.isEmpty)
                    Card(
                      color: scheme.errorContainer.withValues(alpha: 0.3),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: scheme.onErrorContainer,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Seçilen işlemler görev oluşturmaz. "Temizle" işlemi görev oluşturmaz. Lütfen "Boya", "Kaporta" veya "Değişim" işlemlerinden birini seçin.',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: scheme.onErrorContainer),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Selected Tasks Preview
                  if (taskDrafts.isNotEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Seçilen Görevler (${taskDrafts.length})',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),
                            ...taskDrafts.map((draft) {
                              final draftCategoryColor =
                                  TaskCategoryStyles.containerColor(
                                    context,
                                    draft.operationType.category,
                                  );
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: scheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: scheme.outlineVariant,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
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
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    // Task-specific note
                                    TextFormField(
                                      controller: _getDraftNoteController(
                                        draft,
                                      ),
                                      decoration: const InputDecoration(
                                        labelText: 'Görev Notu',
                                        hintText:
                                            'Bu görev için özel notlar...',
                                        border: OutlineInputBorder(),
                                        isDense: true,
                                      ),
                                      maxLines: 2,
                                    ),
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
                                          label: const Text('Fotoğraf Ekle'),
                                          style: OutlinedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
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
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),

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
                              labelText: 'Plaka *',
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
                              labelText: 'Marka *',
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
                              labelText: 'Model *',
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
                  const SizedBox(height: 16),

                  // Operation-Specific Notes
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'İşlem Notları',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _paintNotesController,
                            decoration: const InputDecoration(
                              labelText: 'Boya Notları',
                              hintText: 'Boya işlemleri için özel notlar...',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.format_paint),
                            ),
                            maxLines: 3,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _bodyRepairNotesController,
                            decoration: const InputDecoration(
                              labelText: 'Kaporta Notları',
                              hintText: 'Kaporta işlemleri için özel notlar...',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.handyman),
                            ),
                            maxLines: 3,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _otherNotesController,
                            decoration: const InputDecoration(
                              labelText: 'Diğer Notlar',
                              hintText: 'Diğer işlemler için notlar...',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.note),
                            ),
                            maxLines: 3,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

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
                            controller: _generalNotesController,
                            decoration: const InputDecoration(
                              labelText: 'Genel Notlar (Opsiyonel)',
                              hintText: 'İş emri hakkında genel bilgiler...',
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 4,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

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

  Widget _buildPartList(BuildContext context) {
    final parts = _filteredParts();
    final scheme = Theme.of(context).colorScheme;

    if (parts.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Text(
          _partSearchQuery.trim().isEmpty
              ? 'Parça bulunamadı.'
              : 'Aramaya uygun parça bulunamadı.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    final entries = _buildPartListEntries(parts);
    final textTheme = Theme.of(context).textTheme;

    return SizedBox(
      height: 320,
      child: Scrollbar(
        child: ListView.builder(
          itemCount: entries.length,
          itemBuilder: (context, index) {
            final entry = entries[index];
            if (entry.isHeader) {
              return Padding(
                padding: EdgeInsets.fromLTRB(4, index == 0 ? 0 : 16, 4, 6),
                child: Text(
                  entry.label!,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: scheme.primary,
                  ),
                ),
              );
            }

            final item = entry.item!;
            final resolvedPart =
                item.part ??
                VehiclePart(
                  id: item.id,
                  displayName: item.displayName,
                  path: Path(),
                );
            final actions = _normalizedActions(_selections[item.id]);
            final hasSelection = actions.isNotEmpty;
            final previousIsHeader = index == 0
                ? true
                : entries[index - 1].isHeader;

            final tile = ListTile(
              onTap: () {
                setState(() => _selectedPartId = resolvedPart.id);
                _showPartActionSheet(resolvedPart);
              },
              selected: _selectedPartId == resolvedPart.id,
              selectedTileColor: scheme.primaryContainer.withValues(alpha: 0.2),
              title: Text(item.displayName),
              subtitle: hasSelection
                  ? Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: actions.map((action) {
                          final style = damageActionStyle(action);
                          return Chip(
                            backgroundColor:
                                style?.color.withValues(alpha: 0.2) ??
                                scheme.surfaceContainerHighest,
                            label: Text(action),
                            avatar: Icon(
                              Icons.circle,
                              size: 12,
                              color: style?.color ?? scheme.primary,
                            ),
                          );
                        }).toList(),
                      ),
                    )
                  : Text(
                      'İşlem seçilmedi',
                      style: textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (hasSelection)
                    IconButton(
                      tooltip: 'Seçimi temizle',
                      icon: const Icon(Icons.undo),
                      onPressed: () => _clearPartSelection(resolvedPart),
                    ),
                  const Icon(Icons.chevron_right),
                ],
              ),
            );

            return Column(
              children: [if (!previousIsHeader) const Divider(height: 1), tile],
            );
          },
        ),
      ),
    );
  }
}

class _PartListEntry {
  const _PartListEntry.header(this.label) : item = null, isHeader = true;

  const _PartListEntry.part(this.item) : label = null, isHeader = false;

  final String? label;
  final _PartListItem? item;
  final bool isHeader;
}

class _PartListItem {
  const _PartListItem({required this.id, required this.displayName, this.part});

  final String id;
  final String displayName;
  final VehiclePart? part;
}
