import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../providers/jobs_provider.dart';
import '../../../models/job_models.dart';
import '../../../models/vehicle_area.dart';

class JobOrdersListScreen extends StatefulWidget {
  const JobOrdersListScreen({super.key});

  @override
  State<JobOrdersListScreen> createState() => _JobOrdersListScreenState();
}

class _JobOrdersListScreenState extends State<JobOrdersListScreen> {
  final _searchController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate = DateTime.now();
  bool _showFilters = true; // Varsayılan olarak açık

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _applyFilters(JobsProvider provider) async {
    await provider.refreshJobs(
      search: _searchController.text.trim().isEmpty
          ? null
          : _searchController.text.trim(),
      startDate: _startDate,
      endDate: _endDate,
    );
  }

  Future<void> _clearFilters(JobsProvider provider) async {
    setState(() {
      _searchController.clear();
      _startDate = null;
      _endDate = null;
    });
    // Varsayılan filtreleri uygula: bugün oluşturulan ve tamamlanmamış
    await provider.refreshJobs(todayOnly: true, incompleteOnly: true);
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStartDate
          ? (_startDate ?? DateTime.now())
          : (_endDate ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('tr', 'TR'),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
      // Filtreleri uygula
      final provider = context.read<JobsProvider>();
      await _applyFilters(provider);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('İş Emirleri'),
        actions: [
          IconButton(
            icon: Icon(
              _showFilters ? Icons.filter_alt : Icons.filter_alt_outlined,
            ),
            onPressed: () {
              setState(() {
                _showFilters = !_showFilters;
              });
            },
            tooltip: 'Filtreler',
          ),
        ],
      ),
      body: Consumer<JobsProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              // Filtreler
              if (_showFilters)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Arama
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          labelText: 'Ara',
                          hintText: 'Plaka, marka veya model',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                              _applyFilters(provider);
                            },
                          ),
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: (_) => setState(() {}),
                        onSubmitted: (_) => _applyFilters(provider),
                      ),
                      const SizedBox(height: 12),
                      // Tarih filtreleri
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _selectDate(context, true),
                              icon: const Icon(Icons.calendar_today, size: 18),
                              label: Text(
                                _startDate != null
                                    ? DateFormat(
                                        'dd.MM.yyyy',
                                      ).format(_startDate!)
                                    : 'Başlangıç Tarihi',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _selectDate(context, false),
                              icon: const Icon(Icons.calendar_today, size: 18),
                              label: Text(
                                _endDate != null
                                    ? DateFormat('dd.MM.yyyy').format(_endDate!)
                                    : 'Bitiş Tarihi',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Filtre butonları
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () => _applyFilters(provider),
                              icon: const Icon(Icons.search),
                              label: const Text('Filtrele'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            onPressed: () => _clearFilters(provider),
                            icon: const Icon(Icons.clear),
                            label: const Text('Temizle'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              // İş emirleri listesi
              Expanded(
                child: provider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : provider.jobs.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.assignment_outlined,
                              size: 64,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchController.text.isNotEmpty ||
                                      _startDate != null ||
                                      _endDate != null
                                  ? 'Filtrelere uygun iş emri bulunamadı'
                                  : 'Henüz iş emri bulunmuyor',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _searchController.text.isNotEmpty ||
                                      _startDate != null ||
                                      _endDate != null
                                  ? 'Filtreleri değiştirip tekrar deneyin'
                                  : 'Yeni iş emri oluşturmak için araç hasar haritasını kullanın',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async => _applyFilters(provider),
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: provider.jobs.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final job = provider.jobs[index];
                            return _JobOrderCard(job: job);
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _JobOrderCard extends StatefulWidget {
  const _JobOrderCard({required this.job});

  final JobOrder job;

  @override
  State<_JobOrderCard> createState() => _JobOrderCardState();
}

class _JobOrderCardState extends State<_JobOrderCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm');
    final job = widget.job;

    final pendingTasks = job.tasks
        .where((task) => task.status == JobTaskStatus.pending)
        .length;
    final inProgressTasks = job.tasks
        .where((task) => task.status == JobTaskStatus.inProgress)
        .length;
    final completedTasks = job.tasks
        .where((task) => task.status == JobTaskStatus.completed)
        .length;

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Üst kısım - tıklanabilir (detay sayfasına gider)
          InkWell(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            onTap: () {
              context.push('/dashboard/job-orders/${job.id}');
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${job.vehicle.brand} ${job.vehicle.model}',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              job.vehicle.plate,
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(
                                    color: scheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: job.status.toColor(context),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          job.status.label,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: job.status.onColor(context),
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _TaskStatusChip(
                        label: 'Beklemede',
                        count: pendingTasks,
                        color: scheme.surfaceContainerHighest,
                      ),
                      const SizedBox(width: 8),
                      _TaskStatusChip(
                        label: 'Devam Ediyor',
                        count: inProgressTasks,
                        color: scheme.primaryContainer,
                      ),
                      const SizedBox(width: 8),
                      _TaskStatusChip(
                        label: 'Tamamlandı',
                        count: completedTasks,
                        color: scheme.secondaryContainer,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.task_outlined,
                        size: 14,
                        color: scheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${job.tasks.length} görev',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        dateFormat.format(job.createdAt),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Genişletilebilir görev listesi
          if (job.tasks.isNotEmpty)
            ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 16),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              leading: Icon(Icons.list, size: 20, color: scheme.primary),
              title: Text(
                'Görevleri Görüntüle (${job.tasks.length})',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              trailing: Icon(
                _isExpanded ? Icons.expand_less : Icons.expand_more,
                color: scheme.primary,
              ),
              onExpansionChanged: (expanded) {
                setState(() {
                  _isExpanded = expanded;
                });
              },
              children: job.tasks.map((task) {
                return _TaskListItem(task: task, jobId: job.id);
              }).toList(),
            ),
        ],
      ),
    );
  }
}

class _TaskListItem extends StatelessWidget {
  const _TaskListItem({required this.task, required this.jobId});

  final JobTask task;
  final String jobId;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () {
        // Görev yönetimi sayfasına git
        context.push('/dashboard/job-orders/$jobId/tasks');
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withOpacity(0.5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: scheme.outlineVariant, width: 1),
        ),
        child: Row(
          children: [
            // Görev ikonu
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: task.status.toColor(context),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                task.operationType.icon,
                size: 20,
                color: task.status.onColor(context),
              ),
            ),
            const SizedBox(width: 12),
            // Görev bilgileri
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.area.label,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    task.operationType.label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  if (task.assignedWorkerId != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.person_outline,
                          size: 12,
                          color: scheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          task.assignedWorkerName ??
                              'Personel ID: ${task.assignedWorkerId}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ],
                  if (task.note != null && task.note!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      task.note!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Durum chip'i
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: task.status.toColor(context),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                task.status.label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: task.status.onColor(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskStatusChip extends StatelessWidget {
  const _TaskStatusChip({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (count == 0) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$count $label',
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w500),
      ),
    );
  }
}
