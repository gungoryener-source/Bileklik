# Bileklik: Claude için proje notları

JCV8 ekransız ECG bileklik için Flutter ile iOS ve Android sağlık uygulaması.
Bileklik henüz elde yok; uygulama `FakeDevice` ile çalışır. Ayrıntılı plan ve
ekran analizi: https://claude.ai/code/artifact/dc42487d-5b8e-412b-8e67-b0ae96220721

## Dil

- Arayüz metinleri, kod yorumları, commit mesajları ve PR açıklamaları Türkçe.
- Kod adları (sınıf, değişken, dosya) İngilizce.

## Komutlar

```sh
flutter pub get
flutter analyze   # uyarısız geçmeli; CI aynısını çalıştırır
flutter test
```

Yalnızca değiştirdiğiniz dosyaları `dart format` ile biçimlendirin; tüm depoyu
biçimlendirmek ilgisiz farklar üretir.

## Mimari

```
UI (lib/ui)  ->  DeviceController (lib/state)  ->  WristbandClient  ->  DeviceTransport
                         |                                                 |-- FakeDevice (şimdilik)
                         v                                                 |-- BLE (bileklik gelince)
                 HealthStore + SyncService (lib/data)
```

- `DeviceTransport` ham baytları taşır. Gerçek BLE katmanı aynı arayüzü uygulayacak;
  üst katmanlar değişmeyecek.
- `WristbandClient` komutu gönderir, aynı komut koduyla gelen yanıtı bekler.
  Geçmiş komutları `fetchHistory` ile sayfa sayfa çekilir.
- `HealthStore` arayüzdür; şimdilik `MemoryHealthStore`. SQLite bu arayüzün
  arkasına eklenecek.
- Ekranlar `DeviceScope.of(context)` ile denetleyiciye, `.store` ile ölçümlere erişir.

## Protokol kuralları (V8 API PDF)

- Paket 16 bayt: komut + 14 bayt veri + CRC (ilk 15 baytın toplamı & 0xFF).
- Hata yanıtında komutun 7. biti 1 olur.
- Saat alanları BCD, sayılar küçük sonlu onaltılık.
- `0x09` anlık veri 32 bayttır ve CRC taşımaz.
- Geçmiş kayıt uzunlukları `HistoryKind` içinde. Veri sonu `[komut, 0xFF]`.
- Yeni bir komut eklerken PDF'teki örnek paketi teste koyun (bkz. `test/protocol_test.dart`).
- PDF'te belirsiz kalan noktaları kodda "gerçek cihazda doğrulanacak" diye işaretleyin.

## Yeni özellik eklerken

1. Komut gerekiyorsa: `lib/device/protocol/` altına kodlayıcı/çözücü, PDF örneğiyle test.
2. Sahte cihaz o komuta gerçekçi yanıt versin (`fake_device.dart` / `fake_history.dart`).
3. Veri saklanacaksa `MetricType` ve `SyncService`'e ekleyin.
4. Ekranı `lib/ui/screens/` altına yazın. Renkler temadan gelir: nötr renkler `context.colors` (`AppColors` ThemeExtension), veri renkleri `DataColors` ve `MetricLook`. Sabit renk yazmayın; açık ve koyu temada deneyin.
   Tasarım bize ait; referans uygulamanın görselleri kopyalanmaz.
5. Ekran için `test/` altına widget testi ekleyin.

## Kararlar

- Kilo ve vücut kompozisyonu kullanıcıdan alınır, akıllı tartı yok.
- Veriler ileride kendi portalımıza FHIR R4 Observation olarak aktarılacak; aile ve
  hekimler veriyi yetki (Consent) ile görecek. KVKK'ya uygun tasarlayın.
- Tansiyon değeri tahminidir; ekranda bunu belirtin.

## Tasarım skill'leri

Arayüz işi yaparken `.claude/skills/` altındaki skill'leri kullan. Ana skill `flutter-mobile-design`; kodu her zaman Flutter (Dart) ile yaz.

- Her arayüz işinde: `flutter-mobile-design`.
- Görsel yön, tipografi, renk: `frontend-design`.
- Detay cilası ve hareket felsefesi: `emil-design-eng`, `apple-design`.
- Hareket kararları (gerekli mi, süre, eğri): `animate`.
- Uç durum düşüncesi (uzun metin, boş veri, büyük sayı): `break-ui`.
- Birden fazla tasarım seçeneği istenirse: `prototype`.

Not: `mobile-native`, `apple-design`, `animate`, `break-ui` ve `prototype` web (HTML/CSS/JS) için yazıldı. Bunlardan yalnızca tasarım ilkelerini al; CSS, meta etiketi veya tarayıcı önerilerini kullanma, Flutter karşılığını yaz.

## Mobil tasarım kuralları (özet)

- Mobil öncelikli tasarla; küçük (yaklaşık 360 dp) ve büyük telefonu birlikte düşün.
- Dokunma hedefleri en az 48x48 dp.
- `SafeArea` kullan; çentik ve alt çubuğa uy.
- Sağlık verisi ekranlarında sayılar büyük ve okunaklı olsun; veri yoksa boş durum göster.
- Açık ve koyu temayı birlikte düşün; tek `ThemeData` üzerinden yönet.
- Hareketi azalt ayarına (`disableAnimations`) saygı göster.
- Teslimden önce `flutter analyze` çalıştır ve uç durumları dene.
