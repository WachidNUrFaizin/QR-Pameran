import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:lms_qr_generator/app/helper/customer_scan_coordinator.dart';

void main() {
  const validPayload =
      '{"it":"CLD CNT O","nt":"CANTIK","at":"CILEDUG",'
      '"pt":"IBU MEILIYANA","kp":"";"ws":"HKGI",'
      '"np":"085150999908"}';

  test('concurrent detections persist publish and close only once', () async {
    final releasePersistence = Completer<void>();
    var persistenceCount = 0;
    var publishCount = 0;
    var closeCount = 0;
    final coordinator = CustomerScanCoordinator(
      persist: (_) async {
        persistenceCount++;
        await releasePersistence.future;
      },
      stopCamera: () async {},
      startCamera: () async {},
      canUseScanner: () => true,
      publish: (_) => publishCount++,
      closeScanner: () => closeCount++,
      reportError: (_) {},
      retryDelay: () async {},
    );
    final session = coordinator.beginSession();

    final first = coordinator.process(session, validPayload);
    await Future<void>.delayed(Duration.zero);
    final second = coordinator.process(session, validPayload);

    expect(persistenceCount, 1);
    releasePersistence.complete();
    await Future.wait([first, second]);

    expect(persistenceCount, 1);
    expect(publishCount, 1);
    expect(closeCount, 1);
  });

  test('dismissal during retry prevents a stale camera restart', () async {
    final retryStarted = Completer<void>();
    final releaseRetry = Completer<void>();
    var restartCount = 0;
    final errors = <String>[];
    final coordinator = CustomerScanCoordinator(
      persist: (_) async {},
      stopCamera: () async {},
      startCamera: () async => restartCount++,
      canUseScanner: () => true,
      publish: (_) {},
      closeScanner: () {},
      reportError: errors.add,
      retryDelay: () {
        retryStarted.complete();
        return releaseRetry.future;
      },
    );
    final session = coordinator.beginSession();

    final processing = coordinator.process(session, '{not-json}');
    await retryStarted.future;
    coordinator.endSession(session);
    releaseRetry.complete();
    await processing;

    expect(errors, ['Format QR tidak sesuai']);
    expect(restartCount, 0);
  });

  test(
    'persistence failure does not publish or close a successful scan',
    () async {
      var publishCount = 0;
      var closeCount = 0;
      var restartCount = 0;
      final errors = <String>[];
      final coordinator = CustomerScanCoordinator(
        persist: (_) async => throw StateError('database unavailable'),
        stopCamera: () async {},
        startCamera: () async => restartCount++,
        canUseScanner: () => true,
        publish: (_) => publishCount++,
        closeScanner: () => closeCount++,
        reportError: errors.add,
        retryDelay: () async {},
      );
      final session = coordinator.beginSession();

      await coordinator.process(session, validPayload);

      expect(publishCount, 0);
      expect(closeCount, 0);
      expect(restartCount, 1);
      expect(errors, ['Data scan tidak dapat disimpan. Silakan coba kembali.']);
    },
  );

  test(
    'reopened scanner ignores the old session and accepts the new one',
    () async {
      final releaseOldPersistence = Completer<void>();
      var persistenceCount = 0;
      var publishCount = 0;
      var closeCount = 0;
      final coordinator = CustomerScanCoordinator(
        persist: (_) async {
          persistenceCount++;
          if (persistenceCount == 1) {
            await releaseOldPersistence.future;
          }
        },
        stopCamera: () async {},
        startCamera: () async {},
        canUseScanner: () => true,
        publish: (_) => publishCount++,
        closeScanner: () => closeCount++,
        reportError: (_) {},
        retryDelay: () async {},
      );
      final oldSession = coordinator.beginSession();

      final oldProcessing = coordinator.process(oldSession, validPayload);
      await Future<void>.delayed(Duration.zero);
      coordinator.endSession(oldSession);
      final newSession = coordinator.beginSession();
      releaseOldPersistence.complete();
      await oldProcessing;

      expect(publishCount, 0);
      expect(closeCount, 0);

      await coordinator.process(newSession, validPayload);

      expect(persistenceCount, 2);
      expect(publishCount, 1);
      expect(closeCount, 1);
    },
  );
}
