import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Firestore-da parolaların düz mətn kimi saxlanmaması üçün hash köməkçisi.
///
/// Hər istifadəçinin `id`-si duz (salt) kimi istifadə olunur — ayrıca salt
/// sahəsi saxlamağa ehtiyac yoxdur və rainbow table hücumlarına qarşı
/// istifadəçi başı unikal hash yaranır.
///
/// Köhnə qeydlərdə `password` sahəsində düz mətn ola bilər; `isHash` bunu
/// ayırd edir, login zamanı köhnə düz mətn uğurla yoxlanılsa dərhal hash-ə
/// köçürülür (lazy migration).
class PasswordHasher {
  static const String _prefix = 'sha256:';

  /// [userId]-nin duz kimi istifadə edildiyi hash. Format: `sha256:<hex>`
  static String hash(String userId, String password) {
    final bytes = utf8.encode('$userId|$password');
    return '$_prefix${sha256.convert(bytes).toString()}';
  }

  /// Dəyər artıq hash formatındadırmı?
  static bool isHash(String value) => value.startsWith(_prefix);

  /// Daxil edilən açıq parolanın saxlanmış dəyərə uyğunluğunu yoxlayır.
  static bool verify(String userId, String plainPassword, String stored) {
    if (stored.isEmpty || plainPassword.isEmpty) return false;
    return stored == hash(userId, plainPassword);
  }

  /// Parola təhlükəsizlik siyasəti validasiyası (min 6 simvol).
  static String? validate(String? value, {int minLength = 6}) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Şifrə boş ola bilməz';
    if (v.length < minLength) return 'Şifrə ən azı $minLength simvol olmalıdır';
    return null;
  }
}
