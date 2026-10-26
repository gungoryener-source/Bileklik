# Tanıtım sitesi

Derleme gerektirmeyen tek sayfa statik site: `index.html`, `404.html`,
`img/` (uygulama ve panel ekran görüntüleri, paylaşım görseli) ve `fonts/`
(Manrope, SIL OFL; dış yazı tipi sunucusu kullanılmaz).

- `Tanıtım sitesi` iş akışı bu klasörü `website-deploy` dalına yazar.
- Render'da statik site olarak yayında: dal `website-deploy`, derleme komutu
  boş, yayın klasörü `.`.
- "Dene" bağlantıları test portalına gider (https://bileklik-test.onrender.com).
- "İş birliği" formu (`#is-birligi`) portalın `POST /inquiry` ucuna gönderir
  (şimdilik test portalı). Başvurular portalda şifreli durur; okumak için
  `dart run bin/server.dart --inquiries`.
- Yayın öncesi eklenecekler: App Store ve Google Play bağlantıları, iletişim
  adresi, şirket adı.

Yerelde bakmak için: `python3 -m http.server -d website 8080`.
