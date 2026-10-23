# Bileklik portalı (iskelet)

Uygulamadan FHIR R4 verisi alan, hekim, araştırma kurumu ve aile gibi
takipçilere bu veriyi yalnızca hastanın açık rızasıyla gösteren ve her
erişimi KVKK için kaydeden arka uç. Dart ile yazıldı (shelf).

```sh
cd portal
dart pub get
dart test
dart run bin/server.dart --demo   # http://localhost:8080
```

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

## Yetki kuralları

- Hasta kendi verisinin tamamını görür.
- Takipçi yalnızca süresi dolmamış ve geri alınmamış rızasındaki türleri görür.
  Türlerin kodlara karşılığı `ShareScope.codes` içinde. Kilo, VKİ ve yağ oranı
  gibi elle girilen değerler hiçbir türde yer almaz, takipçiye hiç gösterilmez.
- Hekimin her okuması ve her reddedilen deneme `AuditEvent` olarak kaydedilir.
  Hastanın kendi okumaları kaydedilmez.
- Veri silinse de erişim kayıtları yasal saklama yükümlülüğü nedeniyle kalır.

## Sonraki adımlar

- Kalıcı ve şifreli depo (`PortalStore` arayüzünün arkasına PostgreSQL).
- Gerçek giriş: hekim ve kurum doğrulaması, hasta için uygulamadan cihaz
  anahtarı.
- Topluluk (aile grupları) sunucusunun sahte uygulamasının yerine bu API.
- Saklama süreleri, VERBİS kaydı ve aydınlatma metni hukukla birlikte.
