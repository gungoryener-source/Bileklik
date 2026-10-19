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
- Açık ve koyu temayı birlikte düşün; tek `ThemeData` üzerinden yönet.
- Hareketi azalt ayarına (`disableAnimations`) saygı göster.
- Teslimden önce `flutter analyze` çalıştır ve uç durumları dene.
