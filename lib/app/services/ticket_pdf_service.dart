import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:lms_qr_generator/app/models/ticket_data.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class TicketPdfService {
  const TicketPdfService._();

  static final receiptFormat = PdfPageFormat(
    80 * PdfPageFormat.mm,
    180 * PdfPageFormat.mm,
    marginAll: 5 * PdfPageFormat.mm,
  );

  static Future<Uint8List> build(TicketData ticket) async {
    final regularFont = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Roboto-Regular.ttf'),
    );
    final boldFont = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Roboto-Bold.ttf'),
    );
    final document = pw.Document(
      title: 'ID Customer ${ticket.it}',
      author: 'LMS QR Generator',
    );
    final printedAt = ticket.printedAt;
    final shortYear = printedAt.year.toString().substring(2);
    final date =
        '${printedAt.day.toString().padLeft(2, '0')}/'
        '${printedAt.month.toString().padLeft(2, '0')}/$shortYear';
    final time =
        '${printedAt.hour.toString().padLeft(2, '0')}:'
        '${printedAt.minute.toString().padLeft(2, '0')}';

    document.addPage(
      pw.Page(
        pageFormat: receiptFormat,
        theme: pw.ThemeData.withFont(base: regularFont, bold: boldFont),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.Text(
                'ID CUSTOMER',
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              _fieldRow('ID', ticket.it),
              _fieldRow('Nama', ticket.nt),
              _fieldRow('Area', ticket.at),
              _fieldRow('Pelanggan', ticket.pt),
              if (ticket.np.trim().isNotEmpty)
                _fieldRow('No. Tlp', ticket.np.trim()),
              pw.SizedBox(height: 8),
              pw.Divider(),
              pw.SizedBox(height: 5),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    children: [
                      pw.Text(
                        date,
                        style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(time, style: const pw.TextStyle(fontSize: 12)),
                    ],
                  ),
                  pw.Column(
                    children: [
                      pw.Text(
                        ticket.kp,
                        style: pw.TextStyle(
                          fontSize: 13,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        ticket.wsLabel,
                        style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Center(
                child: pw.BarcodeWidget(
                  barcode: pw.Barcode.qrCode(),
                  data: ticket.qrPayload,
                  width: 42 * PdfPageFormat.mm,
                  height: 42 * PdfPageFormat.mm,
                  drawText: false,
                ),
              ),
            ],
          );
        },
      ),
    );

    return document.save();
  }

  static pw.Widget _fieldRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 25 * PdfPageFormat.mm,
            child: pw.Text(
              label,
              style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Text(': ', style: const pw.TextStyle(fontSize: 9)),
          pw.Expanded(
            child: pw.Text(value, style: const pw.TextStyle(fontSize: 9)),
          ),
        ],
      ),
    );
  }
}
