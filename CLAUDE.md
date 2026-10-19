# Bileklik

JCV8 bileklik için iOS ve Android sağlık uygulaması.

## Tasarım skill'leri

Arayüz işi yaparken `.claude/skills/` altındaki skill'leri kullan:

- Yeni ekran veya bileşen: önce `frontend-design` (görsel yön, tipografi, renk), sonra `mobile-native`.
- Hareket, geçiş, bottom sheet, jest: `apple-design` ve `animate`.
- Detay cilası: `emil-design-eng`.
- Teslimden önce: `break-ui` ile uç durumları dene (uzun isim, boş veri, büyük sayı, taşan metin).
- Birden fazla tasarım seçeneği istenirse: `prototype`.

Not: `mobile-native`, `apple-design` ve `animate` web odaklıdır. Uygulama React Native/Expo ise `animate-expo` skill'ini de repoya ekle ve animasyon için onu kullan.

## Mobil tasarım kuralları

- Mobil öncelikli tasarla, 375px genişlikle başla.
- Dokunma hedefleri en az 44x44.
- Çentik ve alt çubuk güvenli alanlarına (safe area) uy.
- Sağlık verisi ekranlarında sayılar okunaklı ve büyük olsun; veri yoksa boş durum (empty state) göster.
- Açık ve koyu temayı birlikte düşün.
- Hareketi azalt (reduced motion) ayarına saygı göster.
