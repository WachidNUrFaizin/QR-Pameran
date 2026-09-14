import 'package:flutter_test/flutter_test.dart';
import 'package:lms_qr_generator/app/helper/ws_label_helper.dart';

void main() {
  test('formats HKGI as HK', () {
    expect(formatWsLabel('HKGI'), 'HK');
  });

  test('normalizes case and whitespace before formatting HKGI', () {
    expect(formatWsLabel('  hkgi  '), 'HK');
  });

  test('formats the newly registered customers', () {
    expect(formatWsLabel('RJK ASUN'), 'RJK');
    expect(formatWsLabel('ANEKA'), 'ANEKA');
  });

  test('normalizes case and whitespace for the new customers', () {
    expect(formatWsLabel('  rjk   asun '), 'RJK');
    expect(formatWsLabel(' aneka '), 'ANEKA');
  });

  test('keeps existing WS mappings', () {
    const cases = {
      'BT JKT': 'BMJ',
      'BT SBY': 'BMS',
      'BT SMG': 'BM',
      'OTHER': 'BM',
    };

    for (final entry in cases.entries) {
      expect(formatWsLabel(entry.key), entry.value, reason: entry.key);
    }
  });

  test('formats missing WS as SA', () {
    expect(formatWsLabel(null), 'SA');
    expect(formatWsLabel(''), 'SA');
    expect(formatWsLabel('   '), 'SA');
  });
}
