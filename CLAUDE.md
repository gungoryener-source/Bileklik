# Bileklik: Claude için proje notları

JCV8 ekransız ECG bileklik için Flutter ile iOS ve Android sağlık uygulaması.
Telefonda gerçek BLE (`BleTransport`) ve gerçek Health Connect / Apple Health
kullanılır. Bileklik elde değilken `flutter run --dart-define=DEMO=true` ile
sahte bileklik (`FakeDevice`) ve sahte sağlık platformu açılır; web ve testler
her zaman sahte olanları kullanır. Ayrıntılı plan ve
ekran analizi: https://claude.ai/code/artifact/dc42487d-5b8e-412b-8e67-b0ae96220721

## Dil

- Kod yorumları, commit mesajları ve PR açıklamaları Türkçe.
- Kod adları (sınıf, değişken, dosya) İngilizce.
- Uygulama dört dilde: Türkçe (kaynak), İngilizce, Arapça (sağdan sola), Almanca.
  Ekrana yazılan her metin `lib/l10n/app_<dil>.arb` dosyalarına anahtar olarak
  eklenir ve `context.l10n.anahtar` ile okunur; koda Türkçe metin yazılmaz.
  Dört dosyaya birlikte ekleyin, sonra `flutter gen-l10n`.
- Cümleyi parçalardan birleştirmeyin; yer tutuculu tek anahtar kullanın
  (`{value}` gibi). Yüzde işareti dile göre yer değiştirir (%97 / 97% / 97٪).
- Kenar boşluğu ve hizalamada `EdgeInsetsDirectional`, `AlignmentDirectional`,
  `start`/`end` kullanın; Arapçada ekran aynalanır.

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
                         |                                                 |-- BleTransport (telefon)
                         v                                                 |-- FakeDevice (demo, web, test)
                 HealthStore + SyncService (lib/data)
```

- `DeviceTransport` ham baytları taşır. `BleTransport` (flutter_blue_plus,
  `License.nonprofit`; ticari kullanımda ücretli lisans gerekir) ve `FakeDevice`
  aynı arayüzü uygular. Arama hataları `ScanException(ScanProblem)` olarak gelir;
  eşleştirilen bileklik telefonda saklanır.
- Sağlık platformu: `PluginHealthPlatform` (`health` eklentisi) gerçek,
  `FakeHealthPlatform` sahte. Uygulama yalnızca yazar.
- Kamerayla QR okuma `QrScanScreen` (mobile_scanner); testlerde
  `QrScanScreen.scannerOverride` ile kameranın yerine sahte okuyucu verilir.
- `WristbandClient` komutu gönderir, aynı komut koduyla gelen yanıtı bekler.
  Geçmiş komutları `fetchHistory` ile sayfa sayfa çekilir.
- `HealthStore` arayüzdür: telefonda `SqliteHealthStore`, web ve testte
  `MemoryHealthStore`.
- Ekranlar `DeviceScope.of(context)` ile denetleyiciye, `.store` ile ölçümlere erişir.
- FHIR R4: `FhirExporter` (`lib/data/fhir.dart`) depodaki kayıtları Bundle'a
  çevirir (Observation + LOINC/UCUM, EKG için SampledData). Hasta kaynağı takma
  kimliklidir (`AppSettings.patientId`), ad ya da TC kimlik yazılmaz.

- HRV ayrıntısı ve VO2 Max `lib/data/hrv_analysis.dart` (0x63 PPI'dan);
  enerji skoru, haftalık rapor ve rozetler `lib/data/progress.dart`. Rozetler
  saklanmaz, her açılışta geçmişten hesaplanır. Adım hedefi `dailyStepGoal`.

## Portal (`portal/`)

Ayrı bir Dart paketi (shelf): FHIR Bundle alır, takipçilere yalnızca rızadaki
türleri gösterir, her erişimi `AuditEvent` olarak kaydeder. Kökteki
`flutter analyze` bu klasörü taramaz; CI'da ayrı işte `dart analyze
--fatal-infos` ve `dart test` çalışır. Ayrıntılar `portal/README.md`.

## Protokol kuralları (V8 API PDF)

Kaynak V8 API V1.2 ve V8 SDK belgeleri; üreticinin gizli belgeleri olduğu
için depoya eklenmez. Belgeyle karşılaştırma ve açık kalanlar:
`docs/protokol-dogrulama.md`.

- Paket 16 bayt: komut + 14 bayt veri + CRC (ilk 15 baytın toplamı & 0xFF).
- Hata yanıtında komutun 7. biti 1 olur.
- Saat alanları BCD, sayılar küçük sonlu onaltılık.
- `0x09` anlık veri 32 bayttır ve CRC taşımaz.
- Geçmiş kayıt uzunlukları `HistoryKind` içinde. Veri sonu `[komut, 0xFF]`.
- 0x23 hatırlatıcı listesi 16 bayt değildir; bilekliğin paket boyuna (0x01
  yanıtı) göre bölünür, onayı `23 … 23 EE`. Bileklik en çok 5 hatırlatıcı
  ve ASCII etiket tutar.
- Yeni bir komut eklerken PDF'teki örnek paketi teste koyun (bkz. `test/protocol_test.dart`).
- PDF'te belirsiz kalan noktaları kodda "gerçek cihazda doğrulanacak" diye işaretleyin.

## Yeni özellik eklerken

1. Komut gerekiyorsa: `lib/device/protocol/` altına kodlayıcı/çözücü, PDF örneğiyle test.
2. Sahte cihaz o komuta gerçekçi yanıt versin (`fake_device.dart` / `fake_history.dart`).
3. Veri saklanacaksa `MetricType` ve `SyncService`'e ekleyin.
4. Ekranı `lib/ui/screens/` altına yazın. Renkler temadan gelir: nötr renkler `context.colors` (`AppColors` ThemeExtension), veri renkleri `DataColors` ve `MetricLook`. Sabit renk yazmayın. Uygulama yalnızca koyu (Cam) temada çalışır; Cam bileşenlerini (`lib/ui/widgets/cam/`) kullanın, kurallar `docs/flutter-mobile-design.md` içinde.
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
- Tema yalnızca koyu (Cam); tek `ThemeData` (`buildTheme()`) üzerinden yönet, açık tema yok.
- Hareketi azalt ayarına (`disableAnimations`) saygı göster.
- Teslimden önce `flutter analyze` çalıştır ve uç durumları dene.
