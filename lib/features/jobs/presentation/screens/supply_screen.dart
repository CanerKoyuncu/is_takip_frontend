import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/job_models.dart';
import '../../providers/jobs_provider.dart';
import 'package:vehicle_damage_map/vehicle_damage_map.dart'
    show PartSupplySource, PartSupplyStatus, PartSupplyStatusX;
import '../../../../core/widgets/loading_indicator.dart';
import 'package:go_router/go_router.dart';

class SupplyScreen extends StatefulWidget {
  const SupplyScreen({super.key});

  @override
  State<SupplyScreen> createState() => _SupplyScreenState();
}

class _SupplyScreenState extends State<SupplyScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  TabController? _tabController;
  List<SupplyPartListItem> _parts = const [];
  bool _loading = false;

  PartSupplyStatus get _currentStatus {
    final index = _tabController?.index ?? 0;
    switch (index) {
      case 0:
        return PartSupplyStatus.beklemede;
      case 1:
        return PartSupplyStatus.siparisEdildi;
      case 2:
        return PartSupplyStatus.geldi;
      case 3:
      default:
        return PartSupplyStatus.takildi;
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController?.addListener(() {
      if (!(_tabController?.indexIsChanging ?? false)) {
        _loadParts();
      }
    });
    Future.microtask(_loadParts);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Parça Tedarik Takibi'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Bekleyen'),
            Tab(text: 'Siparişte'),
            Tab(text: 'Serviste'),
            Tab(text: 'Takılan'),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadParts),
        ],
      ),
      body: Column(
        children: [
          _buildSearchHeader(),
          Expanded(
            child: _loading
                ? const LoadingIndicator()
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildPartList(_parts),
                      _buildPartList(_parts),
                      _buildPartList(_parts),
                      _buildPartList(_parts),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadParts() async {
    if (!mounted) return;

    setState(() => _loading = true);
    try {
      final parts = await context.read<JobsProvider>().getSpareParts(
        search: _searchQuery,
        status: _currentStatus,
      );
      if (!mounted) return;
      setState(() => _parts = parts);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Parça listesi alınamadı')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _buildSearchHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Parça adı, kod veya plaka...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Theme.of(
            context,
          ).colorScheme.surfaceVariant.withOpacity(0.3),
        ),
        onChanged: (v) {
          setState(() => _searchQuery = v);
          _loadParts();
        },
      ),
    );
  }

  Widget _buildPartList(List<SupplyPartListItem> parts) {
    if (parts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              '${_currentStatus.label} parça bulunmuyor',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: parts.length,
      itemBuilder: (context, index) =>
          _SupplyPartCard(item: parts[index], onSaved: _loadParts),
    );
  }
}

class _SupplyPartCard extends StatelessWidget {
  const _SupplyPartCard({required this.item, required this.onSaved});
  final SupplyPartListItem item;
  final Future<void> Function() onSaved;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isInsurance = item.part.supplySource == PartSupplySource.sigorta;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          ListTile(
            onTap: () => context.push('/dashboard/job-orders/${item.jobId}'),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    item.part.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                _buildSourceBadge(isInsurance),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (item.part.partCode != null)
                  Text(
                    'Kod: ${item.part.partCode}',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontSize: 12,
                    ),
                  ),
                Text(
                  '${item.vehiclePlate} • ${item.vehicleBrand} ${item.vehicleModel}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
          if (item.part.notes != null && item.part.notes!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item.part.notes!,
                  style: const TextStyle(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildActionButton(context),
                const SizedBox(width: 8),
                IconButton.outlined(
                  onPressed: () => _showEditDialog(context),
                  icon: const Icon(Icons.edit_note, size: 20),
                  tooltip: 'Düzenle',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSourceBadge(bool isInsurance) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: (isInsurance ? Colors.blue : Colors.teal).withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        isInsurance ? 'Sigorta' : 'Kendi',
        style: TextStyle(
          color: isInsurance ? Colors.blue : Colors.teal,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context) {
    String label = '';
    IconData icon = Icons.check;
    PartSupplyStatus nextStatus = item.part.status;

    switch (item.part.status) {
      case PartSupplyStatus.beklemede:
        label = 'Sipariş Ver';
        icon = Icons.shopping_cart_outlined;
        nextStatus = PartSupplyStatus.siparisEdildi;
        break;
      case PartSupplyStatus.siparisEdildi:
        label = 'Geldi İşaretle';
        icon = Icons.local_shipping_outlined;
        nextStatus = PartSupplyStatus.geldi;
        break;
      case PartSupplyStatus.geldi:
        label = 'Takıldı İşaretle';
        icon = Icons.build_circle_outlined;
        nextStatus = PartSupplyStatus.takildi;
        break;
      case PartSupplyStatus.takildi:
        return const SizedBox.shrink();
    }

    return FilledButton.icon(
      onPressed: () async {
        await context.read<JobsProvider>().updateSparePartById(
          partId: item.id,
          status: nextStatus,
        );
        await onSaved();
      },
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      style: FilledButton.styleFrom(visualDensity: VisualDensity.compact),
    );
  }

  void _showEditDialog(BuildContext context) {
    final codeController = TextEditingController(text: item.part.partCode);
    final notesController = TextEditingController(text: item.part.notes);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item.part.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: codeController,
              decoration: const InputDecoration(labelText: 'Parça Kodu'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(labelText: 'Notlar'),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () async {
              await context.read<JobsProvider>().updateSparePartById(
                partId: item.id,
                partCode: codeController.text,
                notes: notesController.text,
              );
              Navigator.pop(context);
              await onSaved();
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }
}
