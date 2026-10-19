import 'dart:async';
import 'dart:math';

import 'fake_history.dart';
import 'protocol/commands.dart';
import 'protocol/exercise.dart';
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
    this.exerciseInterval = const Duration(seconds: 1),
    DateTime Function()? clock,
  }) : _random = random ?? Random(),
       _clock = clock ?? DateTime.now;

  final Random _random;
  final DateTime Function() _clock;
  final Duration realtimeInterval;

  /// Egzersizde 0x18 paketlerinin aralığı; her paket 1 saniyelik ilerleme sayılır.
  final Duration exerciseInterval;
  final history = FakeHistory();

  _FakeExercise? _exercise;
  Timer? _exerciseTimer;

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
    _exerciseTimer?.cancel();
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
      case ExerciseCmd.control:
        _handleExercise(d);
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

  void _handleExercise(List<int> d) {
    final now = _clock().add(_clockOffset);
    final ex = _exercise;
    List<int> time(DateTime t) => [
      toBcd(t.year % 100),
      toBcd(t.month),
      toBcd(t.day),
      toBcd(t.hour),
      toBcd(t.minute),
      toBcd(t.second),
    ];
    void ok(bool success, DateTime t, {bool started = false}) => _reply(
      Packet.build(ExerciseCmd.control, [
        success ? 1 : 0,
        if (!started) 0,
        ...time(t),
      ]).bytes,
    );

    switch (d[0]) {
      case 1: // başlat
        if (ex != null) return ok(false, ex.start, started: true);
        final type = SportType.byCode(d[1]) ?? SportType.run;
        _exercise = _FakeExercise(type, now, _heartRate);
        _exerciseTimer?.cancel();
        _exerciseTimer = Timer.periodic(exerciseInterval, (_) => _tick());
        ok(true, now, started: true);
      case 2: // duraklat
        ex?.paused = true;
        ok(ex != null, ex?.start ?? now);
      case 3: // devam
        ex?.paused = false;
        ok(ex != null, ex?.start ?? now);
      case 4: // bitir
        if (ex != null) _finishExercise(ex);
        ok(ex != null, ex?.start ?? now);
      default: // durum sorgusu
        ok(ex != null, ex?.start ?? now);
    }
  }

  void _tick() {
    final ex = _exercise;
    if (ex == null || ex.paused) return;
    ex.seconds++;
    final (cadence, kmh, kcalPerMin) = switch (ex.type) {
      SportType.run => (2.7, 10.0, 10.5),
      SportType.cycling => (0.0, 18.0, 8.0),
      SportType.walk || SportType.hiking => (1.8, 5.2, 4.5),
      SportType.yoga => (0.0, 0.0, 3.0),
      _ => (1.5, 4.0, 7.0),
    };
    ex.steps += (cadence + _random.nextDouble() - 0.5).round().clamp(0, 5);
    ex.km += kmh / 3600;
    ex.calories += kcalPerMin / 60;
    final target = 90 + (cadence * 20).round() + (kmh * 2).round();
    ex.heartRate =
        (ex.heartRate +
                (ex.heartRate < target ? 2 : 0) +
                _random.nextInt(3) -
                1)
            .clamp(60, 185);
    ex.hrSum += ex.heartRate;

    final raw = List<int>.filled(21, 0);
    raw[0] = ExerciseCmd.live;
    raw[1] = ex.heartRate;
    _writeLE(raw, 2, ex.steps, 4);
    raw.setAll(6, FakeHistory.float32LE(ex.calories));
    _writeLE(raw, 10, ex.seconds, 4);
    raw.setAll(14, FakeHistory.float32LE(ex.km));
    _reply(raw);
  }

  void _finishExercise(_FakeExercise ex) {
    _exerciseTimer?.cancel();
    _exercise = null;
    if (ex.seconds == 0) return;
    history.addExercise(
      ex.start,
      ex.type,
      seconds: ex.seconds,
      steps: ex.steps,
      heartRate: ex.hrSum ~/ ex.seconds,
      calories: ex.calories,
      km: ex.km,
    );
  }

  /// Gerçek cihazın hareketsizlik uyarısını taklit eder (18 AA 01 / 18 AA 02).
  void simulateInactivity(int level) =>
      _reply(Packet.build(ExerciseCmd.live, [0xAA, level]).bytes);

  /// Gerçek cihazın 30 dakika hareketsizlikten sonra egzersizi bitirmesi (18 FF 02).
  void simulateAutoEnd() {
    final ex = _exercise;
    if (ex != null) _finishExercise(ex);
    _reply(Packet.build(ExerciseCmd.live, [0xFF, 2]).bytes);
  }

  void dispose() {
    _realtimeTimer?.cancel();
    _exerciseTimer?.cancel();
    _state.close();
    _incoming.close();
  }
}

class _FakeExercise {
  _FakeExercise(this.type, this.start, this.heartRate);

  final SportType type;
  final DateTime start;
  bool paused = false;
  int seconds = 0;
  int steps = 0;
  double km = 0;
  double calories = 0;
  int heartRate;
  int hrSum = 0;
}
