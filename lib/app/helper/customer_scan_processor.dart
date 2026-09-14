import 'package:lms_qr_generator/app/helper/customer_qr_parser.dart';

typedef CustomerScanPersistence =
    Future<void> Function(Map<String, dynamic> payload);

class CustomerScanPersistenceException implements Exception {
  const CustomerScanPersistenceException(this.cause);

  final Object cause;

  @override
  String toString() => 'Customer scan persistence failed: $cause';
}

class CustomerScanResult {
  const CustomerScanResult({
    required this.payload,
    required this.canonicalPayload,
  });

  final Map<String, dynamic> payload;
  final String canonicalPayload;
}

class CustomerScanProcessor {
  const CustomerScanProcessor({required this.persist});

  final CustomerScanPersistence persist;

  Future<CustomerScanResult> process(String raw) async {
    final payload = prepareScannedCustomerPayload(raw);
    final canonicalPayload = encodeCustomerQrPayload(payload);

    try {
      await persist(payload);
    } catch (error) {
      throw CustomerScanPersistenceException(error);
    }

    return CustomerScanResult(
      payload: payload,
      canonicalPayload: canonicalPayload,
    );
  }
}
