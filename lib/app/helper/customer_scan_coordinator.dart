import 'package:lms_qr_generator/app/helper/customer_qr_parser.dart';
import 'package:lms_qr_generator/app/helper/customer_scan_processor.dart';
import 'package:lms_qr_generator/app/helper/scan_processing_guard.dart';

typedef CustomerScanAction = Future<void> Function();
typedef CustomerScanAvailability = bool Function();
typedef CustomerScanPublisher = void Function(CustomerScanResult result);
typedef CustomerScanErrorReporter = void Function(String message);
typedef CustomerScanDiagnostic =
    void Function(Object error, StackTrace stackTrace);

class CustomerScanCoordinator {
  CustomerScanCoordinator({
    required CustomerScanPersistence persist,
    required this.stopCamera,
    required this.startCamera,
    required this.canUseScanner,
    required this.publish,
    required this.closeScanner,
    required this.reportError,
    CustomerScanAction? retryDelay,
    CustomerScanDiagnostic? reportDiagnostic,
    ScanProcessingGuard? guard,
  }) : _processor = CustomerScanProcessor(persist: persist),
       _retryDelay = retryDelay ?? _defaultRetryDelay,
       _reportDiagnostic = reportDiagnostic,
       _guard = guard ?? ScanProcessingGuard();

  static const formatErrorMessage = 'Format QR tidak sesuai';
  static const persistenceErrorMessage =
      'Data scan tidak dapat disimpan. Silakan coba kembali.';
  static const genericErrorMessage = 'Pemindaian gagal. Silakan coba kembali.';

  final CustomerScanProcessor _processor;
  final ScanProcessingGuard _guard;
  final CustomerScanAction _retryDelay;
  final CustomerScanDiagnostic? _reportDiagnostic;
  final CustomerScanAction stopCamera;
  final CustomerScanAction startCamera;
  final CustomerScanAvailability canUseScanner;
  final CustomerScanPublisher publish;
  final void Function() closeScanner;
  final CustomerScanErrorReporter reportError;

  int beginSession() => _guard.beginSession();

  void endSession(int session) => _guard.endSession(session);

  Future<void> process(int session, String raw) async {
    CustomerScanResult? result;
    try {
      result = await _guard.runForSession(session, () async {
        await stopCamera();
        return _processor.process(raw);
      });
    } on CustomerQrFormatException catch (error, stackTrace) {
      _reportDiagnostic?.call(error, stackTrace);
      await _handleFailure(session, formatErrorMessage);
      return;
    } on CustomerScanPersistenceException catch (error, stackTrace) {
      _reportDiagnostic?.call(error, stackTrace);
      await _handleFailure(session, persistenceErrorMessage);
      return;
    } catch (error, stackTrace) {
      _reportDiagnostic?.call(error, stackTrace);
      await _handleFailure(session, genericErrorMessage);
      return;
    }

    if (result == null || !_guard.isSessionActive(session)) {
      return;
    }

    _guard.endSession(session);
    publish(result);
    closeScanner();
  }

  Future<void> _handleFailure(int session, String message) async {
    if (!_guard.isSessionActive(session)) {
      return;
    }

    reportError(message);
    await _retryDelay();

    if (_guard.isSessionActive(session) && canUseScanner()) {
      await startCamera();
    }
  }

  static Future<void> _defaultRetryDelay() {
    return Future<void>.delayed(const Duration(seconds: 2));
  }
}
