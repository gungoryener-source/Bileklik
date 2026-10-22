import 'dart:async';

enum DeviceConnectionState { disconnected, connecting, connected }

/// Bileklikle bayt alışverişi yapan katman.
///
/// Gerçek bileklik (`BleTransport`: servis 0xFFF0, yazma 0xFFF6, bildirim
/// 0xFFF7) ve sahte cihaz bu arayüzü uygular. Üstteki katmanlar hangisine
/// bağlı olduklarını bilmez.
abstract class DeviceTransport {
  String get name;
  Stream<DeviceConnectionState> get state;
  Stream<List<int>> get incoming;

  /// Yakındaki bileklikleri arar. Bluetooth kapalıysa, izin yoksa ya da
  /// telefon BLE desteklemiyorsa [ScanException] fırlatır.
  Future<List<DiscoveredDevice>> scan();

  /// [connect] çağrısının bağlanacağı bilekliği seçer (aramada bulunan).
  void select(DiscoveredDevice device);

  Future<void> connect();
  Future<void> disconnect();
  Future<void> send(List<int> bytes);
}

/// Aramanın neden yapılamadığı; ekran kullanıcının dilinde gösterir.
enum ScanProblem {
  /// Telefonun Bluetooth'u kapalı.
  bluetoothOff,

  /// Kullanıcı Bluetooth (ya da eski Android'de konum) iznini vermedi.
  permissionDenied,

  /// Telefon Bluetooth Low Energy desteklemiyor (ör. web, eski cihaz).
  unsupported,
}

class ScanException implements Exception {
  const ScanException(this.problem, [this.detail]);

  final ScanProblem problem;
  final String? detail;

  @override
  String toString() =>
      'ScanException(${problem.name}${detail == null ? '' : ': $detail'})';
}

/// Henüz bir bileklik eşleştirilmeden [DeviceTransport.connect] çağrıldı.
class DeviceNotPairedException implements Exception {
  const DeviceNotPairedException();

  @override
  String toString() => 'DeviceNotPairedException';
}

/// Aramada bulunan bileklik.
class DiscoveredDevice {
  const DiscoveredDevice({
    required this.name,
    required this.address,
    required this.rssi,
    this.platformId,
  });

  final String name;

  /// "A1:B2:C3:D4:E5:F6" biçiminde adres (QR kodunda da bu yazar).
  final String address;

  /// Sinyal gücü, dBm.
  final int rssi;

  /// Bağlanırken kullanılan platform kimliği. Android'de adresin kendisi;
  /// iOS adresi göstermez, orada sistemin verdiği UUID'dir.
  final String? platformId;

  String get connectId => platformId ?? address;
}

/// Kullanıcının yazdığı adresi "A1:B2:C3:D4:E5:F6" biçimine getirir;
/// 12 onaltılık karakter değilse null.
String? normalizeAddress(String input) {
  final hex = input.replaceAll(RegExp(r'[\s:\-]'), '').toUpperCase();
  if (!RegExp(r'^[0-9A-F]{12}$').hasMatch(hex)) return null;
  return [for (var i = 0; i < 12; i += 2) hex.substring(i, i + 2)].join(':');
}

/// QR kodundan bileklik adresini çıkarır. QR'da yalnızca adres olabileceği
/// gibi başka metinle birlikte (ör. "JCV8 MAC:A1B2C3D4E5F6") de olabilir;
/// metindeki ilk adres alınır. QR içeriğinin biçimi gerçek cihazda
/// doğrulanacak.
String? addressFromQr(String raw) {
  final direct = normalizeAddress(raw.trim());
  if (direct != null) return direct;
  final m = RegExp(
    r'(?<![0-9A-Fa-f])([0-9A-Fa-f]{2}(?:[:\-]?[0-9A-Fa-f]{2}){5})(?![0-9A-Fa-f])',
  ).firstMatch(raw);
  return m == null ? null : normalizeAddress(m.group(1)!);
}
