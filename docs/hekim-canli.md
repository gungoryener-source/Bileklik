# Hekim portalında kod üret, telefon kodla bağlansın

Hekim, hekim portalındaki hasta kaydı için bir davet kodu üretir. Hasta bu
kodu Bileklik uygulamasına yazar (ya da QR karesini okutur), kimin hangi
verileri istediğini görür, paylaşacaklarını kendisi seçip açık rıza verir.
Portal o anda kaydı hastanın bilekliğine bağlar. Uygulama `PORTAL_URL`
verilmeden derlenirse sahte sunucuyla çalışır (demo kodu `DRK482`).

## Kurallar

- Hekim kodu 7 karakter, 24 saat geçerli ve **tek kullanımlık**: bir telefon
  bağlanınca kod silinir. İkinci telefon aynı kodla bağlanamaz ("kod
  geçersiz, kullanılmış ya da süresi dolmuş").
- Araştırma kurumu kodu çalışmaya katılan herkes için ortaktır, 30 gün geçerli.
- Hatalı kod denemesi hesap başına dakikada 10 ile sınırlı; sonra uygulama
  "bir dakika bekleyin" der.
- Hasta paylaşacağı türleri seçer; istenmeyen tür seçilemez. Bağlantıyı
  istediği an kaldırır (Bağlantı > Bağlantıyı kaldır); portalda kayıt
  "Rıza bitti" olur ve yeni veri gelmez.
- Her rıza ve geri alma erişim kaydına (AuditEvent) yazılır.

## Deneme adımları

Gerekenler: test portalı (`docs/topluluk-canli.md` içindeki Render
kurulumu) ve o portala bağlı bir uygulama. Uygulama için iki yol var:
`PORTAL_URL` depo değişkeniyle derlenmiş APK ya da test portalındaki web
sürümü `https://<adres>/uygulama/`.

1. Bilgisayarda `https://<adres>/panel` açın. Test portalında demo hekim
   hesabı vardır: `demo@bileklik.app` / `demo-sifre-2026`. Kendiniz
   kaydolursanız hesap "doğrulanmadı" görünür ve telefonda uyarı çıkar;
   doğrulamak için sunucuda `dart run bin/server.dart --verify-clinician=<e-posta>`.
2. Soldan **Yeni hasta**, ad yazıp kaydedin.
3. Kayıt sayfasında **Bilekliğe bağla** bölümünde istenen verileri ve
   süreyi seçip **Davet kodu oluştur**'a basın. Kod büyük harflerle ve QR
   karesi olarak görünür, altında ne zamana kadar geçerli olduğu yazar.
4. Telefonda **Profil > Hekim ve araştırma kurumu > Davet kodu gir**
   (ya da **QR kodu tara** ile ekrandaki kareyi okutun).
5. Telefonda hekimin adı, amaç ve istenen veriler görünür. Paylaşmak
   istediklerinizi seçin, rıza kutusunu işaretleyin, **Onayla ve bağlan**.
6. Portal sayfası kod beklerken 10 saniyede bir kendiliğinden yenilenir.
   Telefon bağlanınca "Telefon bağlandı" yazar, durum **Bağlı** olur;
   **Verileri gör** ve **Rapor oluştur** açılır. Veri, telefon ölçüm
   yükledikçe gelir.
7. Geri alma: telefonda bağlantıya dokunup **Bağlantıyı kaldır**. Portalda
   kayıt "Rıza bitti" olur.

Ek denemeler: aynı kodu ikinci bir telefona yazın (reddedilir); kod
beklerken **Davet kodu oluştur** ile yenisini üretin (eskisi geçersiz olur).

Not: ücretsiz Render planında sunucu uyuyunca bellekteki hesaplar ve
kayıtlar sıfırlanır; deneme aynı oturumda yapılmalıdır. Kalıcılık için
`docs/topluluk-canli.md` içindeki disk ve `PORTAL_KEY` adımları.
