# Yapay zeka sağlık raporu ve koçluk

Durum (2026-10-26): yalnızca demo. Uygulamada ekranlar, ayrı açık rıza ve
kurallarla yazılan örnek rapor var (`lib/data/ai_report.dart`,
`DemoAiReportService`). Claude API bağlı değil; veri telefondan çıkmıyor.

## Hedeflenen yapı

1. **Rapor sunucuda üretilir.** Telefon, portalın `POST /ai/report` ucuna
   haftanın özetini (`AiReportInput.toJson()`) ve dil kodunu gönderir. Portal
   Claude API'yi çağırır, hazır raporu döner. API anahtarı yalnızca sunucuda
   durur; uygulamaya hiç girmez.
2. **Giden veri en azdır.** Yaş aralığı, cinsiyet, haftalık ortalamalar,
   Sağlık Radarı işaretleri, biyolojik yaş farkı. İsim, iletişim, bileklik
   adresi, ham EKG ve tek tek ölçümler gönderilmez. Kullanıcı aynı JSON'u
   ekranda "Kullanılan veri" altında görür.
3. **Biçim sabittir.** Claude'dan yapılandırılmış çıktı (`output_config.format`,
   JSON şeması) istenir: `summary`, `wins[]`, `watch[]`, `tips[]`; her liste
   en çok 3 madde. Uygulama `AiReport` ile aynı alanları gösterir, böylece
   demo ve gerçek rapor aynı ekranı kullanır.
4. **Dil:** istekteki dil kodu (tr, en, ar, de) sistem talimatına yazılır;
   rapor o dilde döner.

## Tıbbi sınırlar

- Sistem talimatı: tanı koyma, hastalık adı verme, ilaç ya da doz önerme;
  yalnızca yaşam tarzı önerisi; belirti varsa "hekiminize danışın".
- Acil durumlar yapay zekaya bırakılmaz. Hekim uyarı panosu ve aile uyarısı
  (ROADMAP 40, 45) kurallarla çalışmaya devam eder.
- Her raporun altında sabit uyarı metni (`aiDisclaimer`, 4 dil).
- EKG yorumu yapılmaz: bu, ürünü tıbbi cihaz yazılımı (MDR / TİTCK) kapsamına
  sokabilir. Hukuk görüşü alınmadan eklenmeyecek.

## KVKK / GDPR

- Ayrı ve geri alınabilir açık rıza (`AppSettings.aiConsentAt`); hekim ve aile
  paylaşımından bağımsız. Rıza metni yurt dışına (ABD) aktarımı açıkça yazar.
- Canlıya geçmeden önce: Anthropic ile veri işleme sözleşmesi (DPA), mümkünse
  sıfır veri saklama (ZDR) anlaşması, gizlilik politikasına bölüm, VERBİS.
- Portal, gönderilen özeti ve raporu erişim kaydına yazar; rıza geri alınınca
  yeni rapor üretilmez.

## Hekim onayı (sonraki adım)

Kullanıcı şimdilik yalnızca demoyu seçti. Önerilen akış: hasta bir hekime
bağlıysa rapor önce hekim panelinde taslak olarak görünür, hekim düzenleyip
onaylar, hasta ondan sonra görür. Bağlı değilse rapor uyarı metniyle doğrudan
gösterilir.

## Maliyet (2026-10 fiyatları)

Rapor başına yaklaşık 5.000 token girdi (talimat + özet) ve 1.500 token çıktı.

| Model | Girdi / çıktı ($ / 1M token) | Rapor başına |
| --- | --- | --- |
| Claude Opus 5.5 | 4 / 20 | ~0,05 $ |
| Claude Sonnet 5.5 | 2 / 10 | ~0,025 $ |

Gece toplu üretimde (Batches API) fiyat yarıya iner. Haftalık raporla
kullanıcı başına ayda yaklaşık 0,10-0,20 $.

## Kodda nereye bağlanır

- `AiReportService` arayüzü: gerçek uygulama `PortalAiReportService` olarak
  portala istek atar; `AiReportScreen(service: ...)` ile verilir.
- Portal tarafında `portal/lib/src/ai_report.dart` (yazılacak): Anthropic Dart
  SDK'sı yoksa HTTP ile `POST /v1/messages`; anahtar `ANTHROPIC_API_KEY`
  ortam değişkeninde.
