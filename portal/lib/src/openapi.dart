import 'dart:convert';

import 'package:shelf/shelf.dart';

import 'locale.dart';
import 'model.dart';

/// Geliştirici belgesi: `GET /openapi.json` (OpenAPI 3.1) ve `GET /developers`
/// (aynı belgeden üretilen okunur sayfa).
///
/// Kurumlar (klinik, araştırma, iş ortağı) hekim ya da araştırmacı hesabının
/// oturum anahtarıyla `Authorization: Bearer` gönderir; veriyi yalnızca
/// hastanın süren rızasındaki türlerle görür. Belge geliştiriciler için
/// İngilizce; yollar `test/openapi_test.dart` ile yönlendiriciyle karşılaştırılır.
class OpenApi {
  OpenApi._();

  /// Belgedeki uç: yöntem, yol, kim çağırır, özet, parametreler, gövde.
  static const endpoints = <_Op>[
    _Op(
      'post',
      '/patients',
      'Patients',
      'Open a pseudonymous patient account',
      'Called once by the app with its random UUID v4. Returns the session '
          'token and a recovery code, both shown only once.',
      roles: 'anyone',
      body: {'patientId': 'string (UUID v4)'},
      responses: {'201': 'token, recoveryCode', '409': 'already exists'},
    ),
    _Op(
      'post',
      '/patients/recovery',
      'Patients',
      'Issue a new recovery code',
      'The previous code stops working.',
      roles: 'patient',
      responses: {'201': 'recoveryCode'},
    ),
    _Op(
      'post',
      '/recover',
      'Patients',
      'Move the account to a new phone',
      'Exchanges a recovery code for a new token and code; old tokens are '
          'revoked. At most 10 failed attempts per minute.',
      roles: 'anyone',
      body: {'recoveryCode': 'string'},
      responses: {'200': 'patientId, token, recoveryCode', '429': 'throttled'},
    ),
    _Op(
      'get',
      '/connections',
      'Consent',
      'List active consents (app view)',
      'Each consent with the follower’s name, organisation, purpose, '
          'requested and granted data types and validity.',
      roles: 'patient',
      responses: {'200': 'JSON array'},
    ),
    _Op(
      'post',
      '/fhir',
      'FHIR',
      'Upload a FHIR R4 Bundle',
      'Bundle of type collection with one Patient and Observations. An '
          'Observation whose identifier was seen before is skipped. Uploading '
          'runs the alert rules for the patient’s clinicians.',
      roles: 'patient',
      body: {'resourceType': 'Bundle', 'type': 'collection', 'entry': '[…]'},
      responses: {'200': 'OperationOutcome with counts'},
    ),
    _Op(
      'get',
      '/fhir/Observation',
      'FHIR',
      'Search observations',
      'A follower sees only the codes covered by an active consent (or a '
          'shared care group). Every read is written to the access log.',
      roles: 'patient, clinician, researcher, group member',
      query: {
        'patient': 'pseudonymous patient id (required)',
        'code': 'LOINC or local code, comma separated (optional)',
        'date': 'ge<ISO 8601> and/or le<ISO 8601> (optional, repeatable)',
      },
      responses: {'200': 'Bundle (searchset)', '403': 'no consent (logged)'},
    ),
    _Op(
      'get',
      '/fhir/Consent',
      'FHIR',
      'List consents',
      'Patients see the consents they gave, followers those given to them.',
      roles: 'patient, clinician, researcher',
      responses: {'200': 'Bundle (searchset) of Consent'},
    ),
    _Op(
      'get',
      '/fhir/AuditEvent',
      'FHIR',
      'Access log',
      'Who read the patient’s data and when, including refused attempts.',
      roles: 'patient',
      responses: {'200': 'Bundle (searchset) of AuditEvent'},
    ),
    _Op(
      'post',
      '/invites',
      'Consent',
      'Create an invite code',
      'A 7-character code. A clinician code is valid for 24 hours and '
          'single-use; a research code is valid for 30 days for every '
          'participant. The patient enters it in the app, sees the purpose '
          'and requested types, and consents. Wrong codes are limited to 10 '
          'per account per minute (429).',
      roles: 'clinician, researcher',
      body: {
        'purpose': 'string',
        'scopes': 'array of data types',
        'days': 'integer 1-730 (consent length)',
      },
      responses: {'201': 'invite', '403': 'not a clinician'},
    ),
    _Op(
      'get',
      '/invites/{code}',
      'Consent',
      'Show an invite',
      'What the consent screen shows: follower, verification, purpose.',
      roles: 'patient',
      responses: {'200': 'invite', '404': 'unknown or expired'},
    ),
    _Op(
      'post',
      '/invites/{code}/accept',
      'Consent',
      'Accept an invite',
      'Creates a Consent for the chosen types. An earlier consent to the '
          'same follower ends.',
      roles: 'patient',
      body: {'scopes': 'array of data types (subset of requested)'},
      responses: {'201': 'Consent'},
    ),
    _Op(
      'delete',
      '/consents/{id}',
      'Consent',
      'Revoke a consent',
      'Access ends immediately.',
      roles: 'patient',
      responses: {'200': 'revoked'},
    ),
    _Op(
      'delete',
      '/patients/{id}/data',
      'Patients',
      'Erase my data',
      'Deletes observations and alerts and ends consents (right to erasure). '
          'The access log is kept.',
      roles: 'patient (own id)',
      responses: {'200': 'erased'},
    ),
    _Op(
      'get',
      '/groups',
      'Care groups',
      'List care groups',
      'Groups, members, what each member shares and join notices.',
      roles: 'patient',
      responses: {'200': 'JSON'},
    ),
    _Op(
      'post',
      '/groups',
      'Care groups',
      'Create a group',
      '',
      roles: 'patient',
      body: {
        'name': 'string 1-40',
        'displayName': 'optional, my name in the group, up to 40',
      },
      responses: {'201': 'group'},
    ),
    _Op(
      'post',
      '/groups/join',
      'Care groups',
      'Join a group',
      'With a personal invite code or the group code. At most 10 wrong '
          'codes per minute per account.',
      roles: 'patient',
      body: {
        'code': 'string',
        'displayName': 'optional; used when joining with the group code',
      },
      responses: {'200': 'group', '404': 'invalid code', '429': 'throttled'},
    ),
    _Op(
      'put',
      '/groups/{id}/me',
      'Care groups',
      'Change my name in a group',
      'Only members of that group see it.',
      roles: 'member',
      body: {'displayName': 'string up to 40'},
      responses: {'200': 'group'},
    ),
    _Op(
      'post',
      '/groups/{id}/members',
      'Care groups',
      'Invite a member',
      'Returns a 6-character personal code.',
      roles: 'group owner',
      body: {'name': 'string'},
      responses: {'201': 'code'},
    ),
    _Op(
      'delete',
      '/groups/{id}/members/{mid}',
      'Care groups',
      'Remove a member',
      '',
      roles: 'group owner',
      responses: {'200': 'removed'},
    ),
    _Op(
      'put',
      '/groups/{id}/consent',
      'Care groups',
      'Change what I share with a group',
      '',
      roles: 'member',
      body: {'scopes': 'array of data types'},
      responses: {'200': 'updated'},
    ),
    _Op(
      'delete',
      '/groups/{id}',
      'Care groups',
      'Leave or delete a group',
      'The owner deletes the group; others leave.',
      roles: 'member',
      responses: {'200': 'done'},
    ),
    _Op(
      'post',
      '/feedback',
      'Other',
      'Send in-app feedback',
      'Not linked to any account. 30 per minute.',
      roles: 'anyone',
      body: {'category': 'bug | idea | other', 'message': 'string 1-2000'},
      responses: {'201': 'received', '429': 'throttled'},
    ),
    _Op(
      'post',
      '/assistant',
      'Other',
      'Ask the in-app health assistant',
      'Proxy to the Claude API; the key stays on the server. Only summary numbers are sent, no name or raw measurements. 30 per hour per account; 503 when no key is configured.',
      roles: 'patient',
      body: {
        'lang': 'tr | en | de | ar',
        'messages': '[{role: user | assistant, content: string}]',
        'facts': 'object',
      },
      responses: {
        '200': '{reply}',
        '429': 'throttled',
        '503': 'not configured',
      },
    ),
    _Op(
      'post',
      '/inquiry',
      'Other',
      'Partnership inquiry from the website',
      'Form body (application/x-www-form-urlencoded), CORS open. 10 per minute.',
      roles: 'anyone',
      body: {
        'kind': 'distributor | oem | corporate | clinic | other | waitlist',
        'name': 'string',
        'company': 'string',
        'email': 'string',
        'message': 'string',
        'consent': 'on',
      },
      responses: {'201': 'received', '400': 'invalid fields'},
    ),
    _Op(
      'get',
      '/health',
      'Other',
      'Liveness check',
      '',
      roles: 'anyone',
      responses: {'200': 'ok'},
    ),
  ];

  /// OpenAPI 3.1 belgesi.
  static Map<String, Object?> spec() {
    final paths = <String, Map<String, Object?>>{};
    for (final op in endpoints) {
      final params = [
        for (final m in RegExp(r'\{(\w+)\}').allMatches(op.path))
          {
            'name': m[1],
            'in': 'path',
            'required': true,
            'schema': {'type': 'string'},
          },
        for (final e in op.query.entries)
          {
            'name': e.key,
            'in': 'query',
            'required': e.value.contains('(required)'),
            'description': e.value,
            'schema': {'type': 'string'},
          },
      ];
      paths.putIfAbsent(op.path, () => {})[op.method] = {
        'tags': [op.tag],
        'summary': op.summary,
        if (op.description.isNotEmpty) 'description': op.description,
        'x-roles': op.roles,
        if (op.roles == 'anyone') 'security': const <Object>[],
        if (params.isNotEmpty) 'parameters': params,
        if (op.body.isNotEmpty)
          'requestBody': {
            'required': true,
            'content': {
              op.path == '/inquiry'
                  ? 'application/x-www-form-urlencoded'
                  : op.path == '/fhir'
                  ? 'application/fhir+json'
                  : 'application/json': {
                'schema': {
                  'type': 'object',
                  'properties': {
                    for (final e in op.body.entries)
                      e.key: {'description': e.value},
                  },
                },
              },
            },
          },
        'responses': {
          for (final e in op.responses.entries) e.key: {'description': e.value},
          if (op.roles != 'anyone')
            '401': {'description': 'missing or invalid token'},
        },
      };
    }
    return {
      'openapi': '3.1.0',
      'info': {
        'title': 'Bileklik portal API',
        'version': '0.1.0',
        'description':
            'FHIR R4 portal for the JCV8 ECG wristband app. Patients are '
            'pseudonymous; followers (clinicians, researchers, care groups) '
            'see only data types the patient consented to, and every access '
            'is logged (KVKK / GDPR). Data types and their codes: '
            '${ShareScope.values.map((s) => '${s.name} (${s.codes.join(', ')})').join('; ')}.',
      },
      'components': {
        'securitySchemes': {
          'bearer': {
            'type': 'http',
            'scheme': 'bearer',
            'description':
                'Patients get a token from POST /patients. Clinician and '
                'researcher tokens are issued by the portal administrator.',
          },
        },
      },
      'security': [
        {'bearer': <String>[]},
      ],
      'paths': paths,
    };
  }

  static Response json(Request _) => Response.ok(
    const JsonEncoder.withIndent('  ').convert(spec()),
    headers: {
      'content-type': 'application/json; charset=utf-8',
      'access-control-allow-origin': '*',
      'x-content-type-options': 'nosniff',
    },
  );

  /// Geliştirici sayfasının çerçeve metinleri (güvenilir HTML; kullanıcı
  /// girdisi yok).
  static const _pageText = {
    'en': {
      'title': 'Bileklik portal API',
      'intro':
          'FHIR R4 portal for the JCV8 ECG wristband. Patients are pseudonymous. Clinicians, research institutions and care groups see only the data types a patient consented to, for as long as the consent lasts, and every access is logged.',
      'machine': 'Machine-readable',
      'english':
          'Endpoint descriptions are in English, the same as in openapi.json.',
      'auth': 'Authentication',
      'authText':
          'Send <code>Authorization: Bearer &lt;token&gt;</code>. Patient tokens come from <code>POST /patients</code>. Clinician and researcher tokens are issued by the portal administrator; use them from your own system to pull consented data.',
      'types': 'Data types',
      'who': 'Who',
      'body': 'Body',
      'panel':
          'The browser panel for clinicians is at <a href="/panel">/panel</a>; it also exports reports as CSV, FHIR and HL7 v2.5.1 ORU^R01.',
    },
    'tr': {
      'title': 'Bileklik portal API',
      'intro':
          'JCV8 EKG bileklik için FHIR R4 portalı. Hastalar takma kimliklidir. Hekimler, araştırma kurumları ve aile grupları yalnızca hastanın rıza verdiği veri türlerini, rıza sürdüğü sürece görür; her erişim kaydedilir.',
      'machine': 'Makinenin okuyacağı biçim',
      'english':
          'Uç açıklamaları openapi.json ile aynı olsun diye İngilizcedir.',
      'auth': 'Kimlik doğrulama',
      'authText':
          '<code>Authorization: Bearer &lt;anahtar&gt;</code> gönderin. Hasta anahtarı <code>POST /patients</code> ile alınır. Hekim ve araştırmacı anahtarlarını portal yöneticisi verir; rızalı veriyi kendi sisteminizden çekmek için kullanın.',
      'types': 'Veri türleri',
      'who': 'Kim',
      'body': 'Gövde',
      'panel':
          'Hekimler için tarayıcı paneli <a href="/panel">/panel</a> adresinde; raporları CSV, FHIR ve HL7 v2.5.1 ORU^R01 olarak da verir.',
    },
    'ar': {
      'title': 'واجهة برمجة بوابة Bileklik',
      'intro':
          'بوابة FHIR R4 لسوار JCV8 لتخطيط القلب. المرضى بأسماء مستعارة. لا يرى الأطباء ومؤسسات البحث ومجموعات الرعاية إلا أنواع البيانات التي وافق عليها المريض، وطوال مدة الموافقة فقط، ويُسجَّل كل وصول.',
      'machine': 'بصيغة قابلة للقراءة آليًا',
      'english': 'أوصاف نقاط النهاية بالإنجليزية، كما في openapi.json.',
      'auth': 'المصادقة',
      'authText':
          'أرسل <code>Authorization: Bearer &lt;token&gt;</code>. يحصل المريض على مفتاحه من <code>POST /patients</code>. ويصدر مدير البوابة مفاتيح الأطباء والباحثين؛ استخدمها من نظامك لجلب البيانات الموافق عليها.',
      'types': 'أنواع البيانات',
      'who': 'من',
      'body': 'المحتوى',
      'panel':
          'لوحة الأطباء في المتصفح على <a href="/panel">/panel</a>؛ وتصدّر التقارير أيضًا بصيغ CSV وFHIR وHL7 v2.5.1 ORU^R01.',
    },
    'de': {
      'title': 'Bileklik-Portal-API',
      'intro':
          'FHIR-R4-Portal für das JCV8-EKG-Armband. Patienten sind pseudonymisiert. Ärzte, Forschungseinrichtungen und Betreuungsgruppen sehen nur die Datentypen, in die ein Patient eingewilligt hat, und nur so lange die Einwilligung gilt; jeder Zugriff wird protokolliert.',
      'machine': 'Maschinenlesbar',
      'english':
          'Die Beschreibungen der Endpunkte sind wie in openapi.json auf Englisch.',
      'auth': 'Authentifizierung',
      'authText':
          'Senden Sie <code>Authorization: Bearer &lt;Token&gt;</code>. Patienten-Tokens kommen von <code>POST /patients</code>. Tokens für Ärzte und Forschende vergibt der Portaladministrator; damit rufen Sie freigegebene Daten aus Ihrem eigenen System ab.',
      'types': 'Datentypen',
      'who': 'Wer',
      'body': 'Body',
      'panel':
          'Das Browser-Panel für Ärzte liegt unter <a href="/panel">/panel</a>; es exportiert Berichte auch als CSV, FHIR und HL7 v2.5.1 ORU^R01.',
    },
  };

  static String _h(String s) =>
      const HtmlEscape(HtmlEscapeMode.element).convert(s);

  /// Okunur belge sayfası. Sayfanın çerçevesi dört dilde ([PortalLocale]);
  /// uç açıklamaları `openapi.json` ile aynı kalsın diye İngilizcedir.
  static Response page(Request r) {
    final lang = PortalLocale.of(r);
    final t = _pageText[lang] ?? _pageText['en']!;
    final tags = <String, List<_Op>>{};
    for (final op in endpoints) {
      tags.putIfAbsent(op.tag, () => []).add(op);
    }
    final body = StringBuffer();
    for (final MapEntry(key: tag, value: ops) in tags.entries) {
      body.writeln('<h2>${_h(tag)}</h2>');
      for (final op in ops) {
        body.writeln('''
<section class="op" lang="en" dir="ltr">
<h3><span class="m ${op.method}">${op.method.toUpperCase()}</span> <code>${_h(op.path)}</code></h3>
<p><strong>${_h(op.summary)}</strong>${op.description.isEmpty ? '' : ' ${_h(op.description)}'}</p>
<p class="muted">${t['who']}: ${_h(op.roles)}</p>
${op.query.isEmpty ? '' : '<dl>${op.query.entries.map((e) => '<dt><code>${_h(e.key)}</code></dt><dd>${_h(e.value)}</dd>').join()}</dl>'}
${op.body.isEmpty ? '' : '<p class="muted">${t['body']}</p><dl>${op.body.entries.map((e) => '<dt><code>${_h(e.key)}</code></dt><dd>${_h(e.value)}</dd>').join()}</dl>'}
<p class="muted">${op.responses.entries.map((e) => '${_h(e.key)}: ${_h(e.value)}').join(' · ')}</p>
</section>''');
      }
    }
    final scopes = ShareScope.values
        .map(
          (s) =>
              '<tr><td><code>${s.name}</code></td><td><code>${_h(s.codes.join(', '))}</code></td></tr>',
        )
        .join();
    return Response.ok(
      '''<!doctype html>
<html lang="$lang" dir="${lang == 'ar' ? 'rtl' : 'ltr'}">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>${t['title']}</title>
<style>
:root { color-scheme: dark; --fg: #FFFFFF; --muted: rgba(255,255,255,.75); --line: rgba(255,255,255,.16); --card: rgba(22,26,34,.62); }
body { margin: 0; font: 16px/1.6 Manrope, "Segoe UI", system-ui, sans-serif; background: radial-gradient(55vmax 55vmax at 14% 10%, rgba(76,141,255,.28), transparent 70%), radial-gradient(55vmax 55vmax at 10% 88%, rgba(69,214,184,.16), transparent 70%), linear-gradient(180deg, #1F2E4D 0%, #34507A 45%, #0C1016 100%) fixed, #0C1016; color: var(--fg); -webkit-font-smoothing: antialiased; }
a { color: #45D6B8; }
main { max-width: 860px; margin: 0 auto; padding: 24px 16px 64px; }
h1 { margin: 16px 0 8px; } h2 { margin: 36px 0 8px; }
h3 { font-size: 1rem; margin: 0 0 6px; overflow-wrap: anywhere; }
.op { background: linear-gradient(135deg, rgba(255,255,255,.1), rgba(255,255,255,.02)), var(--card); border: 1px solid var(--line); border-radius: 22px; padding: 14px 16px; margin: 10px 0; }
.op p { margin: 4px 0; }
.m { display: inline-block; min-width: 4.2em; text-align: center; border-radius: 6px; padding: 1px 6px; font: 700 12px/1.6 ui-monospace, monospace; border: 1px solid currentColor; }
.get { color: #5BE37D; } .post { color: #4FC3FF; } .put { color: #FFAA5C; } .delete { color: #FFB8C8; }
.muted { color: var(--muted); font-size: .92rem; }
dl { display: grid; grid-template-columns: max-content 1fr; gap: 2px 12px; margin: 6px 0; font-size: .92rem; }
dd { margin: 0; } code { font-family: ui-monospace, monospace; overflow-wrap: anywhere; }
table { border-collapse: collapse; width: 100%; font-size: .92rem; } td { border-top: 1px solid var(--line); padding: 6px 8px 6px 0; vertical-align: top; }
pre { background: rgba(12,16,22,.6); border: 1px solid var(--line); border-radius: 16px; padding: 12px; overflow-x: auto; font-size: .85rem; direction: ltr; text-align: left; }
.op h3, dl code, td code { direction: ltr; unicode-bidi: isolate; }
${PortalLocale.switcherCss}
</style>
</head>
<body><main>
${PortalLocale.switcher(lang)}
<h1>${t['title']}</h1>
<p>${t['intro']}</p>
<p>${t['machine']}: <a href="/openapi.json">/openapi.json</a> (OpenAPI 3.1).</p>
<p class="muted">${t['english']}</p>
<h2>${t['auth']}</h2>
<p>${t['authText']}</p>
<pre>curl -H "Authorization: Bearer \$TOKEN" \\
  "https://…/fhir/Observation?patient=\$PATIENT&amp;code=8867-4&amp;date=ge2026-10-01T00:00:00Z"</pre>
<h2>${t['types']}</h2>
<table><tbody>$scopes</tbody></table>
$body
<p class="muted">${t['panel']}</p>
</main></body>
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
}

class _Op {
  const _Op(
    this.method,
    this.path,
    this.tag,
    this.summary,
    this.description, {
    required this.roles,
    this.query = const {},
    this.body = const {},
    this.responses = const {},
  });

  final String method;
  final String path;
  final String tag;
  final String summary;
  final String description;
  final String roles;
  final Map<String, String> query;
  final Map<String, String> body;
  final Map<String, String> responses;
}
