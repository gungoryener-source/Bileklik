---
name: flutter-mobile-design
description: Flutter ile iOS ve Android sağlık uygulaması arayüzü tasarlarken ve yazarken kullan. Tema, güvenli alan, uyarlanabilir yerleşim, animasyon, haptik, erişilebilirlik ve uç durum testlerini kapsar. Yeni ekran, bileşen, geçiş veya "telefonda kötü görünüyor" işlerinde devreye girer.
---

# Flutter mobil tasarım (Bileklik)

Web odaklı skill'lerdeki (`frontend-design`, `apple-design`, `emil-design-eng`) tasarım ilkelerini kullan, ama kodu her zaman Flutter ile yaz. CSS ve HTML önerilerini Flutter karşılığına çevir.

## Sıra

1. Görsel yönü seç (`frontend-design`): renk, tipografi, boşluk, ton. Sağlık uygulaması için sakin, okunaklı, veri odaklı.
2. Temayı kodla: tek bir `ThemeData` (Material 3, `ColorScheme.fromSeed`), yalnızca koyu (Cam) tema. Renk ve yazı stilini widget içinde sabitleme, `Theme.of(context)` ve `context.colors` üzerinden al. Cam bileşenleri ve ölçüleri için `docs/flutter-mobile-design.md`.
3. Ekranı kur: yerleşim, güvenli alan, uyarlanabilirlik.
4. Hareketi ekle, sonra uç durumları dene.

## Yerleşim

- `SafeArea` kullan; çentik, dinamik ada ve alt çubukta içerik kesilmesin.
- Sabit piksel yerine `LayoutBuilder` / `MediaQuery` ile uyarlanabilir yaz. Küçük telefon (yaklaşık 360 dp genişlik) ve büyük telefonu birlikte düşün.
- Klavye açılınca alan taşmasın: kaydırılabilir gövde (`SingleChildScrollView` / `ListView`), `Scaffold` klavye ayarı.
- Uzun listelerde `ListView.builder`; tüm öğeleri bir kerede kurma.
- Dokunma hedefleri en az 48x48 dp.

## Platform hissi

- Tek kod tabanı ama platforma saygı: iOS'ta geri kaydırma jesti çalışmalı, kaydırma fiziği platforma uygun kalmalı (varsayılanı bozma).
- iOS'ta gerekli yerlerde Cupertino bileşenleri (örneğin sistem tarzı seçiciler, dialoglar) düşün; her yerde Material zorunlu değil.
- Durum çubuğu ve sistem çubuğu saydam, ikonlar açık (edge-to-edge); `CamScaffold` bunu kendisi ayarlar.

## Hareket

- Önce gerekip gerekmediğine karar ver: hareket bir anlam taşımalı (durum değişimi, geri bildirim, süreklilik).
- Basit geçişlerde örtük animasyonlar (`AnimatedContainer`, `AnimatedOpacity`, `TweenAnimationBuilder`). Karmaşık ve kontrollü olanlarda `AnimationController`.
- Jest sonrası bırakmada yay (spring) hissi için `SpringSimulation`; sabit süreli eğriler yerine, kullanıcı hareketi yarıda kesebilmeli.
- Süre kısa tut: dokunma geri bildirimi 100-200 ms, geçişler yaklaşık 200-350 ms.
- Yalnızca kompozit maliyeti düşük şeyleri animasyonla: opaklık, dönüşüm (`Transform`, `FadeTransition`). Her karede ağır yeniden yerleşim tetikleme.
- `MediaQuery.of(context).disableAnimations` açıksa hareketi kapat veya azalt.
- Dokunma anında haptik: `HapticFeedback.lightImpact()` gibi, seyrek ve anlamlı yerlerde.

## Sağlık verisi ekranları

- Ana sayı büyük ve net (nabız, adım, uyku). Birim ve etiket küçük ama okunaklı.
- Grafikte renge tek başına güvenme; etiket veya desen ekle (renk körlüğü). Kütüphane gerekiyorsa yaygın bir grafik paketi (örneğin `fl_chart`) seç, sürümü ve bağımlılığı eklemeden önce kontrol et.
- Bilek bandı bağlı değilken, veri yokken, senkronizasyon sürerken ve hata durumlarında net boş/yükleniyor/hata ekranı göster.
- Tıbbi iddia gibi görünen metinlerden kaçın; ölçümleri tanı gibi sunma.

## Erişilebilirlik

- `Semantics` ve anlamlı etiketler; ikon düğmelerine `tooltip` / `semanticLabel`.
- Sistem yazı boyutu ölçeğiyle bozulmasın: `MediaQuery.textScalerOf(context)` ile büyütülmüş metni dene; sabit yükseklikli kutulardan kaçın.
- Kontrast: metin ve arka plan için en az WCAG AA.

## Teslimden önce (uç durum testi)

Her yeni ekranı şu verilerle dene, taşma (`RenderFlex overflowed`) veya kesilme olmasın:

- Çok uzun ad, tek harfli ad, boş alan
- Sıfır öğe, çok büyük sayı, eksik alan
- Yazı boyutu en büyük, küçük ekran (Cam teması, auroranın en parlak yerinde de okunur mu)
- Hata ve çevrimdışı durumu

Mümkünse bu durumları widget testi veya golden test ile kalıcı hale getir. Kod yazdıktan sonra `flutter analyze` çalıştır.
