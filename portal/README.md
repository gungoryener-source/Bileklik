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
- Oturum anahtarlarının yalnızca SHA-256 özeti saklanır.
- Hasta verisini silince (`DELETE /patients/<id>/data`) dosya, o hastanın
  ölçümleri olmadan baştan yazılır (geçici dosya + yeniden ad). Silinen veri
  şifreli halde bile diskte kalmaz. Erişim kayıtları kalır.
- Kimlikler rastgeledir; yeniden başlatmada çakışmaz.

Tek dosya pilot için yeterlidir. Çok kullanıcılı üretimde aynı `PortalStore`
arayüzünün arkasına PostgreSQL gelebilir.

`--demo` iki deneme hesabı açar. Oturum anahtarları `demo-patient` (hasta) ve
`demo-doctor` (hekim):

```sh
curl -H 'Authorization: Bearer demo-doctor' -H 'content-type: application/json' \
  -d '{"purpose":"Ritim takibi","scopes":["heartRate","ecg"],"days":90}' \
  localhost:8080/invites
```

## API

| Yol | Kim | Ne yapar |
| --- | --- | --- |
| `POST /patients` | herkes | Uygulamanın takma kimliğiyle (UUID v4) hasta hesabı açar; oturum anahtarı yalnızca bir kez verilir. |
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

## Hekim paneli

Sunucu çalışırken `http://…/panel` adresinden açılır. Hekim ya da araştırmacı,
kendisine verilen oturum anahtarıyla giriş yapar (`--add-clinician` ile
açılan hesap).

- **Ana sayfa:** rıza vermiş hastalar takma kimliğin ilk 8 karakteriyle
  listelenir; paylaşılan türler, rıza bitişi ve son veri zamanı görünür.
  Aynı sayfadan amaç, istenen veriler ve süre seçilerek davet kodu
  oluşturulur.
- **Hasta sayfası:** yalnızca süren rızadaki türlerin son 7 günü görünür:
  son değer, kayıt sayısı, ortalama ve son 20 kayıt; nabız için günlük
  ortalama çizgisi. Her görüntüleme ve rızasız her deneme erişim kaydına geçer.
- **Güvenlik:**
  - Oturum sunucu tarafında tutulur. Çerez `HttpOnly`, `SameSite=Strict` ve
    `Path=/panel`; 8 saat geçerli. HTTPS arkasında `PORTAL_HTTPS=1` ile
    `Secure` olur.
  - Formlar oturuma bağlı CSRF jetonu taşır.
  - Sayfalar harici kaynak yüklemez; `Content-Security-Policy` kısıtlayıcı.
    Tüm değerler kaçışlanarak yazılır.
  - Oturumlar bellekte tutulur; sunucu yeniden başlayınca hekim yeniden
    giriş yapar.
- Panel şimdilik yalnızca Türkçe.

## Yetki kuralları

- Hasta kendi verisinin tamamını görür.
- Takipçi yalnızca süresi dolmamış ve geri alınmamış rızasındaki türleri görür.
  Türlerin kodlara karşılığı `ShareScope.codes` içinde. Kilo, VKİ ve yağ oranı
  gibi elle girilen değerler hiçbir türde yer almaz, takipçiye hiç gösterilmez.
- Hekimin her okuması ve her reddedilen deneme `AuditEvent` olarak kaydedilir.
  Hastanın kendi okumaları kaydedilmez.
- Veri silinse de erişim kayıtları yasal saklama yükümlülüğü nedeniyle kalır.

## Sonraki adımlar

- Çok kullanıcılı üretim için PostgreSQL deposu ve yedekleme.
- Gerçek giriş: hekim ve kurum doğrulaması (ör. e-Devlet, kurum SSO); panel
  şu an portalın verdiği anahtarla açılıyor.
- Topluluk (aile grupları) sunucusunun sahte uygulamasının yerine bu API.
- Saklama süreleri, VERBİS kaydı ve aydınlatma metni hukukla birlikte.
