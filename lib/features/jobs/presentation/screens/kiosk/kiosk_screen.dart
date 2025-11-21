/// Kiosk Modu Ana Ekranı
///
/// Kiosk modunda önce görevler listelenir, görev başlatılınca usta seçimi yapılır.
/// Plaka, marka, model bilgileri ile arama yapılabilir.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/job_models.dart';
import '../../../providers/jobs_provider.dart';
import '../../../widgets/task_list_item.dart';

class KioskScreen extends StatefulWidget {
  const KioskScreen({super.key});

  @override
  State<KioskScreen> createState() => _KioskScreenState();
}

class _KioskScreenState extends State<KioskScreen> {
  final _searchController = TextEditingController();
  List<JobTaskWithJob> _tasks = [];
  List<JobTaskWithJob> _filteredTasks = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterTasks);
    // Sayfa açıldığında direkt görevleri yükle (usta seçmeden)
    Future.microtask(() => _loadTasks());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTasks() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final provider = context.read<JobsProvider>();
      // Tüm tamamlanmamış iş emirlerini yükle
      await provider.refreshJobs(
        incompleteOnly: true,
        todayOnly: false, // Tüm tarihler
      );

      // Tüm tamamlanmamış görevleri göster (usta filtresi yok)
      final allJobs = provider.jobs;
      final tasks = <JobTaskWithJob>[];

      for (final job in allJobs) {
        for (final task in job.tasks) {
          // Sadece tamamlanmamış görevler
          if (task.status != JobTaskStatus.completed) {
            tasks.add(JobTaskWithJob(task: task, job: job));
          }
        }
      }

      setState(() {
        _tasks = tasks;
        _filteredTasks = tasks;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Görevler yüklenirken hata oluştu: $e';
        _isLoading = false;
      });
    }
  }

  void _filterTasks() {
    final query = _searchController.text.toLowerCase().trim();

    if (query.isEmpty) {
      setState(() {
        _filteredTasks = _tasks;
      });
      return;
    }

    setState(() {
      _filteredTasks = _tasks.where((item) {
        final plate = item.job.vehicle.plate.toLowerCase();
        final brand = item.job.vehicle.brand.toLowerCase();
        final model = item.job.vehicle.model.toLowerCase();

        return plate.contains(query) ||
            brand.contains(query) ||
            model.contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kiosk Modu'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Yenile',
            onPressed: _loadTasks,
          ),
        ],
      ),
      body: Column(
        children: [
          // Arama çubuğu
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Plaka, Marka veya Model ile Ara',
                hintText: 'Örn: 34ABC123, Toyota, Corolla',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          // Görev listesi
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: scheme.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: scheme.error,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _loadTasks,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Tekrar Dene'),
                        ),
                      ],
                    ),
                  )
                : _filteredTasks.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _searchController.text.isEmpty
                              ? Icons.task_outlined
                              : Icons.search_off,
                          size: 64,
                          color: scheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchController.text.isEmpty
                              ? 'Tamamlanmamış görev bulunamadı'
                              : 'Arama sonucu bulunamadı',
                          style: theme.textTheme.titleLarge,
                        ),
                        if (_searchController.text.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () {
                              _searchController.clear();
                            },
                            child: const Text('Aramayı Temizle'),
                          ),
                        ],
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadTasks,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _filteredTasks.length,
                      itemBuilder: (context, index) {
                        final item = _filteredTasks[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Araç bilgileri
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: scheme.surfaceContainerHighest,
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(12),
                                    topRight: Radius.circular(12),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.directions_car,
                                      color: scheme.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.job.vehicle.plate,
                                            style: theme.textTheme.titleMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                          Text(
                                            '${item.job.vehicle.brand} ${item.job.vehicle.model}',
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                                  color:
                                                      scheme.onSurfaceVariant,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Görev bilgisi
                              TaskListItem(
                                task: item.task,
                                jobId: item.job.id,
                                showActionButtons: true,
                                showPhotos: true,
                                assignedWorkerId:
                                    null, // Görev başlatılınca usta seçilecek
                              ),
                            ],
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
}

/// Görev ve iş emri bilgisini birlikte tutan sınıf
class JobTaskWithJob {
  const JobTaskWithJob({required this.task, required this.job});

  final JobTask task;
  final JobOrder job;
}
