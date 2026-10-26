# Yol haritası

Sırayla yapılacak işler. Her madde ayrı bir PR olur; PR'lar birleştirilene kadar
bir öncekinin dalı üzerine kurulur. Durum: ✅ bitti (PR açık ya da birleşti), 🔄 sürüyor, ⬜ sırada.

| # | İş | Durum | PR |
| --- | --- | --- | --- |
| 1 | Flutter iskeleti, V8 protokol çözücü, sahte bileklik | ✅ | #1 |
| 2 | Sağlık ekranları, geçmiş veri senkronu (adım, uyku, nabız, SpO2, HRV, stres, ısı) | ✅ | #2 |
| 3 | Egzersiz sekmesi: spor seçimi, canlı egzersiz, geçmiş (0x19, 0x18, 0x5C) | ✅ | #3 |
| 4 | EKG ölçümü, kayıtları ve nabız çözümlemesi (0x28, 0x07) | ✅ | #4 |
| 5 | Ana Sayfa yeniden tasarımı: tarih gezgini, günün özeti (uyku/toparlanma/yük), Egzersize başla kısayolu, Uyku, Aktivite halkası, Denge (HRV/stres), Kalp atış hızı ve SpO2 gün grafikleri, Zaman çizelgesi; yüzen alt menü. Düzen `/mnt/project-files/referans/ana-ekran/` ekran görüntülerinden, görseller kendimize ait; `docs/flutter-mobile-design.md` kurallarına uyulur | ✅ | #6 |
| 6 | Tema: açık ve koyu tema birlikte (flutter-mobile-design skill'i), renkler `ColorScheme`/`ThemeExtension` üzerinden `Theme.of(context)` ile; sistem ayarına uyan tema seçimi | ✅ | #7 |
| 7 | Dil desteği: Türkçe (kaynak), İngilizce, Arapça, Almanca. `flutter_localizations` + `gen-l10n` ARB dosyaları; ilk açılışta dil seçim ekranı (cihaz dili varsayılan), Profil > Genel ayarlar'dan değiştirme, seçimin saklanması; Arapça için sağdan sola yerleşim (`EdgeInsetsDirectional`, yön duyarlı ikonlar); tarih ve sayı biçimleri `intl` ile; her dilde taşma ve Arapça RTL widget testi. Sağlık terimlerinin çevirisi ana dili konuşan biri tarafından gözden geçirilecek | ✅ | #8 (çevirilerin ana dili konuşan biri tarafından gözden geçirilmesi bekliyor) |
| 8 | Profil sekmesi menüsü (Cihaz ayarları, Genel ayarlar, Paylaşım, Araştırma kurumu, Üçüncü taraf, Hakkında, Geri bildirim, sürüm) ve cihaz eşleştirme ekranı (sahte cihazla arama, QR ile eşleştirme). Referans: `/mnt/project-files/referans/gece-ekranlari/4-profil-menu.jpg`, `6-cihaz-eslestirme.jpg` | ✅ | #9 |
| 9 | Sağlık topluluğu: aile grupları (grup oluştur, üyeler, katıldığım gruplar, mesaj listesi) ve Consent tabanlı paylaşım izinleri (uygulama tarafı, sahte sunucu). Referans: `/mnt/project-files/referans/gece-ekranlari/1-topluluk.jpg`, `2-topluluk-menu.jpg` (aynı klasör) | ✅ | #10 |
| 10 | Araştırma kurumu ve hekim bağlantısı: davet kodu gir, QR tara, hangi verilerin ne süreyle paylaşılacağını gösteren KVKK açık rıza ekranı, bağlantıyı kaldırma. Referans: `/mnt/project-files/referans/gece-ekranlari/3-arastirma-kurumu.jpg` | ✅ | #11 (kamerayla QR okuma #20'de eklendi) |
| 11 | Üçüncü taraf entegrasyonu: Android'de Health Connect, iOS'ta Apple Health'e veri yazma (izin akışı, hangi türlerin paylaşılacağı). Referans: `/mnt/project-files/referans/gece-ekranlari/5-ucuncu-taraf.jpg` | ✅ | #13 (gerçek `health` eklentisi ve AndroidManifest/Info.plist izinleri #20'de eklendi) |
| 12 | Kalıcı veri deposu: SQLite (`HealthStore` arayüzünün arkasında), uygulama kapanınca veri kaybolmasın | ✅ | #14 (web demosu bellekte kalır; şifreleme 27. maddede) |
| 13 | Elle nabız ve SpO2 ölçümü (0x28 02/03), Ana Sayfa'dan "Şimdi ölç" | ✅ | #15 (ölçüm bitişi PDF'te yok; süre dolunca uygulama bitiriyor, gerçek cihazda doğrulanacak) |
| 13b | Cam tasarım dili, yalnızca koyu tema: aurora zemin, cam kartlar, parlayan ana düğme, cam alt menü, 3D çizimler (kalp, ay, alev, halka), Manrope yazı tipi; tema seçimi kaldırıldı. Kurallar `docs/flutter-mobile-design.md` | ✅ | #16 |
| 14 | Ayarlar: otomatik ölçüm aralığı (0x2A/0x2B), takma algılama (0x86), saat/birim tercihleri | ✅ | #17 (0x2A aralık baytlarının sırası ve 0x86 onay paketi gerçek cihazda doğrulanacak) |
| 15 | Hatırlatıcılar: ilaç, su, hareketsizlik (0x23/0x57) | ✅ | #18, V1.2'ye göre #25'te düzeltildi (en çok 5 kayıt, ASCII etiket; hareketsizlik uyarısı belgede olmadığı için kaldırıldı) |
| 16 | Kilo ve vücut kompozisyonu: elle giriş, VKİ, grafik | ✅ | #19 |
| 17 | Gerçek BLE katmanı (flutter_blue_plus), cihaz taramasının 8. maddedeki eşleştirme ekranına bağlanması, kamerayla QR okuma (şimdilik QR altındaki adres elle giriliyor) | ✅ | #20 (11. maddedeki health eklentisi ve izinler de burada; UUID'ler, yayın adı, iOS'ta adresle eşleştirme gerçek cihazda doğrulanacak; flutter_blue_plus `License.nonprofit`, ticari lisans satıştan önce yeniden değerlendirilecek) |
| 18 | FHIR R4 dışa aktarma: Observation (LOINC), EKG için SampledData, Bundle JSON | ✅ | #21 (EKG SampledData çarpanı ve 10 dk'lık adım dönemi gerçek cihazda doğrulanacak; LOINC seçimi portalla gözden geçirilecek) |
| 19 | Portal arka ucu iskeleti (ayrı klasör): FHIR kabul eden API, takipçi yetkisi, KVKK kayıtları | ✅ | #22 (kalıcı şifreli depo #27'de; gerçek hekim girişi açık, bkz. aşağıdaki "Kodla çözülmeyenler") |
| 20 | PPI geçmişi (0x63) ve HRV ayrıntısı; VO2 Max tahmini | ✅ | #23, 0x63 biçimi V1.2'ye göre #25'te düzeltildi (VO2 Max tahminidir) |
| 21 | Rozetler, haftalık rapor, enerji skoru (referans uygulamadaki özellikler, kendi tasarımımızla) | ✅ | #24 (enerji skoru uygulamanın kendi tahmini; rozetler saklanmaz, geçmişten hesaplanır) |
| 22 | V8 API V1.2 ve SDK belgeleriyle protokol doğrulaması: 0x63 PPI, 0x23/0x57 hatırlatıcılar, 0x03/0x04 tüm gün nabız, 0x27 yazılım sürümü. Ayrıntı `docs/protokol-dogrulama.md` | ✅ | #25 (açık kalanlar notta listeli, gerçek cihazda denenecek) |
| 23 | Uygulamayı portala bağla: takma kimlikle hesap, davet/rıza portal üzerinden, yalnızca rızadaki türlerin FHIR olarak yüklenmesi (`--dart-define=PORTAL_URL`) | ✅ | #26 |
| 24 | Portalda kalıcı ve şifreli depo: AES-256-GCM şifreli olay dosyası, anahtar ortam değişkeninde, oturum anahtarlarının yalnızca özeti; silme hakkında dosya yeniden yazılır | ✅ | #27 (pilot için tek dosya; üretimde PostgreSQL) |
| 25 | Portalda hekim paneli (`/panel`): oturum anahtarıyla giriş, rızalı hastalar (takma kimlik), davet kodu oluşturma, rızadaki türlerin son 7 günü; her görüntüleme erişim kaydına geçer | ✅ | #28 (yalnızca Türkçe; hekim ve kurum doğrulaması sonra) |
| 26 | Geri bildirim ekranı (Profil > Geri bildirim): konu, mesaj, isteğe bağlı sürüm/platform; portalda kimliksiz `POST /feedback`, dakikalık sınır, `--feedback` ile okuma | ✅ | #29 |
| 27 | Telefonda şifreli veritabanı: SQLCipher (`sqflite_sqlcipher`), anahtar Keychain/Keystore'da (`flutter_secure_storage`); eski şifresiz dosyanın taşınması; portal oturum anahtarının da güvenli depoya alınması; Android yedeklemesinin kapatılması | ✅ | #30 (şifrelemenin kendisi gerçek telefonda doğrulanacak; FFI şifrelemez) |
| 28 | Portal hesabını kurtarma: kayıtta 80 bitlik kurtarma kodu (yalnızca özeti saklanır), `POST /recover` ile yeni telefona alma (eski anahtar ve kod geçersiz), `POST /patients/recovery` ile yeni kod; Profil > Portal hesabı ekranı | ✅ | #31 |
| 29 | Aile gruplarını portala bağla: `/groups` uçları, kişiye özel davet kodu (davet edilen verilen adla görünür), grup koduyla adsız katılım, üye başına paylaşım rızası, aynı gruptaki üyenin yalnızca rızadaki türleri okuyabilmesi, gruplarla paylaşılan türlerin de yüklenmesi | ✅ | #32 |
| 30 | iOS izin metinleri dört dilde (`InfoPlist.strings`, `CFBundleLocalizations`) ve hekim paneli dört dilde (`?lang=`, çerez, `Accept-Language`, Arapçada sağdan sola) | ✅ | #33 (Xcode derlemesi gerçek ortamda denenecek) |
| 31 | Gizlilik politikası taslağı (KVKK aydınlatma): uygulamada ekran (Hakkında'dan ve Health Connect "neden" bağlantısından), portalda herkese açık `/gizlilik`, `docs/gizlilik-politikasi.md`; Profil > Portal hesabı'ndan portal verilerini silme; çeviri inceleme tablosu (`docs/ceviri-inceleme.csv`) | ✅ | #34 (hukuk ve çeviri incelemesi bekliyor) |
| 32 | Kilit dosyaları (`pubspec.lock`, `portal/pubspec.lock` artık depoda) ve ekran görüntüsü testi (`EKRAN=1 flutter test --update-goldens test/ekran_goruntusu_test.dart`) | ✅ | #35 |
| 33 | Tarayıcıda deneme: uygulamanın web demosu (sahte bileklik) ve sunucusuz çalışan portal (hekim paneli, gizlilik sayfası) örnek veriyle (`seedDemo`); `Demo` iş akışı `demo-site` dalına ve main'de GitHub Pages'e yayımlar | ✅ | #36 |
| 34 | Gelişmiş hekim portalı: hekimin kendi kaydı (e-posta + PBKDF2 şifre, yönetici doğrulaması, doğrulanmamış hekim uygulamada uyarılır), hasta kayıtları ve kayda özel davetle bilekliğe bağlama, tüm türleri kapsayan tarih aralıklı rapor (özet, günlük grafikler, ESC/ESH tansiyon sınıfları, uyku evreleri, egzersiz, EKG, VO2 Max, eşiğe dayalı bulgular), yazdırma/PDF, CSV ve FHIR dışa aktarma; yeni paylaşım türleri solunum ve vücut ölçüleri | ✅ | (bu PR; bulgu eşikleri ve hekim doğrulama süreci klinik/hukuk ile gözden geçirilecek) |
| 35 | Test portalı: portal sunucusu, portala bağlı uygulamanın web sürümü ve hekim paneli tek adreste; `portal-deploy` dalı ve Render şablonu. Panelde oluşturulan davet kodu uygulamada çalışır, uygulamanın ölçümleri panelde görünür | ✅ | #38 |
| 36 | Nabız bölgeleri: yaştan azami nabız (208 − 0,7 × yaş), beş bölge (Isınma, Yağ yakma, Aerobik, Anaerobik, Azami), her bölgede geçen süre; nabız ayrıntısında ve egzersiz özetinde. İş planı karşılaştırmasından | ✅ | (bu PR) |
| 37 | Vücut ısısı sapması: ölçümlü ilk 7 günün ortalaması kişinin olağan ısısı; ısı ayrıntısında günlük/haftalık/aylık fark grafiği (sıfırın üstü sıcak, altı serin) | ✅ | (bu PR) |
| 38 | Biyolojik yaş: 21 günlük pencerede dinlenik nabız, adım, uyku ve VKİ'den takvim yaşına ± yıl (toplam ±10 sınırlı), son 8 haftanın eğilimi; İlerleme ekranında | ✅ | (bu PR; katsayılar uygulamanın kendi tahmini, klinik gözden geçirme bekliyor) |
| 39 | Sağlık Radarı: son gecenin nabız, HRV, ısı ve SpO2'si son 14 gecenin ortancasıyla karşılaştırılır (nabız +7, HRV −%25, ısı +0,5 °C, SpO2 −3); Ana Sayfa'da ve İlerleme'de kart | ✅ | (bu PR; telefon bildirimi arka plan senkronuyla birlikte sonra) |
| 36 | Tanıtım sitesi: `website/` tek sayfa statik site (tüm özellikler, paylaşım, KVKK, dört dil, SSS, test portalına bağlantılar), `website-deploy` dalı ve Render statik sitesi. Mağaza bağlantıları ve iletişim adresi yayın öncesi eklenecek | ✅ | #39 |
| 40 | Hekim panelinde uyarı panosu (uzaktan izlem): rızalı hastanın verisi geldiğinde kurallar çalışır (SpO2 10 dk %90 altı, nabız 10 dk 120 üstü egzersiz dışında ya da 40 altı, tansiyon ≥180/120, ateş ≥38 °C, 24 saat veri yok). Ana sayfada açık uyarılar kritik önce, "Gördüm" + not, 15 dk yanıtsız kritik uyarı "Gecikti"; `/panel/alerts` 30 günlük kayıt ve ortanca yanıt süresi | ✅ | (bu PR; eşikler klinik gözden geçirme bekliyor, kademeli yükseltme karar bekliyor) |
| 41 | Tanıtım sitesinde iş birliği (B2B) formu: distribütör, OEM/ODM, kurumsal sağlık, klinik; portalda `POST /inquiry` (anahtarsız, dakikada 10, bot tuzağı, aydınlatma onayı zorunlu), şifreli saklama, `--inquiries` ile okuma. Betiksiz tarayıcıda da çalışır | ✅ | (bu PR; yayında form adresi gerçek portala çevrilecek, başvurulara e-posta bildirimi yok) |
| 42 | Hekim panelinde izlem notları ve görevler: hasta kaydına tarihli not ve son günlü görev, "Tamamlandı"; ana sayfada "Görevlerim" (gecikenler önce). Yalnızca kaydı açan hekim görür, kayıt silinince silinir | ✅ | (bu PR; ekip içi paylaşım ve vardiya, hasta rızası kapsamı netleşince) |
| 43 | HL7 v2.5.1 ORU^R01 dışa aktarma: rapor sayfasında "HL7 v2 indir"; hekimin kaydı varsa dosya no ve ad (PID), takma kimlik her zaman; LOINC/UCUM; erişim kaydına geçer | ✅ | (bu PR; MLLP ile canlı gönderim ve kurumla alan doğrulaması hastane anlaşmasıyla) |
| 44 | Geliştirici belgesi: portalda `/openapi.json` (OpenAPI 3.1) ve `/developers` sayfası; kurumlar hekim/araştırmacı anahtarıyla rızalı veriyi FHIR üzerinden çeker. Belge ile yönlendirici testle eşleştirilir | ✅ | (bu PR; kurum başına API anahtarı ve kota, ilk kurumsal müşteriyle) |
| 45 | Aileye acil durum uyarısı: grup sayfasında ayrı izin "Acil durumda grubu uyar" (varsayılan kapalı, yalnızca nabız/SpO2/tansiyon/ısı paylaşılıyorsa); portal hekim uyarılarıyla aynı kurallarla son 24 saati tarar, grup üyeleri Ana Sayfa'da "Aile uyarısı" kartında ve grup sayfasında görür; her gösterim erişim kaydına geçer | ✅ | (bu PR; telefon bildirimi (push) için Firebase/APNs hesabı gerekiyor) |
| 46 | Tanıtım sitesi güncellemesi: "Nasıl ölçer" bölümü (PPG, EKG, HRV, uyku, tahmini tansiyon, cilt ısısı ve her birinin sınırı), doğru takma ve bilek ölçüsü rehberi, ön kayıt formu (`kind=waitlist`, yalnızca e-posta), yeni özellik kartları (Sağlık Radarı, biyolojik yaş, nabız bölgeleri, ısı sapması) ve panel/aile anlatımında uyarılar | ✅ | (bu PR; kayış ölçü aralığı üreticiden gelince eklenecek) |

## Her madde için

1. `CLAUDE.md`'deki kurallara uy (Türkçe arayüz, PDF örneği testte, sahte cihaz desteği).
2. `flutter analyze` uyarısız, `flutter test` yeşil olmadan PR açma.
3. PDF'te belirsiz kalanları kodda "gerçek cihazda doğrulanacak" diye işaretle ve PR açıklamasına yaz.
4. Bu tabloda durumu ve PR numarasını güncelle.

## Kodla çözülmeyenler

Kod tarafı hazır olsa da karar, insan ya da donanım gerektiren işler:

- **Çeviri incelemesi:** Arapça ve Almanca metinler ana dili konuşan biri tarafından gözden geçirilecek (7. madde). Tablo ve yönerge: `docs/ceviri-inceleme.md`.
- **Gerçek bileklikle deneme:** `docs/protokol-dogrulama.md` içindeki "Açık kalanlar".
- **Lisans:** flutter_blue_plus ticari lisansı ya da başka paket, satıştan önce.
- **Hukuk:** `docs/gizlilik-politikasi.md` taslağının son hali (veri sorumlusu, başvuru yolu, saklama süreleri), VERBİS kaydı, sunucunun yeri.
- **Hekim ve kurum doğrulaması:** hekim kendisi kaydoluyor, yönetici `--verify-clinician` ile elle onaylıyor; e-Devlet, kurum SSO ya da sicil sorgusu sonra.
- **Üretim altyapısı:** çok kullanıcılı portal için PostgreSQL ve yedekleme.
