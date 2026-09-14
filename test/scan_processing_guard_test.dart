import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:lms_qr_generator/app/helper/scan_processing_guard.dart';

void main() {
  test(
    'ignores a concurrent scan while the first scan is processing',
    () async {
      final guard = ScanProcessingGuard();
      final releaseFirst = Completer<void>();
      var actionCount = 0;

      final session = guard.beginSession();
      final firstResult = guard.runForSession(session, () async {
        actionCount++;
        await releaseFirst.future;
        return 'first';
      });
      await Future<void>.delayed(Duration.zero);

      final secondResult = await guard.runForSession(session, () async {
        actionCount++;
        return 'second';
      });

      expect(secondResult, isNull);
      expect(actionCount, 1);

      releaseFirst.complete();
      expect(await firstResult, 'first');
    },
  );

  test('releases the guard after an action throws', () async {
    final guard = ScanProcessingGuard();
    final session = guard.beginSession();

    await expectLater(
      guard.runForSession<int>(
        session,
        () async => throw StateError('scan failed'),
      ),
      throwsA(isA<StateError>()),
    );

    expect(await guard.runForSession(session, () async => 2), 2);
  });

  test('ignores callbacks after their scanner session is dismissed', () async {
    final guard = ScanProcessingGuard();
    final session = guard.beginSession();
    var actionCount = 0;

    guard.endSession(session);
    final result = await guard.runForSession(session, () async {
      actionCount++;
      return 'stale';
    });

    expect(result, isNull);
    expect(actionCount, 0);
    expect(guard.isSessionActive(session), isFalse);
  });

  test('discards a result when its session closes during processing', () async {
    final guard = ScanProcessingGuard();
    final session = guard.beginSession();
    final releaseAction = Completer<void>();

    final result = guard.runForSession(session, () async {
      await releaseAction.future;
      return 'stale';
    });
    await Future<void>.delayed(Duration.zero);

    guard.endSession(session);
    releaseAction.complete();

    expect(await result, isNull);
  });

  test('reopening creates a new session that old callbacks cannot affect', () {
    final guard = ScanProcessingGuard();
    final oldSession = guard.beginSession();
    guard.endSession(oldSession);

    final newSession = guard.beginSession();

    expect(newSession, isNot(oldSession));
    expect(guard.isSessionActive(oldSession), isFalse);
    expect(guard.isSessionActive(newSession), isTrue);
  });
}
