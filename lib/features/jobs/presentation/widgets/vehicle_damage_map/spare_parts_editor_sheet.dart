/// Yedek Parça Editörü Bottom Sheet
///
/// Seçilmiş bir araç parçası için:
/// - Varsayılan yedek parça listesini gösterir
/// - Kullanıcının parça eklemesine, silmesine ve düzenlemesine izin verir
/// - Her parça için: ad, parça kodu, adet, tedarik kaynağı, not

import 'package:flutter/material.dart';
import 'package:vehicle_damage_map/vehicle_damage_map.dart';

/// Yedek parça editörü — araç parçası seçildiğinde alt sayfa olarak gösterilir.
///
/// [partId] ile parçanın varsayılan yedek parçaları yüklenir.
/// Kullanıcı ekleyip çıkarabilir, kaydet'e basınca güncellenmiş liste döner.
class SparePartsEditorSheet extends StatefulWidget {
  const SparePartsEditorSheet({
    super.key,
    required this.partId,
    required this.partName,
    this.initialSpareParts,
  });

  final String partId;
  final String partName;

  /// Önceden girilmiş yedek parçalar (null ise varsayılanlar kullanılır).
  final List<SparePartItem>? initialSpareParts;

  @override
  State<SparePartsEditorSheet> createState() => _SparePartsEditorSheetState();
}

class _SparePartsEditorSheetState extends State<SparePartsEditorSheet> {
  late List<SparePartItem> _items;

  @override
  void initState() {
    super.initState();
    if (widget.initialSpareParts != null) {
      _items = List.from(widget.initialSpareParts!);
    } else {
      // Varsayılan yedek parçaları registry'den al
      final def = VehiclePartsRegistry.byId(widget.partId);
      _items = List.from(def?.spareParts ?? const []);
    }
  }

  void _addItem() async {
    final result = await showDialog<SparePartItem>(
      context: context,
      builder: (_) => const _SparePartDialog(),
    );
    if (result != null && mounted) {
      setState(() => _items.add(result));
    }
  }

  void _editItem(int index) async {
    final result = await showDialog<SparePartItem>(
      context: context,
      builder: (_) => _SparePartDialog(initial: _items[index]),
    );
    if (result != null && mounted) {
      setState(() => _items[index] = result);
    }
  }

  void _removeItem(int index) {
    setState(() => _items.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return SafeArea(
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // — Başlık —
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.partName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Yedek Parçalar',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _addItem,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Parça Ekle'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.check),
                    tooltip: 'Kaydet',
                    onPressed: () => Navigator.of(context).pop(_items),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // — Liste —
            Flexible(
              child: _items.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.inventory_2_outlined,
                              size: 48,
                              color: scheme.onSurfaceVariant.withAlpha(100),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Henüz yedek parça eklenmedi.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 8),
                            FilledButton.tonalIcon(
                              onPressed: _addItem,
                              icon: const Icon(Icons.add),
                              label: const Text('Parça Ekle'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.only(bottom: 8),
                      itemCount: _items.length,
                      itemBuilder: (context, index) {
                        final item = _items[index];
                        return _SparePartTile(
                          item: item,
                          onEdit: () => _editItem(index),
                          onDelete: () => _removeItem(index),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tek parça satırı
// ---------------------------------------------------------------------------

class _SparePartTile extends StatelessWidget {
  const _SparePartTile({
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });

  final SparePartItem item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isInsurance = item.supplySource == PartSupplySource.sigorta;

    return ListTile(
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: isInsurance
            ? scheme.primaryContainer
            : scheme.tertiaryContainer,
        child: Icon(
          isInsurance ? Icons.shield_outlined : Icons.store_outlined,
          size: 16,
          color: isInsurance
              ? scheme.onPrimaryContainer
              : scheme.onTertiaryContainer,
        ),
      ),
      title: Text(item.name),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (item.partCode != null && item.partCode!.isNotEmpty)
            Text(
              'Kod: ${item.partCode}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: scheme.primary,
                fontFamily: 'monospace',
              ),
            ),
          Row(
            children: [
              Text(
                isInsurance ? 'Sigorta tedariği' : 'Kendi alım',
                style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
              ),
              const Text(' · ', style: TextStyle(fontSize: 11)),
              Text(
                '${item.quantity} adet',
                style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
              ),
            ],
          ),
          if (item.notes != null && item.notes!.isNotEmpty)
            Text(
              item.notes!,
              style: TextStyle(
                fontSize: 11,
                color: scheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
      isThreeLine: item.notes != null && item.notes!.isNotEmpty,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20),
            tooltip: 'Düzenle',
            onPressed: onEdit,
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, size: 20, color: scheme.error),
            tooltip: 'Sil',
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Parça ekleme / düzenleme dialog'u
// ---------------------------------------------------------------------------

class _SparePartDialog extends StatefulWidget {
  const _SparePartDialog({this.initial});

  /// Düzenleme modunda mevcut parça, ekleme modunda null.
  final SparePartItem? initial;

  @override
  State<_SparePartDialog> createState() => _SparePartDialogState();
}

class _SparePartDialogState extends State<_SparePartDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _codeCtrl;
  late final TextEditingController _notesCtrl;
  late final TextEditingController _quantityCtrl;
  late PartSupplySource _supplySource;

  @override
  void initState() {
    super.initState();
    final item = widget.initial;
    _nameCtrl = TextEditingController(text: item?.name ?? '');
    _codeCtrl = TextEditingController(text: item?.partCode ?? '');
    _notesCtrl = TextEditingController(text: item?.notes ?? '');
    _quantityCtrl = TextEditingController(
      text: (item?.quantity ?? 1).toString(),
    );
    _supplySource = item?.supplySource ?? PartSupplySource.sigorta;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    _notesCtrl.dispose();
    _quantityCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final item = SparePartItem(
      name: _nameCtrl.text.trim(),
      supplySource: _supplySource,
      quantity: int.tryParse(_quantityCtrl.text.trim()) ?? 1,
      partCode: _codeCtrl.text.trim().isEmpty ? null : _codeCtrl.text.trim(),
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    );
    Navigator.of(context).pop(item);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initial != null;
    return AlertDialog(
      title: Text(isEditing ? 'Parça Düzenle' : 'Yedek Parça Ekle'),
      content: SizedBox(
        width: 360,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Parça adı
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Parça Adı *',
                    hintText: 'örn. Kaput Paneli',
                    prefixIcon: Icon(Icons.inventory_2_outlined),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Parça adı gerekli'
                      : null,
                ),
                const SizedBox(height: 12),
                // Parça kodu
                TextFormField(
                  controller: _codeCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Parça Kodu',
                    hintText: 'örn. 53301-07090',
                    prefixIcon: Icon(Icons.qr_code_outlined),
                  ),
                  textCapitalization: TextCapitalization.characters,
                ),
                const SizedBox(height: 12),
                // Adet
                TextFormField(
                  controller: _quantityCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Adet',
                    prefixIcon: Icon(Icons.numbers_outlined),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    final n = int.tryParse(v?.trim() ?? '');
                    if (n == null || n < 1) return 'Geçerli bir adet girin';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Tedarik kaynağı
                Text(
                  'Tedarik Kaynağı',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                const SizedBox(height: 6),
                SegmentedButton<PartSupplySource>(
                  segments: const [
                    ButtonSegment(
                      value: PartSupplySource.sigorta,
                      label: Text('Sigorta'),
                      icon: Icon(Icons.shield_outlined, size: 16),
                    ),
                    ButtonSegment(
                      value: PartSupplySource.kendi,
                      label: Text('Kendi Alım'),
                      icon: Icon(Icons.store_outlined, size: 16),
                    ),
                  ],
                  selected: {_supplySource},
                  onSelectionChanged: (s) =>
                      setState(() => _supplySource = s.first),
                ),
                const SizedBox(height: 12),
                // Not
                TextFormField(
                  controller: _notesCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Not',
                    hintText: 'Ek açıklama...',
                    prefixIcon: Icon(Icons.notes_outlined),
                  ),
                  minLines: 1,
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('İptal'),
        ),
        FilledButton(
          onPressed: _save,
          child: Text(isEditing ? 'Güncelle' : 'Ekle'),
        ),
      ],
    );
  }
}
