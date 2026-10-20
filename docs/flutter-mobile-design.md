# Bileklik ekran ayrıntıları

Asıl kurallar `.claude/skills/flutter-mobile-design/SKILL.md` içinde (ve CLAUDE.md'deki
"Tasarım skill'leri" bölümünde). Bu dosya o kuralları Bileklik'e uyarlayan ölçüleri tutar;
çelişki olursa skill geçerlidir.

## Cam tasarım dili (yalnızca koyu tema)

Uygulama tek temada çalışır: koyu "Cam". Açık tema ve tema seçimi yoktur. Eski sürümlerin
kaydettiği `theme_mode` değeri okunmaz. Bütün renkler `AppColors.cam` (`context.colors`)
içinde token olarak durur; ekranda sabit renk yazılmaz.

### Renkler
- Zemin degradesi (yukarıdan aşağı): `bgTop` #140D38, `bgMid` #0B0A22, `bgBottom` #08142E.
- Aurora ışıkları (kenarı saydama giden radyal degrade, bulanıklık filtresi yok):
  pembe #FF2E88 %95 sol üst, mor #6C4BFF %100 sağ üst-orta, camgöbeği #00C8FF %75 sol alt-orta,
  neon yeşil #9DFF3D %45 sağ alt.
- `scrim` (bgMid %45): auroranın üstüne serilir. Pembe ışığın merkezinde beyaz metin bile
  4.5:1'i tutturamıyordu; perdeyle ikincil metin (beyaz %75) en kötü noktada ~5:1 olur.
  `test/theme_test.dart` bunu her ışık için hesaplar.
- Cam kart: taban #141030 %40, üstte beyaz %16 → %4 çapraz parlaklık, 1 px beyaz %18 kenar.
- Metin beyaz; ikincil metin (`muted`) beyaz %75; hata metni (`danger`) #FFB8C8.
- Kart tonları: nabız #FF408C %38 → #7828C8 %16; uyku #7C5CFF %42 → #281E78 %18 (`camTint`).
- Ana düğme: #D9225F → #6A3DF0, parıltı #D9225F %50 (bulanıklık 24, 10 aşağı).
- Alt menü: taban #161234 %55; seçili sekme #7B5CFF → #D9225F hap, parıltı #9646FF %55.
- Bağlı noktası #9DFF3D, parıltılı; bağlı değilken beyaz %50.
- Veri renkleri (`DataColors`) koyu zeminde parlak kalacak tonlarda; türler birbirinden ayrılır.
  Metin rengi olarak değil, ikon, çizgi ve sütunda kullanılır.
- 3D çizim ve küre tonları `CamArt` içinde (ışık her zaman sol üstten).

### Ölçüler
- Köşe yarıçapı (`CamRadius`): kart 28, ana kart (hero) 32, küçük kutu 22, çip 20.
- İç boşluk (`CamSpace`): kart 18, hero 22; kartlar arası 12. 8 dp ızgarası korunur.
- Alt menü: yükseklik 70, köşe 35, yanlardan 20, alttan güvenli alan + 10. Kaydırılan liste
  altına `GlassNavBar.clearance(context)` kadar boşluk bırakır.
- Dokunma hedefi en az 48x48 dp.

### Bileşenler (`lib/ui/widgets/cam/`, tek import: `cam.dart`)
- `CamScaffold`: her rota zemini ve aurorayı kendisi çizer (`RepaintBoundary` + `IgnorePointer`),
  sistem çubuklarını saydam ve açık ikonlu yapar. `Scaffold` yerine kullanılır.
- `GlassCard`: varsayılan olarak `BackdropFilter` yok. Gerçek bulanıklık (`blur: true`) yalnızca
  içeriğin üstünde yüzen yüzeylerde: alt menü, alt sayfa, diyalog. Kaydırılan listede
  bulanıklık her karede yeniden hesaplanır ve kaydırmayı yavaşlatır.
- `GlowButton`: sayfanın ana eylemi. Üstte ışık, altta gölge (`foregroundDecoration`), renkli
  parıltı; pasifken %45 opak ve parıltısız. Diyalogdaki tehlikeli eylemler `FilledButton` kalır.
- `Pressable`: basınca 0.96'ya küçülür (90/160 ms), `HapticFeedback.lightImpact`, `Semantics`
  düğme etiketi; hareketi azalt açıksa küçülmez.
- `Orb`: içinde ikon olan parlak küre (hızlı işlemler, aktif süre).
- 3D çizimler (`CustomPainter`): `Heart3D`, `Moon3D`, `Flame3D`, `RingProgress`, `GlowProgressBar`.
  Altlarında nesnenin renginde parıltı. Halka ve çubuk 900 ms `easeOutCubic` ile dolar,
  hareketi azalt açıksa anında.
- `showCamDialog` / `showCamSheet`: arkası bulanık cam diyalog ve alt sayfa.
- `GlassNavBar`: cam alt menü (`AppShell`, `extendBody: true`).

### Grafikler (fl_chart ve kendi çizimlerimiz)
- Çizgi veri renginde, altında solan dolgu ve hafif parıltı.
- Izgara beyaz %8 (`grid`), eksen yazıları ikincil metin renginde.
- Sütun grafiğinde bugünün sütunu degrade ve parıltılı; diğerleri veri rengi %70.

### Arapça
- `PositionedDirectional`, `EdgeInsetsDirectional`, `AlignmentDirectional` kullanılır.
  3D nesneler aynalanmış konuma geçer ama çizimin kendisi çevrilmez (ışık yine sol üstten).
- Saat ekseni (grafikler, uyku şeridi) her dilde soldan sağa akar.

### Yazı tipi
- Manrope, `assets/fonts` içinde gömülü (SIL OFL 1.1, lisans "Lisanslar" sayfasında).
  Çalışırken indirme yok. Arapça harfleri olmadığı için Arapça metin sistem fontuna düşer
  (`fontFamilyFallback`). Büyük sayılarda `tabularFigures`.

## Düzen
- 8 dp ızgara: boşluklar 4, 8, 12, 16, 24, 32. Ekran kenar boşluğu 16 (yatay), kartlar arası 12.
- Kartlar `GlassCard` ya da `HomeCard` (başlık, sonda `chevron_right`; tüm kart dokunulabilir ve
  ayrıntı ekranına gider). Eşit yükseklikli ikili kartlar `IntrinsicHeight` ile.
- İçerik `SafeArea` içinde; yüzen alt menü içeriği örtmesin.
- Dar ekran (320 dp) ve büyük yazı (textScaler 1.3) ile taşma olmamalı: `FittedBox`, `maxLines`,
  `Flexible` kullanın; widget testinde en az bir kez küçük ekran deneyin.

## Dokunma ve erişilebilirlik
- Dokunma hedefi en az 48x48 dp.
- Her ikon düğmesinde `tooltip`, anlamlı görsellerde `Semantics` etiketi. Süs niteliğindeki 3D
  çizimler `ExcludeSemantics` ile atlanır; anlamı yanındaki metin taşır.
- Metin/arka plan karşıtlığı en az 4.5:1 (auroranın en parlak yerinde de); renk tek başına anlam
  taşımaz (değerin yanında metin olur).
- Sistem yazı boyutu büyütülünce düzen bozulmaz.

## Yazı ve sayılar
- Büyük değerler `fontFeatures: [FontFeature.tabularFigures()]` ile hizalı.
- Değer yoksa "--" gösterilir ve altında kullanıcıya ne yapacağını söyleyen kısa bir cümle olur
  ("Nabız için bilekliği gün boyu takın.").
- Birim değerin yanında küçük ve soluk (`AppColors.muted`).

## Görseller
- Fotoğraf kullanılmaz; zemin aurora degradesidir.
- Referans uygulamanın görselleri, ikonları ve arka plan resimleri kopyalanmaz; düzen ve akış örnek alınır.

## Hareket
- Geçişler 200-300 ms, `Curves.easeOutCubic`. Halka ve grafikler ilk açılışta bir kez dolar (900 ms).
- `MediaQuery.disableAnimations` açıksa animasyon yapılmaz.

## Durumlar
- Her kartın üç hali vardır: yükleniyor, veri yok, veri var. Üçü de widget testinde denenir.
- Bileklik bağlı değilken ekran boş kalmaz: çipte gri nokta ve "Bağlı değil" (dokununca bağlanır),
  nabız kartında son ölçüm ya da bağlanma çağrısı, "Şimdi ölç" pasif.
