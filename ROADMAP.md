# Yol haritası

Sırayla yapılacak işler. Her madde ayrı bir PR olur; PR'lar birleştirilene kadar
bir öncekinin dalı üzerine kurulur. Durum: ✅ bitti (PR açık ya da birleşti), 🔄 sürüyor, ⬜ sırada.

| # | İş | Durum | PR |
| --- | --- | --- | --- |
| 1 | Flutter iskeleti, V8 protokol çözücü, sahte bileklik | ✅ | #1 |
| 2 | Sağlık ekranları, geçmiş veri senkronu (adım, uyku, nabız, SpO2, HRV, stres, ısı) | ✅ | #2 |
| 3 | Egzersiz sekmesi: spor seçimi, canlı egzersiz, geçmiş (0x19, 0x18, 0x5C) | ✅ | #3 |
| 4 | EKG ölçümü, kayıtları ve nabız çözümlemesi (0x28, 0x07) | ✅ | #4 |
| 5 | Ana Sayfa yeniden tasarımı: tarih gezgini, günün özeti (uyku/toparlanma/yük), Egzersize başla kısayolu, Uyku, Aktivite halkası, Denge (HRV/stres), Kalp atış hızı ve SpO2 gün grafikleri, Zaman çizelgesi; yüzen alt menü. Düzen `/mnt/project-files/referans/ana-ekran/` ekran görüntülerinden, görseller kendimize ait; `docs/flutter-mobile-design.md` kurallarına uyulur | ⬜ | |
| 6 | Profil sekmesi menüsü (Cihaz ayarları, Genel ayarlar, Paylaşım, Araştırma kurumu, Üçüncü taraf, Hakkında, Geri bildirim, sürüm) ve cihaz eşleştirme ekranı (sahte cihazla arama, QR ile eşleştirme). Referans: `/mnt/project-files/referans/gece-ekranlari/4-profil-menu.jpg`, `6-cihaz-eslestirme.jpg` | ⬜ | |
| 7 | Sağlık topluluğu: aile grupları (grup oluştur, üyeler, katıldığım gruplar, mesaj listesi) ve Consent tabanlı paylaşım izinleri (uygulama tarafı, sahte sunucu). Referans: `/mnt/project-files/referans/gece-ekranlari/1-topluluk.jpg`, `2-topluluk-menu.jpg` (aynı klasör) | ⬜ | |
| 8 | Araştırma kurumu ve hekim bağlantısı: davet kodu gir, QR tara, hangi verilerin ne süreyle paylaşılacağını gösteren KVKK açık rıza ekranı, bağlantıyı kaldırma. Referans: `/mnt/project-files/referans/gece-ekranlari/3-arastirma-kurumu.jpg` | ⬜ | |
| 9 | Üçüncü taraf entegrasyonu: Android'de Health Connect, iOS'ta Apple Health'e veri yazma (izin akışı, hangi türlerin paylaşılacağı). Referans: `/mnt/project-files/referans/gece-ekranlari/5-ucuncu-taraf.jpg` | ⬜ | |
| 10 | Kalıcı veri deposu: SQLite (`HealthStore` arayüzünün arkasında), uygulama kapanınca veri kaybolmasın | ⬜ | |
| 11 | Elle nabız ve SpO2 ölçümü (0x28 02/03), Ana Sayfa'dan "Şimdi ölç" | ⬜ | |
| 12 | Ayarlar: otomatik ölçüm aralığı (0x2A/0x2B), takma algılama (0x86), saat/birim tercihleri | ⬜ | |
| 13 | Hatırlatıcılar: ilaç, su, hareketsizlik (0x23/0x57) | ⬜ | |
| 14 | Kilo ve vücut kompozisyonu: elle giriş, VKİ, grafik | ⬜ | |
| 15 | Gerçek BLE katmanı (flutter_blue_plus), cihaz taramasının 6. maddedeki eşleştirme ekranına bağlanması | ⬜ | |
| 16 | FHIR R4 dışa aktarma: Observation (LOINC), EKG için SampledData, Bundle JSON | ⬜ | |
| 17 | Portal arka ucu iskeleti (ayrı klasör): FHIR kabul eden API, takipçi yetkisi, KVKK kayıtları | ⬜ | |
| 18 | PPI geçmişi (0x63) ve HRV ayrıntısı; VO2 Max tahmini | ⬜ | |
| 19 | Rozetler, haftalık rapor, enerji skoru (referans uygulamadaki özellikler, kendi tasarımımızla) | ⬜ | |

## Her madde için

1. `CLAUDE.md`'deki kurallara uy (Türkçe arayüz, PDF örneği testte, sahte cihaz desteği).
2. `flutter analyze` uyarısız, `flutter test` yeşil olmadan PR açma.
3. PDF'te belirsiz kalanları kodda "gerçek cihazda doğrulanacak" diye işaretle ve PR açıklamasına yaz.
4. Bu tabloda durumu ve PR numarasını güncelle.
