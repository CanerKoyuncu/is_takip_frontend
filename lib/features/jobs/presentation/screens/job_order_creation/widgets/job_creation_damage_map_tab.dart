import 'package:flutter/material.dart';
import 'package:is_takip/features/jobs/providers/damage_report_provider.dart';
import 'package:provider/provider.dart';
import 'package:vehicle_damage_map/vehicle_damage_map.dart';

/// İş Emri Oluşturma - Hasar Haritası Sekmesi
///
/// Yeni iş emri oluştururken araç hasarlarını tanımlamak için kullanılır.
class JobCreationDamageMapTab extends StatefulWidget {
  const JobCreationDamageMapTab({super.key, required this.jobId});

  final String jobId;

  @override
  State<JobCreationDamageMapTab> createState() =>
      _JobCreationDamageMapTabState();
}

class _JobCreationDamageMapTabState extends State<JobCreationDamageMapTab> {
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DamageReportProvider>(
      builder: (context, damageProvider, _) {
        final draft = damageProvider.getDamageReportDraftForJob(widget.jobId);
        final selectedDamages = draft.damages;

        return SingleChildScrollView(
          child: Column(
            children: [
              // Info Card
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  border: Border.all(color: Colors.blue.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Hasarlı bölgeleri harita üzerinde seçiniz',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

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

              // Seçilen Hasarlar Özeti
              if (selectedDamages.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Seçilen Hasarlar (${selectedDamages.length})',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${_getTotalActions(selectedDamages)} işlem',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
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
                      'Hasar Notları (Opsiyonel)',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _notesController,
                      maxLines: 4,
                      onChanged: (value) {
                        damageProvider.updateDamageReportDraftNote(
                          widget.jobId,
                          value,
                        );
                      },
                      decoration: InputDecoration(
                        hintText:
                            'Hasar hakkında ek notlarınız (örn: hasar derinliği, göz ile görülüyor vb.)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                    ),
                  ],
                ),
              ),

              // Aksiyon Butonları
              if (selectedDamages.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            damageProvider.deleteDamageReportDraft(
                              widget.jobId,
                            );
                            _notesController.clear();
                          },
                          child: const Text('Seçimi Temizle'),
                        ),
                      ),
                    ],
                  ),
                ),

              // Empty State
              if (selectedDamages.isEmpty)
                Container(
                  padding: const EdgeInsets.all(48),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 48,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Henüz hasar seçilmedi',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 16,
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
            color: Colors.grey.shade50,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      partName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 4,
                      children: actions.map((action) {
                        return Chip(
                          label: Text(_getActionLabel(action)),
                          visualDensity: VisualDensity.compact,
                          backgroundColor: _getActionColor(action),
                          labelStyle: const TextStyle(fontSize: 11),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  _showDamageActionDialog(entry.key, provider);
                },
                iconSize: 20,
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  provider.updatePartDamage(widget.jobId, entry.key, []);
                },
                iconSize: 20,
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  /// Toplam aksiyon sayısını hesapla
  int _getTotalActions(Map<String, List<String>> damages) {
    int total = 0;
    for (final actions in damages.values) {
      total += actions.length;
    }
    return total;
  }

  /// Hasar aksiyon dialog'unu göster
  Future<void> _showDamageActionDialog(
    String partId,
    DamageReportProvider provider,
  ) async {
    final config = VehiclePartsConfig.getPartById(partId);
    if (config == null) return;

    final draft = provider.getDamageReportDraftForJob(widget.jobId);
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
      provider.updatePartDamage(widget.jobId, partId, selected);
    }
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
                color: Colors.blue.shade50,
                border: Border(bottom: BorderSide(color: Colors.blue.shade200)),
              ),
              child: Row(
                children: [
                  Icon(Icons.auto_fix_high, color: Colors.blue.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.partName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Bu parçaya uygulanacak işlemleri seçin',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: widget.allowedActions.map((action) {
                  return CheckboxListTile(
                    title: Text(_getActionLabel(action)),
                    subtitle: Text(_getActionDescription(action)),
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

  String _getActionDescription(String action) {
    switch (action) {
      case 'boya':
        return 'Hasarlı bölgeye boya işlemi';
      case 'kaporta':
        return 'Kapı, kaput gibi parçaların değiştirilmesi';
      case 'degisim':
        return 'Parçanın tamamen değiştirilmesi';
      case 'temizle':
        return 'Hasara bağlı temizlik işlemi';
      default:
        return '';
    }
  }
}
