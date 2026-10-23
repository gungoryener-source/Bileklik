import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';

/// Hekim şifrelerinin özeti: PBKDF2-HMAC-SHA256, 16 baytlık rastgele tuz.
///
/// Saklanan biçim `pbkdf2-sha256$<tur>$<tuz>$<özet>` (base64). Tur sayısı
/// özetin içinde durduğu için sonradan artırılabilir; eski özetler yine
/// doğrulanır. Şifrenin kendisi hiçbir yerde saklanmaz.
class PasswordHasher {
  const PasswordHasher({this.iterations = defaultIterations});

  /// Sunucuda varsayılan tur sayısı. Tarayıcı demosu ve testler daha az
  /// kullanır (yalnızca hız için; gerçek veri yoktur).
  static const defaultIterations = 120000;

  /// En kısa şifre.
  static const minLength = 10;

  final int iterations;

  static const _prefix = 'pbkdf2-sha256';

  Future<String> hash(String password, {Random? random}) async {
    final r = random ?? Random.secure();
    final salt = List.generate(16, (_) => r.nextInt(256));
    final digest = await _derive(password, salt, iterations);
    return '$_prefix\$$iterations\$${base64.encode(salt)}\$${base64.encode(digest)}';
  }

  /// [stored] özetiyle karşılaştırır; biçim bozuksa false.
  Future<bool> verify(String password, String stored) async {
    final parts = stored.split(r'$');
    if (parts.length != 4 || parts[0] != _prefix) return false;
    final rounds = int.tryParse(parts[1]);
    if (rounds == null || rounds < 1) return false;
    final List<int> salt;
    final List<int> expected;
    try {
      salt = base64.decode(parts[2]);
      expected = base64.decode(parts[3]);
    } on FormatException {
      return false;
    }
    final actual = await _derive(password, salt, rounds);
    if (actual.length != expected.length) return false;
    // Sabit zamanlı karşılaştırma.
    var diff = 0;
    for (var i = 0; i < actual.length; i++) {
      diff |= actual[i] ^ expected[i];
    }
    return diff == 0;
  }

  static Future<List<int>> _derive(
    String password,
    List<int> salt,
    int rounds,
  ) async {
    final key = await Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: rounds,
      bits: 256,
    ).deriveKeyFromPassword(password: password, nonce: salt);
    return key.extractBytes();
  }
}
