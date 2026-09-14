import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lms_qr_generator/app/models/customer_model.dart';
import 'package:lms_qr_generator/app/models/scanned_model.dart';
import 'package:lms_qr_generator/app/models/ticket_data.dart';

void main() {
  final printedAt = DateTime(2026, 9, 5, 10, 30);

  test('builds ticket data from a scan map without changing field values', () {
    final ticket = TicketData.fromScanMap({
      'it': 'CLD CNT O',
      'nt': 'CANTIK',
      'at': 'CILEDUG',
      'pt': 'IBU MEILIYANA',
      'kp': 'LG',
      'ws': 'HKGI',
      'np': '085150999908',
    }, printedAt: printedAt);

    expect(ticket.qrMap, {
      'it': 'CLD CNT O',
      'nt': 'CANTIK',
      'at': 'CILEDUG',
      'pt': 'IBU MEILIYANA',
      'kp': 'LG',
      'ws': 'HKGI',
      'np': '085150999908',
    });
    expect(ticket.printedAt, printedAt);
  });

  test('builds ticket data from a history item', () {
    final ticket = TicketData.fromScannedItem(
      ScannedItem(
        id: 4,
        it: 'J02290',
        nt: 'Ponti Suri 2',
        at: 'Pontianak',
        pt: 'JKT Alex',
        ws: 'BT JKT',
        telp: '0812345678',
        date: '2026-09-05T10:00:00.000',
      ),
      printedAt: printedAt,
    );

    expect(ticket.kp, 'LG');
    expect(ticket.np, '0812345678');
    expect(ticket.ws, 'BT JKT');
  });

  test('builds ticket data from a customer and keeps an empty telephone', () {
    final ticket = TicketData.fromCustomerItem(
      CustomerItem(
        id: 8,
        it: 'C001',
        nt: 'TOKO SATU',
        at: 'JAKARTA',
        pt: '',
        ws: 'BT SMG',
        np: '',
        createdAt: '2026-09-05T09:00:00.000',
      ),
      printedAt: printedAt,
    );

    expect(ticket.kp, 'LG');
    expect(ticket.np, '');
    expect(ticket.qrMap['np'], '');
  });

  test('maps HKGI only for the printed label', () {
    final ticket = TicketData.fromScanMap({
      'it': '1',
      'nt': 'N',
      'at': 'A',
      'pt': 'P',
      'kp': 'LG',
      'ws': 'HKGI',
      'np': '0',
    }, printedAt: printedAt);

    expect(ticket.ws, 'HKGI');
    expect(ticket.wsLabel, 'HK');
    expect(ticket.qrMap['ws'], 'HKGI');
  });

  test('maps the new customers only for the printed label', () {
    final cahaya = TicketData.fromScanMap({
      'it': 'CA001',
      'nt': 'CAHAYA INDAH L',
      'at': 'ANYAR',
      'pt': 'Akin',
      'kp': 'LG',
      'ws': 'RJK ASUN',
    }, printedAt: printedAt);

    expect(cahaya.wsLabel, 'RJK');
    expect(cahaya.qrMap['ws'], 'RJK ASUN');
    expect(cahaya.np, '');

    final abadi = TicketData.fromScanMap({
      'it': 'AK00007',
      'nt': 'ABADI',
      'at': 'CILACAP',
      'pt': 'ABADI',
      'np': '',
      'tb': '2026-08-25',
      'ws': 'ANEKA',
      'kp': 'LG',
    }, printedAt: printedAt);

    expect(abadi.wsLabel, 'ANEKA');
    expect(abadi.qrMap['ws'], 'ANEKA');
    expect(abadi.np, '');
  });

  test('qrPayload is canonical valid JSON with all ticket fields', () {
    final ticket = TicketData.fromScanMap({
      'it': 'CLD CNT O',
      'nt': 'CANTIK',
      'at': 'CILEDUG',
      'pt': 'IBU MEILIYANA',
      'kp': 'LG',
      'ws': 'HKGI',
      'np': '085150999908',
    }, printedAt: printedAt);

    expect(jsonDecode(ticket.qrPayload), ticket.qrMap);
    expect(ticket.qrPayload, isNot(contains(';"ws"')));
  });
}
