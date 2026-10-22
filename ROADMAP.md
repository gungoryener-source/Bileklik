# Yol haritası

Sırayla yapılacak işler. Her madde ayrı bir PR olur; PR'lar birleştirilene kadar
bir öncekinin dalı üzerine kurulur. Durum: ✅ bitti (PR açık ya da birleşti), 🔄 sürüyor, ⬜ sırada.

| # | İş | Durum | PR |
| --- | --- | --- | --- |
| 1 | Flutter iskeleti, V8 protokol çözücü, sahte bileklik | ✅ | #1 |
| 2 | Sağlık ekranları, geçmiş veri senkronu (adım, uyku, nabız, SpO2, HRV, stres, ısı) | ✅ | #2 |
| 3 | Egzersiz sekmesi: spor seçimi, canlı egzersiz, geçmiş (0x19, 0x18, 0x5C) | ✅ | #3 |
| 4 | EKG ölçümü, kayıtları ve nabız çözümlemesi (0x28, 0x07) | ✅ | #4 |
| 5 | Ana Sayfa yeniden tasarımı: tarih gezgini, günün özeti (uyku/toparlanma/yük), Egzersize başla kısayolu, Uyku, Aktivite halkası, Denge (HRV/stres), Kalp atış hızı ve SpO2 gün grafikleri, Zaman çizelgesi; yüzen alt menü. Düzen `/mnt/project-files/referans/ana-ekran/` ekran görüntülerinden, görseller kendimize ait; `docs/flutter-mobile-design.md` kurallarına uyulur | ✅ | #6 |
| 6 | Tema: açık ve koyu tema birlikte (flutter-mobile-design skill'i), renkler `ColorScheme`/`ThemeExtension` üzerinden `Theme.of(context)` ile; sistem ayarına uyan tema seçimi | ✅ | #7 |
| 7 | Dil desteği: Türkçe (kaynak), İngilizce, Arapça, Almanca. `flutter_localizations` + `gen-l10n` ARB dosyaları; ilk açılışta dil seçim ekranı (cihaz dili varsayılan), Profil > Genel ayarlar'dan değiştirme, seçimin saklanması; Arapça için sağdan sola yerleşim (`EdgeInsetsDirectional`, yön duyarlı ikonlar); tarih ve sayı biçimleri `intl` ile; her dilde taşma ve Arapça RTL widget testi. Sağlık terimlerinin çevirisi ana dili konuşan biri tarafından gözden geçirilecek | ✅ | #8 (çevirilerin ana dili konuşan biri tarafından gözden geçirilmesi bekliyor) |
| 8 | Profil sekmesi menüsü (Cihaz ayarları, Genel ayarlar, Paylaşım, Araştırma kurumu, Üçüncü taraf, Hakkında, Geri bildirim, sürüm) ve cihaz eşleştirme ekranı (sahte cihazla arama, QR ile eşleştirme). Referans: `/mnt/project-files/referans/gece-ekranlari/4-profil-menu.jpg`, `6-cihaz-eslestirme.jpg` | ✅ | #9 |
| 9 | Sağlık topluluğu: aile grupları (grup oluştur, üyeler, katıldığım gruplar, mesaj listesi) ve Consent tabanlı paylaşım izinleri (uygulama tarafı, sahte sunucu). Referans: `/mnt/project-files/referans/gece-ekranlari/1-topluluk.jpg`, `2-topluluk-menu.jpg` (aynı klasör) | ✅ | #10 |
| 10 | Araştırma kurumu ve hekim bağlantısı: davet kodu gir, QR tara, hangi verilerin ne süreyle paylaşılacağını gösteren KVKK açık rıza ekranı, bağlantıyı kaldırma. Referans: `/mnt/project-files/referans/gece-ekranlari/3-arastirma-kurumu.jpg` | ✅ | #11 (QR şimdilik kodla; kamera 17. maddede) |
| 11 | Üçüncü taraf entegrasyonu: Android'de Health Connect, iOS'ta Apple Health'e veri yazma (izin akışı, hangi türlerin paylaşılacağı). Referans: `/mnt/project-files/referans/gece-ekranlari/5-ucuncu-taraf.jpg` | ✅ | #13 (gerçek `health` eklentisi ve AndroidManifest/Info.plist izinleri 17. maddeyle birlikte) |
| 12 | Kalıcı veri deposu: SQLite (`HealthStore` arayüzünün arkasında), uygulama kapanınca veri kaybolmasın | ✅ | #14 (web demosu bellekte kalır; ek şifreleme KVKK değerlendirmesiyle) |
| 13 | Elle nabız ve SpO2 ölçümü (0x28 02/03), Ana Sayfa'dan "Şimdi ölç" | ✅ | #15 (ölçüm bitişi PDF'te yok; süre dolunca uygulama bitiriyor, gerçek cihazda doğrulanacak) |
| 13b | Cam tasarım dili, yalnızca koyu tema: aurora zemin, cam kartlar, parlayan ana düğme, cam alt menü, 3D çizimler (kalp, ay, alev, halka), Manrope yazı tipi; tema seçimi kaldırıldı. Kurallar `docs/flutter-mobile-design.md` | ✅ | #16 |
| 14 | Ayarlar: otomatik ölçüm aralığı (0x2A/0x2B), takma algılama (0x86), saat/birim tercihleri | ✅ | #17 (0x2A aralık baytlarının sırası ve 0x86 onay paketi gerçek cihazda doğrulanacak) |
| 15 | Hatırlatıcılar: ilaç, su, hareketsizlik (0x23/0x57) | ✅ | #18 (PDF elde değildi; 0x23/0x57 bayt düzeni, tür kodları ve hareketsizlik için 0x25/0x26 gerçek cihazda doğrulanacak) |
| 16 | Kilo ve vücut kompozisyonu: elle giriş, VKİ, grafik | ✅ | #19 |
| 17 | Gerçek BLE katmanı (flutter_blue_plus), cihaz taramasının 8. maddedeki eşleştirme ekranına bağlanması, kamerayla QR okuma (şimdilik QR altındaki adres elle giriliyor) | ✅ | #20 (11. maddedeki health eklentisi ve izinler de burada; UUID'ler, yayın adı, iOS'ta adresle eşleştirme gerçek cihazda doğrulanacak; flutter_blue_plus `License.nonprofit`, ticari lisans satıştan önce yeniden değerlendirilecek) |
| 18 | FHIR R4 dışa aktarma: Observation (LOINC), EKG için SampledData, Bundle JSON | ✅ | #21 (EKG SampledData çarpanı ve 10 dk'lık adım dönemi gerçek cihazda doğrulanacak; LOINC seçimi portalla gözden geçirilecek) |
| 19 | Portal arka ucu iskeleti (ayrı klasör): FHIR kabul eden API, takipçi yetkisi, KVKK kayıtları | ✅ | #22 (iskelet: bellekte depo, Bearer anahtar; kalıcı şifreli depo ve gerçek giriş sonra) |
| 20 | PPI geçmişi (0x63) ve HRV ayrıntısı; VO2 Max tahmini | ⬜ | |
| 21 | Rozetler, haftalık rapor, enerji skoru (referans uygulamadaki özellikler, kendi tasarımımızla) | ⬜ | |

## Her madde için

1. `CLAUDE.md`'deki kurallara uy (Türkçe arayüz, PDF örneği testte, sahte cihaz desteği).
2. `flutter analyze` uyarısız, `flutter test` yeşil olmadan PR açma.
3. PDF'te belirsiz kalanları kodda "gerçek cihazda doğrulanacak" diye işaretle ve PR açıklamasına yaz.
4. Bu tabloda durumu ve PR numarasını güncelle.
