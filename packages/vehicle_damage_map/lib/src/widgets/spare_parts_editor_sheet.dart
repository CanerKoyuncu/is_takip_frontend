import 'package:flutter/material.dart';
import '../models/vehicle_config.dart';

/// Bottom sheet for editing spare parts of a vehicle component.
class SparePartsEditorSheet extends StatefulWidget {
  const SparePartsEditorSheet({
    super.key,
    required this.partId,
    required this.partName,
    this.initialSpareParts,
  });

  final String partId;
  final String partName;

  /// Pre-filled spare parts list. If null, use defaults from registry.
  final List<SparePartItem>? initialSpareParts;

  @override
  State<SparePartsEditorSheet> createState() => _SparePartsEditorSheetState();
}

class _SparePartsEditorSheetState extends State<SparePartsEditorSheet> {
  late List<SparePartItem> _items;
  late List<SparePartItem> _suggestions;

  @override
  void initState() {
    super.initState();
    _items = widget.initialSpareParts != null
        ? List.from(widget.initialSpareParts!)
        : [];

    final def = VehiclePartsRegistry.byId(widget.partId);
    _suggestions = List.from(def?.spareParts ?? const []);

    // Filter out suggestions that are already in items
    _filterSuggestions();
  }

  void _filterSuggestions() {
    setState(() {
      _suggestions.removeWhere(
        (s) => _items.any((item) => item.name == s.name),
      );
    });
  }

  void _addItem() async {
    final result = await showDialog<SparePartItem>(
      context: context,
      builder: (_) => const _SparePartDialog(),
    );
    if (result != null && mounted) {
      setState(() => _items.add(result));
      _filterSuggestions();
    }
  }

  void _editItem(int index) async {
    final result = await showDialog<SparePartItem>(
      context: context,
      builder: (_) => _SparePartDialog(initial: _items[index]),
    );
    if (result != null && mounted) {
      setState(() => _items[index] = result);
      _filterSuggestions();
    }
  }

  void _removeItem(int index) {
    setState(() => _items.removeAt(index));

    // Re-check suggestions if a default part was removed
    final def = VehiclePartsRegistry.byId(widget.partId);
    final defaults = def?.spareParts ?? const [];
    for (final d in defaults) {
      if (!_suggestions.any((s) => s.name == d.name) &&
          !_items.any((item) => item.name == d.name)) {
        _suggestions.add(d);
      }
    }
    setState(() {});
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
            // — Header —
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

            // — List —
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

            // — Suggestions —
            if (_suggestions.isNotEmpty) ...[
              const Divider(height: 1),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Önerilen Parçalar',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: scheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: _suggestions.map((s) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ActionChip(
                              avatar: Icon(
                                s.supplySource == PartSupplySource.sigorta
                                    ? Icons.shield_outlined
                                    : Icons.store_outlined,
                                size: 14,
                                color: scheme.primary,
                              ),
                              label: Text(
                                s.name,
                                style: const TextStyle(fontSize: 12),
                              ),
                              onPressed: () {
                                setState(() {
                                  _items.add(s);
                                  _suggestions.remove(s);
                                });
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

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

class _SparePartDialog extends StatefulWidget {
  const _SparePartDialog({this.initial});

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
