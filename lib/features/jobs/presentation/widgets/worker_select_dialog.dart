/// Personel Seçim Dialog'u
///
/// Görev başlatılırken personel seçimi için kullanılır.
import 'package:flutter/material.dart';
import '../../models/worker_model.dart';
import '../../services/workers_api_service.dart';
import '../../../../core/services/api_service_factory.dart';

class WorkerSelectDialog extends StatefulWidget {
  const WorkerSelectDialog({super.key, this.kioskMode = false});

  /// Kiosk modu için token gerektirmeyen endpoint kullan
  final bool kioskMode;

  /// Dialog'u gösterir ve seçilen personeli döndürür
  static Future<Worker?> show(
    BuildContext context, {
    bool kioskMode = false,
  }) async {
    return showDialog<Worker?>(
      context: context,
      builder: (context) => WorkerSelectDialog(kioskMode: kioskMode),
    );
  }

  @override
  State<WorkerSelectDialog> createState() => _WorkerSelectDialogState();
}

class _WorkerSelectDialogState extends State<WorkerSelectDialog> {
  List<Worker> _workers = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadWorkers();
  }

  Future<void> _loadWorkers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // ApiService'i factory'den al
      final apiService = ApiServiceFactory.getApiService();
      final workersApiService = WorkersApiService(apiService: apiService);
      // Kiosk modu için token gerektirmeyen endpoint kullan
      final workers = await workersApiService.getWorkers(
        kioskMode: widget.kioskMode,
      );

      setState(() {
        _workers = workers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Personeller yüklenirken hata oluştu: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Personel Seç'),
      content: SizedBox(
        width: double.maxFinite,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadWorkers,
                    child: const Text('Tekrar Dene'),
                  ),
                ],
              )
            : _workers.isEmpty
            ? const Text('Personel bulunamadı')
            : ListView.builder(
                shrinkWrap: true,
                itemCount: _workers.length,
                itemBuilder: (context, index) {
                  final worker = _workers[index];
                  return ListTile(
                    leading: CircleAvatar(
                      child: Text(worker.displayName[0].toUpperCase()),
                    ),
                    title: Text(worker.displayName),
                    subtitle: worker.role != 'worker' && worker.email != null
                        ? Text(worker.email!)
                        : null,
                    onTap: () {
                      Navigator.of(context).pop(worker);
                    },
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('İptal'),
        ),
      ],
    );
  }
}
