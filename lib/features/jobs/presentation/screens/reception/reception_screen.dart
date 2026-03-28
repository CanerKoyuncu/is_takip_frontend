import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:is_takip/core/widgets/platform_image.dart';
import 'package:vehicle_damage_map/vehicle_damage_map.dart'
    show
        VehicleDamageMap,
        VehiclePartSelections,
        DamageOperationType,
        VehiclePartsRegistry,
        damageActionLabel;
import '../../../models/reception_models.dart';
import '../../../services/job_creation_cache_service.dart';
import '../../../services/reception_report_service.dart';
import 'photo_annotation_screen.dart';

/// Araç giriş kayıt ekranı (Teslim Alma).
class VehicleReceptionScreen extends StatefulWidget {
  const VehicleReceptionScreen({super.key});

  @override
  State<VehicleReceptionScreen> createState() => _VehicleReceptionScreenState();
}

class _VehicleReceptionScreenState extends State<VehicleReceptionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _plateController = TextEditingController();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _generalNoteController = TextEditingController();

  final ImagePicker _imagePicker = ImagePicker();
  final _cacheService = JobCreationCacheService();

  List<ReceptionPhoto> _photos = [];
  VehiclePartSelections _damageSelections = {};
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
        _generalNoteController.text = draft['generalNotes'] ?? '';
        _photos = draft['receptionPhotos'] ?? [];
        _damageSelections = draft['selections'] ?? {};
        _isInitialized = true;
      });
    } else {
      setState(() => _isInitialized = true);
    }
  }

  Future<void> _saveDraft() async {
    if (!_isInitialized) return;
    await _cacheService.saveDraft(
      plate: _plateController.text,
      brand: _brandController.text,
      model: _modelController.text,
      selections: _damageSelections,
      spareParts: {},
      receptionPhotos: _photos,
      generalNotes: _generalNoteController.text,
      requiredParts: [],
    );
  }

  Future<void> _addPhoto({
    String? partId,
    String? partName,
    String? damageType,
  }) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (image == null || !mounted) return;

      // Fotoğraf çekildikten hemen sonra işaretleme ekranını aç
      final String? annotatedPath = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PhotoAnnotationScreen(
            imagePath: image.path,
            initialNote: partName != null ? '$partName - $damageType' : null,
          ),
        ),
      );

      setState(() {
        _photos.add(
          ReceptionPhoto(
            originalPath: image.path,
            annotatedPath: annotatedPath,
            partId: partId,
            partName: partName,
            damageTypes: damageType != null ? [damageType] : [],
          ),
        );
      });
      _saveDraft();
    } catch (e) {
      debugPrint('Error adding photo: $e');
    }
  }

  Future<void> _annotatePhoto(int index) async {
    final photo = _photos[index];
    final String? annotatedPath = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PhotoAnnotationScreen(
          imagePath: photo.originalPath,
          initialNote: photo.note,
        ),
      ),
    );

    if (annotatedPath != null) {
      setState(() {
        _photos[index] = photo.copyWith(annotatedPath: annotatedPath);
      });
      _saveDraft();
    }
  }

  void _editPhotoDetails(int index) async {
    final List<String> availableTypes = ReceptionPhoto.standardizedTypes;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Fotoğraf Detayları'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Hasar Türleri:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 4,
                    runSpacing: 0,
                    children: availableTypes.map((type) {
                      final isSelected = _photos[index].damageTypes.contains(
                        type,
                      );
                      return FilterChip(
                        label: Text(type),
                        selected: isSelected,
                        onSelected: (selected) {
                          setDialogState(() {
                            final currentTypes = List<String>.from(
                              _photos[index].damageTypes,
                            );
                            if (selected) {
                              currentTypes.add(type);
                            } else {
                              currentTypes.remove(type);
                            }
                            setState(() {
                              _photos[index] = _photos[index].copyWith(
                                damageTypes: currentTypes,
                              );
                            });
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Not:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  TextField(
                    controller: TextEditingController(
                      text: _photos[index].note,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Problem detayı...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                    onChanged: (val) {
                      setState(() {
                        _photos[index] = _photos[index].copyWith(note: val);
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    _saveDraft();
                    Navigator.pop(context);
                  },
                  child: const Text('KAYDET'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Araç Kaydı (Giriş)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () =>
                _cacheService.clearDraft().then((_) => _loadDraft()),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _generalNoteController,
                decoration: const InputDecoration(
                  labelText: 'Genel Notlar',
                  hintText: 'Araç teslimatı ile ilgili genel notlar...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.note_alt_outlined),
                ),
                maxLines: 2,
                onChanged: (_) => _saveDraft(),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton.icon(
                  onPressed: () => ReceptionReportService.generateAndShowReport(
                    plate: _plateController.text,
                    brand: _brandController.text,
                    model: _modelController.text,
                    selections: _damageSelections,
                    photos: _photos,
                    generalNotes: _generalNoteController.text,
                  ),
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('ARAÇ KABUL RAPORU (PDF)'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: !_isInitialized
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Vehicle Info
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _plateController,
                            decoration: const InputDecoration(
                              labelText: 'Plaka',
                            ),
                            onChanged: (_) => _saveDraft(),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _brandController,
                                  decoration: const InputDecoration(
                                    labelText: 'Marka',
                                  ),
                                  onChanged: (_) => _saveDraft(),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextFormField(
                                  controller: _modelController,
                                  decoration: const InputDecoration(
                                    labelText: 'Model',
                                  ),
                                  onChanged: (_) => _saveDraft(),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Damage Map Section
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
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              if (_damageSelections.isNotEmpty)
                                Badge(
                                  label: Text('${_damageSelections.length}'),
                                  child: const Icon(Icons.car_repair_outlined),
                                ),
                            ],
                          ),
                          const Divider(),
                          const SizedBox(height: 8),
                          Container(
                            height: 320,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceVariant
                                  .withOpacity(0.3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: VehicleDamageMap(
                                assetName: 'assets/car-cutout-grouped.svg',
                                initialSelections: _damageSelections,
                                showLegend: false,
                                showSpareParts: false,
                                availableActions: const [
                                  DamageOperationType.vuruk,
                                  DamageOperationType.cizik,
                                  DamageOperationType.surtuk,
                                  DamageOperationType.leke,
                                  DamageOperationType.kirik,
                                ],
                                onActionToggled: (partId, action, selected) {
                                  if (selected) {
                                    // Parça ismini bulup kamerayı aç
                                    final partName =
                                        VehiclePartsRegistry.byId(
                                          partId,
                                        )?.name ??
                                        partId;
                                    final damageLabel = damageActionLabel(
                                      action,
                                    );
                                    _addPhoto(
                                      partId: partId,
                                      partName: partName,
                                      damageType: damageLabel,
                                    );
                                  }
                                },
                                onSelectionsChanged: (selections) {
                                  setState(
                                    () => _damageSelections = selections,
                                  );
                                  _saveDraft();
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Hasar bölgelerini işaretlemek için dokunun.',
                            style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Photo Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Fotoğraflar (${_photos.length})',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      FilledButton.icon(
                        onPressed: () => _addPhoto(),
                        icon: const Icon(Icons.add_a_photo),
                        label: const Text('EKLE'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 0.8,
                        ),
                    itemCount: _photos.length,
                    itemBuilder: (context, index) {
                      final photo = _photos[index];
                      return Card(
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            PlatformImage(
                              path: photo.displayPath,
                              fit: BoxFit.cover,
                            ),

                            // Damage Type Badges
                            if (photo.damageTypes.isNotEmpty)
                              Positioned(
                                top: 8,
                                left: 8,
                                child: Wrap(
                                  spacing: 4,
                                  runSpacing: 4,
                                  children: photo.damageTypes.take(2).map((
                                    type,
                                  ) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.redAccent.withOpacity(
                                          0.8,
                                        ),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        type,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),

                            // Edit Overlays
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                color: Colors.black54,
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.edit,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                      onPressed: () => _annotatePhoto(index),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons
                                            .label, // Changed from note_add to label
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                      onPressed: () => _editPhotoDetails(index),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.redAccent,
                                        size: 20,
                                      ),
                                      onPressed: () {
                                        setState(() => _photos.removeAt(index));
                                        _saveDraft();
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            if (photo.note != null && photo.note!.isNotEmpty)
                              Positioned(
                                top: 4,
                                left: 4,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Icon(
                                    Icons.description,
                                    color: Colors.white,
                                    size: 12,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // General Note
                  TextFormField(
                    controller: _generalNoteController,
                    decoration: const InputDecoration(
                      labelText: 'Giriş Notları',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    onChanged: (_) => _saveDraft(),
                  ),

                  const SizedBox(height: 32),

                  // Continue to Job Creation
                  FilledButton(
                    onPressed: () => context.push('/create-job-order'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      minimumSize: const Size(double.infinity, 56),
                    ),
                    child: const Text('İŞ EMRİ OLUŞTURMAYA GEÇ'),
                  ),
                ],
              ),
            ),
    );
  }
}
