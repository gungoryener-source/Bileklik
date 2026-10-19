import 'dart:async';

import 'package:flutter/foundation.dart';

import '../device/protocol/commands.dart';
import '../device/transport.dart';
import '../device/wristband_client.dart';

/// Ekranların bileklik durumunu dinlediği tek nokta.
///
/// Hangi cihaz katmanının (sahte ya da gerçek) kullanılacağı dışarıdan verilir.
class DeviceController extends ChangeNotifier {
  DeviceController(this._transport) : _client = WristbandClient(_transport) {
    _stateSub = _transport.state.listen((s) {
      connection = s;
      notifyListeners();
    });
    _realtimeSub = _client.realtime.listen((d) {
      live = d;
      lastUpdate = DateTime.now();
      notifyListeners();
    });
  }

  final DeviceTransport _transport;
  final WristbandClient _client;
  late final StreamSubscription<DeviceConnectionState> _stateSub;
  late final StreamSubscription<RealtimeData> _realtimeSub;

  DeviceConnectionState connection = DeviceConnectionState.disconnected;
  RealtimeData? live;
  BatteryStatus? battery;
  PersonalInfo? profile;
  DateTime? lastUpdate;
  String? error;

  String get deviceName => _transport.name;
  bool get isConnected => connection == DeviceConnectionState.connected;

  Future<void> connect() async {
    error = null;
    try {
      await _transport.connect();
      await _client.syncTime(DateTime.now());
      battery = await _client.getBattery();
      profile = await _client.getPersonalInfo();
      await _client.startRealtime();
    } catch (e) {
      error = e.toString();
    }
    notifyListeners();
  }

  Future<void> disconnect() async {
    await _transport.disconnect();
    live = null;
    notifyListeners();
  }

  Future<void> saveProfile(PersonalInfo info) async {
    error = null;
    try {
      await _client.setPersonalInfo(info);
      profile = await _client.getPersonalInfo();
    } catch (e) {
      error = e.toString();
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _stateSub.cancel();
    _realtimeSub.cancel();
    _client.dispose();
    super.dispose();
  }
}
