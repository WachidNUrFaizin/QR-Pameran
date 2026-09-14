String formatWsLabel(Object? raw) {
  final ws =
      raw?.toString().toUpperCase().trim().replaceAll(RegExp(r'\s+'), ' ') ??
      '';
  if (ws.isEmpty) return 'SA';
  if (ws == 'HKGI') return 'HK';
  if (ws == 'RJK ASUN') return 'RJK';
  if (ws == 'ANEKA') return 'ANEKA';
  if (ws == 'BT JKT') return 'BMJ';
  if (ws == 'BT SBY') return 'BMS';
  if (ws == 'BT SMG') return 'BM';
  return 'BM';
}
