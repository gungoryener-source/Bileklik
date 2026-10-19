import 'dart:async';

enum DeviceConnectionState { disconnected, connecting, connected }

/// Bileklikle bayt alışverişi yapan katman.
///
/// Gerçek bileklik (BLE, servis 0xFFF0, yazma 0xFFF6, bildirim 0xFFF7) ve
/// sahte cihaz bu arayüzü uygular. Üstteki katmanlar hangisine bağlı
/// olduklarını bilmez.
abstract class DeviceTransport {
  String get name;
  Stream<DeviceConnectionState> get state;
  Stream<List<int>> get incoming;

  /// Yakındaki bileklikleri arar. Gerçek BLE katmanında ad ve servis
  /// (0xFFF0) ile süzülecek; gerçek cihazda doğrulanacak.
  Future<List<DiscoveredDevice>> scan();

  Future<void> connect();
  Future<void> disconnect();
  Future<void> send(List<int> bytes);
}

/// Aramada bulunan bileklik.
class DiscoveredDevice {
  const DiscoveredDevice({
    required this.name,
    required this.address,
    required this.rssi,
  });

  final String name;

  /// "A1:B2:C3:D4:E5:F6" biçiminde adres (QR kodunda da bu yazar).
  final String address;

  /// Sinyal gücü, dBm.
  final int rssi;
}

/// Kullanıcının yazdığı adresi "A1:B2:C3:D4:E5:F6" biçimine getirir;
/// 12 onaltılık karakter değilse null.
String? normalizeAddress(String input) {
  final hex = input.replaceAll(RegExp(r'[\s:\-]'), '').toUpperCase();
  if (!RegExp(r'^[0-9A-F]{12}$').hasMatch(hex)) return null;
  return [for (var i = 0; i < 12; i += 2) hex.substring(i, i + 2)].join(':');
}
