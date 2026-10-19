import 'dart:async';
import 'dart:math';

import 'fake_history.dart';
import 'protocol/commands.dart';
import 'protocol/history.dart';
import 'protocol/packet.dart';
import 'transport.dart';

/// Bileklik elde yokken onun yerine geçen sahte cihaz.
///
/// Gelen komutlara V8 API PDF'indeki biçimde yanıt verir ve anlık mod açıkken
/// gerçekçi adım, nabız, ısı ve SpO2 değerleri üretir. Geçmiş komutlarına
/// son 7 günün kayıtlarıyla yanıt verir.
class FakeDevice implements DeviceTransport {
  FakeDevice({
    Random? random,
    this.realtimeInterval = const Duration(seconds: 2),
    DateTime Function()? clock,
  }) : _random = random ?? Random(),
       _clock = clock ?? DateTime.now;

  final Random _random;
  final DateTime Function() _clock;
  final Duration realtimeInterval;
  final history = FakeHistory();

  final _state = StreamController<DeviceConnectionState>.broadcast();
  final _incoming = StreamController<List<int>>.broadcast();
  bool _connected = false;
  Timer? _realtimeTimer;
  Duration _clockOffset = Duration.zero;

  PersonalInfo _profile = const PersonalInfo(
    isMale: true,
    age: 35,
    heightCm: 175,
    weightKg: 75,
    stepLengthCm: 70,
  );
  int _battery = 82;
  int _steps = 3200;
  int _heartRate = 72;
  double _temperature = 34.6;
  int _spo2 = 97;

  static const mac = [0xA1, 0xB2, 0xC3, 0xD4, 0xE5, 0xF6];

  @override
  String get name => 'Sahte bileklik (JCV8)';

  @override
  Stream<DeviceConnectionState> get state => _state.stream;

  @override
  Stream<List<int>> get incoming => _incoming.stream;

  @override
  Future<void> connect() async {
    _state.add(DeviceConnectionState.connecting);
    await Future<void>.delayed(const Duration(milliseconds: 300));
    _connected = true;
    _state.add(DeviceConnectionState.connected);
  }

  @override
  Future<void> disconnect() async {
    _realtimeTimer?.cancel();
    _connected = false;
    _state.add(DeviceConnectionState.disconnected);
  }

  @override
  Future<void> send(List<int> bytes) async {
    if (!_connected) throw StateError('Cihaz bağlı değil');
    final Packet cmd;
    try {
      cmd = Packet.parse(bytes);
    } on FormatException {
      // Gerçek cihaz CRC hatasında komutun 7. bitini 1 yapıp boş yanıt döner.
      _reply(Packet.error(bytes.isEmpty ? 0 : bytes[0]).bytes);
      return;
    }
    scheduleMicrotask(() => _handle(cmd));
  }

  void _handle(Packet cmd) {
    final d = cmd.payload;
    switch (cmd.command) {
      case Cmd.setTime:
        final deviceTime = DateTime(
          2000 + fromBcd(d[0]),
          fromBcd(d[1]),
          fromBcd(d[2]),
          fromBcd(d[3]),
          fromBcd(d[4]),
          fromBcd(d[5]),
        );
        _clockOffset = deviceTime.difference(_clock());
        _reply(Packet.build(Cmd.setTime, [0xF4]).bytes);
      case Cmd.getTime:
        final t = _clock().add(_clockOffset);
        _reply(
          Packet.build(Cmd.getTime, [
            toBcd(t.year % 100),
            toBcd(t.month),
            toBcd(t.day),
            toBcd(t.hour),
            toBcd(t.minute),
            toBcd(t.second),
            t.weekday,
            0xF4,
          ]).bytes,
        );
      case Cmd.setPersonalInfo:
        _profile = PersonalInfo(
          isMale: d[0] == 1,
          age: d[1],
          heightCm: d[2],
          weightKg: d[3],
          stepLengthCm: _profile.stepLengthCm,
        );
        _reply(Packet.build(Cmd.setPersonalInfo).bytes);
      case Cmd.getPersonalInfo:
        _reply(
          Packet.build(Cmd.getPersonalInfo, [
            _profile.isMale ? 1 : 0,
            _profile.age,
            _profile.heightCm,
            _profile.weightKg,
            _profile.stepLengthCm ?? 0,
            ...mac,
          ]).bytes,
        );
      case Cmd.batteryLevel:
        _reply(Packet.build(Cmd.batteryLevel, [_battery, 0, 0x0F, 0xA0]).bytes);
      case Cmd.realtime:
        _realtimeTimer?.cancel();
        if (d[0] == 1) {
          _emitRealtime();
          _realtimeTimer = Timer.periodic(
            realtimeInterval,
            (_) => _emitRealtime(),
          );
        } else {
          _reply(Packet.build(Cmd.realtime).bytes);
        }
      default:
        if (HistoryKind.byCommand(cmd.command) != null) {
          history.respond(cmd, _clock().add(_clockOffset)).forEach(_reply);
        } else {
          _reply(Packet.error(cmd.command).bytes);
        }
    }
  }

  void _emitRealtime() {
    _steps += _random.nextInt(25);
    _heartRate = (_heartRate + _random.nextInt(7) - 3).clamp(58, 110);
    _temperature = ((_temperature + (_random.nextDouble() - 0.5) * 0.2).clamp(
      33.5,
      36.0,
    ));
    _spo2 = (_spo2 + _random.nextInt(3) - 1).clamp(94, 99);
    if (_random.nextInt(30) == 0 && _battery > 5) _battery--;

    final calories = (_steps * 0.04 * 100).round(); // kcal x 100
    final distance = (_steps * (_profile.stepLengthCm ?? 70) / 1000)
        .round(); // km x 100
    final temp = (_temperature * 10).round();
    final raw = List<int>.filled(32, 0);
    raw[0] = Cmd.realtime;
    _writeLE(raw, 1, _steps, 4);
    _writeLE(raw, 5, calories, 4);
    _writeLE(raw, 9, distance, 4);
    raw[21] = _heartRate;
    _writeLE(raw, 22, temp, 2);
    raw[24] = _spo2;
    _reply(raw);
  }

  static void _writeLE(List<int> out, int offset, int value, int count) {
    for (var i = 0; i < count; i++) {
      out[offset + i] = (value >> (8 * i)) & 0xFF;
    }
  }

  void _reply(List<int> bytes) {
    if (_connected) _incoming.add(List.unmodifiable(bytes));
  }

  void dispose() {
    _realtimeTimer?.cancel();
    _state.close();
    _incoming.close();
  }
}
