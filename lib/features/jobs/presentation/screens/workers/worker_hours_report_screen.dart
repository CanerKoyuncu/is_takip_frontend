/// İşçi Mesai Saatleri Rapor Ekranı
///
/// İşçilerin hangi arabaya kaç saat mesai harcadığını gösteren rapor ekranı.
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/worker_model.dart';
import '../../../models/worker_hours_model.dart';
import '../../../models/vehicle_area.dart';
import '../../../models/job_models.dart';
import '../../../utils/enum_mapper.dart';
import '../../../services/workers_api_service.dart';
import '../../../services/reports_api_service.dart';
import '../../../../../core/services/api_service_factory.dart';
import '../../../../../core/widgets/error_snackbar.dart';

class WorkerHoursReportScreen extends StatefulWidget {
  const WorkerHoursReportScreen({super.key});

  @override
  State<WorkerHoursReportScreen> createState() =>
      _WorkerHoursReportScreenState();
}

class _WorkerHoursReportScreenState extends State<WorkerHoursReportScreen> {
  List<Worker> _workers = [];
  List<Worker> _filteredWorkers = [];
  Worker? _selectedWorker;
  bool _showAllWorkers = false;
  WorkerHoursReport? _report;
  bool _isLoadingWorkers = true;
  bool _isLoadingReport = false;
  DateTime? _startDate;
  DateTime? _endDate;
  final TextEditingController _searchController = TextEditingController();
  // Worker ID -> Worker Name mapping for displaying in work sessions
  final Map<String, String> _workerNameMap = {};

  late final WorkersApiService _workersApiService;
  late final ReportsApiService _reportsApiService;

  @override
  void initState() {
    super.initState();
    final apiService = ApiServiceFactory.getApiService();
    _workersApiService = WorkersApiService(apiService: apiService);
    _reportsApiService = ReportsApiService(apiService: apiService);
    _loadWorkers();
    _searchController.addListener(() {
      // Controller listener for suffix icon visibility
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadWorkers() async {
    setState(() {
      _isLoadingWorkers = true;
    });

    try {
      final workers = await _workersApiService.getWorkers();
      // Sadece worker rolündeki kullanıcıları göster
      final workerRoleUsers = workers.where((w) => w.role == 'worker').toList();
      // Worker name map'i oluştur
      final workerNameMap = <String, String>{};
      for (final worker in workerRoleUsers) {
        workerNameMap[worker.id] = worker.fullName ?? worker.username;
      }
      setState(() {
        _workers = workerRoleUsers;
        _filteredWorkers = workerRoleUsers;
        _workerNameMap.clear();
        _workerNameMap.addAll(workerNameMap);
        _isLoadingWorkers = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingWorkers = false;
      });
      if (mounted) {
        ErrorSnackbar.showError(
          context,
          'Personeller yüklenirken hata oluştu: $e',
        );
      }
    }
  }

  Future<void> _loadReport() async {
    if (!_showAllWorkers && _selectedWorker == null) {
      ErrorSnackbar.showError(
        context,
        'Lütfen bir işçi seçin veya "Tüm İşçiler" seçeneğini kullanın',
      );
      return;
    }

    setState(() {
      _isLoadingReport = true;
    });

    try {
      final report = _showAllWorkers
          ? await _reportsApiService.getAllWorkersHours(
              startDate: _startDate,
              endDate: _endDate,
            )
          : await _reportsApiService.getWorkerHours(
              workerId: _selectedWorker!.id,
              startDate: _startDate,
              endDate: _endDate,
            );
      setState(() {
        _report = report;
        _isLoadingReport = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingReport = false;
      });
      if (mounted) {
        ErrorSnackbar.showError(context, 'Rapor yüklenirken hata oluştu: $e');
      }
    }
  }

  void _filterWorkers(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredWorkers = _workers;
      } else {
        _filteredWorkers = _workers
            .where(
              (worker) =>
                  worker.displayName.toLowerCase().contains(
                    query.toLowerCase(),
                  ) ||
                  worker.username.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();
      }
    });
  }

  /// Her usta için toplam çalışma saatlerini hesaplar
  Map<String, double> _calculateWorkerHours(List<WorkSession> sessions) {
    final Map<String, double> workerHours = {};
    for (final session in sessions) {
      if (session.workerId != null) {
        final hours = session.durationSeconds / 3600.0;
        workerHours[session.workerId!] =
            (workerHours[session.workerId] ?? 0) + hours;
      }
    }
    return workerHours;
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStartDate
          ? (_startDate ?? DateTime.now().subtract(const Duration(days: 30)))
          : (_endDate ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
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
    }
  }

  String _formatHours(double hours) {
    final h = hours.floor();
    final m = ((hours - h) * 60).round();
    if (h > 0 && m > 0) {
      return '$h saat $m dakika';
    } else if (h > 0) {
      return '$h saat';
    } else {
      return '$m dakika';
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('İşçi Mesai Saatleri Raporu')),
      body: _isLoadingWorkers
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // İşçi seçimi
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('İşçi Seçimi', style: textTheme.titleMedium),
                          const SizedBox(height: 12),
                          // Tüm İşçiler seçeneği
                          CheckboxListTile(
                            title: const Text('Tüm İşçiler'),
                            subtitle: const Text(
                              'Tüm işçilerin toplam mesai saatlerini göster',
                            ),
                            value: _showAllWorkers,
                            onChanged: (value) {
                              setState(() {
                                _showAllWorkers = value ?? false;
                                if (_showAllWorkers) {
                                  _selectedWorker = null;
                                  _searchController.clear();
                                  _filterWorkers('');
                                }
                                _report = null; // Raporu temizle
                              });
                            },
                            contentPadding: EdgeInsets.zero,
                          ),
                          if (!_showAllWorkers) ...[
                            const Divider(height: 24),
                            // Arama kutusu
                            TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                labelText: 'İşçi Ara',
                                hintText: 'İsim veya kullanıcı adı ile ara...',
                                prefixIcon: const Icon(Icons.search),
                                suffixIcon: _searchController.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear),
                                        onPressed: () {
                                          _searchController.clear();
                                          _filterWorkers('');
                                        },
                                      )
                                    : null,
                                border: const OutlineInputBorder(),
                              ),
                              onChanged: _filterWorkers,
                            ),
                            const SizedBox(height: 12),
                            // İşçi listesi
                            if (_filteredWorkers.isEmpty)
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Center(
                                  child: Text(
                                    'İşçi bulunamadı',
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              )
                            else
                              Container(
                                constraints: const BoxConstraints(
                                  maxHeight: 200,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: scheme.outlineVariant,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: _filteredWorkers.length,
                                  itemBuilder: (context, index) {
                                    final worker = _filteredWorkers[index];
                                    final isSelected =
                                        _selectedWorker?.id == worker.id;
                                    return ListTile(
                                      title: Text(worker.displayName),
                                      subtitle: Text(worker.username),
                                      selected: isSelected,
                                      onTap: () {
                                        setState(() {
                                          _selectedWorker = worker;
                                          _report = null; // Raporu temizle
                                        });
                                      },
                                      trailing: isSelected
                                          ? Icon(
                                              Icons.check_circle,
                                              color: scheme.primary,
                                            )
                                          : null,
                                    );
                                  },
                                ),
                              ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Tarih filtreleri
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tarih Aralığı (Opsiyonel)',
                            style: textTheme.titleMedium,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _selectDate(context, true),
                                  icon: const Icon(Icons.calendar_today),
                                  label: Text(
                                    _startDate != null
                                        ? DateFormat(
                                            'dd.MM.yyyy',
                                            'tr_TR',
                                          ).format(_startDate!)
                                        : 'Başlangıç Tarihi',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _selectDate(context, false),
                                  icon: const Icon(Icons.calendar_today),
                                  label: Text(
                                    _endDate != null
                                        ? DateFormat(
                                            'dd.MM.yyyy',
                                            'tr_TR',
                                          ).format(_endDate!)
                                        : 'Bitiş Tarihi',
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (_startDate != null || _endDate != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: TextButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _startDate = null;
                                    _endDate = null;
                                    _report = null;
                                  });
                                },
                                icon: const Icon(Icons.clear),
                                label: const Text('Filtreleri Temizle'),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Raporu Yükle butonu
                  ElevatedButton.icon(
                    onPressed:
                        (!_showAllWorkers && _selectedWorker == null) ||
                            _isLoadingReport
                        ? null
                        : _loadReport,
                    icon: _isLoadingReport
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh),
                    label: const Text('Raporu Yükle'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Rapor sonuçları
                  if (_report != null) ...[
                    // Özet kartı
                    Card(
                      color: scheme.primaryContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Özet',
                              style: textTheme.titleLarge?.copyWith(
                                color: scheme.onPrimaryContainer,
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (_report!.isAllWorkers) ...[
                              _SummaryRow(
                                label: 'Rapor Tipi',
                                value: 'Tüm İşçiler',
                              ),
                              _SummaryRow(
                                label: 'İşçi Sayısı',
                                value: '${_report!.totalWorkers} işçi',
                              ),
                            ] else ...[
                              _SummaryRow(
                                label: 'İşçi',
                                value: _report!.workerName ?? 'Bilinmiyor',
                              ),
                            ],
                            const Divider(),
                            _SummaryRow(
                              label: 'Toplam Mesai',
                              value: _formatHours(_report!.totalHours),
                            ),
                            _SummaryRow(
                              label: 'Toplam Dakika',
                              value: '${_report!.totalMinutes} dakika',
                            ),
                            _SummaryRow(
                              label: 'Araç Sayısı',
                              value: '${_report!.vehicleHours.length} araç',
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Araç bazında detaylar
                    if (_report!.vehicleHours.isEmpty)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 48,
                                  color: scheme.onSurfaceVariant,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Seçilen tarih aralığında mesai kaydı bulunamadı',
                                  style: textTheme.bodyLarge?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    else
                      ..._report!.vehicleHours.map((vehicleHours) {
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ExpansionTile(
                            initiallyExpanded: true,
                            leading: Icon(
                              Icons.directions_car,
                              color: scheme.primary,
                            ),
                            title: Text(
                              '${vehicleHours.vehicle.plate} - ${vehicleHours.vehicle.brand} ${vehicleHours.vehicle.model}',
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              '${vehicleHours.taskCount} görev • ${_formatHours(vehicleHours.totalHours)}',
                              style: textTheme.bodySmall,
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _DetailRow(
                                      label: 'Toplam Mesai',
                                      value: _formatHours(
                                        vehicleHours.totalHours,
                                      ),
                                    ),
                                    _DetailRow(
                                      label: 'Toplam Dakika',
                                      value:
                                          '${vehicleHours.totalMinutes} dakika',
                                    ),
                                    _DetailRow(
                                      label: 'Görev Sayısı',
                                      value: '${vehicleHours.taskCount}',
                                    ),
                                    if (vehicleHours.firstTaskDate != null)
                                      _DetailRow(
                                        label: 'İlk Görev',
                                        value: DateFormat(
                                          'dd.MM.yyyy HH:mm',
                                          'tr_TR',
                                        ).format(vehicleHours.firstTaskDate!),
                                      ),
                                    if (vehicleHours.lastTaskDate != null)
                                      _DetailRow(
                                        label: 'Son Görev',
                                        value: DateFormat(
                                          'dd.MM.yyyy HH:mm',
                                          'tr_TR',
                                        ).format(vehicleHours.lastTaskDate!),
                                      ),
                                    // Görev detayları
                                    if (vehicleHours.tasks.isNotEmpty) ...[
                                      const Divider(height: 32),
                                      Text(
                                        'Görev Detayları',
                                        style: textTheme.titleSmall?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      ...vehicleHours.tasks.map((task) {
                                        return _TaskDetailCard(
                                          task: task,
                                          scheme: scheme,
                                          textTheme: textTheme,
                                          workerNameMap: _workerNameMap,
                                          calculateWorkerHours:
                                              _calculateWorkerHours,
                                        );
                                      }),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                  ],
                ],
              ),
            ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _TaskDetailCard extends StatelessWidget {
  const _TaskDetailCard({
    required this.task,
    required this.scheme,
    required this.textTheme,
    required this.workerNameMap,
    required this.calculateWorkerHours,
  });

  final TaskDetail task;
  final ColorScheme scheme;
  final TextTheme textTheme;
  final Map<String, String> workerNameMap;
  final Map<String, double> Function(List<WorkSession>) calculateWorkerHours;

  String _getAreaLabel(String area) {
    try {
      final vehicleArea = EnumMapper.vehicleAreaFromBackend(area);
      return vehicleArea.label;
    } catch (_) {
      return area;
    }
  }

  String _getOperationTypeLabel(String operationType) {
    try {
      final opType = EnumMapper.jobOperationTypeFromBackend(operationType);
      return opType.label;
    } catch (_) {
      return operationType;
    }
  }

  IconData _getOperationTypeIcon(String operationType) {
    try {
      final opType = EnumMapper.jobOperationTypeFromBackend(operationType);
      return opType.icon;
    } catch (_) {
      return Icons.task_outlined;
    }
  }

  String _formatHours(double hours) {
    final h = hours.floor();
    final m = ((hours - h) * 60).round();
    if (h > 0 && m > 0) {
      return '$h saat $m dakika';
    } else if (h > 0) {
      return '$h saat';
    } else {
      return '$m dakika';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: scheme.outlineVariant, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getOperationTypeIcon(task.operationType),
                  size: 20,
                  color: scheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getAreaLabel(task.area),
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getOperationTypeLabel(task.operationType),
                      style: textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (task.note != null && task.note!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.note_outlined,
                    size: 16,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      task.note!,
                      style: textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _TaskInfoItem(
                  icon: Icons.play_circle_outline,
                  label: 'Başlangıç',
                  value: DateFormat(
                    'dd.MM.yyyy HH:mm',
                    'tr_TR',
                  ).format(task.startedAt),
                  scheme: scheme,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _TaskInfoItem(
                  icon: Icons.check_circle_outline,
                  label: 'Tamamlanma',
                  value: DateFormat(
                    'dd.MM.yyyy HH:mm',
                    'tr_TR',
                  ).format(task.completedAt),
                  scheme: scheme,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _TaskInfoItem(
                  icon: Icons.access_time,
                  label: task.hasPauses ? 'Çalışma Süresi' : 'Süre',
                  value: _formatHours(task.durationHours),
                  scheme: scheme,
                ),
              ),
              if (task.hasPauses) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: _TaskInfoItem(
                    icon: Icons.pause_circle_outline,
                    label: 'Toplam Süre',
                    value: _formatHours(task.totalDurationHours),
                    scheme: scheme,
                  ),
                ),
              ],
            ],
          ),
          // Her ustanın çalışma saatleri özeti
          if (task.workSessions.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 16,
                        color: scheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Usta Çalışma Özeti',
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Her usta için toplam çalışma saatlerini hesapla
                  ...calculateWorkerHours(task.workSessions).entries.map((
                    entry,
                  ) {
                    final workerId = entry.key;
                    final hours = entry.value;
                    final workerName =
                        workerNameMap[workerId] ?? 'Usta ID: $workerId';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Icon(
                                  Icons.person_outline,
                                  size: 14,
                                  color: scheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    workerName,
                                    style: textTheme.bodySmall?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            _formatHours(hours),
                            style: textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: scheme.primary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
          if (task.hasPauses && task.workSessions.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 14,
                        color: scheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Çalışma Oturumları',
                        style: textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...task.workSessions.asMap().entries.map((entry) {
                    final index = entry.key;
                    final session = entry.value;
                    // Worker name'i bul (eğer varsa)
                    String? workerName;
                    if (session.workerId != null) {
                      workerName =
                          workerNameMap[session.workerId!] ??
                          'Usta ID: ${session.workerId}';
                    }
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Text(
                            '${index + 1}. ',
                            style: textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${DateFormat('HH:mm', 'tr_TR').format(session.startTime)} - ${DateFormat('HH:mm', 'tr_TR').format(session.endTime)} (${_formatHours(session.durationSeconds / 3600)})',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                                if (workerName != null)
                                  Text(
                                    'Usta: $workerName',
                                    style: textTheme.bodySmall?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                      fontSize: 11,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TaskInfoItem extends StatelessWidget {
  const _TaskInfoItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.scheme,
  });

  final IconData icon;
  final String label;
  final String value;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: scheme.onSurfaceVariant),
              const SizedBox(width: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
