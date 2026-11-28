# Tanıtım sitesi

Derleme gerektirmeyen tek sayfa statik site: `index.html`, `404.html`,
`img/` (uygulama ve panel ekran görüntüleri, paylaşım görseli) ve `fonts/`
(Manrope, SIL OFL; dış yazı tipi sunucusu kullanılmaz).

Görünüm uygulamanın koyu Cam tasarımıdır (yalnızca koyu): lacivert-mavi gökyüzü
degradesi, altta sabit ve kısılmış dağ (satır içi SVG), koyu yarı saydam cam
kartlar, turkuaz vurgu (#45D6B8) ve yeşilden maviye ana düğme. Renkler
`lib/ui/theme.dart` içindeki `AppColors.cam`, `HomeSky` ve `DataColors`'tan
alınır; tasarım değişince önce oradaki tokenlar, sonra bu sayfanın `:root`
değişkenleri güncellenir. Hekim paneli (`portal/lib/src/panel.dart`) aynı
değişkenleri kullanır.

Uygulama ekran görüntüleri `EKRAN=1 flutter test --update-goldens
test/ekran_goruntusu_test.dart` ile üretilip 780x1688 WebP'ye küçültülür.

- `Tanıtım sitesi` iş akışı bu klasörü `website-deploy` dalına yazar.
- Render'da statik site olarak yayında: dal `website-deploy`, derleme komutu
  boş, yayın klasörü `.`.
- "Dene" bağlantıları test portalına gider (https://bileklik-test.onrender.com).
- "İş birliği" formu (`#is-birligi`) portalın `POST /inquiry` ucuna gönderir
  (şimdilik test portalı). Başvurular portalda şifreli durur; okumak için
  `dart run bin/server.dart --inquiries`. Sondaki "Haber ver" ön kayıt formu
  da aynı uca `kind=waitlist` ile yalnızca e-posta gönderir.
- "Satın al" bölümü (`#satin-al`) demodur: sepet tarayıcıda durur, ödeme
  sayfası taklittir, hiçbir şey gönderilmez. Plan `docs/odeme.md`.
- Yayın öncesi eklenecekler: App Store ve Google Play bağlantıları, iletişim
  adresi, şirket adı, kayış ölçü aralığı ("Nasıl ölçer" bölümü).

## Diller

Site dört dilde: Türkçe (`index.html`in kendisi), English, العربية (sağdan
sola), Deutsch. Üst çubuktaki seçiciyle değişir; seçim tarayıcıda kalır
(`localStorage` `bk-lang`) ve otomatik seçimin önüne geçer.

- `i18n.js` dil katmanıdır. İlk dil: `?lang=` > elle seçim > bağlanılan
  ülke > tarayıcı dili > İngilizce. Statik sitede sunucu olmadığından ülke
  tarayıcının saat diliminden bulunur (Europe/Istanbul -> tr, Europe/Berlin ->
  de, Asia/Riyadh -> ar…). Tablolar portaldaki `PortalLocale` ile aynıdır.
- Sözlükler `i18n/en.js`, `i18n/ar.js`, `i18n/de.js`. Anahtar sayfadaki Türkçe
  metnin kendisidir (boşluklar teke indirilir); bağlantı ya da kalın yazı
  içeren paragraflar bütün olarak çevrilir. Türkçe bir metni değiştirince üç
  sözlükteki anahtarı da değiştirin. Eksikleri görmek için
  `?lang=en&i18n=eksik` açıp konsola bakın; `test/website_i18n_test.dart`
  sözlüklerin tutarlılığını denetler.
- Betiklerdeki anlık metinler `bkI18n.t("Türkçe {ad}", {ad: …})` ile çevrilir;
  dil değişince `bk:lang` olayı gelir.
- Portala giden bağlantılar (`data-lang-link`) seçilen dili `?lang=` ile
  taşır; panel ve gizlilik sayfası aynı dilde açılır. Formlar gizli `lang`
  alanı gönderir.
- Uygulama ekran görüntüleri şimdilik Türkçe; dil bölümündeki görsel Arapça.

Yerelde bakmak için: `python3 -m http.server -d website 8080`.
