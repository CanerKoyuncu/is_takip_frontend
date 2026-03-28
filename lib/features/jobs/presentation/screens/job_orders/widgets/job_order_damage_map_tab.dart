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
                      initialSelections: selectedDamages,
                      availableActions: workOrderDamageOperations,
                      onSelectionsChanged: (updated) {
                        damageProvider.updateDamageReportDraft(
                          widget.jobOrderId,
                          updated,
                        );
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

  Color _getActionColorInList(String action) {
    return damageActionColor(action) ?? Colors.grey;
  }

  /// Seçilen hasarları liste olarak göster
  List<Widget> _buildDamageItems(
    Map<String, List<String>> damages,
    DamageReportProvider provider,
  ) {
    return damages.entries.map((entry) {
      final partConfig = VehiclePartsRegistry.byId(entry.key);
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
                          label: Text(_getActionLabelInList(action)),
                          visualDensity: VisualDensity.compact,
                          backgroundColor: _getActionColorInList(action),
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

  /// Hasar raporunu kaydet
  void _saveDamageReport(DamageReportProvider provider) {
    provider.saveDamageReport(
      widget.jobOrderId,
      onSuccess: (report) {
        if (!mounted) return;
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
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $error'), backgroundColor: Colors.red),
        );
      },
    );
  }

  String _getActionLabelInList(String action) {
    return damageActionLabel(action);
  }
}
