import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:lms_qr_generator/app/models/ticket_data.dart';
import 'package:lms_qr_generator/app/services/thermal_qr_image_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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

  testWidgets('builds the existing 366 by 150 PNG ticket image', (
    tester,
  ) async {
    final rendered = await tester.runAsync(() async {
      final bytes = await ThermalQrImageService.build(ticket);
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final result = (
        bytes: bytes,
        width: frame.image.width,
        height: frame.image.height,
      );
      frame.image.dispose();
      codec.dispose();
      return result;
    });

    expect(rendered, isNotNull);
    expect(rendered!.bytes.take(8), [137, 80, 78, 71, 13, 10, 26, 10]);
    expect(rendered.width, 366);
    expect(rendered.height, 150);
  });

  testWidgets('shrinks longer WS labels to fit the text column', (
    tester,
  ) async {
    double fittedSize(String label) {
      return ThermalQrImageService.calculateFittedFontSize(
        textLine1: 'LG',
        textLine2: label,
      );
    }

    // Two-letter codes such as BM and HK print at the full size.
    expect(fittedSize('BM'), 40);
    expect(fittedSize('HK'), 40);

    // RJK behaves like the existing three-letter BMJ/BMS codes.
    expect(fittedSize('RJK'), fittedSize('BMJ'));
    expect(fittedSize('RJK'), lessThan(40));

    // ANEKA is the longest registered label and still stays readable.
    expect(fittedSize('ANEKA'), lessThan(fittedSize('RJK')));
    expect(fittedSize('ANEKA'), greaterThanOrEqualTo(16));
  });
}
