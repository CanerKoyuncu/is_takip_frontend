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
        damageActionLabel,
        damageActionColor;
import '../../../models/reception_models.dart';
import '../../../services/cache/job_creation_cache_service.dart';
import '../../../services/api/reception_api_service.dart';
import '../../../services/pdf/pdf_reception_report_service.dart';
import '../../../../../core/services/api_service_factory.dart';
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
  final _deliveredByController = TextEditingController();
  final _receivedByController = TextEditingController();
  final _defectsController = TextEditingController();

  final ImagePicker _imagePicker = ImagePicker();
  final _cacheService = JobCreationCacheService();
  late final ReceptionApiService _receptionApi;

  List<ReceptionPhoto> _photos = [];
  VehiclePartSelections _damageSelections = {};
  String? _activePartId;
  String? _activePartName;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _receptionApi = ReceptionApiService(ApiServiceFactory.getApiService());
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
        _deliveredByController.text = draft['deliveredBy'] ?? '';
        _receivedByController.text = draft['receivedBy'] ?? '';
        _defectsController.text = draft['defects'] ?? '';
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
      deliveredBy: _deliveredByController.text,
      receivedBy: _receivedByController.text,
      defects: _defectsController.text,
    );
  }

  Future<void> _addPhoto({
    String? partId,
    String? partName,
    List<String> damageTypes = const [],
    List<String> damageActions = const [],
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
            initialNote: partName,
            damageActions: damageActions,
          ),
        ),
      );

      setState(() {
        final newPhoto = ReceptionPhoto(
          originalPath: image.path,
          annotatedPath: annotatedPath,
          partId: partId,
          partName: partName,
          damageTypes: damageTypes,
        );

        // Parça bazında tek fotoğraf: aynı parçaya tekrar fotoğraf çekilirse eskisini güncelle.
        if (partId != null) {
          final existingIndex = _photos.indexWhere((p) => p.partId == partId);
          if (existingIndex >= 0) {
            _photos[existingIndex] = newPhoto;
          } else {
            _photos.add(newPhoto);
          }
        } else {
          _photos.add(newPhoto);
        }
      });
      _saveDraft();
    } catch (e) {
      debugPrint('Error adding photo: $e');
    }
  }

  List<String> _activeDamageLabels() {
    final partId = _activePartId;
    if (partId == null) return const [];

    final actions = _damageSelections[partId] ?? const [];
    return actions.map((action) => damageActionLabel(action)).toList();
  }

  List<String> _activeDamageActions() {
    final partId = _activePartId;
    if (partId == null) return const [];
    return List<String>.from(_damageSelections[partId] ?? const []);
  }

  Future<void> _completeDetectionWithPhoto() async {
    final partId = _activePartId;
    if (partId == null) return;

    final damageLabels = _activeDamageLabels();
    final damageActions = _activeDamageActions();
    if (damageLabels.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Önce seçili parça için en az bir hasar tespiti işaretleyin.',
          ),
        ),
      );
      return;
    }

    await _addPhoto(
      partId: partId,
      partName: _activePartName,
      damageTypes: damageLabels,
      damageActions: damageActions,
    );
  }

  bool _isValidServerPath(String path) {
    /// Validate that path is a valid server path (not binary/local data)
    if (path.isEmpty) return false;

    // Reject binary data, local paths, URLs
    if (path.startsWith(
      RegExp(r'^(data:|blob:|file://|http|/data|/var|/tmp|C:|\D:)'),
    )) {
      return false;
    }

    // Reject path traversal
    if (path.contains('..')) return false;

    // Accept only server paths from uploads/reception/ or reception/
    if (!path.startsWith(RegExp(r'^(uploads/reception/|reception/)'))) {
      return false;
    }

    return true;
  }

  bool _isValidPhotoId(String id) {
    final value = id.trim();
    return RegExp(r'^[a-fA-F0-9]{24}$').hasMatch(value);
  }

  Future<void> _saveReceptionForm() async {
    final plate = _plateController.text.trim();
    final brand = _brandController.text.trim();
    final model = _modelController.text.trim();

    if (plate.isEmpty || brand.isEmpty || model.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen plaka, marka ve model alanlarını doldurun.'),
        ),
      );
      return;
    }

    try {
      final uploadedPhotos = <Map<String, dynamic>>[];
      for (final photo in _photos) {
        final originalUpload = await _receptionApi.uploadReceptionPhoto(
          plate: plate,
          imagePath: photo.originalPath,
          variant: 'original',
        );

        // Validate uploaded photo id/path
        if (!_isValidPhotoId(originalUpload.photoId) ||
            !_isValidServerPath(originalUpload.path)) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Fotoğraf upload hatası: Geçersiz foto referansı'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        String? annotatedPhotoId;
        String? annotatedUploadPath;
        if (photo.annotatedPath != null &&
            photo.annotatedPath!.trim().isNotEmpty) {
          final annotatedUpload = await _receptionApi.uploadReceptionPhoto(
            plate: plate,
            imagePath: photo.annotatedPath!,
            variant: 'annotated',
          );
          annotatedPhotoId = annotatedUpload.photoId;
          annotatedUploadPath = annotatedUpload.path;

          // Validate annotated photo
          if (!_isValidPhotoId(annotatedPhotoId) ||
              !_isValidServerPath(annotatedUploadPath)) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Fotoğraf upload hatası: Invalid annotated path'),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }
        }

        // If an annotated image exists, persist it as the primary reference too.
        final effectiveOriginalPhotoId =
            annotatedPhotoId ?? originalUpload.photoId;

        uploadedPhotos.add({
          'originalPhotoId': effectiveOriginalPhotoId,
          'annotatedPhotoId': annotatedPhotoId,
          'note': photo.note,
          'damageTypes': photo.damageTypes,
          'partId': photo.partId,
          'partName': photo.partName,
        });
      }

      final insertedId = await _receptionApi.saveForm(
        plate: plate,
        brand: brand,
        model: model,
        selections: _damageSelections,
        photos: uploadedPhotos,
        generalNotes: _generalNoteController.text.trim(),
        deliveredBy: _deliveredByController.text.trim(),
        receivedBy: _receivedByController.text.trim(),
        defects: _defectsController.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kabul formu kaydedildi. Kayıt No: $insertedId'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kabul formu kaydedilemedi: $e'),
          backgroundColor: Colors.red,
        ),
      );
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
          damageActions: photo.partId != null
              ? List<String>.from(_damageSelections[photo.partId] ?? const [])
              : const [],
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
                  onPressed: () async {
                    try {
                      await ReceptionReportService.generateAndShowReport(
                        plate: _plateController.text.trim(),
                        brand: _brandController.text.trim(),
                        model: _modelController.text.trim(),
                        selections: _damageSelections,
                        photos: _photos,
                        generalNotes: _generalNoteController.text.trim(),
                        deliveredBy: _deliveredByController.text.trim(),
                        receivedBy: _receivedByController.text.trim(),
                        defects: _defectsController.text.trim(),
                      );
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('PDF oluşturulurken hata: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
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
                  const SizedBox(height: 24),

                  // Delivery Information
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Teslimat Bilgileri',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _deliveredByController,
                            decoration: const InputDecoration(
                              labelText: 'Teslim Eden (Ad Soyad)',
                              hintText:
                                  'Aracı teslim eden kişinin adı ve soyadı',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                            onChanged: (_) => _saveDraft(),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _receivedByController,
                            decoration: const InputDecoration(
                              labelText: 'Teslim Alan (Ad Soyad)',
                              hintText:
                                  'Aracı kabul eden kişinin adı ve soyadı',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                            onChanged: (_) => _saveDraft(),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _defectsController,
                            decoration: const InputDecoration(
                              labelText: 'Araç Kusurları / Hasarları',
                              hintText:
                                  'Teslim alınan araçtaki kusurları/hasarları girin (virgülle ayrılmış)',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.error_outline),
                            ),
                            maxLines: 3,
                            onChanged: (_) => _saveDraft(),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  // Vehicle Info
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Teslimat Bilgileri',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
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
                            height: 600,
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
                                showLegend: true,
                                showSpareParts: false,
                                availableActions: const [
                                  DamageOperationType.vuruk,
                                  DamageOperationType.gocuk,
                                  DamageOperationType.cizik,
                                  DamageOperationType.surtuk,
                                  DamageOperationType.leke,
                                  DamageOperationType.kirik,
                                ],
                                onPartTapped: (partId) {
                                  setState(() {
                                    _activePartId = partId;
                                    _activePartName =
                                        VehiclePartsRegistry.byId(
                                          partId,
                                        )?.name ??
                                        partId;
                                  });
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
                          if (_activePartId != null) ...[
                            const SizedBox(height: 10),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Seçili Parça: ${_activePartName ?? _activePartId}',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children:
                                  (_damageSelections[_activePartId] ?? const [])
                                      .map((action) {
                                        final color =
                                            damageActionColor(action) ??
                                            Colors.blueGrey;
                                        return Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: color.withValues(
                                              alpha: 0.25,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            border: Border.all(color: color),
                                          ),
                                          child: Text(
                                            damageActionLabel(action),
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: color,
                                            ),
                                          ),
                                        );
                                      })
                                      .toList(),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed:
                                    (_damageSelections[_activePartId]
                                            ?.isNotEmpty ??
                                        false)
                                    ? _completeDetectionWithPhoto
                                    : null,
                                icon: const Icon(Icons.check_circle_outline),
                                label: const Text(
                                  'TESPİTİ FOTOĞRAF İLE TAMAMLA',
                                ),
                              ),
                            ),
                          ],
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

                  // Continue to Job Creation
                  FilledButton(
                    onPressed: _saveReceptionForm,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      minimumSize: const Size(double.infinity, 56),
                    ),
                    child: const Text('KABUL FORMUNU KAYDET'),
                  ),

                  const SizedBox(height: 12),

                  FilledButton(
                    onPressed: () => context.goNamed('create-job-order'),
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
