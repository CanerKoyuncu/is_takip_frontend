import 'package:flutter/foundation.dart';
import 'package:is_takip/features/jobs/models/damage_report.dart';

/// Hasar Raporu Provider'ı
///
/// İş emirlerine ait hasar raporlarını yönetir.
/// Oluşturma, güncelleme ve silme işlemlerini yapır.
class DamageReportProvider extends ChangeNotifier {
  /// Hasar raporları - jobOrderId -> DamageReport
  final Map<String, DamageReport> _damageReports = {};

  /// Hasar raporu taslakları - jobOrderId -> DamageReportDraft
  final Map<String, DamageReportDraft> _damageReportDrafts = {};

  /// Yükleniyor durumu
  bool _isLoading = false;

  /// Hata mesajı
  String? _error;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Belirli bir iş emri için hasar raporunu al
  DamageReport? getDamageReportForJob(String jobOrderId) {
    return _damageReports[jobOrderId];
  }

  /// Belirli bir iş emri için hasar raporu taslağını al
  DamageReportDraft getDamageReportDraftForJob(String jobOrderId) {
    return _damageReportDrafts[jobOrderId] ?? DamageReportDraft();
  }

  /// Hasar raporu taslağını güncelle
  void updateDamageReportDraft(
    String jobOrderId,
    Map<String, List<String>> damages, {
    String? notes,
  }) {
    final currentDraft = _damageReportDrafts[jobOrderId] ?? DamageReportDraft();

    _damageReportDrafts[jobOrderId] = currentDraft.copyWith(
      damages: damages,
      notes: notes ?? currentDraft.notes,
    );

    notifyListeners();
  }

  /// Hasar raporu taslağına not ekle/güncelle
  void updateDamageReportDraftNote(String jobOrderId, String note) {
    final currentDraft = _damageReportDrafts[jobOrderId] ?? DamageReportDraft();

    _damageReportDrafts[jobOrderId] = currentDraft.copyWith(notes: note);

    notifyListeners();
  }

  /// Belirli bir parça için hasar verilerini güncelle
  void updatePartDamage(
    String jobOrderId,
    String partId,
    List<String> actions,
  ) {
    final currentDraft = _damageReportDrafts[jobOrderId] ?? DamageReportDraft();
    final updatedDamages = Map<String, List<String>>.from(currentDraft.damages);

    if (actions.isEmpty) {
      updatedDamages.remove(partId);
    } else {
      updatedDamages[partId] = actions;
    }

    _damageReportDrafts[jobOrderId] = currentDraft.copyWith(
      damages: updatedDamages,
    );

    notifyListeners();
  }

  /// Hasar raporunu kaydet (API'ya gönder)
  Future<void> saveDamageReport(
    String jobOrderId, {
    required Function(DamageReport) onSuccess,
    required Function(String) onError,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final draft = _damageReportDrafts[jobOrderId];
      if (draft == null) {
        throw Exception('Hasar raporu taslağı bulunamadı');
      }

      // TODO: API'ya gönder
      // Şu an taslağı raporuna çevir
      final report = draft.toDamageReport(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        jobOrderId: jobOrderId,
      );

      _damageReports[jobOrderId] = report;
      _damageReportDrafts.remove(jobOrderId);

      _isLoading = false;
      notifyListeners();

      onSuccess(report);
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      onError(e.toString());
    }
  }

  /// Hasar raporunu sil
  void deleteDamageReportDraft(String jobOrderId) {
    _damageReportDrafts.remove(jobOrderId);
    notifyListeners();
  }

  /// Tüm hasar raporlarını temizle
  void clearAll() {
    _damageReports.clear();
    _damageReportDrafts.clear();
    _error = null;
    notifyListeners();
  }
}
