import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../providers/jobs_provider.dart';
import '../../../models/job_models.dart';
import '../../../models/vehicle_area.dart';
import 'package:is_takip/core/widgets/error_snackbar.dart';

class AddDataToJobScreen extends StatefulWidget {
  const AddDataToJobScreen({super.key, required this.jobId});

  final String jobId;

  @override
  State<AddDataToJobScreen> createState() => _AddDataToJobScreenState();
}

class _AddDataToJobScreenState extends State<AddDataToJobScreen> {
  final _noteController = TextEditingController();
  final _generalNoteController = TextEditingController();
  String? _selectedTaskId;
  TaskPhotoType _selectedPhotoType = TaskPhotoType.damage;
  JobStatus? _selectedStage;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void dispose() {
    _noteController.dispose();
    _generalNoteController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (_selectedTaskId == null) {
      ErrorSnackbar.showError(context, 'Lütfen önce bir görev seçin');
      return;
    }

    // Show source selection dialog
    final source = await showDialog<ImageSource?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Fotoğraf Kaynağı'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Kamera'),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galeri'),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null || !mounted) return;

    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (image == null || !mounted) return;

      // Show loading
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 12),
                Text('Fotoğraf yükleniyor...'),
              ],
            ),
            duration: Duration(seconds: 30),
          ),
        );
      }

      final provider = context.read<JobsProvider>();
      await provider.addDamagePhoto(
        jobId: widget.jobId,
        taskId: _selectedTaskId!,
        photoPath: image.path,
        type: _selectedPhotoType,
        stage: _selectedStage,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ErrorSnackbar.showSuccess(context, 'Fotoğraf başarıyla eklendi');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ErrorSnackbar.showError(
          context,
          'Fotoğraf eklenirken hata: ${e.toString()}',
        );
      }
    }
  }

  Future<void> _addNoteToTask() async {
    if (_selectedTaskId == null) {
      ErrorSnackbar.showError(context, 'Lütfen önce bir görev seçin');
      return;
    }

    if (_noteController.text.trim().isEmpty) {
      ErrorSnackbar.showError(context, 'Lütfen bir not girin');
      return;
    }

    try {
      final provider = context.read<JobsProvider>();
      final job = provider.jobById(widget.jobId);
      if (job == null) return;

      final task = job.tasks.firstWhere((t) => t.id == _selectedTaskId);
      final updatedNote = task.note != null && task.note!.isNotEmpty
          ? '${task.note}\n\n${DateFormat('dd.MM.yyyy HH:mm').format(DateTime.now())}: ${_noteController.text.trim()}'
          : '${DateFormat('dd.MM.yyyy HH:mm').format(DateTime.now())}: ${_noteController.text.trim()}';

      await provider.updateTaskNote(
        jobId: widget.jobId,
        taskId: _selectedTaskId!,
        note: updatedNote,
      );

      _noteController.clear();
      if (mounted) {
        ErrorSnackbar.showSuccess(context, 'Not başarıyla eklendi');
      }
    } catch (e) {
      if (mounted) {
        ErrorSnackbar.showError(context, 'Not eklenirken hata: $e');
      }
    }
  }

  Future<void> _addGeneralNote() async {
    if (_generalNoteController.text.trim().isEmpty) {
      ErrorSnackbar.showError(context, 'Lütfen bir not girin');
      return;
    }

    try {
      final provider = context.read<JobsProvider>();
      final job = provider.jobById(widget.jobId);
      if (job == null) return;

      final updatedNote =
          job.generalNotes != null && job.generalNotes!.isNotEmpty
          ? '${job.generalNotes}\n\n${DateFormat('dd.MM.yyyy HH:mm').format(DateTime.now())}: ${_generalNoteController.text.trim()}'
          : '${DateFormat('dd.MM.yyyy HH:mm').format(DateTime.now())}: ${_generalNoteController.text.trim()}';

      await provider.updateGeneralNotes(
        jobId: widget.jobId,
        notes: updatedNote,
      );

      _generalNoteController.clear();
      if (mounted) {
        ErrorSnackbar.showSuccess(context, 'Genel not başarıyla eklendi');
      }
    } catch (e) {
      if (mounted) {
        ErrorSnackbar.showError(context, 'Not eklenirken hata: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Veri Ekle')),
      body: Consumer<JobsProvider>(
        builder: (context, provider, child) {
          final job = provider.jobById(widget.jobId);

          // If job not found, try to load from API
          if (job == null) {
            // Trigger load if not already loading
            if (!provider.isLoading) {
              Future.microtask(() => provider.loadJobById(widget.jobId));
            }

            return provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48),
                        const SizedBox(height: 16),
                        Text(
                          provider.errorMessage ?? 'İş emri bulunamadı',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => provider.loadJobById(widget.jobId),
                          child: const Text('Tekrar Dene'),
                        ),
                      ],
                    ),
                  );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Job Info Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'İş Emri Bilgileri',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
               
                      Text(
                        job.vehicle.plate,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Task Selection
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Görev Seç',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      if (job.tasks.isEmpty)
                        const Text('Bu iş emrinde görev bulunmuyor')
                      else
                        ...job.tasks.map((task) {
                          final isSelected = _selectedTaskId == task.id;
                          return RadioListTile<String>(
                            title: Text(task.area.label),
                            subtitle: Text(task.operationType.label),
                            value: task.id,
                            groupValue: _selectedTaskId,
                            onChanged: (value) {
                              setState(() {
                                _selectedTaskId = value;
                                _noteController.clear();
                              });
                            },
                            selected: isSelected,
                          );
                        }),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Add Note to Task
              if (_selectedTaskId != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Göreve Not Ekle',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _noteController,
                          decoration: const InputDecoration(
                            labelText: 'Not',
                            hintText: 'Görev için not ekleyin...',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 4,
                        ),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: _addNoteToTask,
                          icon: const Icon(Icons.note_add),
                          label: const Text('Not Ekle'),
                        ),
                      ],
                    ),
                  ),
                ),
              if (_selectedTaskId != null) const SizedBox(height: 16),

              // Add Photo
              if (_selectedTaskId != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Fotoğraf Ekle',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        ToggleButtons(
                          isSelected: [
                            _selectedPhotoType == TaskPhotoType.damage,
                            _selectedPhotoType == TaskPhotoType.completion,
                          ],
                          onPressed: (index) {
                            setState(() {
                              _selectedPhotoType = index == 0
                                  ? TaskPhotoType.damage
                                  : TaskPhotoType.completion;
                            });
                          },
                          children: const [
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.broken_image, size: 18),
                                  SizedBox(width: 8),
                                  Text('Hasar'),
                                ],
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check_circle, size: 18),
                                  SizedBox(width: 8),
                                  Text('Tamamlanma'),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Aşama seçimi
                        DropdownButtonFormField<JobStatus?>(
                          value: _selectedStage,
                          decoration: const InputDecoration(
                            labelText: 'Aşama (Opsiyonel)',
                            hintText: 'Fotoğrafın hangi aşamada yüklendiğini seçin',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.timeline),
                          ),
                          items: [
                            const DropdownMenuItem<JobStatus?>(
                              value: null,
                              child: Text('Aşama seçilmedi'),
                            ),
                            ...JobStatus.values.map((stage) {
                              return DropdownMenuItem<JobStatus?>(
                                value: stage,
                                child: Row(
                                  children: [
                                    Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: stage.toColor(context),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(stage.label),
                                  ],
                                ),
                              );
                            }),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedStage = value;
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: _pickImage,
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Fotoğraf Çek'),
                        ),
                      ],
                    ),
                  ),
                ),
              if (_selectedTaskId != null) const SizedBox(height: 16),

              // Add General Note
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Genel Not Ekle',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _generalNoteController,
                        decoration: const InputDecoration(
                          labelText: 'Genel Not',
                          hintText: 'İş emri için genel not ekleyin...',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 4,
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: _addGeneralNote,
                        icon: const Icon(Icons.note_add),
                        label: const Text('Genel Not Ekle'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Add New Task Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Yeni Görev Ekle',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: () {
                              context.push(
                                '/dashboard/job-orders/${widget.jobId}/add-task',
                              );
                            },
                            tooltip: 'Yeni Görev Ekle',
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Araç şemasından yeni parça seçerek görev ekleyebilirsiniz',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
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

