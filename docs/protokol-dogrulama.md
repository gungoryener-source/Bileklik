# Protokol doğrulama notları

Kaynak: **V8 API V1.2** (JCV8, 31 Temmuz 2026) ve **V8 SDK** (iOS) belgeleri.
Belgeler üreticinin gizli belgeleridir; depoya eklenmez. Bu sayfa kodun
belgeyle karşılaştırılmasının özetidir. Gerçek bileklik gelince "Açık"
satırları tek tek denenmeli.

## Belgeyle düzeltilenler

| Konu | Önceki varsayım | Belgedeki (kodda şimdi) |
| --- | --- | --- |
| 0x63 PPI kaydı | 26 bayt, en çok 8 aralık, zaman ilk atım | 123 bayt: `63 ID1 ID2 YY MM DD HH mm SS CC ID P1…P112`. CC gruptaki kayıt sayısı, ID sırası; 56 adet 2 baytlık (işaretli, ms) aralık, ilk 0 grubun sonu. Zaman ölçümün **kaydedildiği** an. Uygulama grubu birleştirip son atımı bu ana yerleştiriyor. |
| Hatırlatıcı sayısı | 10 | 5 (indeks 0-4). SDK 10 diyor; cihaza özgü API belgesi esas alındı. |
| 0x57 okuma kaydı | 0x23 ile aynı düzen | `57 ID1 ID2 AA BB CC DD EE FF T1…T30`: okuma no, sıra, **tür** (0 = kapalı), saat, dakika, günler, etiket uzunluğu. Kapalı kaydın türü bileklikte saklanmıyor; uygulama son yazdığı listeden tamamlıyor. |
| Hatırlatıcı etiketi | UTF-8 | ASCII. Türkçe/Almanca harfler Latin karşılığına çevriliyor (ş → s), karşılığı olmayanlar atlanıyor. |
| 0x23 yazımı | Tek uzun paket | Bilekliğin paket boyuna (0x01 yanıtının ilk baytı, ör. F4 = 244) ve telefonun MTU'suna göre tam kayıtlarla bölünüyor; sonda `23 FF`. |
| 0x23 onayı | 16 baytlık `23` paketi | `23 R1 23 R2 … 23 EE`; `23 EE` gelince kaydedildi sayılıyor. |
| Hareketsizlik uyarısı (0x25/0x26) | Başka bir SDK'dan alınmıştı | Belgede yok. Kaldırıldı; bilinmeyen komut hatası hatırlatıcı listesini de "yüklenemedi" gösteriyordu. |

## Belgeyle doğrulananlar

- BLE: servis 0xFFF0, yazma 0xFFF6, bildirim 0xFFF7; 16 baytlık paket, CRC
  ilk 15 baytın toplamı & 0xFF; hata yanıtında 7. bit 1.
- 0x01/0x41 saat (BCD), 0x02/0x42 kişisel bilgi (MAC büyük sonlu), 0x13 pil.
- 0x09 anlık veri (32 bayt, CRC yok): adım, kalori/100, mesafe/100, 8 boş
  bayt, nabız, ısı/10, SpO2.
- 0x2A/0x2B otomatik ölçüm alanları (PDF örneği testte).
- 0x51, 0x52, 0x53 (01 derin, 02 hafif, 03 REM, diğerleri uyanık), 0x54,
  0x55, 0x56 (HRV, solunum, nabız, stres, tansiyon), 0x62, 0x66 kayıtları.
- 0x19 egzersiz kontrolü (başlatma yanıtı `19 01 YY…`, diğerleri
  `19 01 00 YY…`), 0x18 canlı veri ve uyarılar, 0x5C egzersiz kaydı
  (süre sn, kalori ve mesafe float).
- 0x28 elle ölçüm (02 nabız, 03 SpO2, 04 EKG), 0x07 EKG ham verisi (3 bayt,
  küçük sonlu).
- 0x86 takma algılaması bildirimleri (01 ölçüm başı, 02 durum değişti,
  03 hareket).

## Belgeden eklenenler

- 0x03/0x04 tüm gün nabız takibi (NN = 0x81 açık, 0x80 kapalı): Cihaz
  ekranında anahtar.
- 0x27 yazılım sürümü ve derleme tarihi: Cihaz ekranında satır.

## Açık kalanlar (gerçek cihazda denenecek)

| Konu | Neden açık | Koddaki yeri |
| --- | --- | --- |
| Bilekliğin yayın adı | Belgede yok; `JCV8`/`V8` öneki varsayıldı | `BleTransport.namePrefixes` |
| iOS'ta QR ile eşleştirme | iOS MAC adresini göstermiyor; adres üretici verisinde yayınlanıyor mu? | `BleTransport._addressOf` |
| QR içeriğinin biçimi | Belgede yok | `addressFromQr` |
| EKG örnekleme hızı ve birimi | Belgede yok; 250 Hz ve ham sayım varsayıldı | `ecgSampleRate`, `FhirExporter.ecg` |
| EKG örneği işaretli mi | Belgede yok | `EcgPacket` |
| 0x2A/0x2B aralık bayt sırası | Açıklama "big-endian", örnek küçük sonlu | `AutoMeasureConfig.toBytes` |
| 0x52 kayıt zamanı | 10 dakikalık aralığın başı mı sonu mu yazmıyor | `FhirExporter`, `PluginHealthPlatform` |
| 0x13 gerilim bayt sırası | Belgede yok | `Decoders.battery` |
| 0x86 komutuna verilen onay | Gövdesi tanımsız; ilk 0x86 onay sayılıyor | `WristbandClient.setWearDetection` |
| 0x57 99 silme yanıtı | Gövdesi tanımsız | `deleteRemindersCommand` |
| Elle ölçümün bitişi | Bitiş paketi yok; süre + 10 sn sonunda uygulama bitiriyor. `28 80` durum sorgusu ileride kullanılabilir. | `DeviceController.startSpot` |
| 0x18 süre birimi | Belgede yazmıyor (saniye varsayıldı) | `ExerciseLive` |
| 0x56 HRV türü | SDNN mi RMSSD mi yazmıyor; PPI'dan hesaplananla karşılaştırılacak | `ExportType.hrv` |

## Kullanılmayan komutlar

0x12 fabrika ayarı (uyku kipi), 0x2E MCU sıfırlama, 0x14 cihaz ısısı, 0x6B
uyku ve hareket ayrıntısı (yarım bayt evreler), 0x28 01 (50 Hz) ve 0x28 80
durum sorgusu. Gerekirse `lib/device/protocol/` altına belge örneğiyle
eklenir.
