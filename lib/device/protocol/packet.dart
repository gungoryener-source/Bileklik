import 'dart:typed_data';

/// JCV8 bileklik protokolündeki 16 baytlık paket.
///
/// Bayt 0 komut, bayt 1-14 veri, bayt 15 CRC'dir.
/// CRC, ilk 15 baytın toplamının en düşük 8 bitidir (V8 API PDF, bölüm 2).
class Packet {
  static const int length = 16;

  /// Cihaz CRC hatası ya da başarısız işlemde komutun 7. bitini 1 yapar.
  static const int errorBit = 0x80;

  final Uint8List bytes;

  Packet._(this.bytes);

  /// Komut ve en fazla 14 baytlık veriyle CRC'si hesaplanmış paket üretir.
  factory Packet.build(int command, [List<int> payload = const []]) {
    if (command < 0 || command > 0x7F) {
      throw ArgumentError.value(command, 'command', '0x00-0x7F aralığında olmalı');
    }
    if (payload.length > 14) {
      throw ArgumentError.value(payload.length, 'payload', 'en fazla 14 bayt');
    }
    final bytes = Uint8List(length);
    bytes[0] = command;
    for (var i = 0; i < payload.length; i++) {
      bytes[i + 1] = payload[i] & 0xFF;
    }
    bytes[15] = crc(bytes);
    return Packet._(bytes);
  }

  /// Cihazın CRC hatası ya da başarısız işlemde döndüğü yanıt (ör. 0x81).
  factory Packet.error(int command) {
    final bytes = Uint8List(length);
    bytes[0] = (command & 0x7F) | errorBit;
    bytes[15] = crc(bytes);
    return Packet._(bytes);
  }

  /// Cihazdan gelen 16 baytlık yanıtı doğrular.
  factory Packet.parse(List<int> raw) {
    if (raw.length != length) {
      throw FormatException('Paket 16 bayt olmalı, ${raw.length} geldi');
    }
    final bytes = Uint8List.fromList(raw);
    if (crc(bytes) != bytes[15]) {
      throw const FormatException('CRC uyuşmuyor');
    }
    return Packet._(bytes);
  }

  /// İlk 15 baytın toplamının en düşük 8 biti.
  static int crc(List<int> bytes) {
    var sum = 0;
    for (var i = 0; i < 15; i++) {
      sum += bytes[i];
    }
    return sum & 0xFF;
  }

  int get command => bytes[0] & 0x7F;
  bool get isError => bytes[0] & errorBit != 0;
  Uint8List get payload => Uint8List.sublistView(bytes, 1, 15);
}

/// BCD kodlu bir baytı sayıya çevirir (0x24 -> 24).
int fromBcd(int b) => ((b >> 4) & 0x0F) * 10 + (b & 0x0F);

/// Sayıyı BCD kodlu bayta çevirir (24 -> 0x24).
int toBcd(int v) => ((v ~/ 10) << 4) | (v % 10);

/// Küçük sonlu (little-endian) işaretsiz tamsayı okur.
int readUintLE(List<int> bytes, int offset, int count) {
  var value = 0;
  for (var i = count - 1; i >= 0; i--) {
    value = (value << 8) | bytes[offset + i];
  }
  return value;
}
