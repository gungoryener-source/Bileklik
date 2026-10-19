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

  Future<void> connect();
  Future<void> disconnect();
  Future<void> send(List<int> bytes);
}
