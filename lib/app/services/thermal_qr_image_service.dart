import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:lms_qr_generator/app/models/ticket_data.dart';
import 'package:qr_flutter/qr_flutter.dart';

class ThermalQrImageService {
  const ThermalQrImageService._();

  static Future<Uint8List> build(
    TicketData ticket, {
    double qrSize = 150,
    double textWidth = 100,
    double timestampWidth = 100,
    double padding = 8,
    double fontSize = 40,
    double timeFontSize = 24,
    double dateFontSize = 22,
  }) async {
    final now = ticket.printedAt;
    final shortYear = now.year.toString().substring(2);
    final time =
        '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}';
    final date =
        '${now.day.toString().padLeft(2, '0')}/'
        '${now.month.toString().padLeft(2, '0')}/$shortYear';

    final totalWidth = (timestampWidth + padding + textWidth + padding + qrSize)
        .toInt();
    final totalHeight = qrSize.toInt();
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    canvas.drawRect(
      Rect.fromLTWH(0, 0, totalWidth.toDouble(), totalHeight.toDouble()),
      Paint()..color = Colors.white,
    );

    final timestampPainter = TextPainter(
      text: TextSpan(
        children: [
          TextSpan(
            text: '$date\n',
            style: TextStyle(
              color: Colors.black,
              fontSize: dateFontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
          TextSpan(
            text: time,
            style: TextStyle(color: Colors.black87, fontSize: timeFontSize),
          ),
        ],
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: timestampWidth);
    timestampPainter.paint(
      canvas,
      Offset(
        (timestampWidth - timestampPainter.width) / 2,
        (totalHeight - timestampPainter.height) / 2,
      ),
    );

    final fittedFontSize = calculateFittedFontSize(
      textLine1: ticket.kp,
      textLine2: ticket.wsLabel,
      maxWidth: textWidth,
      maxHeight: totalHeight.toDouble(),
      maxFontSize: fontSize,
    );
    final labelPainter = _labelPainter(
      textLine1: ticket.kp,
      textLine2: ticket.wsLabel,
      fontSize: fittedFontSize,
    )..layout(maxWidth: textWidth);
    labelPainter.paint(
      canvas,
      Offset(
        timestampWidth + padding + (textWidth - labelPainter.width) / 2,
        (totalHeight - labelPainter.height) / 2,
      ),
    );

    final qrPainter = QrPainter(
      data: ticket.qrPayload,
      version: QrVersions.auto,
      gapless: true,
    );
    canvas.save();
    canvas.translate(timestampWidth + padding + textWidth + padding, 0);
    qrPainter.paint(canvas, Size(qrSize, qrSize));
    canvas.restore();

    final picture = recorder.endRecording();
    final image = await picture.toImage(totalWidth, totalHeight);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return byteData!.buffer.asUint8List();
  }

  static double calculateFittedFontSize({
    required String textLine1,
    required String textLine2,
    double maxWidth = 100,
    double maxHeight = 150,
    double maxFontSize = 40,
    double minFontSize = 16,
  }) {
    var candidate = maxFontSize;
    while (candidate > minFontSize) {
      final painter = _labelPainter(
        textLine1: textLine1,
        textLine2: textLine2,
        fontSize: candidate,
      )..layout(maxWidth: maxWidth);
      if (!painter.didExceedMaxLines &&
          painter.width <= maxWidth &&
          painter.height <= maxHeight) {
        return candidate;
      }
      candidate--;
    }
    return minFontSize;
  }

  static TextPainter _labelPainter({
    required String textLine1,
    required String textLine2,
    required double fontSize,
  }) {
    return TextPainter(
      text: TextSpan(
        text: '$textLine1\n$textLine2',
        style: TextStyle(
          color: Colors.black,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
      maxLines: 2,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
  }
}
