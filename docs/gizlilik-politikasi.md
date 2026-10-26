# Gizlilik politikası (taslak)

Uygulamadaki gizlilik ekranının (`lib/l10n/app_*.arb`, `privacy…` anahtarları) ve portaldaki `/gizlilik` sayfasının (`portal/lib/src/privacy_page.dart`) kaynağı. Üçü aynı tutulur.

> **Hukuk incelemesi bekliyor.** Yayından önce eklenecekler: veri sorumlusunun unvanı ve adresi, başvuru yolu (KVKK m. 13), portaldaki verilerin ve erişim kayıtlarının saklama süreleri, VERBİS kaydı, yurt dışına aktarım (sunucu nerede olacaksa). Google Play için herkese açık adres: portalın `/gizlilik` sayfası.

Taslak: Bu metin hukuk incelemesinden geçmedi. Veri sorumlusunun unvanı, adresi ve saklama süreleri yayından önce eklenecek.

Bu metin, Bileklik uygulamasının ve portalının kişisel verilerinizi nasıl işlediğini 6698 sayılı Kişisel Verilerin Korunması Kanunu (KVKK) kapsamında anlatır.

## Hangi verileri işliyoruz?

Bilekliğin ölçtükleri: nabız, kalp atış hızı değişkenliği (HRV), kandaki oksijen (SpO2), EKG, uyku, adım, egzersiz, vücut ısısı, stres ve tahmini tansiyon. Sizin girdikleriniz: yaş, boy, kilo, cinsiyet, vücut kompozisyonu ve hatırlatıcılar. Bilekliğin Bluetooth adresi. Adınız, TC kimlik numaranız, telefonunuz ya da e-postanız istenmez; portalda yalnızca rastgele bir takma kimlikle tanınırsınız. Tanıtım sitesindeki iş birliği formunu doldurursanız adınız, kurumunuz, e-postanız ve mesajınız yalnızca size dönmek için şifreli saklanır; sağlık verisiyle birleştirilmez.

## Veriler nerede durur?

Ölçümler telefonunuzda şifreli bir veritabanında durur; anahtarı telefonun güvenli bölgesindedir (iOS Keychain, Android Keystore). Bu veriler telefon yedeğine girmez. Portala yalnızca paylaşmayı seçtiğiniz türler gider ve orada da şifreli saklanır.

## Neden işliyoruz?

Ölçümlerinizi size göstermek; sizin seçtiğiniz hekim, araştırma kurumu ve aile üyeleriyle paylaşmak; isterseniz Apple Sağlık ya da Health Connect'e yazmak. Verileriniz reklam için kullanılmaz ve satılmaz.

## Hukuki sebep

Sağlık verileri özel nitelikli kişisel veridir ve açık rızanızla işlenir (KVKK madde 6). Her paylaşım için ayrı rıza alınır: kiminle, hangi türlerin, ne kadar süreyle paylaşılacağını siz seçersiniz ve rızanızı istediğiniz an geri alırsınız.

## Kimlerle paylaşılır?

Yalnızca rıza verdiğiniz hekim, araştırma kurumu ya da aile grubu üyeleri, yalnızca seçtiğiniz türleri ve rıza süresince görür. Kilo ve vücut kompozisyonu gibi elle girdiğiniz değerler yalnızca “Vücut ölçüleri”ni ayrıca seçerseniz paylaşılır. Apple Sağlık ya da Health Connect'e yalnızca seçtiğiniz türler yazılır; uygulama oradan veri okumaz. Geri bildirimler kimliğinize bağlanmaz. Hekiminize, paylaştığınız türlerde belirgin bir değişiklik olduğunda (örneğin SpO2 uzun süre düşükse ya da bir gündür veri gelmiyorsa) portal otomatik uyarı gösterir; bu uyarılar tanı değildir ve portaldaki verinizi silince onlar da silinir. Bir aile grubu için "Acil durumda grubu uyar"ı ayrıca açarsanız, o grupla paylaştığınız türlerdeki aynı uyarılar grup üyelerine de gösterilir.

## Erişim kayıtları

Portalda verinize yapılan her erişim, reddedilen denemeler dahil, kaydedilir. Kimin ne zaman baktığını uygulamadan görebilirsiniz.

## Ne kadar süre saklanır?

Telefondaki veriler uygulamayı silene kadar kalır. Portaldaki ölçümler siz silene kadar kalır; paylaşım rızası bitince takipçi artık göremez. Erişim kayıtları yasal saklama yükümlülüğü nedeniyle silmeden sonra da tutulur.

## Haklarınız

KVKK madde 11 kapsamında verilerinizin işlenip işlenmediğini öğrenebilir, düzeltilmesini ya da silinmesini isteyebilir, rızanızı geri alabilirsiniz. Uygulamadan: paylaşımları Profil > Hekim ve araştırma kurumu ile Profil > Sağlık topluluğu bölümlerinden kaldırabilir, portaldaki verilerinizi Profil > Portal hesabı'ndan silebilir, tüm verinizi Profil > Verilerimi dışa aktar ile FHIR dosyası olarak alabilirsiniz.

## İletişim

Veri sorumlusunun unvanı, adresi ve başvuru yolu yayından önce burada yer alacak. Uygulama içinden Profil > Geri bildirim ile de bize yazabilirsiniz.

## Teknik karşılıkları

| Metindeki söz | Kodda |
| --- | --- |
| Telefonda şifreli veritabanı, anahtar güvenli bölgede | `SqliteHealthStore.openEncrypted`, `DeviceSecretStore` |
| Telefon yedeğine girmez | `AndroidManifest.xml` `allowBackup=false`, `data_extraction_rules.xml`; iOS'ta anahtar `first_unlock_this_device` |
| Portalda rastgele takma kimlik | `AppSettings.patientId` (UUID v4) |
| Yalnızca seçilen türler gider | `PortalUploader`, `filterBundle` |
| Elle girilenler paylaşılmaz | portal `ShareScope.codes` (kilo, VKİ yok) |
| Portalda şifreli | `EncryptedPortalStore` (AES-256-GCM) |
| Her erişim kaydedilir | portal `AuditEntry`, `GET /fhir/AuditEvent` |
| Portaldaki verileri silme | Profil > Portal hesabı, `DELETE /patients/<id>/data` |
| Dışa aktarma | Profil > Verilerimi dışa aktar (`FhirExporter`) |
| Geri bildirim kimliğe bağlanmaz | `POST /feedback` anahtarsız |
