# iOS sürümü: derleme, imza ve TestFlight

iOS uygulaması Android ile aynı Flutter kodundan çıkar. Mac gerekmez: derleme
GitHub Actions'taki macOS makinesinde yapılır (`.github/workflows/ios.yml`).
Depo herkese açık olduğu için macOS dakikaları ücretsizdir.

## Şu an ne çalışıyor (imza olmadan)

Her push'ta (main, PR #42 dalı ve bu dal) ya da **Actions > iOS > Run
workflow** ile:

1. Uygulama iPhone simülatörü için derlenir, demo kipinde (sahte bileklik)
   açılır. 30 saniye sonra hâlâ açıksa adım geçer; ekran görüntüsü alınır.
2. Aynısı gerçek kipte yapılır. Simülatörde Bluetooth yoktur; burada
   denenen, uygulamanın Bluetooth olmadan çökmeden açılmasıdır.
3. Telefon için yayın derlemesi imzasız yapılır (`--no-codesign`). Bu, kodun
   telefon mimarisinde derlendiğini gösterir; imzasız .ipa telefona
   **kurulamaz**.

Çıktılar çalışmanın sayfasında **Artifacts > bileklik-ios-N** altında:
`ios-sim/demo.png`, `ios-sim/gercek.png`, uygulama çıktıları
(`*-cikti.log`) ve imzasız .ipa.

## iPhone'a kurmak için gerekenler

Gerçek bir iPhone'a kurmanın tek pratik yolu (Mac olmadan) TestFlight'tır.
Bunun için aşağıdakilerin hepsi gerekir; hiçbiri şu an depoda ya da GitHub'da
yok.

| Gerekli | Neden | Kim yapar |
| --- | --- | --- |
| Apple Developer Program üyeliği (yıllık 99 USD) | Sertifika, profil ve TestFlight yalnızca ücretli hesapta | Siz |
| App ID `com.bileklik.bileklik`, HealthKit açık | Uygulama Apple Sağlık'a yazıyor | Siz (adım 2) |
| Apple Distribution sertifikası (.p12) | Uygulamayı imzalar | Siz (adım 3) |
| App Store provisioning profile | Sertifikayı App ID'ye bağlar | Siz (adım 4) |
| App Store Connect'te uygulama kaydı | TestFlight bu kayda yüklenir | Siz (adım 5) |
| App Store Connect API anahtarı (.p8) | GitHub'ın TestFlight'a yükleyebilmesi | Siz (adım 6) |
| 6 GitHub gizli değeri | İş akışı bunlarla imzalar ve yükler | Siz (adım 7) |
| Bir iPhone (iOS 15 veya üstü) ve TestFlight uygulaması | Deneme için | Siz |

### 1. Apple Developer Program

<https://developer.apple.com/programs/enroll/> adresinden Apple hesabınızla
katılın. Bireysel üyelik birkaç saatte, şirket üyeliği D-U-N-S numarası
istediği için birkaç gün sürebilir. App Store'da satıcı adı olarak bireysel
üyelikte kendi adınız, şirket üyeliğinde şirket adı görünür.

### 2. App ID (Bundle ID)

developer.apple.com > **Certificates, Identifiers & Profiles > Identifiers >
+ > App IDs > App**:

- Description: `Bileklik`
- Bundle ID: **Explicit**, `com.bileklik.bileklik` (projedekiyle aynı olmalı;
  başka bir kimlik isterseniz söyleyin, projede ve iş akışında birlikte
  değiştirilir)
- Capabilities: **HealthKit** işaretli. Arka planda Bluetooth için ayrı
  yetenek gerekmez (Info.plist'te `bluetooth-central` var).

### 3. Apple Distribution sertifikası (Windows'ta)

Sertifika isteği (CSR) Mac olmadan OpenSSL ile üretilir. Git for Windows
kuruluysa OpenSSL "Git Bash" içinde vardır.

```sh
openssl req -new -newkey rsa:2048 -nodes \
  -keyout dagitim.key -out dagitim.csr \
  -subj "/CN=Bileklik Dagitim/C=TR"
```

developer.apple.com > **Certificates > + > Apple Distribution** seçin,
`dagitim.csr` dosyasını yükleyin, `distribution.cer` dosyasını indirin. Sonra:

```sh
openssl x509 -inform DER -in distribution.cer -out dagitim.pem
openssl pkcs12 -export -legacy -inkey dagitim.key -in dagitim.pem -out dagitim.p12
```

İkinci komut bir parola sorar; bu parola `IOS_DIST_CERT_PASSWORD` olur.
`-legacy` macOS anahtar zincirinin .p12'yi okuyabilmesi için gerekir (OpenSSL
1.x kullanıyorsanız bu seçeneği silin). `dagitim.key` ve `dagitim.p12`
gizlidir; depoya ya da sohbete koymayın, güvenli bir yerde saklayın.

### 4. Provisioning profile

**Profiles > + > Distribution > App Store Connect**, App ID olarak
`com.bileklik.bileklik`, sertifika olarak adım 3'teki sertifika. Profile bir
ad verin (ör. `Bileklik App Store`) ve `.mobileprovision` dosyasını indirin.
HealthKit'i App ID'de sonradan açarsanız profili yeniden oluşturun; iş akışı
profilde HealthKit yoksa durur ve bunu söyler.

### 5. App Store Connect'te uygulama kaydı

<https://appstoreconnect.apple.com> > **Uygulamalarım > + > Yeni Uygulama**:
platform iOS, ad `Bileklik` (App Store'da başkası kullanıyorsa farklı bir ad),
birincil dil Türkçe, Bundle ID `com.bileklik.bileklik`, SKU örneğin
`bileklik-ios`.

### 6. App Store Connect API anahtarı

App Store Connect > **Kullanıcılar ve Erişim > Entegrasyonlar > App Store
Connect API > Ekip Anahtarları > +**, rol **App Manager**. Oluşunca:

- **Key ID** → `APP_STORE_CONNECT_KEY_ID`
- Sayfanın üstündeki **Issuer ID** → `APP_STORE_CONNECT_ISSUER_ID`
- `AuthKey_XXXX.p8` dosyası (yalnızca bir kez indirilebilir) →
  `APP_STORE_CONNECT_PRIVATE_KEY`

### 7. GitHub gizli değerleri

Önce iki dosyayı base64 metne çevirin. Windows PowerShell'de (dosyaların
bulunduğu klasörde):

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("$PWD\dagitim.p12")) | Set-Clipboard
# panodaki metni IOS_DIST_CERT_P12_BASE64 olarak yapıştırın, sonra:
[Convert]::ToBase64String([IO.File]::ReadAllBytes("$PWD\Bileklik_App_Store.mobileprovision")) | Set-Clipboard
# bunu da IOS_PROVISION_PROFILE_BASE64 olarak
```

GitHub'da depo > **Settings > Secrets and variables > Actions > New
repository secret** ile şunları ekleyin:

| Ad | Değer |
| --- | --- |
| `IOS_DIST_CERT_P12_BASE64` | dagitim.p12'nin base64 hali |
| `IOS_DIST_CERT_PASSWORD` | .p12 parolası |
| `IOS_PROVISION_PROFILE_BASE64` | .mobileprovision'ın base64 hali |
| `APP_STORE_CONNECT_KEY_ID` | Key ID |
| `APP_STORE_CONNECT_ISSUER_ID` | Issuer ID |
| `APP_STORE_CONNECT_PRIVATE_KEY` | .p8 dosyasını Not Defteri'nde açıp tüm içeriği (BEGIN/END satırları dahil) |
| `IOS_MAPS_API_KEY` (isteğe bağlı) | iOS uygulamasına kısıtlı Google Haritalar anahtarı |

Takım kimliği (Team ID) ayrıca istenmez; iş akışı profilden okur.

### 8. Derleme ve TestFlight

**Actions > iOS > Run workflow**. Gizli değerler tamsa iş akışı ayrıca:

- profilin `com.bileklik.bileklik` ve HealthKit içerdiğini denetler,
- imzalı `bileklik-ios-0.1.N.ipa` üretir (Artifacts'ta),
- TestFlight'a yükler.

Yüklemeden sonra App Store Connect derlemeyi 10-30 dakikada işler ve e-posta
gönderir. Sonra **TestFlight** sekmesinde:

1. Derleme "Eksik uyumluluk" (şifreleme) sorusu gösterirse yanıtlayın.
   Uygulama HTTPS ve cihazdaki şifreli veritabanı (SQLCipher) kullanıyor;
   bu soruya ne yanıt verileceği şirketin ihracat durumuna bağlı, emin
   değilseniz Apple'ın açıklamasını okuyun. Yanıtı her derlemede sormaması
   için daha sonra Info.plist'e `ITSAppUsesNonExemptEncryption` eklenebilir.
2. **Dahili Test** grubuna kendi Apple hesabınızı ekleyin (dahili testte
   Apple incelemesi beklenmez).
3. iPhone'a App Store'dan **TestFlight** uygulamasını kurun; davet o
   hesapla görünür.

Sürüm numarası `0.1.<çalışma no>`; her çalışmada artar, TestFlight eski
derlemenin üstüne günceller.

### Google Haritalar (isteğe bağlı)

Android anahtarı Android uygulamasına kısıtlıysa iOS'ta çalışmaz. Google
Cloud Console'da **Maps SDK for iOS**'u açıp yeni bir anahtar oluşturun,
"iOS uygulamaları" kısıtıyla `com.bileklik.bileklik` ekleyin ve
`IOS_MAPS_API_KEY` olarak kaydedin. Anahtar yoksa egzersiz ekranında
çizilmiş harita zemini görünür.

Yerelde (Mac'te) derlerken anahtarı `ios/Flutter/Secrets.xcconfig` dosyasına
`MAPS_API_KEY = ...` satırıyla yazın; bu dosya depoya girmez.

## iOS'a özgü notlar

- En düşük sürüm iOS 15.0 (`health` eklentisi istiyor; Podfile ve Xcode
  projesinde aynı).
- Info.plist izin metinleri dört dilde (`ios/Runner/*.lproj/InfoPlist.strings`):
  Bluetooth, kamera (QR), Apple Sağlık okuma/yazma, konum (Google Haritalar
  SDK'sı konum API'sine bağlandığı için App Store yüklemesi bu metni ister;
  uygulama şu an konum istemiyor) ve Fotoğraflar'a kaydetme (paylaşım
  menüsündeki "Görüntüyü Kaydet" metin olmadan uygulamayı kapatır).
- Arka plan kipi `bluetooth-central`: uygulama arka plandayken bileklik
  bağlantısı ve bildirimleri sürer. App Store incelemesinde gerekçesi
  "bileklikten ölçüm almak"tır.
- Bildirim: uygulamada şu an yerel ya da uzaktan bildirim eklentisi yok, bu
  yüzden bildirim izni de yok. Acil uyarı için push eklenince APNs anahtarı
  ve `aps-environment` yeteneği gerekecek.
- iOS bileklik MAC adresini vermez. QR ile eşleştirme şu an adresi yayındaki
  üretici verisinden okumayı deniyor (`BleTransport._addressOf`); bu alan
  gerçek bileklikte doğrulanmadı. Bkz. aşağıdaki SDK karşılaştırması.
- App Store'a çıkışta (TestFlight için değil): gizlilik etiketleri (sağlık
  verisi, kullanıcıya bağlı), gizlilik politikası adresi ve EKG gibi tıbbi
  özellikler için Apple'ın 1.4.1 ve 5.1.3 kuralları geçerli; EKG'nin tanı
  aracı olarak sunulması yasal onay ister.

## V8 iOS SDK ile uygulamadaki protokolün farkı

Üreticinin iOS SDK'sı (V8 SDK.pdf, `BleSDK` klasörü) yalnızca paket üreten
ve çözen bir Objective-C kütüphanesi: her yöntem gönderilecek baytları
(`NSMutableData`) döndürür, `DataParsingWithData:` gelen baytı sözlüğe
çevirir. Bluetooth bağlantısını (CoreBluetooth, tarama, 0xFFF0 servisi) SDK
yapmıyor; bunu uygulama kendisi yapmak zorunda. Uygulamamız aynı işi Dart'ta
iki platform için birden yapıyor (`lib/device/protocol/` + `BleTransport`),
bu yüzden **SDK'yı iOS'a eklemek gerekmiyor** ve eklemek iOS'u Android'den
ayırır. SDK yine de API belgesinde olmayan birkaç şeyi gösteriyor:

| SDK'da | API belgesinde | Uygulamada | Önem |
| --- | --- | --- | --- |
| `setECGRealtimeDuringHRVEnabled:` ham EKG akışını açar/kapatır; veri `ECG_RawData_V8`, 3 bayt küçük sonlu | Yok; belgede EKG yalnızca `0x28 04` | Yalnızca `0x28 04` gönderiliyor | **Yüksek.** Bilekliğin bizim uygulamada EKG verisi göndermemesinin olası nedeni. Komutun baytları PDF'te yazmıyor; üreticiden istenmeli ya da tanılama ekranındaki ham komutla denenmeli. |
| `ppgWithMode:ppgStatus:` PPG ölçümü; ham PPG "ayrı bir veri kanalından", 4 bayt büyük sonlu | Yok | Yok | Orta. Hangi karakteristik olduğu yazmıyor; üreticiye sorulmalı. |
| `manualMeasurementWithDataType:` HRV "bu cihazda desteklenmiyor" | `0x28` AA=02/03/04 | 02 nabız, 03 SpO2, 04 EKG | Uyumlu. HRV için elle ölçüm eklenmemeli. |
| `GetDeviceMacAddress` | `0x22` | Komut kodu tanımlı, kullanılmıyor | **iOS için önemli.** iOS MAC vermediği için bağlandıktan sonra `0x22` ile adres okunup QR'daki adresle karşılaştırılabilir; üretici verisine güvenmekten daha sağlam. Uygulama kodu işi (ayrı iş). |
| Hatırlatıcı 10 adet | 5 adet | 5 | API belgesi esas (bkz. `protokol-dogrulama.md`). |
| `ClearAllHistoryData` | Tür başına `99` silme | Tür başına | Fark yok, toplu silme kolaylığı. |
| `getSleepDetailsAndActivityWithMode:` | `0x6B` | Kullanılmıyor | Düşük; `protokol-dogrulama.md` "kullanılmayan komutlar". |

Sonuç: iOS'ta protokol açısından ek iş yok; Android'deki açık maddeler
(`docs/protokol-dogrulama.md`) iOS için de geçerli. İki somut iş çıkıyor:
EKG akışını açan komutun baytlarını üreticiden istemek ve iOS eşleştirmesini
`0x22` MAC okumasıyla sağlamlaştırmak.
