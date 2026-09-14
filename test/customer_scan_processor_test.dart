import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lms_qr_generator/app/helper/customer_qr_parser.dart';
import 'package:lms_qr_generator/app/helper/customer_scan_processor.dart';

void main() {
  const legacyPayload =
      '{"it":"CLD CNT O","nt":"CANTIK","at":"CILEDUG",'
      '"pt":"IBU MEILIYANA","kp":"";"ws":"HKGI",'
      '"np":"085150999908"}';

  test('persists one canonical scan before returning its result', () async {
    final releasePersistence = Completer<void>();
    var persistenceCount = 0;
    Map<String, dynamic>? persistedPayload;
    final processor = CustomerScanProcessor(
      persist: (payload) async {
        persistenceCount++;
        persistedPayload = Map<String, dynamic>.from(payload);
        await releasePersistence.future;
      },
    );

    var completed = false;
    final processing = processor.process(legacyPayload).then((result) {
      completed = true;
      return result;
    });
    await Future<void>.delayed(Duration.zero);

    expect(persistenceCount, 1);
    expect(completed, isFalse);

    releasePersistence.complete();
    final result = await processing;
    final decoded = jsonDecode(result.canonicalPayload);

    expect(persistedPayload?['kp'], 'LG');
    expect(persistedPayload?['ws'], 'HKGI');
    expect(decoded['np'], '085150999908');
    expect(completed, isTrue);
  });

  test('does not persist a malformed QR payload', () async {
    var persistenceCount = 0;
    final processor = CustomerScanProcessor(
      persist: (_) async {
        persistenceCount++;
      },
    );

    await expectLater(
      processor.process('{not-json}'),
      throwsA(isA<CustomerQrFormatException>()),
    );
    expect(persistenceCount, 0);
  });

  test('propagates a typed persistence failure without returning success', () {
    final processor = CustomerScanProcessor(
      persist: (_) async => throw StateError('database unavailable'),
    );

    expect(
      () => processor.process(legacyPayload),
      throwsA(
        isA<CustomerScanPersistenceException>().having(
          (error) => error.toString(),
          'message',
          contains('database unavailable'),
        ),
      ),
    );
  });
}
