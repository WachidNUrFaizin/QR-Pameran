import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lms_qr_generator/app/helper/customer_qr_parser.dart';

void main() {
  const validPayload =
      '{"it":"J02290","nt":"Ponti Suri 2","at":"Pontianak",'
      '"pt":"JKT Alex","kp":"","ws":"BT JKT","np":"0812345678"}';

  const legacyPayload =
      '{"it":"CLD CNT O","nt":"CANTIK","at":"CILEDUG",'
      '"pt":"IBU MEILIYANA","kp":"";"ws":"HKGI",'
      '"np":"085150999908"}';

  group('parseCustomerQrPayload', () {
    test('parses valid customer JSON without changing values', () {
      final result = parseCustomerQrPayload(validPayload);

      expect(result, {
        'it': 'J02290',
        'nt': 'Ponti Suri 2',
        'at': 'Pontianak',
        'pt': 'JKT Alex',
        'kp': '',
        'ws': 'BT JKT',
        'np': '0812345678',
      });
    });

    test('repairs the supplied semicolon field separator', () {
      final result = parseCustomerQrPayload(legacyPayload);

      expect(result['it'], 'CLD CNT O');
      expect(result['nt'], 'CANTIK');
      expect(result['at'], 'CILEDUG');
      expect(result['pt'], 'IBU MEILIYANA');
      expect(result['kp'], '');
      expect(result['ws'], 'HKGI');
      expect(result['np'], '085150999908');
    });

    test('repairs a separator followed by whitespace and a quoted key', () {
      final result = parseCustomerQrPayload(
        legacyPayload.replaceFirst(';"ws"', ';\n  "ws"'),
      );

      expect(result['ws'], 'HKGI');
      expect(result['np'], '085150999908');
    });

    test('preserves semicolons inside quoted values', () {
      const raw =
          '{"it":"CLD CNT O","nt":"CANTIK; MANIS","at":"A; B",'
          '"pt":"IBU MEILIYANA","kp":"";"ws":"HKGI","np":"1"}';

      final result = parseCustomerQrPayload(raw);

      expect(result['nt'], 'CANTIK; MANIS');
      expect(result['at'], 'A; B');
    });

    test('accepts a leading BOM and surrounding whitespace', () {
      final result = parseCustomerQrPayload('\uFEFF  $validPayload\n');

      expect(result['it'], 'J02290');
    });

    test('rejects empty malformed and non-object payloads', () {
      for (final raw in ['', '   ', '{not-json}', '[1,2,3]']) {
        expect(
          () => parseCustomerQrPayload(raw),
          throwsA(isA<CustomerQrFormatException>()),
          reason: 'Expected rejection for $raw',
        );
      }
    });

    test('rejects an object missing a required customer key', () {
      const raw = '{"it":"1","nt":"Name","at":"Area"}';

      expect(
        () => parseCustomerQrPayload(raw),
        throwsA(isA<CustomerQrFormatException>()),
      );
    });
  });

  test('prepareScannedCustomerPayload preserves fields and applies kp LG', () {
    final result = prepareScannedCustomerPayload(legacyPayload);

    expect(result, {
      'it': 'CLD CNT O',
      'nt': 'CANTIK',
      'at': 'CILEDUG',
      'pt': 'IBU MEILIYANA',
      'kp': 'LG',
      'ws': 'HKGI',
      'np': '085150999908',
    });
  });

  group('newly registered customers', () {
    const cahayaPayload =
        '{"it":"CA001","nt":"CAHAYA INDAH L","at":"ANYAR",'
        '"pt":"Akin","ws":"RJK ASUN"}';

    const abadiPayload =
        '{"it":"AK00007","nt":"ABADI","at":"CILACAP","pt":"ABADI",'
        '"np":"","tb":"2026-08-25","ws":"ANEKA","kp":""}';

    test('scans CAHAYA INDAH L without an np or kp key', () {
      expect(prepareScannedCustomerPayload(cahayaPayload), {
        'it': 'CA001',
        'nt': 'CAHAYA INDAH L',
        'at': 'ANYAR',
        'pt': 'Akin',
        'ws': 'RJK ASUN',
        'kp': 'LG',
      });
    });

    test('scans ABADI and keeps its extra tb field', () {
      expect(prepareScannedCustomerPayload(abadiPayload), {
        'it': 'AK00007',
        'nt': 'ABADI',
        'at': 'CILACAP',
        'pt': 'ABADI',
        'np': '',
        'tb': '2026-08-25',
        'ws': 'ANEKA',
        'kp': 'LG',
      });
    });
  });

  test('encodeCustomerQrPayload produces valid canonical JSON', () {
    final prepared = prepareScannedCustomerPayload(legacyPayload);

    final encoded = encodeCustomerQrPayload(prepared);
    final decoded = jsonDecode(encoded) as Map<String, dynamic>;

    expect(encoded, isNot(contains(';"ws"')));
    expect(decoded['kp'], 'LG');
    expect(decoded['ws'], 'HKGI');
    expect(decoded['np'], '085150999908');
  });
}
