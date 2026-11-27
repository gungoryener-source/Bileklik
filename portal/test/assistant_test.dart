import 'dart:convert';

import 'package:bileklik_portal/portal.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

Request _req(Object body) => Request(
  'POST',
  Uri.parse('http://portal.test/assistant'),
  body: jsonEncode(body),
);

void main() {
  test('anahtar yoksa 503', () async {
    final r = await AssistantEndpoint().handle(
      _req({
        'messages': [
          {'role': 'user', 'content': 'merhaba'},
        ],
      }),
      'p1',
    );
    expect(r.statusCode, 503);
  });

  test('istek kurallarla ve verilerle gider, yanıt metni döner', () async {
    Map<String, Object?>? sent;
    final e = AssistantEndpoint(
      sender: (body) async {
        sent = body;
        return {
          'stop_reason': 'end_turn',
          'content': [
            {'type': 'text', 'text': ' Dün gece 7 saat uyudunuz. '},
          ],
        };
      },
    );
    final r = await e.handle(
      _req({
        'lang': 'de',
        'messages': [
          {'role': 'assistant', 'content': 'Hallo'},
          {'role': 'user', 'content': 'Wie habe ich geschlafen?'},
        ],
        'facts': {'sleep_minutes': 420},
      }),
      'p1',
    );
    expect(r.statusCode, 200);
    expect(
      jsonDecode(await r.readAsString())['reply'],
      'Dün gece 7 saat uyudunuz.',
    );
    expect(sent!['model'], AssistantEndpoint.model);
    final messages = sent!['messages']! as List;
    // Sohbet kullanıcı mesajıyla başlar.
    expect(messages, hasLength(1));
    final system = sent!['system']! as String;
    expect(system, contains('Deutsch'));
    expect(system, contains('"sleep_minutes":420'));
    expect(system, contains('112'));
  });

  test('saatlik sınır', () async {
    final e = AssistantEndpoint(
      hourlyLimit: 2,
      sender: (_) async => {
        'content': [
          {'type': 'text', 'text': 'ok'},
        ],
      },
    );
    final body = {
      'messages': [
        {'role': 'user', 'content': 'merhaba'},
      ],
    };
    expect((await e.handle(_req(body), 'p1')).statusCode, 200);
    expect((await e.handle(_req(body), 'p1')).statusCode, 200);
    expect((await e.handle(_req(body), 'p1')).statusCode, 429);
    expect((await e.handle(_req(body), 'p2')).statusCode, 200);
  });

  test('model reddederse boş yanıt ve işaret', () async {
    final e = AssistantEndpoint(
      sender: (_) async => {'stop_reason': 'refusal', 'content': []},
    );
    final r = await e.handle(
      _req({
        'messages': [
          {'role': 'user', 'content': 'x'},
        ],
      }),
      'p1',
    );
    expect(jsonDecode(await r.readAsString())['refused'], isTrue);
  });
}
