# Ödeme ve abonelik

Durum (2026-10-27): yalnızca demo. Gerçek para alınmaz, fiyatlar örnektir.

## Üç ayrı ödeme yolu

1. **Uygulama içi Premium abonelik** (yapay zeka raporu). Apple ve Google,
   uygulamada satılan dijital hizmetlerin kendi ödeme sistemleriyle
   alınmasını şart koşar. Uygulamada `BillingService` arayüzü var
   (`lib/data/billing.dart`); şimdilik `FakeBillingService` mağazayı taklit
   eder. Gerçeği `in_app_purchase` ya da RevenueCat ile yazılacak, satın alma
   makbuzu portalda doğrulanacak. Mağaza komisyonu %15-30.
2. **Sitede bileklik satışı** (fiziksel ürün, mağaza kuralı yok). Sitedeki
   `#satin-al` bölümü sepet ve sahte ödeme sayfası gösterir; veri hiçbir yere
   gitmez. Yayında Türkiye için iyzico ya da PayTR, yurt dışı için Stripe'ın
   barındırılan ödeme sayfası kullanılacak: kart bilgisi bizim sunucumuza
   gelmez. Sipariş kaydı ve kargo portalda tutulacak.
3. **Kurumsal (hekim/klinik) lisans**: sözleşme ve fatura ile; portala
   yalnızca lisans takibi eklenir.

## Ücretsiz / Premium ayrımı

Ölçüm, geçmiş, paylaşım, hekim ve aile uyarıları ücretsiz kalır. Premium
şimdilik yalnızca yapay zeka raporunu açar.

## Yayından önce gerekenler (kodla çözülmez)

- Şirket, vergi kaydı ve fatura altyapısı (e-Arşiv / e-Fatura).
- App Store ve Google Play geliştirici hesapları, abonelik ürünleri.
- Ödeme kuruluşu başvurusu (iyzico/PayTR/Stripe).
- Mesafeli satış sözleşmesi, ön bilgilendirme formu, iade koşulları;
  gizlilik politikasına ödeme bölümü.
- Gerçek fiyatlar.
