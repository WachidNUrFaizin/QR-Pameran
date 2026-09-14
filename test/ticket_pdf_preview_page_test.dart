import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lms_qr_generator/app/models/ticket_data.dart';
import 'package:lms_qr_generator/app/shared/ticket_pdf_preview_page.dart';
import 'package:printing/printing.dart';

void main() {
  testWidgets('shows the PDF preview for a customer ticket', (tester) async {
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

    await tester.pumpWidget(
      MaterialApp(
        home: TicketPdfPreviewPage(ticketData: ticket, title: 'Preview PDF'),
      ),
    );

    expect(find.text('Preview PDF'), findsOneWidget);
    expect(find.byType(PdfPreview), findsOneWidget);
  });

  testWidgets('shows a snackbar when PDF generation fails', (tester) async {
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

    await tester.pumpWidget(
      MaterialApp(
        home: TicketPdfPreviewPage(
          ticketData: ticket,
          pdfBuilder: (_) async => throw StateError('PDF gagal'),
        ),
      ),
    );
    final preview = tester.widget<PdfPreview>(find.byType(PdfPreview));
    await expectLater(
      preview.build(preview.initialPageFormat!),
      throwsA(isA<StateError>()),
    );
    await tester.pump();

    expect(
      find.text('PDF tidak dapat dibuat. Silakan coba kembali.'),
      findsWidgets,
    );
    final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
    expect(snackBar.backgroundColor, Colors.red);
  });
}
