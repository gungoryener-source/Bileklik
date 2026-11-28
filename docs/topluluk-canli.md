# Aile grupları ve davet kodları: iki telefonla canlı deneme

Topluluk (aile grupları, davet kodu, kişi bazlı paylaşım izni) portal
sunucusu (`portal/`) üzerinden çalışır. Uygulama `PORTAL_URL` verilmeden
derlenirse sahte sunucuyla (`FakeCommunityServer`, örnek kişiler) çalışır;
demo ve testler böyle kalır.

## Akış

1. Telefon A: Profil > Sağlık topluluğu > Yeni grup oluştur. İlk seferde
   "Görünen adınız" sorulur (yalnızca gruptakiler görür).
2. A, grup sayfasında "Üye davet et" ile kişiye özel kod üretir (ya da grup
   kodunu verir) ve "Paylaş" ile WhatsApp/SMS'ten gönderir.
3. Telefon B: Sağlık topluluğu > Kodla katıl, kodu girer.
4. A'nın ekranı 15 saniyede bir (ve uygulama öne gelince) yenilenir; B
   "katıldı" olarak görünür. Aşağı çekince hemen yenilenir.
5. Paylaşım varsayılan kapalıdır. Her kişi grup sayfasında yalnızca seçtiği
   türleri açar; istediği an kapatır, gruptan ayrılır. Sahip üyeyi çıkarır.

Güvenlik: kodlar 6 karakter, kişiye özel kod bir kez kullanılır, grup kodu
yalnızca sahibine gösterilir, hatalı kod denemesi hesap başına dakikada 10
ile sınırlı. Her paylaşım değişikliği erişim kaydına (AuditEvent) geçer.

## Sunucu (Render)

`deploy.yml` her PR'da derlenmiş portalı `portal-deploy` dalına yazar;
`deploy/render.yaml` ile kurulan `bileklik-test` servisi bu dalı izler ve
kendiliğinden yeniden yayına alır. Sağlık kontrolü: `https://<adres>/health`.

Ücretsiz planda sunucu `PORTAL_DEMO=1` ile bellekte çalışır: 15 dakika boşta
kalınca uyur, uyanınca gruplar ve hesaplar sıfırlanır. Uygulama bunu fark
edince hesabı kendiliğinden yeniden açar, ama gruplar yeniden kurulmalıdır.
Deneme için yeterlidir. Kalıcı olması için:

1. Render'da servisi ücretli bir plana alın ve Disks bölümünden disk ekleyin
   (Mount path: `/var/data`).
2. Bir anahtar üretin (`cd portal && dart run bin/server.dart --new-key`) ve
   Environment bölümüne gizli değer olarak ekleyin: `PORTAL_KEY=<anahtar>`,
   `PORTAL_DATA=/var/data/portal.log`. Anahtar kaybolursa veri açılmaz;
   güvenli bir yerde saklayın, depoya yazmayın.

## Uygulama

GitHub > Settings > Secrets and variables > Actions > Variables >
New repository variable: `PORTAL_URL` = `https://<render adresi>/`. Android
ve iOS iş akışları bunu `--dart-define=PORTAL_URL=…` olarak geçer; değişken
yoksa telefon sürümü sahte sunucuyla kalır. Sonra Actions > Android APK >
Run workflow ile yeni APK üretilir (Releases).

İkinci telefon Android değilse test portalındaki web sürümü
(`https://<adres>/uygulama/`) aynı sunucuya bağlıdır; davet kodu orada da
çalışır.
