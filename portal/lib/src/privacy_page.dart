import 'dart:convert';

import 'package:shelf/shelf.dart';

import 'panel_text.dart';

/// Gizlilik politikası sayfası (`/gizlilik`, `/privacy`): herkese açık.
///
/// Google Play ve Health Connect incelemesi herkese açık bir gizlilik
/// politikası adresi ister. Metin uygulamadaki gizlilik ekranıyla
/// (`lib/l10n`, `privacy…` anahtarları) ve `docs/gizlilik-politikasi.md`
/// ile aynıdır; birini değiştirirken ötekileri de güncelleyin.
///
/// Dil: `?lang=`, yoksa `Accept-Language`, o da yoksa Türkçe.
class PrivacyPage {
  const PrivacyPage._(this.title, this.draft, this.intro, this.sections);

  final String title;
  final String draft;
  final String intro;
  final List<(String, String)> sections;

  static PrivacyPage of(String lang) => switch (lang) {
    'en' => _en,
    'ar' => _ar,
    'de' => _de,
    _ => _tr,
  };

  static String _h(String s) => const HtmlEscape(
    HtmlEscapeMode(escapeLtGt: true, escapeQuot: true, escapeApos: true),
  ).convert(s);

  /// `GET /gizlilik` ve `GET /privacy`.
  static Response handle(Request r) {
    final q = r.url.queryParameters['lang'];
    final lang = q != null && PanelText.supported.contains(q)
        ? q
        : PanelText.fromAcceptLanguage(r.headers['accept-language']);
    final p = of(lang);
    final links = [
      for (final l in PanelText.supported)
        l == lang
            ? '<strong>${_h(PanelText.of(l).language)}</strong>'
            : '<a href="?lang=$l" hreflang="$l" lang="$l">'
                  '${_h(PanelText.of(l).language)}</a>',
    ].join(' · ');
    final body = StringBuffer()
      ..write('<nav>$links</nav>')
      ..write('<h1>${_h(p.title)}</h1>')
      ..write('<p class="note">${_h(p.draft)}</p>')
      ..write('<p>${_h(p.intro)}</p>');
    for (final (t, b) in p.sections) {
      body.write('<h2>${_h(t)}</h2><p>${_h(b)}</p>');
    }
    return Response.ok(
      '''<!doctype html>
<html lang="$lang" dir="${lang == 'ar' ? 'rtl' : 'ltr'}">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>${_h(p.title)} · Bileklik</title>
<style>
:root { color-scheme: light dark; --bg: #f6f7fb; --fg: #16181d; --muted: #5d6472; --line: #dfe3ea; --accent: #2457d6; }
@media (prefers-color-scheme: dark) { :root { --bg: #111318; --fg: #e9ebf0; --muted: #9aa3b2; --line: #2c313b; --accent: #7aa2ff; } }
body { margin: 0; font: 17px/1.6 system-ui, sans-serif; background: var(--bg); color: var(--fg); }
main { max-width: 720px; margin: 0 auto; padding: 24px 16px 48px; }
h1 { font-size: 1.8rem; margin: 16px 0; }
h2 { font-size: 1.2rem; margin: 28px 0 8px; }
a { color: var(--accent); }
nav { color: var(--muted); font-size: .9rem; }
.note { border-inline-start: 4px solid var(--line); padding-inline-start: 12px; color: var(--muted); }
</style>
</head>
<body><main>$body</main></body>
</html>
''',
      headers: {
        'content-type': 'text/html; charset=utf-8',
        'content-security-policy':
            "default-src 'none'; style-src 'unsafe-inline'; base-uri 'none'; "
            "form-action 'none'; frame-ancestors 'none'",
        'x-content-type-options': 'nosniff',
        'referrer-policy': 'no-referrer',
      },
    );
  }

  static const _tr = PrivacyPage._(
    'Gizlilik politikası',
    'Taslak: Bu metin hukuk incelemesinden geçmedi. Veri sorumlusunun unvanı, adresi ve saklama süreleri yayından önce eklenecek.',
    'Bu metin, Bileklik uygulamasının ve portalının kişisel verilerinizi nasıl işlediğini 6698 sayılı Kişisel Verilerin Korunması Kanunu (KVKK) kapsamında anlatır.',
    [
      (
        'Hangi verileri işliyoruz?',
        'Bilekliğin ölçtükleri: nabız, kalp atış hızı değişkenliği (HRV), kandaki oksijen (SpO2), EKG, uyku, adım, egzersiz, vücut ısısı, stres ve tahmini tansiyon. Sizin girdikleriniz: yaş, boy, kilo, cinsiyet, vücut kompozisyonu ve hatırlatıcılar. Bilekliğin Bluetooth adresi. Adınız, TC kimlik numaranız, telefonunuz ya da e-postanız istenmez; portalda yalnızca rastgele bir takma kimlikle tanınırsınız.',
      ),
      (
        'Veriler nerede durur?',
        'Ölçümler telefonunuzda şifreli bir veritabanında durur; anahtarı telefonun güvenli bölgesindedir (iOS Keychain, Android Keystore). Bu veriler telefon yedeğine girmez. Portala yalnızca paylaşmayı seçtiğiniz türler gider ve orada da şifreli saklanır.',
      ),
      (
        'Neden işliyoruz?',
        'Ölçümlerinizi size göstermek; sizin seçtiğiniz hekim, araştırma kurumu ve aile üyeleriyle paylaşmak; isterseniz Apple Sağlık ya da Health Connect\'e yazmak. Verileriniz reklam için kullanılmaz ve satılmaz.',
      ),
      (
        'Hukuki sebep',
        'Sağlık verileri özel nitelikli kişisel veridir ve açık rızanızla işlenir (KVKK madde 6). Her paylaşım için ayrı rıza alınır: kiminle, hangi türlerin, ne kadar süreyle paylaşılacağını siz seçersiniz ve rızanızı istediğiniz an geri alırsınız.',
      ),
      (
        'Kimlerle paylaşılır?',
        'Yalnızca rıza verdiğiniz hekim, araştırma kurumu ya da aile grubu üyeleri, yalnızca seçtiğiniz türleri ve rıza süresince görür. Kilo ve vücut kompozisyonu gibi elle girdiğiniz değerler yalnızca “Vücut ölçüleri”ni ayrıca seçerseniz paylaşılır. Apple Sağlık ya da Health Connect\'e yalnızca seçtiğiniz türler yazılır; uygulama oradan veri okumaz. Geri bildirimler kimliğinize bağlanmaz.',
      ),
      (
        'Erişim kayıtları',
        'Portalda verinize yapılan her erişim, reddedilen denemeler dahil, kaydedilir. Kimin ne zaman baktığını uygulamadan görebilirsiniz.',
      ),
      (
        'Ne kadar süre saklanır?',
        'Telefondaki veriler uygulamayı silene kadar kalır. Portaldaki ölçümler siz silene kadar kalır; paylaşım rızası bitince takipçi artık göremez. Erişim kayıtları yasal saklama yükümlülüğü nedeniyle silmeden sonra da tutulur.',
      ),
      (
        'Haklarınız',
        'KVKK madde 11 kapsamında verilerinizin işlenip işlenmediğini öğrenebilir, düzeltilmesini ya da silinmesini isteyebilir, rızanızı geri alabilirsiniz. Uygulamadan: paylaşımları Profil > Hekim ve araştırma kurumu ile Profil > Sağlık topluluğu bölümlerinden kaldırabilir, portaldaki verilerinizi Profil > Portal hesabı\'ndan silebilir, tüm verinizi Profil > Verilerimi dışa aktar ile FHIR dosyası olarak alabilirsiniz.',
      ),
      (
        'İletişim',
        'Veri sorumlusunun unvanı, adresi ve başvuru yolu yayından önce burada yer alacak. Uygulama içinden Profil > Geri bildirim ile de bize yazabilirsiniz.',
      ),
    ],
  );

  static const _en = PrivacyPage._(
    'Privacy policy',
    'Draft: this text has not been reviewed by a lawyer. The data controller\'s name, address and retention periods will be added before release.',
    'This text explains how the Bileklik app and portal process your personal data under the Turkish Personal Data Protection Law No. 6698 (KVKK).',
    [
      (
        'What data do we process?',
        'What the wristband measures: heart rate, heart rate variability (HRV), blood oxygen (SpO2), ECG, sleep, steps, workouts, body temperature, stress and estimated blood pressure. What you enter: age, height, weight, sex, body composition and reminders. The wristband\'s Bluetooth address. We don\'t ask for your name, national ID number, phone or email; on the portal you are known only by a random pseudonym.',
      ),
      (
        'Where is the data kept?',
        'Measurements are kept on your phone in an encrypted database whose key lives in the phone\'s secure area (iOS Keychain, Android Keystore). This data is not included in phone backups. Only the types you choose to share go to the portal, where they are also stored encrypted.',
      ),
      (
        'Why do we process it?',
        'To show you your measurements; to share them with the doctors, research institutions and family members you choose; and, if you want, to write them to Apple Health or Health Connect. Your data is not used for advertising and is not sold.',
      ),
      (
        'Legal basis',
        'Health data is a special category of personal data and is processed with your explicit consent (KVKK Article 6). Each sharing needs its own consent: you choose who sees which types and for how long, and you can withdraw consent at any time.',
      ),
      (
        'Who is it shared with?',
        'Only the doctors, research institutions or family group members you consent to, only the types you choose and only for the consent period. Values you enter yourself, such as weight and body composition, are shared only if you separately choose “Body measurements”. Only the types you choose are written to Apple Health or Health Connect; the app does not read data from them. Feedback is not linked to your identity.',
      ),
      (
        'Access log',
        'Every access to your data on the portal, including refused attempts, is logged. You can see in the app who looked and when.',
      ),
      (
        'How long is it kept?',
        'Data on your phone stays until you delete the app. Measurements on the portal stay until you delete them; when a consent ends, that follower can no longer see them. Access logs are kept after deletion because of legal retention duties.',
      ),
      (
        'Your rights',
        'Under KVKK Article 11 you can ask whether your data is processed, ask for it to be corrected or deleted, and withdraw consent. In the app you can remove sharing under Profile > Doctors and research and Profile > Health community, delete your portal data under Profile > Portal account, and get all your data as a FHIR file under Profile > Export my data.',
      ),
      (
        'Contact',
        'The data controller\'s name, address and how to make a request will appear here before release. You can also write to us in the app under Profile > Feedback.',
      ),
    ],
  );

  static const _ar = PrivacyPage._(
    'سياسة الخصوصية',
    'مسودة: لم تتم مراجعة هذا النص قانونيًا. سيُضاف اسم المسؤول عن البيانات وعنوانه ومدد الاحتفاظ قبل النشر.',
    'يوضح هذا النص كيف يعالج تطبيق Bileklik وبوابته بياناتك الشخصية وفق قانون حماية البيانات الشخصية التركي رقم 6698 (KVKK).',
    [
      (
        'ما البيانات التي نعالجها؟',
        'ما يقيسه السوار: نبض القلب وتقلبه (HRV) وأكسجين الدم (SpO2) وتخطيط القلب والنوم والخطوات والتمارين وحرارة الجسم والتوتر وضغط الدم التقديري. ما تدخله أنت: العمر والطول والوزن والجنس وتكوين الجسم والتذكيرات. عنوان البلوتوث للسوار. لا نطلب اسمك أو رقم هويتك أو هاتفك أو بريدك الإلكتروني؛ تُعرف في البوابة باسم مستعار عشوائي فقط.',
      ),
      (
        'أين تُحفظ البيانات؟',
        'تُحفظ القياسات على هاتفك في قاعدة بيانات مشفرة، ومفتاحها في المنطقة الآمنة للهاتف (iOS Keychain وAndroid Keystore). لا تدخل هذه البيانات في نسخ الهاتف الاحتياطية. لا يُرسل إلى البوابة إلا الأنواع التي تختار مشاركتها، وتُحفظ هناك مشفرة أيضًا.',
      ),
      (
        'لماذا نعالجها؟',
        'لعرض قياساتك عليك، ومشاركتها مع الأطباء ومؤسسات البحث وأفراد العائلة الذين تختارهم، وكتابتها في Apple Health أو Health Connect إن رغبت. لا تُستخدم بياناتك للإعلانات ولا تُباع.',
      ),
      (
        'الأساس القانوني',
        'البيانات الصحية فئة خاصة من البيانات الشخصية وتُعالج بموافقتك الصريحة (المادة 6 من KVKK). كل مشاركة تحتاج إلى موافقة مستقلة: تختار من يرى أي الأنواع ولأي مدة، ويمكنك سحب موافقتك في أي وقت.',
      ),
      (
        'مع من تُشارك؟',
        'فقط مع الأطباء أو مؤسسات البحث أو أفراد مجموعة العائلة الذين توافق عليهم، وللأنواع التي تختارها فقط وطوال مدة الموافقة. القيم التي تدخلها بنفسك مثل الوزن وتكوين الجسم لا تُشارك إلا إذا اخترت «قياسات الجسم» صراحةً. لا يُكتب في Apple Health أو Health Connect إلا ما تختاره، ولا يقرأ التطبيق منهما. الملاحظات لا ترتبط بهويتك.',
      ),
      (
        'سجل الوصول',
        'يُسجَّل كل وصول إلى بياناتك في البوابة، بما في ذلك المحاولات المرفوضة. يمكنك أن ترى في التطبيق من اطلع ومتى.',
      ),
      (
        'كم مدة الاحتفاظ؟',
        'تبقى البيانات على هاتفك حتى تحذف التطبيق. تبقى القياسات في البوابة حتى تحذفها؛ وعند انتهاء الموافقة لا يعود المتابع يراها. تُحفظ سجلات الوصول بعد الحذف بسبب التزامات الاحتفاظ القانونية.',
      ),
      (
        'حقوقك',
        'بموجب المادة 11 من KVKK يمكنك أن تسأل إن كانت بياناتك تُعالج، وأن تطلب تصحيحها أو حذفها، وأن تسحب موافقتك. في التطبيق يمكنك إزالة المشاركة من الملف الشخصي > الأطباء ومؤسسات البحث والملف الشخصي > مجتمع الصحة، وحذف بياناتك في البوابة من الملف الشخصي > حساب البوابة، والحصول على جميع بياناتك كملف FHIR من الملف الشخصي > تصدير بياناتي.',
      ),
      (
        'التواصل',
        'سيظهر هنا قبل النشر اسم المسؤول عن البيانات وعنوانه وطريقة تقديم الطلب. يمكنك أيضًا مراسلتنا من التطبيق عبر الملف الشخصي > الملاحظات.',
      ),
    ],
  );

  static const _de = PrivacyPage._(
    'Datenschutzerklärung',
    'Entwurf: Dieser Text wurde noch nicht juristisch geprüft. Name und Anschrift des Verantwortlichen sowie Speicherfristen werden vor der Veröffentlichung ergänzt.',
    'Dieser Text erklärt, wie die Bileklik-App und das Portal Ihre personenbezogenen Daten nach dem türkischen Datenschutzgesetz Nr. 6698 (KVKK) verarbeiten.',
    [
      (
        'Welche Daten verarbeiten wir?',
        'Was das Armband misst: Herzfrequenz, Herzfrequenzvariabilität (HRV), Blutsauerstoff (SpO2), EKG, Schlaf, Schritte, Training, Körpertemperatur, Stress und geschätzter Blutdruck. Was Sie eingeben: Alter, Größe, Gewicht, Geschlecht, Körperzusammensetzung und Erinnerungen. Die Bluetooth-Adresse des Armbands. Name, Ausweisnummer, Telefon oder E-Mail werden nicht abgefragt; im Portal sind Sie nur unter einem zufälligen Pseudonym bekannt.',
      ),
      (
        'Wo werden die Daten gespeichert?',
        'Die Messwerte liegen auf Ihrem Telefon in einer verschlüsselten Datenbank; der Schlüssel liegt im geschützten Bereich des Telefons (iOS Keychain, Android Keystore). Diese Daten sind nicht Teil von Telefon-Backups. Ins Portal gehen nur die Datentypen, die Sie teilen möchten; auch dort werden sie verschlüsselt gespeichert.',
      ),
      (
        'Wozu verarbeiten wir sie?',
        'Um Ihnen Ihre Messwerte anzuzeigen, sie mit den von Ihnen gewählten Ärzten, Forschungseinrichtungen und Familienmitgliedern zu teilen und sie auf Wunsch in Apple Health oder Health Connect zu schreiben. Ihre Daten werden weder für Werbung genutzt noch verkauft.',
      ),
      (
        'Rechtsgrundlage',
        'Gesundheitsdaten sind besondere personenbezogene Daten und werden mit Ihrer ausdrücklichen Einwilligung verarbeitet (KVKK Art. 6). Jede Freigabe braucht eine eigene Einwilligung: Sie wählen, wer welche Datentypen wie lange sieht, und können die Einwilligung jederzeit widerrufen.',
      ),
      (
        'Mit wem wird geteilt?',
        'Nur mit den Ärzten, Forschungseinrichtungen oder Mitgliedern einer Familiengruppe, denen Sie zustimmen, nur die gewählten Datentypen und nur für die Dauer der Einwilligung. Selbst eingegebene Werte wie Gewicht und Körperzusammensetzung werden nur geteilt, wenn Sie „Körpermaße“ ausdrücklich auswählen. In Apple Health oder Health Connect werden nur die gewählten Datentypen geschrieben; die App liest dort nichts. Feedback wird nicht mit Ihrer Identität verknüpft.',
      ),
      (
        'Zugriffsprotokoll',
        'Jeder Zugriff auf Ihre Daten im Portal wird protokolliert, auch abgelehnte Versuche. In der App sehen Sie, wer wann zugegriffen hat.',
      ),
      (
        'Wie lange wird gespeichert?',
        'Daten auf dem Telefon bleiben, bis Sie die App löschen. Messwerte im Portal bleiben, bis Sie sie löschen; endet eine Einwilligung, sieht die betreffende Person sie nicht mehr. Zugriffsprotokolle werden wegen gesetzlicher Aufbewahrungspflichten auch nach dem Löschen aufbewahrt.',
      ),
      (
        'Ihre Rechte',
        'Nach KVKK Art. 11 können Sie Auskunft verlangen, ob Ihre Daten verarbeitet werden, deren Berichtigung oder Löschung verlangen und Ihre Einwilligung widerrufen. In der App können Sie Freigaben unter Profil > Ärzte und Forschung sowie Profil > Gesundheitsgemeinschaft entfernen, Ihre Portaldaten unter Profil > Portal-Konto löschen und alle Daten unter Profil > Meine Daten exportieren als FHIR-Datei erhalten.',
      ),
      (
        'Kontakt',
        'Name und Anschrift des Verantwortlichen und der Weg für Anfragen werden vor der Veröffentlichung hier ergänzt. Sie können uns auch in der App unter Profil > Feedback schreiben.',
      ),
    ],
  );
}
