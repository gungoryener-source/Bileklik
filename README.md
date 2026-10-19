# Bileklik

JCV8 ekransız ECG bileklik için iOS ve Android sağlık uygulaması (Flutter).

Bileklik henüz elde olmadığından uygulama **sahte cihazla** çalışır. Sahte cihaz,
üreticinin V8 API protokolündeki paketlerin aynısını üretir; gerçek bileklik
geldiğinde yalnızca cihaz katmanı değişir.

## Çalıştırma

```sh
flutter pub get
flutter run        # bağlı telefon ya da emülatörde
flutter test       # protokol, sahte cihaz ve ekran testleri
```

## Klasörler

| Klasör | İçerik |
| --- | --- |
| `lib/device/protocol/` | 16 baytlık paket, CRC, komut üretici ve yanıt çözücüler |
| `lib/device/transport.dart` | Cihaz katmanı arayüzü (gerçek BLE ve sahte cihaz bunu uygular) |
| `lib/device/protocol/exercise.dart` | Egzersiz komutları: başlat/duraklat/bitir (0x19), canlı veri (0x18), geçmiş (0x5C) |
| `lib/device/protocol/history.dart` | Geçmiş veri komutları (adım, uyku, nabız, HRV, ısı, SpO2) |
| `lib/device/fake_device.dart` | Bileklik yerine geçen sahte cihaz |
| `lib/device/fake_history.dart` | Sahte cihazın son 7 günlük geçmiş kayıtları |
| `lib/device/wristband_client.dart` | Komut gönderip yanıt bekleyen istemci |
| `lib/data/` | Ölçüm modelleri, veri deposu, senkron ve grafik özetleri |
| `lib/state/` | Ekranların dinlediği uygulama durumu |
| `lib/ui/` | Tema ve ekranlar |
| `test/` | PDF'teki örnek paketlerle protokol testleri |

## Protokol özeti

- BLE servisi `0xFFF0`; uygulama `0xFFF6` karakteristiğine yazar, cihaz `0xFFF7` ile bildirir.
- Paket: 1 bayt komut + 14 bayt veri + 1 bayt CRC (ilk 15 baytın toplamı & 0xFF).
- Hata yanıtında komutun 7. biti 1 olur (ör. `0x01` → `0x81`).
- Saat alanları BCD, diğer sayılar onaltılık; çok baytlı değerler küçük sonludur.
- `0x09` anlık veri yanıtı 16 bayttan uzundur ve CRC taşımaz.
- Geçmiş istekleri `komut AA 00 00 YY MM DD HH mm SS` biçimindedir (AA: `00` oku,
  `02` sonraki 50 kayıt, `99` sil). Kayıtlar uç uca gelir, veri `[komut, FF]` ile biter.

Plan ve ekran analizi: [V8 Bileklik Uygulaması: Mimari ve Ekran Analizi](https://claude.ai/code/artifact/dc42487d-5b8e-412b-8e67-b0ae96220721)
