import 'package:flutter/material.dart';
import 'package:is_takip/features/jobs/providers/damage_report_provider.dart';
import 'package:provider/provider.dart';
import 'package:vehicle_damage_map/vehicle_damage_map.dart';

/// İş Emri Hasar Haritası Sekmesi
///
/// İş emri detay sayfasında kullanılır. Araç hasarlarını gösterir ve
/// düzenlemeler yapılmasını sağlar.
class JobOrderDamageMapTab extends StatefulWidget {
  const JobOrderDamageMapTab({super.key, required this.jobOrderId});

  final String jobOrderId;

  @override
  State<JobOrderDamageMapTab> createState() => _JobOrderDamageMapTabState();
}

class _JobOrderDamageMapTabState extends State<JobOrderDamageMapTab> {
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController();
    _loadDamageReport();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _loadDamageReport() {
    Future.microtask(() {
      if (!mounted) return;
      final provider = context.read<DamageReportProvider>();
      final draft = provider.getDamageReportDraftForJob(widget.jobOrderId);
      _notesController.text = draft.notes ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DamageReportProvider>(
      builder: (context, damageProvider, _) {
        final draft = damageProvider.getDamageReportDraftForJob(
          widget.jobOrderId,
        );
        final selectedDamages = draft.damages;

        return SingleChildScrollView(
          child: Column(
            children: [
              // Araç Hasar Haritası
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.grey.shade50,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Araç Hasar Haritası',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    VehicleDamageMap(
                      assetName: 'assets/car-cutout-grouped.svg',
                      fit: BoxFit.contain,
                      partColorMap: _getPartColorMap(selectedDamages),
                      partActionsMap: selectedDamages,
                      onPartTapped: (partId) {
                        _showDamageActionDialog(partId, damageProvider);
                      },
                    ),
                  ],
                ),
              ),

              // Seçilen Hasarlar Listesi
              if (selectedDamages.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Seçilen Hasarlar',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      ..._buildDamageItems(selectedDamages, damageProvider),
                    ],
                  ),
                ),

              // Hasar Notları
              Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hasar Notları',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _notesController,
                      maxLines: 5,
                      onChanged: (value) {
                        damageProvider.updateDamageReportDraftNote(
                          widget.jobOrderId,
                          value,
                        );
                      },
                      decoration: InputDecoration(
                        hintText: 'Hasar hakkında notlarınız...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Aksiyon Butonları
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: selectedDamages.isEmpty
                            ? null
                            : () {
                                damageProvider.deleteDamageReportDraft(
                                  widget.jobOrderId,
                                );
                              },
                        child: const Text('Temizle'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: selectedDamages.isEmpty
                            ? null
                            : () {
                                _saveDamageReport(damageProvider);
                              },
                        child: damageProvider.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Raporu Kaydet'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Parçaların renk haritasını oluştur
  Map<String, Color> _getPartColorMap(Map<String, List<String>> damages) {
    final colors = <String, Color>{};
    for (final partId in damages.keys) {
      final actions = damages[partId] ?? [];
      if (actions.isNotEmpty) {
        colors[partId] = _getActionColor(actions.first);
      }
    }
    return colors;
  }

  /// Aksiyon türüne göre renk döndür
  Color _getActionColor(String action) {
    switch (action) {
      case 'boya':
        return const Color(0xFF90CAF9); // Mavi
      case 'kaporta':
        return const Color(0xFFFFF59D); // Sarı
      case 'degisim':
        return const Color(0xFFFFCDD2); // Kırmızı
      case 'temizle':
        return const Color(0xFFC8E6C9); // Yeşil
      default:
        return Colors.grey;
    }
  }

  /// Seçilen hasarları liste olarak göster
  List<Widget> _buildDamageItems(
    Map<String, List<String>> damages,
    DamageReportProvider provider,
  ) {
    return damages.entries.map((entry) {
      final partConfig = VehiclePartsConfig.getPartById(entry.key);
      final partName = partConfig?.name ?? entry.key;
      final actions = entry.value;

      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      partName,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 4,
                      children: actions.map((action) {
                        return Chip(
                          label: Text(_getActionLabel(action)),
                          visualDensity: VisualDensity.compact,
                          backgroundColor: _getActionColor(action),
                          labelStyle: const TextStyle(fontSize: 12),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  provider.updatePartDamage(widget.jobOrderId, entry.key, []);
                },
                iconSize: 20,
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  /// Hasar aksiyon dialog'unu göster
  Future<void> _showDamageActionDialog(
    String partId,
    DamageReportProvider provider,
  ) async {
    final config = VehiclePartsConfig.getPartById(partId);
    if (config == null) return;

    final draft = provider.getDamageReportDraftForJob(widget.jobOrderId);
    final currentActions = draft.damages[partId] ?? [];

    if (!mounted) return;

    final selected = await showDialog<List<String>>(
      context: context,
      builder: (context) => _DamageActionDialog(
        partName: config.name,
        allowedActions: config.allowedActions,
        selectedActions: currentActions,
      ),
    );

    if (selected != null && mounted) {
      provider.updatePartDamage(widget.jobOrderId, partId, selected);
    }
  }

  /// Hasar raporunu kaydet
  void _saveDamageReport(DamageReportProvider provider) {
    provider.saveDamageReport(
      widget.jobOrderId,
      onSuccess: (report) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Hasar raporu kaydedildi: ${report.damages.length} parça',
            ),
            backgroundColor: Colors.green,
          ),
        );
      },
      onError: (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $error'), backgroundColor: Colors.red),
        );
      },
    );
  }

  String _getActionLabel(String action) {
    switch (action) {
      case 'boya':
        return 'Boya';
      case 'kaporta':
        return 'Kaporta';
      case 'degisim':
        return 'Değişim';
      case 'temizle':
        return 'Temizle';
      default:
        return action;
    }
  }
}

/// Hasar Aksiyonu Seçim Dialog'u
class _DamageActionDialog extends StatefulWidget {
  const _DamageActionDialog({
    required this.partName,
    required this.allowedActions,
    required this.selectedActions,
  });

  final String partName;
  final List<String> allowedActions;
  final List<String> selectedActions;

  @override
  State<_DamageActionDialog> createState() => _DamageActionDialogState();
}

class _DamageActionDialogState extends State<_DamageActionDialog> {
  late Set<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.selectedActions.toSet();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Text(
                widget.partName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: widget.allowedActions.map((action) {
                  return CheckboxListTile(
                    title: Text(_getActionLabel(action)),
                    value: _selected.contains(action),
                    onChanged: (value) {
                      setState(() {
                        if (value ?? false) {
                          _selected.add(action);
                        } else {
                          _selected.remove(action);
                        }
                      });
                    },
                    contentPadding: EdgeInsets.zero,
                  );
                }).toList(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('İptal'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, _selected.toList()),
                    child: const Text('Seç'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getActionLabel(String action) {
    switch (action) {
      case 'boya':
        return 'Boya';
      case 'kaporta':
        return 'Kaporta';
      case 'degisim':
        return 'Parça Değişim';
      case 'temizle':
        return 'Temizle';
      default:
        return action;
    }
  }
}
