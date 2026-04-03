import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../services/api/reception_api_service.dart';
import '../../../utils/server_datetime_parser.dart';
import '../../../../../core/services/api_service_factory.dart';
import 'reception_detail_screen.dart';

/// Kaydedilmiş araç kabul formlarını listeleyen ekran.
class ReceptionListScreen extends StatefulWidget {
  const ReceptionListScreen({super.key});

  @override
  State<ReceptionListScreen> createState() => _ReceptionListScreenState();
}

class _ReceptionListScreenState extends State<ReceptionListScreen> {
  late final ReceptionApiService _receptionApi;
  final _searchController = TextEditingController();

  List<Map<String, dynamic>> _forms = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _receptionApi = ReceptionApiService(ApiServiceFactory.getApiService());
    _loadForms();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadForms({String? search}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await _receptionApi.listForms(search: search);
      if (mounted) {
        setState(() {
          _forms = results;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  String _formatDate(dynamic raw) {
    if (raw == null) return '-';
    try {
      final dt = ServerDateTimeParser.parseNullable(raw);
      if (dt == null) return '-';
      return DateFormat('dd.MM.yyyy HH:mm', 'tr_TR').format(dt);
    } catch (_) {
      return raw.toString();
    }
  }

  Future<void> _showDetail(String formId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final detail = await _receptionApi.getFormById(formId);
      if (!mounted) return;
      Navigator.pop(context); // dismiss spinner

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ReceptionDetailScreen(detail: detail),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Detay yüklenemedi: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Araç Kabul Geçmişi')),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Plaka, marka veya model ile ara...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _loadForms();
                        },
                      )
                    : null,
              ),
              onSubmitted: (val) => _loadForms(search: val),
              onChanged: (val) {
                // Rebuild to show/hide clear button
                setState(() {});
              },
            ),
          ),

          // Content
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: scheme.error,
                        ),
                        const SizedBox(height: 8),
                        Text(_error!, style: TextStyle(color: scheme.error)),
                        const SizedBox(height: 16),
                        FilledButton.tonal(
                          onPressed: () => _loadForms(),
                          child: const Text('Tekrar Dene'),
                        ),
                      ],
                    ),
                  )
                : _forms.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 64,
                          color: scheme.onSurfaceVariant.withValues(alpha: 0.4),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Henüz kaydedilmiş kabul formu yok',
                          style: TextStyle(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () => _loadForms(
                      search: _searchController.text.isNotEmpty
                          ? _searchController.text
                          : null,
                    ),
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      itemCount: _forms.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final form = _forms[index];
                        final plate = form['plate'] as String? ?? '';
                        final brand = form['brand'] as String? ?? '';
                        final model = form['model'] as String? ?? '';
                        final photoCount = form['photo_count'] as int? ?? 0;
                        final selectionCount =
                            form['selection_count'] as int? ?? 0;
                        final createdAt = _formatDate(form['created_at']);
                        final formId = form['id'] as String;

                        return Card(
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () => _showDetail(formId),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                children: [
                                  // Leading icon
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: scheme.primaryContainer.withValues(
                                        alpha: 0.6,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      Icons.directions_car_filled,
                                      color: scheme.onPrimaryContainer,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  // Info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          plate,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '$brand $model',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                color: scheme.onSurfaceVariant,
                                              ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.calendar_today,
                                              size: 12,
                                              color: scheme.onSurfaceVariant
                                                  .withValues(alpha: 0.6),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              createdAt,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.copyWith(
                                                    color: scheme
                                                        .onSurfaceVariant
                                                        .withValues(alpha: 0.7),
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Badges
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      if (selectionCount > 0)
                                        _buildBadge(
                                          context,
                                          Icons.map_outlined,
                                          '$selectionCount bölge',
                                          scheme.tertiary,
                                        ),
                                      const SizedBox(height: 4),
                                      if (photoCount > 0)
                                        _buildBadge(
                                          context,
                                          Icons.photo_camera_outlined,
                                          '$photoCount foto',
                                          scheme.secondary,
                                        ),
                                    ],
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.chevron_right,
                                    color: scheme.onSurfaceVariant.withValues(
                                      alpha: 0.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(
    BuildContext context,
    IconData icon,
    String label,
    Color color,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 3),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
