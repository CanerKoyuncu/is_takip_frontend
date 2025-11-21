/// Personel Yönetimi Ekranı
///
/// Personellerin listelenmesi, eklenmesi, düzenlenmesi ve silinmesi için kullanılır.
import 'package:flutter/material.dart';
import '../../../models/worker_model.dart';
import '../../../services/workers_api_service.dart';
import '../../../../../core/services/api_service_factory.dart';
import '../../../../../core/widgets/error_snackbar.dart';
import '../../../../../core/widgets/loading_snackbar.dart';

class WorkersManagementScreen extends StatefulWidget {
  const WorkersManagementScreen({super.key});

  @override
  State<WorkersManagementScreen> createState() =>
      _WorkersManagementScreenState();
}

class _WorkersManagementScreenState extends State<WorkersManagementScreen> {
  List<Worker> _workers = [];
  bool _isLoading = true;
  String? _errorMessage;

  late final WorkersApiService _workersApiService;

  @override
  void initState() {
    super.initState();
    final apiService = ApiServiceFactory.getApiService();
    _workersApiService = WorkersApiService(apiService: apiService);
    _loadWorkers();
  }

  Future<void> _loadWorkers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final workers = await _workersApiService.getWorkers();
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

  Future<void> _createWorker() async {
    final result = await showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (context) => const _WorkerDialog(),
    );

    if (result != null && mounted) {
      try {
        LoadingSnackbar.show(context, message: 'Personel oluşturuluyor...');
        await _workersApiService.createWorker(
          username: result['username'] as String,
          fullName: result['fullName'] as String?,
          role: result['role'] as String?,
        );
        if (mounted) {
          LoadingSnackbar.hide(context);
          final role = result['role'] as String? ?? 'worker';
          final roleName = role == 'worker'
              ? 'Usta'
              : role == 'supervisor'
              ? 'Denetçi'
              : role == 'manager'
              ? 'Yönetici'
              : 'Admin';
          final passwordInfo = role == 'worker'
              ? ' (şifre gerekmez)'
              : ' (şifre: ${result['username']}123)';
          ErrorSnackbar.showSuccess(
            context,
            '$roleName oluşturuldu$passwordInfo',
          );
          _loadWorkers();
        }
      } catch (e) {
        if (mounted) {
          LoadingSnackbar.hide(context);
          // Hata mesajını daha anlaşılır hale getir
          String errorMessage = 'Personel oluşturulurken hata oluştu';
          final errorStr = e.toString().toLowerCase();
          if (errorStr.contains('username already exists') ||
              errorStr.contains('kullanıcı adı zaten mevcut')) {
            errorMessage = 'Bu kullanıcı adı zaten kullanılıyor';
          } else if (errorStr.contains('invalid role')) {
            errorMessage = 'Geçersiz rol seçildi';
          } else if (errorStr.contains('network') ||
              errorStr.contains('connection')) {
            errorMessage =
                'Bağlantı hatası. Lütfen internet bağlantınızı kontrol edin';
          }
          ErrorSnackbar.showError(context, errorMessage);
        }
      }
    }
  }

  Future<void> _editWorker(Worker worker) async {
    final result = await showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (context) => _WorkerDialog(worker: worker),
    );

    if (result != null && mounted) {
      try {
        LoadingSnackbar.show(context, message: 'Personel güncelleniyor...');
        await _workersApiService.updateWorker(
          workerId: worker.id,
          username: result['username'] as String?,
          fullName: result['fullName'] as String?,
          role: result['role'] as String?,
        );
        if (mounted) {
          LoadingSnackbar.hide(context);
          ErrorSnackbar.showSuccess(context, 'Personel güncellendi');
          _loadWorkers();
        }
      } catch (e) {
        if (mounted) {
          LoadingSnackbar.hide(context);
          // Hata mesajını daha anlaşılır hale getir
          String errorMessage = 'Personel güncellenirken hata oluştu';
          final errorStr = e.toString().toLowerCase();
          if (errorStr.contains('username already exists') ||
              errorStr.contains('kullanıcı adı zaten mevcut')) {
            errorMessage = 'Bu kullanıcı adı zaten kullanılıyor';
          } else if (errorStr.contains('network') ||
              errorStr.contains('connection')) {
            errorMessage =
                'Bağlantı hatası. Lütfen internet bağlantınızı kontrol edin';
          }
          ErrorSnackbar.showError(context, errorMessage);
        }
      }
    }
  }

  Future<void> _resetPassword(Worker worker) async {
    final result = await showDialog<String?>(
      context: context,
      builder: (context) => _PasswordResetDialog(worker: worker),
    );

    if (result != null && result.isNotEmpty && mounted) {
      try {
        LoadingSnackbar.show(context, message: 'Şifre sıfırlanıyor...');
        await _workersApiService.updateWorker(
          workerId: worker.id,
          password: result,
        );
        if (mounted) {
          LoadingSnackbar.hide(context);
          ErrorSnackbar.showSuccess(context, 'Şifre sıfırlandı');
        }
      } catch (e) {
        if (mounted) {
          LoadingSnackbar.hide(context);
          ErrorSnackbar.showError(context, 'Şifre sıfırlanırken hata: $e');
        }
      }
    }
  }

  Future<void> _deleteWorker(Worker worker) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Personel Sil'),
        content: Text(
          '${worker.displayName} adlı personeli silmek istediğinizden emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        LoadingSnackbar.show(context, message: 'Personel siliniyor...');
        await _workersApiService.deleteWorker(worker.id);
        if (mounted) {
          LoadingSnackbar.hide(context);
          ErrorSnackbar.showSuccess(context, 'Personel silindi');
          _loadWorkers();
        }
      } catch (e) {
        if (mounted) {
          LoadingSnackbar.hide(context);
          ErrorSnackbar.showError(context, 'Personel silinirken hata: $e');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Personel Yönetimi')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: scheme.error),
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
                    onPressed: _loadWorkers,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Tekrar Dene'),
                  ),
                ],
              ),
            )
          : _workers.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.person_off,
                    size: 64,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Personel bulunamadı',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Yeni personel eklemek için + butonuna tıklayın',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadWorkers,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _workers.length,
                itemBuilder: (context, index) {
                  final worker = _workers[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: scheme.primaryContainer,
                        child: Text(
                          worker.displayName[0].toUpperCase(),
                          style: TextStyle(
                            color: scheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        worker.displayName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kullanıcı adı: ${worker.username}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          if (worker.role != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Rol: ${_getRoleDisplayName(worker.role!)}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: scheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                      trailing: PopupMenuButton(
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'edit',
                            child: const Row(
                              children: [
                                Icon(Icons.edit, size: 20),
                                SizedBox(width: 8),
                                Text('Düzenle'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'resetPassword',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.lock_reset,
                                  size: 20,
                                  color: scheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Şifre Sıfırla',
                                  style: TextStyle(color: scheme.primary),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.delete,
                                  size: 20,
                                  color: scheme.error,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Sil',
                                  style: TextStyle(color: scheme.error),
                                ),
                              ],
                            ),
                          ),
                        ],
                        onSelected: (value) {
                          if (value == 'edit') {
                            _editWorker(worker);
                          } else if (value == 'resetPassword') {
                            _resetPassword(worker);
                          } else if (value == 'delete') {
                            _deleteWorker(worker);
                          }
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createWorker,
        child: const Icon(Icons.add),
      ),
    );
  }

  String _getRoleDisplayName(String role) {
    switch (role) {
      case 'admin':
        return 'Admin';
      case 'manager':
        return 'Yönetici';
      case 'supervisor':
        return 'Denetçi';
      case 'worker':
        return 'Usta';
      default:
        return role;
    }
  }
}

class _WorkerDialog extends StatefulWidget {
  const _WorkerDialog({this.worker});

  final Worker? worker;

  @override
  State<_WorkerDialog> createState() => _WorkerDialogState();
}

class _WorkerDialogState extends State<_WorkerDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _usernameController;
  late final TextEditingController _fullNameController;
  String? _selectedRole;
  final FocusNode _usernameFocus = FocusNode();
  final FocusNode _fullNameFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.worker?.username);
    _fullNameController = TextEditingController(text: widget.worker?.fullName);
    _selectedRole = widget.worker?.role ?? 'worker';
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _fullNameController.dispose();
    _usernameFocus.dispose();
    _fullNameFocus.dispose();
    super.dispose();
  }

  void _submit() {
    // Klavyeyi kapat
    FocusScope.of(context).unfocus();

    if (_formKey.currentState!.validate()) {
      Navigator.of(context).pop({
        'username': _usernameController.text.trim(),
        'fullName': _fullNameController.text.trim().isEmpty
            ? null
            : _fullNameController.text.trim(),
        'role': _selectedRole,
      });
    }
  }

  String _getRoleDescription(String role) {
    switch (role) {
      case 'admin':
        return 'Tam yetkili yönetici. Tüm işlemleri yapabilir.';
      case 'manager':
        return 'Patron ve yöneticiler. İş emri oluşturabilir ve yönetebilir.';
      case 'supervisor':
        return 'İş takip eden ve görevleri oluşturanlar. İş emri oluşturabilir.';
      case 'worker':
        return 'Usta. Şifre gerektirmez, sadece kiosk modu kullanır.';
      default:
        return '';
    }
  }

  String _getPasswordInfo(String role, String username) {
    if (role == 'worker') {
      return 'Şifre gerekmez (kiosk modu)';
    }
    return 'Şifre: ${username}123';
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.worker != null;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            isEdit ? Icons.edit_outlined : Icons.person_add_outlined,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isEdit ? 'Personel Düzenle' : 'Yeni Personel Ekle',
              style: theme.textTheme.titleLarge,
            ),
          ),
        ],
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Kullanıcı Adı
              TextFormField(
                controller: _usernameController,
                focusNode: _usernameFocus,
                autofocus: !isEdit,
                enabled: !isEdit,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'Kullanıcı Adı *',
                  helperText: 'En az 3, en fazla 50 karakter',
                  prefixIcon: const Icon(Icons.person_outline),
                  border: const OutlineInputBorder(),
                ),
                onFieldSubmitted: (_) {
                  FocusScope.of(context).requestFocus(_fullNameFocus);
                },
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Kullanıcı adı gereklidir';
                  }
                  final trimmed = value.trim();
                  if (trimmed.length < 3) {
                    return 'Kullanıcı adı en az 3 karakter olmalıdır';
                  }
                  if (trimmed.length > 50) {
                    return 'Kullanıcı adı en fazla 50 karakter olabilir';
                  }
                  // Özel karakter kontrolü (sadece harf, rakam, alt çizgi, tire)
                  final validPattern = RegExp(r'^[a-zA-Z0-9_-]+$');
                  if (!validPattern.hasMatch(trimmed)) {
                    return 'Sadece harf, rakam, alt çizgi (_) ve tire (-) kullanılabilir';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              // Tam Ad
              TextFormField(
                controller: _fullNameController,
                focusNode: _fullNameFocus,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Tam Ad (opsiyonel)',
                  helperText: 'Gerçek ad ve soyad',
                  prefixIcon: Icon(Icons.badge_outlined),
                  border: OutlineInputBorder(),
                ),
                onFieldSubmitted: (_) {
                  FocusScope.of(context).unfocus();
                },
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    if (value.trim().length > 100) {
                      return 'Tam ad en fazla 100 karakter olabilir';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              // Rol Seçimi
              DropdownButtonFormField<String>(
                value: _selectedRole,
                decoration: const InputDecoration(
                  labelText: 'Rol *',
                  helperText: 'Kullanıcının yetki seviyesi',
                  prefixIcon: Icon(Icons.workspace_premium_outlined),
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'worker',
                    child: Row(
                      children: [
                        Icon(Icons.construction, size: 20),
                        SizedBox(width: 8),
                        Text('Usta'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'supervisor',
                    child: Row(
                      children: [
                        Icon(Icons.supervisor_account, size: 20),
                        SizedBox(width: 8),
                        Text('Denetçi'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'manager',
                    child: Row(
                      children: [
                        Icon(Icons.business, size: 20),
                        SizedBox(width: 8),
                        Text('Yönetici'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'admin',
                    child: Row(
                      children: [
                        Icon(Icons.admin_panel_settings, size: 20),
                        SizedBox(width: 8),
                        Text('Admin'),
                      ],
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedRole = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Rol seçilmelidir';
                  }
                  return null;
                },
              ),
              // Rol Açıklaması
              if (_selectedRole != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceVariant.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: colorScheme.outline.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 20,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _getRoleDescription(_selectedRole!),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              // Şifre Bilgisi (sadece yeni kullanıcı oluştururken göster)
              if (!isEdit &&
                  _selectedRole != null &&
                  _usernameController.text.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _selectedRole == 'worker'
                        ? colorScheme.tertiaryContainer.withOpacity(0.5)
                        : colorScheme.primaryContainer.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _selectedRole == 'worker'
                          ? colorScheme.tertiary
                          : colorScheme.primary,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _selectedRole == 'worker'
                            ? Icons.no_encryption
                            : Icons.lock_outline,
                        size: 20,
                        color: _selectedRole == 'worker'
                            ? colorScheme.onTertiaryContainer
                            : colorScheme.onPrimaryContainer,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _getPasswordInfo(
                            _selectedRole!,
                            _usernameController.text.trim(),
                          ),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: _selectedRole == 'worker'
                                ? colorScheme.onTertiaryContainer
                                : colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            FocusScope.of(context).unfocus();
            Navigator.of(context).pop();
          },
          child: const Text('İptal'),
        ),
        FilledButton.icon(
          onPressed: _submit,
          icon: Icon(isEdit ? Icons.save : Icons.add),
          label: Text(isEdit ? 'Kaydet' : 'Oluştur'),
        ),
      ],
    );
  }
}

class _PasswordResetDialog extends StatefulWidget {
  const _PasswordResetDialog({required this.worker});

  final Worker worker;

  @override
  State<_PasswordResetDialog> createState() => _PasswordResetDialogState();
}

class _PasswordResetDialogState extends State<_PasswordResetDialog> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      Navigator.of(context).pop(_passwordController.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Şifre Sıfırla - ${widget.worker.displayName}'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Yeni Şifre',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Şifre gereklidir';
                  }
                  if (value.trim().length < 4) {
                    return 'Şifre en az 4 karakter olmalıdır';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordController,
                decoration: const InputDecoration(
                  labelText: 'Şifre Tekrar',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Şifre tekrar gereklidir';
                  }
                  if (value != _passwordController.text) {
                    return 'Şifreler eşleşmiyor';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('İptal'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Sıfırla')),
      ],
    );
  }
}
