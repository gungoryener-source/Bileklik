import 'dart:async';

import 'protocol/commands.dart';
import 'protocol/packet.dart';
import 'transport.dart';

class DeviceCommandException implements Exception {
  final int command;
  final String message;
  DeviceCommandException(this.command, this.message);

  @override
  String toString() =>
      'Komut 0x${command.toRadixString(16).padLeft(2, '0')}: $message';
}

/// Bileklik komutlarını gönderip yanıtlarını çözen katman.
///
/// Her komut için cihazın aynı komut koduyla döndüğü yanıtı bekler.
/// 0x09 anlık veri akışı ayrı bir yayın olarak sunulur.
class WristbandClient {
  WristbandClient(this.transport, {this.timeout = const Duration(seconds: 5)}) {
    _sub = transport.incoming.listen(_onData);
  }

  final DeviceTransport transport;
  final Duration timeout;
  late final StreamSubscription<List<int>> _sub;
  final _pending = <int, Completer<Packet>>{};
  final _realtime = StreamController<RealtimeData>.broadcast();

  Stream<RealtimeData> get realtime => _realtime.stream;

  void _onData(List<int> raw) {
    if (raw.isEmpty) return;
    final command = raw[0] & 0x7F;
    if (command == Cmd.realtime && raw.length > Packet.length) {
      _realtime.add(Decoders.realtime(raw));
      return;
    }
    final completer = _pending.remove(command);
    if (completer == null) return;
    try {
      final packet = Packet.parse(raw);
      if (packet.isError) {
        completer.completeError(
            DeviceCommandException(command, 'cihaz hata döndü'));
      } else {
        completer.complete(packet);
      }
    } on FormatException catch (e) {
      completer.completeError(DeviceCommandException(command, e.message));
    }
  }

  Future<Packet> _request(Packet packet) {
    final completer = Completer<Packet>();
    _pending[packet.command]?.completeError(
        DeviceCommandException(packet.command, 'yeni istekle değiştirildi'));
    _pending[packet.command] = completer;
    transport.send(packet.bytes);
    return completer.future.timeout(timeout, onTimeout: () {
      _pending.remove(packet.command);
      throw DeviceCommandException(packet.command, 'yanıt gelmedi');
    });
  }

  Future<void> syncTime(DateTime now) => _request(Commands.setTime(now));

  Future<DateTime> getTime() async =>
      Decoders.time(await _request(Commands.getTime()));

  Future<void> setPersonalInfo(PersonalInfo info) =>
      _request(Commands.setPersonalInfo(info));

  Future<PersonalInfo> getPersonalInfo() async =>
      Decoders.personalInfo(await _request(Commands.getPersonalInfo()));

  Future<BatteryStatus> getBattery() async =>
      Decoders.battery(await _request(Commands.batteryLevel()));

  Future<void> startRealtime() => transport.send(Commands.realtime(true).bytes);

  Future<void> stopRealtime() => _request(Commands.realtime(false));

  Future<void> dispose() async {
    await _sub.cancel();
    await _realtime.close();
  }
}
