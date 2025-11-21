/// Personel (Worker) modeli
///
/// Bir personeli temsil eder. Kullanıcı bilgilerini içerir.
class Worker {
  Worker({
    required this.id,
    required this.username,
    this.fullName,
    this.email,
    this.role,
  });

  final String id;
  final String username;
  final String? fullName;
  final String? email;
  final String? role;

  /// JSON'dan Worker oluşturur
  factory Worker.fromJson(Map<String, dynamic> json) {
    final role = json['role'] as String?;
    // Workers don't have email - set to null for worker role
    final email = (role == 'worker') ? null : (json['email'] as String?);

    return Worker(
      id: json['id'] as String,
      username: json['username'] as String,
      fullName: json['fullName'] as String?,
      email: email,
      role: role,
    );
  }

  /// Worker'ı JSON'a dönüştürür
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      if (fullName != null) 'fullName': fullName,
      // Workers don't have email - don't include email for worker role
      if (email != null && role != 'worker') 'email': email,
      if (role != null) 'role': role,
    };
  }

  /// Görüntüleme adı
  ///
  /// fullName varsa onu, yoksa username'i döndürür
  String get displayName => fullName ?? username;
}
