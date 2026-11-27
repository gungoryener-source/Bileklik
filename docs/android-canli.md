# Android: gerçek bileklikle deneme ve yayına hazırlık

Bu sayfa JCV8 bilekliği gerçek bir Android telefonla denemek ve sonra Google
Play'e çıkmak için gerekenleri anlatır.

## 1. APK'yı telefona kurma

1. GitHub'da depo > **Actions > Android APK** iş akışı her itmede kendiliğinden
   çalışır; elle çalıştırmak için **Run workflow**.
2. İş bitince depo > **Releases** altında `Android deneme 0.1.N` sürümü çıkar.
   Telefonun tarayıcısından bu sayfayı açıp `bileklik-0.1.N-deneme.apk`
   dosyasını indirin.
3. Dosyayı açın. Android "bilinmeyen kaynaklardan yükleme" izni ister; tarayıcı
   (Chrome) için bir kez izin verin. Play Protect uyarısında **Yine de yükle**.
4. Sonraki sürümler aynı anahtarla imzalandığı için eskisinin üstüne kurulur;
   veriler silinmez.

Bilgisayarda Flutter varsa aynı APK: `flutter build apk --release`
(çıktı `build/app/outputs/flutter-apk/app-release.apk`).

## 2. İlk bağlantı

1. Bilekliği şarj edin ve telefonun Bluetooth'unu açın. Android 11 ve öncesinde
   **Konum** da açık olmalı (eski Android'de Bluetooth araması konum ister).
2. Bilekliği üreticinin uygulamasıyla (JCVitalPro) eşleştirdiyseniz o
   uygulamada bağlantıyı kesin ya da uygulamayı kapatın; bileklik aynı anda tek
   telefona bağlanır.
3. Uygulamayı açın: **Profil > Cihaz > Ara**. Android "Yakındaki cihazlar"
   iznini sorar; **İzin ver**.
4. Bileklik listede çıkınca dokunun. Bağlanınca saat ayarlanır, pil ve
   kişisel bilgi okunur, anlık veri ve geçmiş eşitleme başlar.
5. Sonraki açılışlarda uygulama kendiliğinden bağlanır. Bağlantı koparsa
   3 sn, 10 sn, 30 sn, sonra dakikada bir yeniden dener; uygulama öne gelince
   hemen dener. **Bağlantıyı kes** denirse yeniden denemez.

## 3. Bir şey ters giderse: Bağlantı tanılama

**Profil > Cihaz** ekranında sağ üstteki tanılama simgesi (büyüteçli çizgi).

- **Durum kartı:** kip (gerçek / demo), bağlantı durumu, eşleştirilen bileklik
  ve MAC adresi, paket boyu (MTU − 3; 20 ise MTU büyütülemedi), sonraki
  yeniden deneme.
- **Test komutları:** Pil (0x13), Saat (0x41), Sürüm (0x27), Kişisel bilgi
  (0x42), Anlık veri (0x09). Dokununca giden paket `>>`, bilekliğin yanıtı `<<`
  ile kayda düşer.
- **Ham komut:** onaltılık bayt yazın (ör. `13` ya da `28 02`), CRC ve sıfır
  dolgusu kendiliğinden eklenir.
- **Tüm cihazları ara:** bileklik normal aramada çıkmıyorsa (yayın adı `JCV8`
  ya da `V8` ile başlamıyorsa) ad süzgeci olmadan arar. Her satırda ad, adres,
  sinyal, yayındaki servis UUID'leri ve üretici verisi görünür. Bilekliği
  bulup **Bağlan** deyin; adını bize iletin, süzgece ekleyelim.
- **Kayıt:** son 5000 satır bellekte tutulur (diske yazılmaz). Sağ üstteki
  paylaş düğmesi kaydı başlık bilgileriyle düz metin olarak gönderir
  (e-posta, WhatsApp, Drive).
- **Demo kipi:** anahtar açılırsa uygulama yeniden açıldığında sahte bileklikle
  çalışır (sunum için). Demo verisi Health Connect'e yazılmaz.

### Bize göndermeniz gerekenler

Aşağıdakileri deneyip her birinden sonra kaydı paylaşın:

1. Aramada bileklik çıktı mı? Çıkmadıysa **Tüm cihazları ara** listesinin
   ekran görüntüsü.
2. Bağlandıktan sonra Pil, Saat, Sürüm ve Kişisel bilgi düğmeleri.
3. Ana sayfada nabız/adım geliyor mu (anlık veri)?
4. Elle nabız ve SpO2 ölçümü; EKG ölçümü (30 sn).
5. Bir gece taktıktan sonra uygulamayı açıp eşitleme (uyku ve geçmiş).

Kayıttan doğrulanacak açık konular `docs/protokol-dogrulama.md` içindeki
"Açık kalanlar" tablosunda.

### Sık görülen sorunlar

| Belirti | Olası neden | Ne yapmalı |
| --- | --- | --- |
| Aramada hiçbir şey yok | İzin verilmedi, Bluetooth/konum kapalı | Ayarlar > Uygulamalar > Bileklik > İzinler > Yakındaki cihazlar |
| Liste boş ama "Tüm cihazlar"da var | Yayın adı farklı | Adı bize iletin |
| `bağlantı hatası … 133` | Android BLE yığını; bileklik başka telefona bağlı | Üretici uygulamasını kapatın, Bluetooth'u kapatıp açın |
| `0xFFF0 servisi bulunamadı` | Farklı servis UUID'si | Kaydı paylaşın |
| `>>` var `<<` yok | Bildirim açılmadı ya da komut biçimi farklı | Kaydı paylaşın |
| Paket boyu 20 | MTU büyütülemedi; EKG/anlık veri kesilebilir | Kaydı paylaşın |

## 4. Arka planda bağlantı

Uygulama açıkken (ekran kapalı olsa da) bağlantıyı korur ve koparsa yeniden
bağlanır. Uygulama kapatılınca (görevlerden kaydırılınca) bağlantı da kapanır;
bileklik ölçümleri kendi belleğinde tutar ve bir sonraki açılışta geçmiş
eşitlemesiyle telefona gelir. Bu yüzden veri kaybolmaz.

Uygulama kapalıyken de sürekli bağlı kalmak (ör. anlık uyarılar) Android'de
ön plan hizmeti (kalıcı bildirim, `FOREGROUND_SERVICE_CONNECTED_DEVICE`)
ister; Google Play bu izin için ayrıca gerekçe ve video ister. Gerçek
cihazdaki denemeden sonra gerekip gerekmediğine karar verilecek.

Pil tasarrufu bazı telefonlarda (Xiaomi, Huawei, Samsung) arka plandaki
uygulamayı kapatır. Sorun olursa: Ayarlar > Uygulamalar > Bileklik > Pil >
**Kısıtlama yok**.

## 5. Google Play'e çıkış listesi

Kod dışında sizin yapmanız gerekenler:

1. **Geliştirici hesabı:** play.google.com/console, tek seferlik 25 ABD doları.
   Kurum adına yayın için D-U-N-S numarası gerekir (şirket hesabı tercih
   edilmeli; sağlık uygulamalarında bireysel hesaplardan ek doğrulama
   isteniyor). Yeni bireysel hesaplarda üretime çıkmadan önce **en az 12 test
   kullanıcısıyla 14 gün kapalı test** zorunlu.
2. **Yükleme anahtarı:** gerçek anahtarı bir kez üretip güvenli saklayın
   (kaybolursa Play'den sıfırlama istenir):
   ```sh
   keytool -genkeypair -v -keystore bileklik-yukleme.jks -alias bileklik \
     -keyalg RSA -keysize 2048 -validity 10000
   base64 -w0 bileklik-yukleme.jks   # ANDROID_KEYSTORE_BASE64 için
   ```
   GitHub > Settings > Secrets and variables > Actions altına
   `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`,
   `ANDROID_KEY_PASSWORD` ekleyin. İş akışı o zaman `.aab` da üretir; Play'e
   `.aab` yüklenir ve **Play App Signing** açılır.
   Not: deneme anahtarlı APK kuruluysa yükleme anahtarlı sürümün üstüne
   kurulamaz; bir kez kaldırıp kurun.
3. **Uygulama kimliği:** `com.bileklik.bileklik`. İlk yüklemeden sonra
   değişmez; alan adınıza göre (ör. `app.bileklik`) değiştirmek isterseniz
   ilk yüklemeden önce söyleyin.
4. **Gizlilik politikası adresi:** herkese açık bir URL olmalı. Metin hazır
   (`docs/gizlilik-politikasi.md`, portalda `/gizlilik`); yayındaki portal ya
   da tanıtım sitesinin adresi verilir.
5. **Veri güvenliği formu (Data safety):** toplanan veriler: sağlık ve fitness
   (nabız, SpO2, EKG, uyku, adım, ısı), kişisel bilgi (yaş, boy, kilo,
   cinsiyet), cihaz kimliği (bileklik MAC). Şifreli aktarım (HTTPS), şifreli
   depolama, kullanıcı silme isteği (Profil > Gizlilik). Paylaşım: yalnızca
   kullanıcının izin verdiği hekim/aile (portal).
6. **Sağlık uygulaması beyanı (Health apps declaration):** Play Console >
   Uygulama içeriği. Uygulama türü: "sağlık ve fitness / tıbbi olmayan". Tıbbi
   cihaz olmadığı, teşhis koymadığı açıkça yazılmalı (uygulamada zaten
   "Hakkında"da var). EKG özelliği bazı ülkelerde tıbbi cihaz onayı (CE/FDA)
   ister; onay yoksa mağaza açıklamasında "bilgi amaçlı" denmeli.
7. **Health Connect izinleri:** Play Console'da Health Connect izin beyanı
   formu (her yazma izni için gerekçe). Uygulama yalnızca yazar; okuma izni
   istemez.
8. **Hedef kitle:** 18+ (çocuklara yönelik değil).
9. **Mağaza kaydı:** ad, kısa ve uzun açıklama (4 dilde), simge 512×512, öne
   çıkan görsel 1024×500, en az 2 telefon ekran görüntüsü.
10. **İçerik derecelendirmesi** anketi ve **reklam yok** beyanı.
11. **Lisans:** flutter_blue_plus ticari kullanımda ücretli lisans ister
    (şimdi `License.nonprofit`). Satışa çıkmadan önce lisans alınmalı.
12. **Ödeme:** Premium aboneliği gerçek olacaksa Google Play Faturalandırma
    hesabı ve ürün kimlikleri (şimdi demo, `docs/odeme.md`).
