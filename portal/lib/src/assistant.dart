import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';

/// Claude API'ye bir istek gönderip yanıt gövdesini döner. Testlerde sahtesi
/// verilir.
typedef ClaudeSender =
    Future<Map<String, Object?>> Function(Map<String, Object?> body);

/// `POST /assistant`: uygulamadaki sağlık asistanı için Claude API
/// aracısı (proxy).
///
/// API anahtarı yalnızca sunucuda (`ANTHROPIC_API_KEY`) durur; uygulamaya
/// gömülmez. Uygulama takma kimlikli oturumla son mesajları ve özet
/// verileri ([facts]: uyku süresi, toparlanma, nabız ortalaması gibi
/// sayılar; ad, kimlik ya da ham ölçüm yok) gönderir, düz metin yanıt
/// alır. Anahtar yoksa 503 döner; uygulama o zaman çevrimdışı kurallarla
/// yanıtlar.
///
/// Gövde: `{"lang": "tr", "messages": [{"role": "user", "content": "…"}],
/// "facts": {…}}`. Yanıt: `{"reply": "…"}`.
class AssistantEndpoint {
  AssistantEndpoint({
    ClaudeSender? sender,
    String? apiKey,
    DateTime Function()? clock,
    this.hourlyLimit = 30,
  }) : _send =
           sender ??
           (apiKey == null || apiKey.isEmpty ? null : anthropicSender(apiKey)),
       _now = clock ?? DateTime.now;

  final ClaudeSender? _send;
  final DateTime Function() _now;

  /// Bir hesabın saatte gönderebileceği soru sayısı.
  final int hourlyLimit;
  final _recent = <String, List<DateTime>>{};

  static const model = 'claude-opus-5-5';

  /// Gönderilen sohbetin en çok bu kadar son mesajı modele gider.
  static const maxMessages = 12;
  static const maxMessageLength = 2000;

  Future<Response> handle(Request request, String accountId) async {
    final send = _send;
    if (send == null) return _json(503, {'error': 'not_configured'});
    final now = _now();
    final times = (_recent[accountId] ??= [])
      ..removeWhere((t) => now.difference(t) > const Duration(hours: 1));
    if (times.length >= hourlyLimit) {
      return _json(429, {'error': 'rate_limited'});
    }

    final Map<String, Object?> body;
    try {
      body = jsonDecode(await request.readAsString()) as Map<String, Object?>;
    } catch (_) {
      return _json(400, {'error': 'invalid_json'});
    }
    final lang = switch (body['lang']) {
      'en' || 'de' || 'ar' || 'tr' => body['lang']! as String,
      _ => 'tr',
    };
    final raw = body['messages'];
    if (raw is! List || raw.isEmpty) {
      return _json(400, {'error': 'messages_required'});
    }
    final messages = <Map<String, Object?>>[];
    for (final m in raw.skip(
      raw.length > maxMessages ? raw.length - maxMessages : 0,
    )) {
      if (m is! Map) continue;
      final role = m['role'];
      final content = m['content'];
      if ((role != 'user' && role != 'assistant') || content is! String) {
        continue;
      }
      final text = content.length > maxMessageLength
          ? content.substring(0, maxMessageLength)
          : content;
      if (text.trim().isEmpty) continue;
      messages.add({'role': role, 'content': text});
    }
    // Sohbet kullanıcıyla başlar ve kullanıcıyla biter.
    while (messages.isNotEmpty && messages.first['role'] != 'user') {
      messages.removeAt(0);
    }
    if (messages.isEmpty || messages.last['role'] != 'user') {
      return _json(400, {'error': 'last_message_must_be_user'});
    }
    final facts = body['facts'] is Map ? body['facts'] : const {};
    times.add(now);

    try {
      final res = await send({
        'model': model,
        'max_tokens': 16000,
        // Sohbet için kısa ve hızlı yanıt.
        'output_config': {'effort': 'low'},
        // Güvenlik sınıflandırıcısı reddederse sunucu yedek modelle dener.
        'fallbacks': 'default',
        'system': systemPrompt(lang, jsonEncode(facts)),
        'messages': messages,
      });
      if (res['stop_reason'] == 'refusal') {
        return _json(200, {'reply': null, 'refused': true});
      }
      final content = res['content'];
      final text = content is List
          ? content
                .whereType<Map>()
                .where((b) => b['type'] == 'text')
                .map((b) => b['text'])
                .join()
          : '';
      if (text.trim().isEmpty) return _json(502, {'error': 'empty_reply'});
      return _json(200, {'reply': text.trim()});
    } catch (_) {
      return _json(502, {'error': 'upstream_failed'});
    }
  }

  static const _languages = {
    'tr': 'Türkçe',
    'en': 'English',
    'de': 'Deutsch',
    'ar': 'العربية',
  };

  /// Asistanın kuralları. Kişisel veri yok; yalnızca özet sayılar.
  static String systemPrompt(String lang, String factsJson) =>
      '''
You are Vita, the health assistant inside the Bileklik app, which reads data from an ECG wristband (heart rate, HRV, SpO2, ECG, sleep, steps, stress, workouts).

Answer in ${_languages[lang]}. Keep replies short and friendly: a few sentences, or a short list when it helps. Use plain text, no Markdown headings or tables.

Use the user's data below to answer questions about their sleep, recovery, daily load (strain, 0-21 scale), heart rate, ECG pre-assessment, biological age, stress, steps and workouts. Quote the numbers you use. If the data for a question is missing, say so and suggest wearing and syncing the wristband.

Safety rules:
- You are not a doctor. Do not diagnose, do not name diseases the user has, and do not recommend or dose medication. For those questions, say that a doctor should evaluate it and offer what the data shows.
- The app's ECG findings are an automatic pre-assessment, not a diagnosis; a flagged finding should be shown to a doctor.
- If the user describes possible emergency symptoms (chest pain, severe shortness of breath, fainting, signs of stroke, thoughts of self-harm), tell them first to call 112 or go to the nearest emergency department.
- Training advice must match the recovery score: low recovery means rest or light activity.

User data (JSON, pseudonymous, values for today unless noted):
$factsJson
''';

  /// Claude API'ye `dart:io` ile istek (Dart için resmi SDK yok).
  static ClaudeSender anthropicSender(String apiKey, {Uri? endpoint}) =>
      (body) async {
        final client = HttpClient()
          ..connectionTimeout = const Duration(seconds: 15);
        try {
          final req = await client.postUrl(
            endpoint ?? Uri.parse('https://api.anthropic.com/v1/messages'),
          );
          req.headers
            ..contentType = ContentType.json
            ..set('x-api-key', apiKey)
            ..set('anthropic-version', '2026-10-21')
            ..set('anthropic-beta', 'server-side-fallback-2026-07-01');
          req.add(utf8.encode(jsonEncode(body)));
          final res = await req.close().timeout(const Duration(seconds: 90));
          final text = await res.transform(utf8.decoder).join();
          if (res.statusCode != 200) {
            throw HttpException('Claude API ${res.statusCode}');
          }
          return jsonDecode(text) as Map<String, Object?>;
        } finally {
          client.close();
        }
      };

  static Response _json(int status, Object body) => Response(
    status,
    body: jsonEncode(body),
    headers: {'content-type': 'application/json; charset=utf-8'},
  );
}
