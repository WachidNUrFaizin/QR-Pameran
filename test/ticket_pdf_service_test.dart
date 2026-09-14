import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lms_qr_generator/app/models/ticket_data.dart';
import 'package:lms_qr_generator/app/services/ticket_pdf_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('builds a complete PDF ticket for the supplied HKGI customer', () async {
    final ticket = TicketData(
      it: 'CLD CNT O',
      nt: 'CANTIK',
      at: 'CILEDUG',
      pt: 'IBU MEILIYANA',
      kp: 'LG',
      ws: 'HKGI',
      np: '085150999908',
      printedAt: DateTime(2026, 9, 5, 10, 30),
    );

    final bytes = await TicketPdfService.build(ticket);

    expect(bytes.length, greaterThan(1000));
    expect(ascii.decode(bytes.take(5).toList()), '%PDF-');
    expect(
      latin1.decode(bytes.skip(bytes.length - 32).toList()),
      contains('%%EOF'),
    );
  });

  test('builds a PDF ticket when the optional telephone is empty', () async {
    final ticket = TicketData(
      it: 'CLD CNT O',
      nt: 'CANTIK',
      at: 'CILEDUG',
      pt: 'IBU MEILIYANA',
      kp: 'LG',
      ws: 'HKGI',
      np: '',
      printedAt: DateTime(2026, 9, 5, 10, 30),
    );

    final bytes = await TicketPdfService.build(ticket);

    expect(bytes.length, greaterThan(1000));
    expect(ascii.decode(bytes.take(5).toList()), '%PDF-');
  });
}
