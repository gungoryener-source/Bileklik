# Bileklik portalı (iskelet)

Uygulamadan FHIR R4 verisi alan, hekim, araştırma kurumu ve aile gibi
takipçilere bu veriyi yalnızca hastanın açık rızasıyla gösteren ve her
erişimi KVKK için kaydeden arka uç. Dart ile yazıldı (shelf).

```sh
cd portal
dart pub get
dart test
dart run bin/server.dart --demo   # bellekte, http://localhost:8080
```

Kalıcı kip: veriler şifreli bir dosyada tutulur.

```sh
export PORTAL_KEY=$(dart run bin/server.dart --new-key)   # bir kez üretip saklayın
export PORTAL_DATA=data/portal.log
dart run bin/server.dart --add-clinician="Dr. Ayşe Kaya" --org="Kardiyoloji Polikliniği"
# yazdırılan oturum anahtarını hekime verin
dart run bin/server.dart
```

## Depolama ve şifreleme

`EncryptedPortalStore` her değişikliği bir olay olarak dosyaya ekler.

- Her satır AES-256-GCM ile ayrı şifrelenir: rastgele nonce, doğrulama
  etiketi ve sabit bir ek veri. Açılışta tüm satırlar çözülür ve durum
  bellekte yeniden kurulur.
- Anahtar dosyada değil, `PORTAL_KEY` ortam değişkenindedir. Anahtar
  kaybedilirse veri geri alınamaz; yanlış anahtarla sunucu açılmaz.
- Oturum anahtarlarının ve kurtarma kodlarının yalnızca SHA-256 özeti
  saklanır. Kurtarma kodu 16 karakter (80 bit), bir kez kullanılır.
- Hasta verisini silince (`DELETE /patients/<id>/data`) dosya, o hastanın
  ölçümleri olmadan baştan yazılır (geçici dosya + yeniden ad). Silinen veri
  şifreli halde bile diskte kalmaz. Erişim kayıtları kalır.
- Kimlikler rastgeledir; yeniden başlatmada çakışmaz.

Tek dosya pilot için yeterlidir. Çok kullanıcılı üretimde aynı `PortalStore`
arayüzünün arkasına PostgreSQL gelebilir.

`--demo` deneme verisiyle açılır (`seedDemo`): bir hekim, bir araştırma
kurumu, son 30 günün tüm türlerdeki ölçümleriyle üç takma kimlikli hasta ve
hekimin üç hasta kaydı (ikisi bağlı, biri davet bekliyor; adlar uydurma). Oturum
anahtarları `demo-doctor` (hekim, panel girişi; ya da e-posta `demo@bileklik.app`,
şifre `demo-sifre-2026`), `demo-research` (araştırma),
`demo-patient`, `demo-patient-2`, `demo-patient-3` (hasta):

```sh
curl -H 'Authorization: Bearer demo-doctor' -H 'content-type: application/json' \
  -d '{"purpose":"Ritim takibi","scopes":["heartRate","ecg"],"days":90}' \
  localhost:8080/invites
```

## API

| Yol | Kim | Ne yapar |
| --- | --- | --- |
| `POST /patients` | herkes | Uygulamanın takma kimliğiyle (UUID v4) hasta hesabı açar; oturum anahtarı ve kurtarma kodu yalnızca bir kez verilir. |
| `POST /patients/recovery` | hasta | Yeni kurtarma kodu üretir; eskisi geçersiz olur. |
| `POST /recover` | herkes | Kurtarma koduyla hesabı yeni telefona alır: kimlik, yeni oturum anahtarı ve yeni kod döner; eski anahtarlar ve kod geçersiz olur. Dakikada en çok 10 hatalı deneme. |
| `GET /connections` | hasta | Süren rızaları, karşı tarafın adı ve kurumuyla birlikte uygulamanın göstereceği biçimde listeler. |
| `POST /fhir` | hasta | Uygulamanın Bundle'ını alır. Aynı `identifier` ikinci kez yazılmaz, bozuk kayıtlar uyarıyla döner. |
| `GET /fhir/Observation?patient=&code=&date=ge…&date=le…` | hasta, rızalı takipçi | Ölçümleri `searchset` Bundle olarak döner. |
| `GET /fhir/Consent` | hasta, takipçi | Hasta kendi rızalarını, takipçi kendisine verilenleri görür. |
| `GET /fhir/AuditEvent` | hasta | Verisine kimin, ne zaman eriştiği; reddedilen denemeler dahil. |
| `POST /invites` | hekim, araştırmacı | Amaç, istenen türler ve süreyle 7 haneli davet kodu üretir (30 gün geçerli). |
| `GET /invites/<kod>` | hasta | Uygulamanın açık rıza ekranındaki bilgileri döner. |
| `POST /invites/<kod>/accept` | hasta | Seçilen türlerle Consent oluşturur. Aynı takipçiye verilmiş eski rıza biter. |
| `DELETE /consents/<id>` | hasta | Rızayı geri alır; erişim hemen biter. |
| `DELETE /patients/<id>/data` | hasta | Ölçümleri siler ve rızaları bitirir (unutulma hakkı). |
| `GET /groups` | hasta | Aile grupları, üyeler, her üyenin paylaştığı türler ve "katıldı" bildirimleri. Grup kodu ve bekleyen davet kodları yalnızca sahibine gösterilir. |
| `POST /groups` | hasta | Grup açar (ad 1-40 karakter). |
| `POST /groups/<id>/members` | grup sahibi | Davet edilenin adıyla kişiye özel 6 karakterlik kod üretir. |
| `POST /groups/join` | hasta | Kişiye özel kodla (verilen adla) ya da grup koduyla (adsız) katılır. |
| `PUT /groups/<id>/consent` | üye | Grupla paylaşılan türleri ve isteğe bağlı `alerts` (acil uyarı izni) değiştirir; erişim kaydına geçer. Paylaşım boşsa izin kapanır. İzin veren üyenin paylaştığı türlerde son 24 saatteki olaylar (hekim uyarılarıyla aynı kurallar) `GET /groups` yanıtında diğer üyelere `alerts` olarak gider; gösterim erişim kaydına geçer. |
| `DELETE /groups/<id>/members/<mid>` | grup sahibi | Üyeyi ya da bekleyen daveti çıkarır; paylaşımı biter. |
| `DELETE /groups/<id>` | üye | Sahipse grubu siler (dosyadan da çıkar), değilse ayrılır. |
| `POST /feedback` | herkes | Uygulama içi geri bildirim. Anahtar istenmez, kimliğe bağlanmaz; dakikada en çok 30, mesaj en çok 2000 karakter. Okumak için `dart run bin/server.dart --feedback`. |
| `POST /inquiry` | herkes | Tanıtım sitesindeki iş birliği (distribütör, OEM/ODM, kurum, klinik) formu. Form gövdesi (`application/x-www-form-urlencoded`), herkese açık CORS; `Accept: application/json` ise JSON, değilse kısa HTML yanıt. Ad, kurum, e-posta, mesaj ve aydınlatma onayı zorunlu; dakikada en çok 10; gizli `website` alanı dolu gelirse kaydedilmez. Şifreli depoda saklanır, okumak için `dart run bin/server.dart --inquiries`. |
| `GET /openapi.json`, `GET /developers` | herkes | Geliştirici belgesi: OpenAPI 3.1 ve aynı belgeden üretilen okunur sayfa (İngilizce). Kurumlar hekim/araştırmacı anahtarıyla `GET /fhir/Observation` üzerinden yalnızca rızalı veriyi çeker. Belgedeki her ucun yönlendiricide olduğu testle denetlenir (`test/openapi_test.dart`). |

## Hekim paneli

Sunucu çalışırken `http://…/panel` adresinden açılır. Dört dilde (Türkçe,
İngilizce, Arapça, Almanca; `PanelText`, `ClinicText`); dil `?lang=` ile
seçilir ve çerezde kalır, Arapçada sayfa sağdan sola.

### Hekim hesabı

- **Kayıt:** `/panel/register`. Ad, uzmanlık, kurum, diploma tescil/sicil
  no, e-posta ve şifre (en az 10 karakter) ile hekim ya da araştırma kurumu
  hesabı açılır. Şifrenin yalnızca tuzlu PBKDF2-SHA256 özeti saklanır
  (`PasswordHasher`, 120 000 tur).
- **Doğrulama:** Kendi kaydolan hesap "doğrulanmadı" başlar. Panelde uyarı
  görünür; hasta davet ekranında da uyarılır (`GET /invites/<kod>` yanıtında
  `verified: false`). Yönetici kimliği kontrol edince onaylar:

  ```sh
  dart run bin/server.dart --list-clinicians
  dart run bin/server.dart --verify-clinician=ayse@klinik.test
  ```

- **Giriş:** e-posta ve şifreyle. Aynı e-postaya 15 dakikada 5 hatalı
  denemeden sonra giriş geçici olarak kapanır. Eski oturum anahtarıyla giriş
  de sürer; anahtarla açılan hesap "Hesabım" sayfasından e-posta ve şifre
  belirleyebilir.

### Hasta kayıtları

- Hekim "Yeni hasta" ile kendi kaydını açar: ad soyad, doğum tarihi,
  cinsiyet, dosya/protokol no, telefon, notlar. Bu bilgiler yalnızca kaydı
  açan hekime görünür; bileklik verisi her zaman takma kimlikle gelir.
- **Bilekliğe bağlama:** kayıt sayfasından kayda özel davet kodu üretilir.
  Hasta kodu uygulamada girip türleri seçince portal kaydı o takma kimliğe
  bağlar. Hekim, kendisine zaten rıza vermiş bir bağlantıyı da kayda
  bağlayabilir. Bağ kaldırılınca rıza sürer.
- Hasta listesi: kayıtlar (ad, dosya no, yaş, bağlantı durumu, paylaşılan
  türler, son veri) ve ad/dosya no araması; ayrıca kayda bağlanmamış
  rızalı bağlantılar.
- Düzeltilen ya da silinen kaydın eski hali şifreli dosyadan da çıkar
  (dosya baştan yazılır).

### Raporlar

`/panel/patients/<takma kimlik>/report?from=yyyy-aa-gg&to=yyyy-aa-gg&s=<tür>`

- Yalnızca süren rızadaki türler; en çok 2 yıllık dönem, varsayılan son 30
  gün. Bölümler tür tür seçilebilir.
- Başlık: hasta kaydı (ad, doğum tarihi/yaş, cinsiyet, dosya no), takma
  kimlik, dönem, hazırlayan hekim, paylaşılan türler.
- **Özet tablosu:** her ölçüm için kayıt sayısı, en düşük, en yüksek,
  ortalama, son değer ve dönemin iki yarısı arasındaki değişim. Veri bulunan
  gün sayısı.
- **Bölümler:** nabız (dinlenik nabız ve yaşla VO2 Max tahmini), HRV, SpO2,
  solunum hızı, vücut ısısı, stres, tansiyon (ESC/ESH 2018 sınıfları), uyku
  (gece gece süre ve derin/hafif/REM/uyanık evreleri), adım, mesafe, kalori,
  egzersiz listesi, EKG kayıtları (süre, ortalama nabız, SDNN), kilo, VKİ
  (sınıfıyla), yağ oranı, kas kütlesi. Her biri için günlük grafik (satır
  içi SVG) ve açılır günlük tablo.
- **Dikkat çeken bulgular:** eşiklerle otomatik (nabız >100 / <50, SpO2
  <%90, tansiyon ≥140/90, ateş ≥38 °C, solunum >20/dk, uyku <6 sa, günlük
  adım <5000, kilo değişimi ≥2 kg, eksik veri). Tanı değildir; eşikler
  raporda yazılıdır (`PatientReport`).
- **Çıktılar:** "Yazdır / PDF" (tarayıcının "PDF olarak kaydet"i; A4 baskı
  stili, panel öğeleri gizlenir), CSV (Excel için UTF-8 BOM, formül
  enjeksiyonuna karşı korumalı), FHIR Bundle (JSON; EKG ham örnekleri
  dahil) ve HL7 v2.5.1 ORU^R01 (`report.hl7`; hastane bilgi sistemleri için,
  her sayısal değer bir OBX, LOINC/UCUM; EKG dalga formu yalnızca FHIR'da;
  gerçek bir hastane arayüzüyle denenmedi). Her rapor ve dışa aktarma erişim kaydına geçer.

### İzlem notları ve görevler

Hasta kaydı sayfasında hekim tarihli not (görüşme, ilaç değişikliği,
telefon) ve son günlü görev ekler (`POST /panel/records/<id>/care`);
görev "Tamamlandı" ile kapanır (`…/care/<kayıt>/done`). Ana sayfadaki
"Görevlerim" açık görevleri gecikenler önce listeler. Notlar yalnızca kaydı
açan hekime görünür, şifreli depoda durur ve kayıt silinince silinir.

### Uyarılar (uzaktan izlem)

Hasta veri yükleyince ve hekim paneli açınca `AlertEngine`
(`lib/src/alerts.dart`) hekimin süren rızasındaki türlere son 48 saatte bakar:

- SpO2 en az 10 dk %90 altı; nabız en az 10 dk 120 üstü (egzersizin 5 dk
  öncesinden 15 dk sonrasına kadar sayılmaz) ya da 40 altı; tansiyon
  ≥180/120 (bileklikten tahmini); ateş ≥38 °C (kritik).
- 24 saattir veri gelmiyor (uyarı); veri gelince kendiliğinden kapanır.
- Aynı türde bir saat içinde süren olay yeni uyarı açmaz, açık olanı günceller.

Panel ana sayfasında açık uyarılar kritik önce listelenir, açık kritik
uyarısı olan hasta kayıtlarda üste çıkar. "Gördüm" (`POST
/panel/alerts/<id>/ack`, CSRF'li) uyarıyı kapatır; kim, ne zaman ve isteğe
bağlı not kaydedilir. 15 dk yanıtlanmayan kritik uyarı "Gecikti" olur.
`/panel/alerts` son 30 günün kaydını ve ortanca yanıt süresini gösterir.
Eşikler `AlertRules` içinde, klinik danışmanla gözden geçirilecek; karar
destek içindir, tanı koymaz. Hasta verisini silince uyarıları da silinir.

### Güvenlik

- Oturum sunucu tarafında tutulur. Çerez `HttpOnly`, `SameSite=Strict` ve
  `Path=/panel`; 8 saat geçerli. HTTPS arkasında `PORTAL_HTTPS=1` ile
  `Secure` olur.
- Tüm formlar oturuma bağlı CSRF jetonu taşır.
- Sayfalar harici kaynak yüklemez; `Content-Security-Policy` kısıtlayıcı.
  Rapor sayfasında yalnızca özeti CSP'de yazılı yazdırma betiği çalışır.
  Tüm değerler kaçışlanarak yazılır.
- Başka hekimin hasta kaydı "bulunamadı" döner; rızasız her deneme erişim
  kaydına geçer.
- Oturumlar bellekte tutulur; sunucu yeniden başlayınca hekim yeniden
  giriş yapar.

## Yetki kuralları

- Hasta kendi verisinin tamamını görür.
- Takipçi yalnızca süresi dolmamış ve geri alınmamış rızasındaki türleri görür.
- Aile grubu üyesi, aynı gruptaki bir hastanın o grupla paylaştığı türleri
  görür; okuması hastanın erişim kayıtlarına geçer. Gruptan ayrılınca ya da
  çıkarılınca erişim biter.
  Türlerin kodlara karşılığı `ShareScope.codes` içinde. Kilo, VKİ, yağ oranı
  ve kas kütlesi gibi elle girilen değerler yalnızca hasta "Vücut ölçüleri"
  (`body`) türünü ayrıca seçerse paylaşılır; solunum hızı `respiration`.
- Hekimin her okuması ve her reddedilen deneme `AuditEvent` olarak kaydedilir.
  Hastanın kendi okumaları kaydedilmez.
- Veri silinse de erişim kayıtları yasal saklama yükümlülüğü nedeniyle kalır.

## Sonraki adımlar

- Çok kullanıcılı üretim için PostgreSQL deposu ve yedekleme.
- Hekim doğrulamasının otomatikleşmesi (ör. e-Devlet, kurum SSO, TTB
  sicil sorgusu); şimdilik yönetici `--verify-clinician` ile onaylıyor.
- Şifre sıfırlama e-postası (e-posta gönderimi yok); şimdilik yönetici yeni
  hesap açar.
- İki adımlı doğrulama (TOTP).
- Saklama süreleri, VERBİS kaydı ve aydınlatma metni hukukla birlikte.

## Test portalı (Render)

`Test portalı` iş akışı (`.github/workflows/deploy.yml`) çalışır paketi
`portal-deploy` dalına yazar: derlenmiş sunucu, portala bağlı uygulamanın web
sürümü (`/uygulama/`), açılış sayfası, `Dockerfile` ve `render.yaml`.

1. render.com'da GitHub hesabıyla oturum açın.
2. New > Blueprint > `gungoryener-source/Bileklik`, dal `portal-deploy`
   (ya da New > Web Service > aynı depo ve dal, Docker, Free).
3. Yayına girince adres `https://bileklik-test.onrender.com` gibi olur:
   - `/`: açılış sayfası
   - `/uygulama/`: uygulama (sahte bileklik, portala bağlı)
   - `/panel`: hekim paneli (`demo@bileklik.app` / `demo-sifre-2026`)

Ücretsiz planda servis 15 dakika boş kalınca uyur; ilk istek yaklaşık bir
dakika sürer. Veriler bellekte tutulur, yeniden başlayınca deneme verisiyle
sıfırlanır. Kalıcı veri için diskli bir planda `PORTAL_KEY` ve `PORTAL_DATA`
verin (`--new-key` ile anahtar üretilir).

