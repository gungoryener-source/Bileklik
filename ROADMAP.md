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
| 6 | Kalıcı veri deposu: SQLite (`HealthStore` arayüzünün arkasında), uygulama kapanınca veri kaybolmasın | ⬜ | |
| 7 | Elle nabız ve SpO2 ölçümü (0x28 02/03), Ana Sayfa'dan "Şimdi ölç" | ⬜ | |
| 8 | Ayarlar: otomatik ölçüm aralığı (0x2A/0x2B), takma algılama (0x86), saat/birim tercihleri | ⬜ | |
| 9 | Hatırlatıcılar: ilaç, su, hareketsizlik (0x23/0x57) | ⬜ | |
| 10 | Kilo ve vücut kompozisyonu: elle giriş, VKİ, grafik | ⬜ | |
| 11 | Gerçek BLE katmanı (flutter_blue_plus), cihaz tarama ve eşleştirme ekranı | ⬜ | |
| 12 | FHIR R4 dışa aktarma: Observation (LOINC), EKG için SampledData, Bundle JSON | ⬜ | |
| 13 | Paylaşım ve takipçiler: aile/hekim davet, Consent tabanlı izin modeli (uygulama tarafı) | ⬜ | |
| 14 | Portal arka ucu iskeleti (ayrı klasör): FHIR kabul eden API, takipçi yetkisi, KVKK kayıtları | ⬜ | |
| 15 | PPI geçmişi (0x63) ve HRV ayrıntısı; VO2 Max tahmini | ⬜ | |
| 16 | Rozetler, haftalık rapor, enerji skoru (referans uygulamadaki özellikler, kendi tasarımımızla) | ⬜ | |

## Her madde için

1. `CLAUDE.md`'deki kurallara uy (Türkçe arayüz, PDF örneği testte, sahte cihaz desteği).
2. `flutter analyze` uyarısız, `flutter test` yeşil olmadan PR açma.
3. PDF'te belirsiz kalanları kodda "gerçek cihazda doğrulanacak" diye işaretle ve PR açıklamasına yaz.
4. Bu tabloda durumu ve PR numarasını güncelle.
