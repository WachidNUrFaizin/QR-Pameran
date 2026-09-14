import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:lms_qr_generator/app/models/ticket_data.dart';
import 'package:lms_qr_generator/app/services/ticket_pdf_service.dart';
import 'package:printing/printing.dart';

class TicketPdfPreviewPage extends StatelessWidget {
  const TicketPdfPreviewPage({
    super.key,
    required this.ticketData,
    this.title = 'Preview PDF',
    this.pdfBuilder,
  });

  final TicketData ticketData;
  final String title;
  final Future<Uint8List> Function(TicketData)? pdfBuilder;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: PdfPreview(
        build: (_) async {
          try {
            return await (pdfBuilder ?? TicketPdfService.build)(ticketData);
          } catch (_) {
            if (context.mounted) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  const SnackBar(
                    backgroundColor: Colors.red,
                    content: Text(
                      'PDF tidak dapat dibuat. Silakan coba kembali.',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                );
            }
            rethrow;
          }
        },
        initialPageFormat: TicketPdfService.receiptFormat,
        canChangePageFormat: false,
        canChangeOrientation: false,
        allowPrinting: true,
        allowSharing: true,
        maxPageWidth: 360,
        pdfFileName: _fileName(ticketData.it),
        onError: (context, error) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'PDF tidak dapat dibuat. Silakan coba kembali.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        },
      ),
    );
  }

  static String _fileName(String customerId) {
    final safeId = customerId.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    return 'id-customer-${safeId.isEmpty ? 'customer' : safeId}.pdf';
  }
}
