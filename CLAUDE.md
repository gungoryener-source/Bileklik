# Bileklik

JCV8 bileklik için iOS ve Android sağlık uygulaması. Flutter ile yazılıyor.

## Tasarım skill'leri

Arayüz işi yaparken `.claude/skills/` altındaki skill'leri kullan. Ana skill `flutter-mobile-design`; kodu her zaman Flutter (Dart) ile yaz.

- Her arayüz işinde: `flutter-mobile-design`.
- Görsel yön, tipografi, renk: `frontend-design`.
- Detay cilası ve hareket felsefesi: `emil-design-eng`, `apple-design`.
- Hareket kararları (gerekli mi, süre, eğri): `animate`.
- Uç durum düşüncesi (uzun metin, boş veri, büyük sayı): `break-ui`.
- Birden fazla tasarım seçeneği istenirse: `prototype`.

Not: `mobile-native`, `apple-design`, `animate`, `break-ui` ve `prototype` web (HTML/CSS/JS) için yazıldı. Bunlardan yalnızca tasarım ilkelerini al; CSS, meta etiketi veya tarayıcı önerilerini kullanma, Flutter karşılığını yaz.

## Mobil tasarım kuralları

- Mobil öncelikli tasarla; küçük (yaklaşık 360 dp) ve büyük telefonu birlikte düşün.
- Dokunma hedefleri en az 48x48 dp.
- `SafeArea` kullan; çentik ve alt çubuğa uy.
- Sağlık verisi ekranlarında sayılar büyük ve okunaklı olsun; veri yoksa boş durum göster.
- Tema tek `ThemeData` üzerinden (`lib/theme/app_theme.dart`). Cam tasarım dili koyu temadır; açık tema şimdilik yok.
- Hareketi azalt ayarına (`disableAnimations`) saygı göster.
- Teslimden önce `flutter analyze` ve `flutter test` çalıştır, uç durumları dene.

## Tasarım dili: Cam

Ana ekranla kesinleşti. Yeni her ekran bu dili ve bu bileşenleri kullanır, yenisini icat etmez.

- Zemin: koyu gece mavisi ve arkasında pembe, mor, camgöbeği, neon yeşil ışıklar. `AuroraBackground`, uygulama kabuğunda (`lib/app_shell.dart`) bir kez çizilir; ekranlar saydamdır.
- Kartlar: `GlassCard` (yarı saydam, ince ışık kenarlı, köşe 28; büyük kart 32). Gerçek bulanıklık (`blur: true`) yalnızca içeriğin üstünde yüzen yüzeylerde (alt menü, alt sayfa); kartlarda kapalı kalsın, yoksa ucuz Android telefonlarda kaydırma takılır.
- 3D objeler: `lib/widgets/illustrations.dart` (CustomPainter). Işık sol üstten gelir, altta objenin renginde parıltı olur. Yeni obje de aynı ışık yönünü kullanır.
- Butonlar: ana eylem `GlowButton` (parlayan degrade). Küçük eylemler cam karo içinde `Orb` (parlak küre ikon). Dokunulabilir her şey `Pressable` ile sarılır (haptik, basınca küçülme, erişilebilirlik etiketi).
- Renkler yalnızca `AppColors`, yazı stilleri yalnızca `AppText` (Manrope). Widget içinde yeni renk veya font tanımlama; gerekiyorsa önce `AppColors`'a ekle.
- Alt menü: `GlassNavBar`. Ekranlar menünün altında içerik kalmasın diye alt boşluk bırakır.
- Büyük sayılar `FittedBox(fit: BoxFit.scaleDown)` içinde; yan yana kartlar `IntrinsicHeight` ile eşit boy.
- Veri yoksa "—" ve kısa bir açıklama ("Veri yok", "Bileklik bağlı değil"); bileklik bağlı değilken ölçüm butonları pasif.
