import 'package:bileklik_portal/portal.dart';
import 'package:test/test.dart';

void main() {
  final t = DateTime.utc(2026, 10, 18, 10, 5, 9);
  StoredObservation obs(String id, Map<String, Object?> r) => StoredObservation(
    patientId: 'p-1',
    identifier: id,
    code: ((r['code'] as Map)['coding'] as List).first['code'] as String,
    effective: t,
    resource: r,
  );

  test('kayıtlı hasta, bileşenler, not, atlanan EKG ve kaçış', () {
    final msg = Hl7Export.oru(
      messageId: 'm|1',
      now: t,
      patientId: 'p-1',
      from: DateTime.utc(2026, 10, 1),
      to: DateTime.utc(2026, 10, 20),
      facility: 'Kardiyoloji & Ritim',
      record: PatientRecord(
        id: 'r',
        ownerId: 'dr',
        name: 'Ayşe Nur Yılmaz',
        created: t,
        birthDate: DateTime.utc(1968, 3, 4),
        sex: Sex.female,
        fileNo: 'D-1001',
      ),
      observations: [
        obs('bp', {
          'code': {
            'coding': [
              {
                'system': 'http://loinc.org',
                'code': '85354-9',
                'display': 'BP panel',
              },
            ],
          },
          'note': [
            {'text': 'Estimated | not cuff'},
          ],
          'component': [
            {
              'code': {
                'coding': [
                  {
                    'system': 'http://loinc.org',
                    'code': '8480-6',
                    'display': 'Systolic',
                  },
                ],
              },
              'valueQuantity': {'value': 150, 'unit': 'mmHg', 'code': 'mm[Hg]'},
            },
            {
              'code': {
                'coding': [
                  {
                    'system': 'http://loinc.org',
                    'code': '8462-4',
                    'display': 'Diastolic',
                  },
                ],
              },
              'valueQuantity': {'value': 95, 'unit': 'mmHg', 'code': 'mm[Hg]'},
            },
          ],
        }),
        obs('temp', {
          'code': {
            'coding': [
              {
                'system': 'http://loinc.org',
                'code': '8310-5',
                'display': 'Body temperature',
              },
            ],
          },
          'valueQuantity': {'value': 36.75, 'unit': '°C', 'code': 'Cel'},
        }),
        obs('ecg', {
          'code': {
            'coding': [
              {
                'system': 'http://loinc.org',
                'code': '11524-6',
                'display': 'EKG study',
              },
            ],
          },
          'valueSampledData': {'data': '1 2 3'},
        }),
      ],
    );
    expect(msg, endsWith('\r'));
    final s = msg.split('\r')..removeLast();
    expect(
      s[0],
      r'MSH|^~\&|BILEKLIK|Kardiyoloji \T\ Ritim|||20261018100509+0000||'
      r'ORU^R01^ORU_R01|m\F\1|P|2.5.1|||AL|NE||UNICODE UTF-8',
    );
    expect(
      s[1],
      r'PID|1||D-1001^^^Kardiyoloji \T\ Ritim^MR~p-1^^^BILEKLIK^PI||'
      'Yılmaz^Ayşe Nur||19680304|F',
    );
    expect(s[2], startsWith(r'OBR|1||m\F\1^BILEKLIK|WRIST^'));
    expect(s[2], endsWith('|20261001000000+0000|20261020000000+0000'));
    expect(
      s[3],
      'OBX|1|NM|8480-6^Systolic^LN||150|mm[Hg]^mm[Hg]^UCUM|||||F|||20261018100509+0000',
    );
    expect(s[4], startsWith('OBX|2|NM|8462-4^Diastolic^LN||95|'));
    expect(s[5], r'NTE|1|L|Estimated \F\ not cuff');
    expect(
      s[6],
      startsWith('OBX|3|NM|8310-5^Body temperature^LN||36.75|Cel^Cel^UCUM|'),
    );
    expect(s[7], startsWith('NTE|1|L|1 observation(s) without numeric value'));
    expect(s, hasLength(8));
  });

  test('kayıt yoksa yalnızca takma kimlik, ad ve cinsiyet boş', () {
    final msg = Hl7Export.oru(
      messageId: '1',
      now: t,
      patientId: 'p-1',
      from: t,
      to: t,
      observations: const [],
    );
    expect(msg.split('\r')[1], 'PID|1||p-1^^^BILEKLIK^PI|||||');
  });

  test('kaçış karakterleri', () {
    expect(
      Hl7Export.esc(
        r'a|b^c~d\e&f'
        '\nx',
      ),
      r'a\F\b\S\c\R\d\E\e\T\f x',
    );
  });
}
