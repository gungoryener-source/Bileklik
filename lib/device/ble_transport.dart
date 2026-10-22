import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'transport.dart';

/// Gerçek bileklikle Bluetooth Low Energy üzerinden konuşan katman
/// (flutter_blue_plus).
///
/// V8 API PDF'ine göre servis 0xFFF0; komutlar 0xFFF6'ya yazılır, yanıtlar
/// 0xFFF7 bildirimiyle gelir. UUID'ler, bilekliğin yayın adı ve bir
/// bildirimin tek paket taşıdığı varsayımı gerçek cihazda doğrulanacak.
///
/// Lisans: flutter_blue_plus ticari kullanımda ücretli lisans ister; şimdilik
/// [License.nonprofit] ile kullanılıyor. Ürün satışa çıkmadan önce yeniden
/// değerlendirilecek.
class BleTransport implements DeviceTransport {
  /// [prefs] verilirse eşleştirilen bileklik saklanır; uygulama yeniden
  /// açıldığında arama yapmadan ona bağlanılır.
  BleTransport({
    SharedPreferences? prefs,
    this.scanTimeout = const Duration(seconds: 8),
    this.connectTimeout = const Duration(seconds: 15),
  }) : _prefs = prefs {
    final id = prefs?.getString(_idKey);
    if (id != null) {
      _device = BluetoothDevice.fromId(id);
      _name = prefs?.getString(_nameKey) ?? _name;
    }
  }

  static const _idKey = 'paired_device_id';
  static const _nameKey = 'paired_device_name';
  final SharedPreferences? _prefs;

  static final serviceUuid = Guid('fff0');
  static final writeUuid = Guid('fff6');
  static final notifyUuid = Guid('fff7');

  /// Yayın adı bu öneklerden biriyle başlayanlar bileklik sayılır (servis
  /// UUID'si yayında yoksa). Gerçek cihazda doğrulanacak.
  static const namePrefixes = ['JCV8', 'V8'];

  final Duration scanTimeout;
  final Duration connectTimeout;

  final _state = StreamController<DeviceConnectionState>.broadcast();
  final _incoming = StreamController<List<int>>.broadcast();

  BluetoothDevice? _device;
  BluetoothCharacteristic? _write;
  StreamSubscription<List<int>>? _notifySub;
  StreamSubscription<BluetoothConnectionState>? _connSub;
  String _name = 'JCV8';
  bool _connected = false;

  @override
  String get name => _name;

  @override
  Stream<DeviceConnectionState> get state => _state.stream;

  @override
  Stream<List<int>> get incoming => _incoming.stream;

  @override
  Future<List<DiscoveredDevice>> scan() async {
    await _ensureAdapterOn();
    final results = <String, ScanResult>{};
    Object? streamError;
    final sub = FlutterBluePlus.onScanResults.listen(
      (list) {
        for (final r in list) {
          results[r.device.remoteId.str] = r;
        }
      },
      onError: (Object e) => streamError = e,
    );
    try {
      await FlutterBluePlus.startScan(timeout: scanTimeout);
      await FlutterBluePlus.isScanning
          .where((s) => !s)
          .first
          .timeout(scanTimeout + const Duration(seconds: 5), onTimeout: () => false);
    } on FlutterBluePlusException catch (e) {
      throw _scanError(e);
    } finally {
      await sub.cancel();
      if (FlutterBluePlus.isScanningNow) {
        await FlutterBluePlus.stopScan();
      }
    }
    final error = streamError;
    if (error is FlutterBluePlusException) throw _scanError(error);
    final found = [
      for (final r in results.values)
        if (_isWristband(r)) _toDiscovered(r),
    ]..sort((a, b) => b.rssi.compareTo(a.rssi));
    return found;
  }

  /// Bluetooth açık değilse uygun [ScanException] fırlatır.
  Future<void> _ensureAdapterOn() async {
    if (!await FlutterBluePlus.isSupported) {
      throw const ScanException(ScanProblem.unsupported);
    }
    // iOS ilk açılışta izin sorarken durum bir süre "unknown" kalır.
    final s = await FlutterBluePlus.adapterState
        .where((s) => s != BluetoothAdapterState.unknown)
        .first
        .timeout(
          const Duration(seconds: 10),
          onTimeout: () => BluetoothAdapterState.unknown,
        );
    switch (s) {
      case BluetoothAdapterState.on:
        return;
      case BluetoothAdapterState.unauthorized:
        throw const ScanException(ScanProblem.permissionDenied);
      case BluetoothAdapterState.unavailable:
        throw const ScanException(ScanProblem.unsupported);
      case BluetoothAdapterState.unknown ||
          BluetoothAdapterState.turningOn ||
          BluetoothAdapterState.turningOff ||
          BluetoothAdapterState.off:
        throw const ScanException(ScanProblem.bluetoothOff);
    }
  }

  /// Android 12+ izinleri flutter_blue_plus arama başlarken ister; reddedilirse
  /// hata metninde "permission" geçer.
  ScanException _scanError(FlutterBluePlusException e) {
    final text = '${e.function} ${e.description ?? ''}'.toLowerCase();
    if (text.contains('permission') || text.contains('location')) {
      return ScanException(ScanProblem.permissionDenied, e.toString());
    }
    if (e.code == FbpErrorCode.adapterIsOff.index || text.contains('off')) {
      return ScanException(ScanProblem.bluetoothOff, e.toString());
    }
    return ScanException(ScanProblem.unsupported, e.toString());
  }

  static bool _isWristband(ScanResult r) {
    if (r.advertisementData.serviceUuids.contains(serviceUuid)) return true;
    final n = _nameOf(r).toUpperCase();
    return namePrefixes.any(n.startsWith);
  }

  static String _nameOf(ScanResult r) {
    final adv = r.advertisementData.advName;
    if (adv.isNotEmpty) return adv;
    return r.device.platformName;
  }

  static DiscoveredDevice _toDiscovered(ScanResult r) {
    final id = r.device.remoteId.str;
    final name = _nameOf(r);
    return DiscoveredDevice(
      name: name.isEmpty ? 'JCV8' : name,
      address: _addressOf(r) ?? id,
      rssi: r.rssi,
      platformId: id,
    );
  }

  /// Android'de kimlik zaten MAC adresidir. iOS adresi vermez; bileklik
  /// adresini üretici verisinde (6 bayt) yayınlıyorsa oradan okunur. Bu
  /// alanın varlığı gerçek cihazda doğrulanacak.
  static String? _addressOf(ScanResult r) {
    final id = normalizeAddress(r.device.remoteId.str);
    if (id != null) return id;
    for (final bytes in r.advertisementData.manufacturerData.values) {
      if (bytes.length == 6) {
        return normalizeAddress(
          bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(),
        );
      }
    }
    return null;
  }

  @override
  void select(DiscoveredDevice device) {
    _device = BluetoothDevice.fromId(device.connectId);
    _name = device.name;
    unawaited(_prefs?.setString(_idKey, device.connectId));
    unawaited(_prefs?.setString(_nameKey, device.name));
  }

  @override
  Future<void> connect() async {
    final d = _device;
    if (d == null) throw const DeviceNotPairedException();
    _state.add(DeviceConnectionState.connecting);
    try {
      // Android'de MTU 512 istenir; 0x09 anlık veri (32 bayt) varsayılan
      // 23 baytlık MTU'ya sığmaz. iOS MTU'yu kendisi ayarlar.
      await d.connect(license: License.nonprofit, timeout: connectTimeout);
      final services = await d.discoverServices();
      final service = services.where((s) => s.uuid == serviceUuid).firstOrNull;
      if (service == null) throw StateError('0xFFF0 servisi bulunamadı');
      final write = service.characteristics
          .where((c) => c.uuid == writeUuid)
          .firstOrNull;
      final notify = service.characteristics
          .where((c) => c.uuid == notifyUuid)
          .firstOrNull;
      if (write == null || notify == null) {
        throw StateError('0xFFF6/0xFFF7 karakteristikleri bulunamadı');
      }
      await _notifySub?.cancel();
      final sub = notify.onValueReceived.listen(_incoming.add);
      d.cancelWhenDisconnected(sub);
      _notifySub = sub;
      await notify.setNotifyValue(true);
      _write = write;
      await _connSub?.cancel();
      _connSub = d.connectionState.listen(_onConnectionState);
      _connected = true;
      _state.add(DeviceConnectionState.connected);
    } catch (_) {
      _write = null;
      _connected = false;
      try {
        await d.disconnect();
      } catch (e) {
        debugPrint('BLE bağlantısı kapatılamadı: $e');
      }
      _state.add(DeviceConnectionState.disconnected);
      rethrow;
    }
  }

  /// Bileklik uzaklaşınca ya da kapanınca bağlantı kendiliğinden kopar.
  void _onConnectionState(BluetoothConnectionState s) {
    if (s != BluetoothConnectionState.disconnected || !_connected) return;
    _connected = false;
    _write = null;
    _state.add(DeviceConnectionState.disconnected);
  }

  @override
  Future<void> disconnect() async {
    _connected = false;
    _write = null;
    await _connSub?.cancel();
    _connSub = null;
    await _notifySub?.cancel();
    _notifySub = null;
    await _device?.disconnect();
    _state.add(DeviceConnectionState.disconnected);
  }

  @override
  Future<void> send(List<int> bytes) async {
    final w = _write;
    if (w == null) throw StateError('Cihaz bağlı değil');
    // Yanıtlı yazma destekleniyorsa onu kullan; yoksa yanıtsız.
    final props = w.properties;
    await w.write(bytes, withoutResponse: !props.write && props.writeWithoutResponse);
  }
}
