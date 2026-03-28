import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:is_takip/core/widgets/platform_image.dart';
import 'package:is_takip/core/widgets/section_card.dart';
import 'package:vehicle_damage_map/vehicle_damage_map.dart'
    show
        VehiclePartSelections,
        VehiclePartsRegistry,
        canonicalDamageActionKey,
        damageActionColor,
        damageActionLabel;
import '../../../models/reception_models.dart';
import '../../../services/reception_report_service.dart';

class ReceptionDetailScreen extends StatelessWidget {
  const ReceptionDetailScreen({super.key, required this.detail});

  final Map<String, dynamic> detail;

  static const Map<String, String> _labelToAction = {
    'vuruk': 'tespit:vuruk',
    'göçük': 'tespit:gocuk',
    'gocuk': 'tespit:gocuk',
    'çizik': 'tespit:cizik',
    'cizik': 'tespit:cizik',
    'sürtme': 'tespit:surtuk',
    'sürtük': 'tespit:surtuk',
    'surtme': 'tespit:surtuk',
    'surtuk': 'tespit:surtuk',
    'leke': 'tespit:leke',
    'kırık': 'tespit:kirik',
    'kirik': 'tespit:kirik',
  };

  String _formatDate(dynamic raw) {
    if (raw == null) return '-';
    try {
      final dt = DateTime.parse(raw.toString());
      return DateFormat('dd.MM.yyyy HH:mm', 'tr_TR').format(dt.toLocal());
    } catch (_) {
      return raw.toString();
    }
  }

  String _normalizeActionOrLabel(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return value;

    if (value.contains(':')) return canonicalDamageActionKey(value);

    final key = _labelToAction[value.toLowerCase()];
    if (key != null) return canonicalDamageActionKey(key);

    return value;
  }

  String _formatFallbackId(String rawId) {
    final clean = rawId.trim();
    if (clean.isEmpty) return 'Genel';

    return clean
        .replaceAll('-', ' ')
        .replaceAll('_', ' ')
        .split(' ')
        .where((p) => p.isNotEmpty)
        .map((p) => p[0].toUpperCase() + p.substring(1))
        .join(' ');
  }

  String _displayPartName({String? partName, String? partId}) {
    final id = (partId ?? '').trim();

    if (id.isNotEmpty) {
      final byId = VehiclePartsRegistry.byId(id);
      if (byId != null) return byId.name;
    }

    final name = (partName ?? '').trim();
    if (name.isNotEmpty && !name.contains(':')) {
      final byName = VehiclePartsRegistry.byId(name);
      if (byName != null) return byName.name;

      final looksTechnical =
          name.contains('-') || name.contains('_') || name.startsWith('path');
      if (!looksTechnical) return name;

      final byTechnicalName = VehiclePartsRegistry.byId(name);
      if (byTechnicalName != null) return byTechnicalName.name;

      return _formatFallbackId(name);
    }

    if (id.isNotEmpty) return _formatFallbackId(id);
    return 'Genel';
  }

  Color _chipColor(String actionOrLabel) {
    final normalized = _normalizeActionOrLabel(actionOrLabel);
    return damageActionColor(normalized) ?? Colors.blueGrey;
  }

  String _chipLabel(String actionOrLabel) {
    final normalized = _normalizeActionOrLabel(actionOrLabel);
    if (normalized.contains(':')) {
      return damageActionLabel(normalized);
    }
    return actionOrLabel;
  }

  String? _readString(Map<String, dynamic> source, List<String> keys) {
    for (final key in keys) {
      final value = source[key];
      if (value is String && value.trim().isNotEmpty) {
        return value;
      }
    }
    return null;
  }

  List<String> _toStringList(dynamic value) {
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return const [];
  }

  Map<String, List<String>> _extractSelections() {
    final raw = detail['selections'];
    if (raw is! Map) return const {};

    final normalized = <String, List<String>>{};
    raw.forEach((key, value) {
      final partKey = key.toString();
      final actions = _toStringList(value);
      if (actions.isNotEmpty) {
        normalized[partKey] = actions;
      }
    });
    return normalized;
  }

  List<Map<String, dynamic>> _extractPhotos() {
    final rawPhotos = detail['photos'] ?? detail['receptionPhotos'];
    if (rawPhotos is! List) return const [];

    return rawPhotos.whereType<Map>().map((item) {
      final rawMap = Map<String, dynamic>.from(item);
      final originalPath =
          _readString(rawMap, const ['original_path', 'originalPath']) ?? '';
      final annotatedPath = _readString(rawMap, const [
        'annotated_path',
        'annotatedPath',
      ]);
      final partId = _readString(rawMap, const ['part_id', 'partId']);
      final partName = _readString(rawMap, const ['part_name', 'partName']);
      final note = _readString(rawMap, const ['note']);
      final damageTypes = _toStringList(
        rawMap['damage_types'] ?? rawMap['damageTypes'],
      );

      return {
        'original_path': originalPath,
        'annotated_path': annotatedPath,
        'part_id': partId,
        'part_name': partName,
        'note': note,
        'damage_types': damageTypes,
      };
    }).toList();
  }

  String _extractNotes() {
    return _readString(detail, const ['general_notes', 'generalNotes']) ?? '';
  }

  String _extractCreatedAt() {
    final raw = detail['created_at'] ?? detail['createdAt'];
    return _formatDate(raw);
  }

  String _photoPath(Map<String, dynamic> photo) {
    final annotated =
        _readString(photo, const ['annotated_path', 'annotatedPath']) ?? '';
    if (annotated.isNotEmpty) return annotated;

    return _readString(photo, const ['original_path', 'originalPath']) ?? '';
  }

  VehiclePartSelections _pdfSelections() {
    return _extractSelections();
  }

  List<ReceptionPhoto> _pdfPhotos() {
    final rawPhotos = _extractPhotos();
    return rawPhotos.map((item) {
      final photo = item;
      final originalPath = (photo['original_path'] as String?) ?? '';
      final annotatedPath = (photo['annotated_path'] as String?)?.trim();

      return ReceptionPhoto(
        originalPath: originalPath,
        annotatedPath: (annotatedPath == null || annotatedPath.isEmpty)
            ? null
            : annotatedPath,
        note: photo['note'] as String?,
        damageTypes:
            (photo['damage_types'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        partId: photo['part_id'] as String?,
        partName: photo['part_name'] as String?,
      );
    }).toList();
  }

  Future<void> _printReport(BuildContext context) async {
    try {
      await ReceptionReportService.generateAndShowReport(
        plate: (detail['plate'] as String?) ?? '-',
        brand: (detail['brand'] as String?) ?? '-',
        model: (detail['model'] as String?) ?? '-',
        selections: _pdfSelections(),
        photos: _pdfPhotos(),
        generalNotes: _readString(detail, const [
          'general_notes',
          'generalNotes',
        ]),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Çıktı alınırken hata oluştu: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildMetric(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: scheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _buildDamageChip(BuildContext context, String value) {
    final color = _chipColor(value);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        _chipLabel(value),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final selections = _extractSelections();
    final photos = _extractPhotos();
    final notes = _extractNotes();
    final plate = (detail['plate'] as String?) ?? '-';
    final brand = (detail['brand'] as String?) ?? '-';
    final model = (detail['model'] as String?) ?? '-';
    final createdAt = _extractCreatedAt();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kabul Raporu'),
        actions: [
          IconButton(
            tooltip: 'Çıktı Al',
            icon: const Icon(Icons.print_outlined),
            onPressed: () => _printReport(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: scheme.primaryContainer.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.directions_car_filled,
                          color: scheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              plate,
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$brand $model',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(color: scheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildMetric(
                        context,
                        icon: Icons.calendar_today_outlined,
                        label: 'Kabul',
                        value: createdAt,
                      ),
                      _buildMetric(
                        context,
                        icon: Icons.map_outlined,
                        label: 'Bölge',
                        value: '${selections.length}',
                      ),
                      _buildMetric(
                        context,
                        icon: Icons.photo_camera_outlined,
                        label: 'Foto',
                        value: '${photos.length}',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          SectionCard(
            title: 'Hasar Tespitleri (${selections.length})',
            children: selections.isEmpty
                ? [
                    Text(
                      'Hasar kaydı bulunmuyor.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ]
                : selections.entries.map((entry) {
                    final actions = entry.value;
                    final displayPartName = _displayPartName(partId: entry.key);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHighest.withValues(
                          alpha: 0.35,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: scheme.outlineVariant),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.precision_manufacturing_outlined,
                                size: 16,
                                color: scheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  displayPartName,
                                  style: Theme.of(context).textTheme.titleSmall
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                              ),
                              Text(
                                '${actions.length}',
                                style: Theme.of(context).textTheme.labelMedium
                                    ?.copyWith(color: scheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: actions
                                .map(
                                  (action) => _buildDamageChip(context, action),
                                )
                                .toList(),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
          ),
          const SizedBox(height: 12),
          SectionCard(
            title: 'Fotoğraflar (${photos.length})',
            children: photos.isEmpty
                ? [
                    Text(
                      'Fotoğraf bulunmuyor.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ]
                : [
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.maxWidth;
                        final crossAxisCount = width >= 920
                            ? 3
                            : width >= 560
                            ? 2
                            : 1;

                        return GridView.builder(
                          itemCount: photos.length,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                                childAspectRatio: crossAxisCount == 1
                                    ? 1.45
                                    : 0.92,
                              ),
                          itemBuilder: (context, index) {
                            final photo = photos[index];
                            final partName = _displayPartName(
                              partName: photo['part_name'] as String?,
                              partId: photo['part_id'] as String?,
                            );
                            final typeList = _toStringList(
                              photo['damage_types'],
                            );
                            final note =
                                (photo['note'] as String?)?.trim() ?? '';
                            final path = _photoPath(photo);

                            return Card(
                              clipBehavior: Clip.antiAlias,
                              elevation: 1,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: scheme.outlineVariant),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: path.isNotEmpty
                                        ? PlatformImage(
                                            path: path,
                                            fit: BoxFit.cover,
                                          )
                                        : Container(
                                            color:
                                                scheme.surfaceContainerHighest,
                                            child: const Center(
                                              child: Icon(
                                                Icons.broken_image_outlined,
                                              ),
                                            ),
                                          ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      10,
                                      8,
                                      10,
                                      10,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          partName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelLarge
                                              ?.copyWith(
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                        if (typeList.isNotEmpty) ...[
                                          const SizedBox(height: 6),
                                          Wrap(
                                            spacing: 4,
                                            runSpacing: 4,
                                            children: typeList
                                                .map(
                                                  (type) => _buildDamageChip(
                                                    context,
                                                    type,
                                                  ),
                                                )
                                                .toList(),
                                          ),
                                        ],
                                        if (note.isNotEmpty) ...[
                                          const SizedBox(height: 6),
                                          Text(
                                            note,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color:
                                                      scheme.onSurfaceVariant,
                                                ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
          ),
          if (notes.isNotEmpty) ...[
            const SizedBox(height: 12),
            SectionCard(
              title: 'Genel Notlar',
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest.withValues(
                      alpha: 0.55,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(notes),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
