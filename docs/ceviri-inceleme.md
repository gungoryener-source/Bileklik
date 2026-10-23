# Çeviri incelemesi

Uygulama dört dilde: Türkçe (kaynak), İngilizce, Arapça, Almanca. Türkçe dışındaki metinler ana dili konuşan biri, özellikle sağlık ve hukuk terimleri için, tercihen sağlık alanında çalışan biri tarafından gözden geçirilmeli (ROADMAP 7. madde).

## Gözden geçirilecek dosyalar

| Ne | Dosya | Not |
| --- | --- | --- |
| Uygulama metinleri | `docs/ceviri-inceleme.csv` | Tüm anahtarlar dört dilde yan yana. "öncelik" sütunu sağlık ve hukuk terimlerini (nabız, HRV, EKG, uyku, tansiyon, rıza, gizlilik…) başa alır. Düzeltmeyi "not" sütununa yazın. |
| Gizlilik politikası | `lib/l10n/app_*.arb` (`privacy…`), `portal/lib/src/privacy_page.dart` | Hukuki metin; hukuk incelemesiyle birlikte. |
| Hekim paneli | `portal/lib/src/panel_text.dart` | Hekimin gördüğü metinler ve birimler. |
| iOS izin metinleri | `ios/Runner/*.lproj/InfoPlist.strings` | App Store incelemesinde okunur. |

## Dikkat edilecekler

- **Arapça:** sağdan sola. Sayılar Batı rakamlarıyla yazılıyor; yüzde işareti `٪`, ondalık ayırıcı panelde `٫`. Sayıya göre değişen çoğul biçimler (ör. "{n} سجلًا") kontrol edilmeli.
- **Almanca:** uzun birleşik sözcükler dar ekranda satır kırabilir. Widget testleri taşmayı denetler; anlam değişmeden kısaltmak gerekirse not düşün.
- **Tansiyon:** her dilde "tahmini" olduğu açıkça yazmalı. Uygulama tıbbi cihaz değildir.
- **Yer tutucular** (`{value}`, `{count}` gibi) olduğu gibi kalmalı; cümle içindeki yeri dile göre değişebilir.

## Düzeltmeleri işlemek

1. Düzeltilmiş CSV'yi ya da notları geliştiriciye iletin.
2. Geliştirici `lib/l10n/app_<dil>.arb` dosyalarını günceller ve `flutter gen-l10n` çalıştırır.
3. `flutter test`: dil testleri taşma ve sağdan sola yerleşimi denetler.
4. Tablo yeniden üretilir: `dart run tool/ceviri_tablosu.dart`. Tablo `app_tr.arb`'deki tüm anahtarları içerir.
