# Bileklik ekran ayrıntıları

Asıl kurallar `.claude/skills/flutter-mobile-design/SKILL.md` içinde (ve CLAUDE.md'deki
"Tasarım skill'leri" bölümünde). Bu dosya o kuralları Bileklik'e uyarlayan ölçüleri tutar;
çelişki olursa skill geçerlidir.

## Düzen
- 8 dp ızgara: boşluklar 4, 8, 12, 16, 24, 32. Ekran kenar boşluğu 16 (yatay), kartlar arası 12.
- Kartlar tek tip: `AppColors` yüzey rengi, 20 köşe yarıçapı, ince kenar çizgisi, 16 iç boşluk.
  Başlık solda, sağda `chevron_right`; tüm kart dokunulabilir ve ayrıntı ekranına gider.
- İçerik `SafeArea` içinde; yüzen alt menü içeriği örtmesin (listenin altına menü yüksekliği kadar boşluk).
- Dar ekran (320 dp) ve büyük yazı (textScaler 1.3) ile taşma olmamalı: `FittedBox`, `maxLines`,
  `Flexible` kullanın; widget testinde en az bir kez küçük ekran deneyin.

## Dokunma ve erişilebilirlik
- Dokunma hedefi en az 48x48 dp.
- Her ikon düğmesinde `tooltip`, anlamlı görsellerde `Semantics` etiketi (Türkçe).
- Metin/arka plan karşıtlığı en az 4.5:1; renk tek başına anlam taşımaz (değerin yanında metin olur).
- Sistem yazı boyutu büyütülünce düzen bozulmaz.

## Yazı ve sayılar
- Büyük değerler `fontFeatures: [FontFeature.tabularFigures()]` ile hizalı.
- Değer yoksa "--" gösterilir ve altında kullanıcıya ne yapacağını söyleyen kısa bir cümle olur
  ("Nabız için bilekliği gün boyu takın.").
- Birim değerin yanında küçük ve soluk (`AppColors.muted`).

## Renk ve görseller
- Renkler yalnızca `AppColors` ve `MetricLook`'tan; ekranda sabit renk kodu yok.
- Koyu tema öncelikli; arka plan sade (degrade olabilir), fotoğraf kullanılmaz.
- Referans uygulamanın görselleri, ikonları ve arka plan resimleri kopyalanmaz; düzen ve akış örnek alınır.

## Hareket
- Geçişler 200-300 ms, `Curves.easeOutCubic`. Halka ve grafikler ilk açılışta bir kez dolar.
- `MediaQuery.disableAnimations` açıksa animasyon yapılmaz.

## Durumlar
- Her kartın üç hali vardır: yükleniyor, veri yok, veri var. Üçü de widget testinde denenir.
- Bileklik bağlı değilken ekran boş kalmaz; son senkron verisi ve "Bağlan" çağrısı görünür.
