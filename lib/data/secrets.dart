import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Gizli değerlerin (veritabanı anahtarı, portal oturum anahtarı) saklandığı
/// yer. Telefonda [DeviceSecretStore], web ve testlerde [MemorySecretStore].
abstract class SecretStore {
  Future<String?> read(String key);

  /// [value] null ise siler.
  Future<void> write(String key, String? value);

  /// Rastgele 32 bayt, onaltılık (64 karakter).
  static String newKey([Random? random]) {
    final r = random ?? Random.secure();
    return List.generate(
      32,
      (_) => r.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
  }
}

/// iOS Keychain ve Android Keystore üzerinden.
///
/// iOS'ta anahtar telefon ilk kez açıldıktan sonra okunabilir (arka plan
/// senkronu için) ve yedekle başka telefona taşınmaz
/// (`first_unlock_this_device`). Android'de Keystore ile şifrelenir.
class DeviceSecretStore implements SecretStore {
  DeviceSecretStore([FlutterSecureStorage? storage])
    : _storage =
          storage ??
          const FlutterSecureStorage(
            iOptions: IOSOptions(
              accessibility: KeychainAccessibility.first_unlock_this_device,
            ),
          );

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String? value) => value == null
      ? _storage.delete(key: key)
      : _storage.write(key: key, value: value);
}

/// Bellekte; uygulama kapanınca kaybolur.
class MemorySecretStore implements SecretStore {
  MemorySecretStore([Map<String, String>? initial]) : values = {...?initial};

  final Map<String, String> values;

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String? value) async {
    if (value == null) {
      values.remove(key);
    } else {
      values[key] = value;
    }
  }
}
