import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/job_models.dart';
import '../../models/vehicle_area.dart';
import '../../providers/jobs_provider.dart';
import 'package:vehicle_damage_map/vehicle_damage_map.dart'
    show SparePartItem, PartSupplySource, VehicleAreaX;
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../core/widgets/error_state.dart';
import 'package:go_router/go_router.dart';

class SupplyScreen extends StatefulWidget {
  const SupplyScreen({super.key});

  @override
  State<SupplyScreen> createState() => _SupplyScreenState();
}

class _SupplyScreenState extends State<SupplyScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  PartSupplySource? _filterSource;

  @override
  void initState() {
    super.initState();
    // Ensure jobs are loaded
    Future.microtask(() {
      context.read<JobsProvider>().loadJobs();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Parça Tedarik Takibi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<JobsProvider>().loadJobs(),
          ),
        ],
      ),
      body: Consumer<JobsProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.jobs.isEmpty) {
            return const LoadingIndicator();
          }

          if (provider.errorMessage != null && provider.jobs.isEmpty) {
            return ErrorState(
              message: provider.errorMessage!,
              onRetry: () => provider.loadJobs(),
            );
          }

          // Extract all spare parts from all jobs
          final List<_SparePartWithJob> allParts = [];
          for (final job in provider.jobs) {
            for (final task in job.tasks) {
              for (final part in task.spareParts) {
                allParts.add(
                  _SparePartWithJob(part: part, job: job, task: task),
                );
              }
            }
          }

          // Apply filters
          final filteredParts = allParts.where((item) {
            final matchesQuery =
                _searchQuery.isEmpty ||
                item.part.name.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ||
                (item.part.partCode?.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ) ??
                    false) ||
                item.job.vehicle.plate.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                );

            final matchesSource =
                _filterSource == null ||
                item.part.supplySource == _filterSource;

            return matchesQuery && matchesSource;
          }).toList();

          // Sort by date (descending)
          filteredParts.sort(
            (a, b) => b.job.createdAt.compareTo(a.job.createdAt),
          );

          return Column(
            children: [
              // Search and Filter Bar
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Parça adı, kod veya plaka ile ara...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  setState(() {
                                    _searchController.clear();
                                    _searchQuery = '';
                                  });
                                },
                              )
                            : null,
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          FilterChip(
                            label: const Text('Tümü'),
                            selected: _filterSource == null,
                            onSelected: (selected) {
                              if (selected)
                                setState(() => _filterSource = null);
                            },
                          ),
                          const SizedBox(width: 8),
                          FilterChip(
                            label: const Text('Sigorta'),
                            selected: _filterSource == PartSupplySource.sigorta,
                            onSelected: (selected) {
                              setState(
                                () => _filterSource = selected
                                    ? PartSupplySource.sigorta
                                    : null,
                              );
                            },
                          ),
                          const SizedBox(width: 8),
                          FilterChip(
                            label: const Text('Kendi Tedariğimiz'),
                            selected: _filterSource == PartSupplySource.kendi,
                            onSelected: (selected) {
                              setState(
                                () => _filterSource = selected
                                    ? PartSupplySource.kendi
                                    : null,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Parts List
              Expanded(
                child: filteredParts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inventory_2_outlined,
                              size: 64,
                              color: Colors.grey.shade300,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Aranan kriterlere uygun parça bulunamadı',
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: filteredParts.length,
                        itemBuilder: (context, index) {
                          final item = filteredParts[index];
                          return _SupplyPartCard(item: item);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SparePartWithJob {
  final SparePartItem part;
  final JobOrder job;
  final JobTask task;

  _SparePartWithJob({
    required this.part,
    required this.job,
    required this.task,
  });
}

class _SupplyPartCard extends StatelessWidget {
  const _SupplyPartCard({required this.item});

  final _SparePartWithJob item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isInsurance = item.part.supplySource == PartSupplySource.sigorta;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () => context.push('/dashboard/job-orders/${item.job.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      item.part.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isInsurance
                          ? Colors.blue.withOpacity(0.1)
                          : Colors.teal.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      isInsurance ? 'Sigorta' : 'Kendi',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isInsurance ? Colors.blue : Colors.teal,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              if (item.part.partCode != null &&
                  item.part.partCode!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'Parça Kodu: ${item.part.partCode}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
              const Divider(height: 24),
              Row(
                children: [
                  Icon(
                    Icons.directions_car_outlined,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    item.job.vehicle.plate,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${item.job.vehicle.brand} ${item.job.vehicle.model}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.assignment_outlined,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${item.task.area.label} - ${item.task.operationType.label}',
                    style: theme.textTheme.bodySmall,
                  ),
                  const Spacer(),
                  Text(
                    DateFormat('dd.MM.yyyy').format(item.job.createdAt),
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
              if (item.part.notes != null && item.part.notes!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Not: ${item.part.notes}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
