import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/reception_models.dart';
import 'package:vehicle_damage_map/vehicle_damage_map.dart' show SparePartItem;

/// İş emri oluşturma ekranı için cache servisi.
///
/// Form verilerini (araç bilgileri, seçimler, fotoğraflar)
/// yerel depolama biriminde (SharedPreferences) saklar.
class JobCreationCacheService {
  static const String _cacheKey = 'job_creation_draft';

  /// Taslağı kaydeder
  Future<void> saveDraft({
    required String plate,
    required String brand,
    required String model,
    required Map<String, List<String>> selections,
    required Map<String, List<SparePartItem>> spareParts,
    required List<ReceptionPhoto> receptionPhotos,
    required String generalNotes,
    required List<String> requiredParts,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final draftData = {
      'plate': plate,
      'brand': brand,
      'model': model,
      'selections': selections,
      'spareParts': spareParts.map(
        (key, value) => MapEntry(key, value.map((p) => p.toMap()).toList()),
      ),
      'receptionPhotos': receptionPhotos.map((p) => p.toMap()).toList(),
      'generalNotes': generalNotes,
      'requiredParts': requiredParts,
      'updatedAt': DateTime.now().toIso8601String(),
    };

    await prefs.setString(_cacheKey, jsonEncode(draftData));
  }

  /// Kayıtlı taslağı yükler
  Future<Map<String, dynamic>?> loadDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_cacheKey);

    if (jsonString == null) return null;

    try {
      final data = jsonDecode(jsonString) as Map<String, dynamic>;

      // SpareParts'ları tekrar nesneye dönüştür
      if (data['spareParts'] != null) {
        final rawSpareParts = data['spareParts'] as Map<String, dynamic>;
        final Map<String, List<SparePartItem>> structuredSpareParts = {};

        rawSpareParts.forEach((key, value) {
          final list = value as List<dynamic>;
          structuredSpareParts[key] = list
              .map(
                (item) => SparePartItem.fromMap(item as Map<String, dynamic>),
              )
              .toList();
        });

        data['spareParts'] = structuredSpareParts;
      }

      // Selections'ları normalize et (List<dynamic> -> List<String>)
      if (data['selections'] != null) {
        final rawSelections = data['selections'] as Map<String, dynamic>;
        data['selections'] = rawSelections.map(
          (key, value) => MapEntry(key, List<String>.from(value as List)),
        );
      }

      // List'leri normalize et
      if (data['receptionPhotos'] != null) {
        final rawPhotos = data['receptionPhotos'] as List<dynamic>;
        data['receptionPhotos'] = rawPhotos
            .map((p) => ReceptionPhoto.fromMap(p as Map<String, dynamic>))
            .toList();
      } else {
        data['receptionPhotos'] = <ReceptionPhoto>[];
      }
      data['requiredParts'] = List<String>.from(data['requiredParts'] ?? []);

      return data;
    } catch (e) {
      // Hatalı cache'i temizle
      await clearDraft();
      return null;
    }
  }

  /// Taslağı temizler
  Future<void> clearDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey);
  }

  /// Kayıtlı taslak var mı kontrol eder
  Future<bool> hasDraft() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_cacheKey);
  }
}
