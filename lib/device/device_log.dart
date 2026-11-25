import 'dart:async';

import 'package:flutter/foundation.dart';

import 'transport.dart';

/// Kaydın türü: telefondan giden, bileklikten gelen ya da bir olay.
enum LogKind { tx, rx, event, error }

class LogEntry {
  const LogEntry(this.time, this.kind, this.text);

  final DateTime time;
  final LogKind kind;
  final String text;

  String get _tag => switch (kind) {
    LogKind.tx => '>>',
    LogKind.rx => '<<',
    LogKind.event => '--',
    LogKind.error => '!!',
  };

  /// "08:41:28.123 >> 13 00 … 13" biçiminde tek satır.
  String format() {
    String two(int v) => v.toString().padLeft(2, '0');
    final ms = time.millisecond.toString().padLeft(3, '0');
    return '${two(time.hour)}:${two(time.minute)}:${two(time.second)}.$ms '
        '$_tag $text';
  }
}

/// Bileklikle yapılan bayt alışverişinin son kayıtları (bellekte).
///
/// Gerçek bileklikle ilk denemelerde sorun teşhisi için: Cihaz > Bağlantı
/// tanılama ekranı gösterir ve metin olarak paylaşır. Sağlık verisi
/// içerebileceği için diske yazılmaz; yalnızca kullanıcı paylaşırsa çıkar.
class DeviceLog extends ChangeNotifier {
  DeviceLog({this.capacity = 5000});

  final int capacity;
  final _entries = <LogEntry>[];

  List<LogEntry> get entries => List.unmodifiable(_entries);

  void add(LogKind kind, String text) {
    _entries.add(LogEntry(DateTime.now(), kind, text));
    if (_entries.length > capacity) {
      _entries.removeRange(0, _entries.length - capacity);
    }
    // Geçmiş eşitlemesinde saniyede yüzlerce paket gelir; ekran en çok
    // 10 kez yenilenir.
    _notify ??= Timer(const Duration(milliseconds: 100), () {
      _notify = null;
      notifyListeners();
    });
  }

  Timer? _notify;

  @override
  void dispose() {
    _notify?.cancel();
    super.dispose();
  }

  void event(String text) => add(LogKind.event, text);
  void error(String text) => add(LogKind.error, text);

  void clear() {
    _entries.clear();
    _notify?.cancel();
    _notify = null;
    notifyListeners();
  }

  /// Paylaşılacak düz metin; en eskisi başta.
  String export({String? header}) {
    final b = StringBuffer();
    if (header != null) b.writeln(header);
    for (final e in _entries) {
      b.writeln(e.format());
    }
    return b.toString();
  }
}

/// Baytları "13 00 FF" biçiminde yazar.
String hexBytes(List<int> bytes) => bytes
    .map((b) => (b & 0xFF).toRadixString(16).padLeft(2, '0').toUpperCase())
    .join(' ');

/// "13 00 ff" ya da "1300FF" metnini baytlara çevirir; geçersizse null.
List<int>? parseHex(String input) {
  final hex = input.replaceAll(RegExp(r'[\s,:\-]|0x'), '');
  if (hex.isEmpty || hex.length.isOdd) return null;
  if (!RegExp(r'^[0-9a-fA-F]+$').hasMatch(hex)) return null;
  return [
    for (var i = 0; i < hex.length; i += 2)
      int.parse(hex.substring(i, i + 2), radix: 16),
  ];
}

/// Herhangi bir [DeviceTransport]'u saran ve trafiği [DeviceLog]'a yazan
/// katman. Sahte cihazla da çalışır; böylece tanılama ekranı testte de
/// aynı davranır.
class LoggingTransport implements DeviceTransport {
  LoggingTransport(this.inner, this.log) {
    _rxSub = inner.incoming.listen((b) => log.add(LogKind.rx, hexBytes(b)));
    _stateSub = inner.state.listen((s) => log.event('durum: ${s.name}'));
  }

  final DeviceTransport inner;
  final DeviceLog log;
  late final StreamSubscription<List<int>> _rxSub;
  late final StreamSubscription<DeviceConnectionState> _stateSub;

  /// Uygulama kapanırken; testlerde dinleyici bırakmamak için.
  Future<void> dispose() async {
    await _rxSub.cancel();
    await _stateSub.cancel();
  }

  @override
  String get name => inner.name;

  @override
  Stream<DeviceConnectionState> get state => inner.state;

  @override
  Stream<List<int>> get incoming => inner.incoming;

  @override
  bool get hasPairedDevice => inner.hasPairedDevice;

  @override
  String? get pairedId => inner.pairedId;

  @override
  int get maxWriteLength => inner.maxWriteLength;

  @override
  Future<List<DiscoveredDevice>> scan({bool all = false}) async {
    log.event(all ? 'arama başladı (tüm cihazlar)' : 'arama başladı');
    try {
      final found = await inner.scan(all: all);
      log.event('arama bitti: ${found.length} cihaz');
      for (final d in found) {
        log.event(
          '  ${d.name} ${d.connectId} ${d.rssi} dBm'
          '${d.details == null ? '' : ' ${d.details}'}',
        );
      }
      return found;
    } catch (e) {
      log.error('arama hatası: $e');
      rethrow;
    }
  }

  @override
  void select(DiscoveredDevice device) {
    log.event('seçildi: ${device.name} ${device.connectId}');
    inner.select(device);
  }

  @override
  void forget() {
    log.event('eşleştirme silindi');
    inner.forget();
  }

  @override
  Future<void> connect() async {
    log.event('bağlanılıyor: ${inner.name} ${inner.pairedId ?? '-'}');
    try {
      await inner.connect();
      log.event('bağlandı, yazma boyu ${inner.maxWriteLength}');
    } catch (e) {
      log.error('bağlantı hatası: $e');
      rethrow;
    }
  }

  @override
  Future<void> disconnect() async {
    log.event('bağlantı kesiliyor');
    await inner.disconnect();
  }

  @override
  Future<void> send(List<int> bytes) async {
    log.add(LogKind.tx, hexBytes(bytes));
    try {
      await inner.send(bytes);
    } catch (e) {
      log.error('gönderilemedi: $e');
      rethrow;
    }
  }
}
