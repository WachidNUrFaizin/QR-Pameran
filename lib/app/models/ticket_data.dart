import 'package:lms_qr_generator/app/helper/customer_qr_parser.dart';
import 'package:lms_qr_generator/app/helper/ws_label_helper.dart';
import 'package:lms_qr_generator/app/models/customer_model.dart';
import 'package:lms_qr_generator/app/models/scanned_model.dart';

class TicketData {
  const TicketData({
    required this.it,
    required this.nt,
    required this.at,
    required this.pt,
    required this.kp,
    required this.ws,
    required this.np,
    required this.printedAt,
  });

  factory TicketData.fromScanMap(
    Map<String, dynamic> data, {
    DateTime? printedAt,
  }) {
    return TicketData(
      it: _stringValue(data['it']),
      nt: _stringValue(data['nt']),
      at: _stringValue(data['at']),
      pt: _stringValue(data['pt']),
      kp: _stringValue(data['kp'], fallback: 'LG'),
      ws: _stringValue(data['ws']),
      np: _stringValue(data['np'] ?? data['telp']),
      printedAt: printedAt ?? DateTime.now(),
    );
  }

  factory TicketData.fromScannedItem(ScannedItem item, {DateTime? printedAt}) {
    return TicketData(
      it: item.it,
      nt: item.nt,
      at: item.at,
      pt: item.pt,
      kp: 'LG',
      ws: item.ws,
      np: item.telp,
      printedAt: printedAt ?? DateTime.now(),
    );
  }

  factory TicketData.fromCustomerItem(
    CustomerItem item, {
    DateTime? printedAt,
  }) {
    return TicketData(
      it: item.it,
      nt: item.nt,
      at: item.at,
      pt: item.pt,
      kp: 'LG',
      ws: item.ws,
      np: item.np,
      printedAt: printedAt ?? DateTime.now(),
    );
  }

  final String it;
  final String nt;
  final String at;
  final String pt;
  final String kp;
  final String ws;
  final String np;
  final DateTime printedAt;

  String get wsLabel => formatWsLabel(ws);

  Map<String, dynamic> get qrMap => {
    'it': it,
    'nt': nt,
    'at': at,
    'pt': pt,
    'kp': kp,
    'ws': ws,
    'np': np,
  };

  String get qrPayload => encodeCustomerQrPayload(qrMap);
}

String _stringValue(Object? value, {String fallback = ''}) {
  return value?.toString() ?? fallback;
}
