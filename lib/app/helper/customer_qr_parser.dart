import 'dart:convert';

const _requiredCustomerQrKeys = {'it', 'nt', 'at', 'pt'};

class CustomerQrFormatException implements Exception {
  const CustomerQrFormatException([this.message = 'Format QR tidak sesuai']);

  final String message;

  @override
  String toString() => message;
}

Map<String, dynamic> parseCustomerQrPayload(String raw) {
  var source = raw.trim();
  if (source.startsWith('\uFEFF')) {
    source = source.substring(1).trimLeft();
  }
  if (source.isEmpty) {
    throw const CustomerQrFormatException();
  }

  dynamic decoded;
  try {
    decoded = jsonDecode(source);
  } on FormatException {
    final repaired = _repairLegacyFieldSeparators(source);
    if (repaired == source) {
      throw const CustomerQrFormatException();
    }
    try {
      decoded = jsonDecode(repaired);
    } on FormatException {
      throw const CustomerQrFormatException();
    }
  }

  if (decoded is! Map) {
    throw const CustomerQrFormatException();
  }

  final Map<String, dynamic> payload;
  try {
    payload = Map<String, dynamic>.from(decoded);
  } on TypeError {
    throw const CustomerQrFormatException();
  }

  if (!_requiredCustomerQrKeys.every(payload.containsKey)) {
    throw const CustomerQrFormatException();
  }

  return payload;
}

Map<String, dynamic> prepareScannedCustomerPayload(String raw) {
  final payload = Map<String, dynamic>.from(parseCustomerQrPayload(raw));
  payload['kp'] = 'LG';
  return payload;
}

String encodeCustomerQrPayload(Map<String, dynamic> payload) {
  return jsonEncode(payload);
}

String _repairLegacyFieldSeparators(String source) {
  final repaired = StringBuffer();
  var inString = false;
  var escaped = false;

  for (var index = 0; index < source.length; index++) {
    final character = source[index];

    if (inString) {
      repaired.write(character);
      if (escaped) {
        escaped = false;
      } else if (character == r'\') {
        escaped = true;
      } else if (character == '"') {
        inString = false;
      }
      continue;
    }

    if (character == '"') {
      inString = true;
      repaired.write(character);
      continue;
    }

    if (character == ';' && _startsQuotedObjectKey(source, index + 1)) {
      repaired.write(',');
    } else {
      repaired.write(character);
    }
  }

  return repaired.toString();
}

bool _startsQuotedObjectKey(String source, int start) {
  var index = start;
  while (index < source.length && _isJsonWhitespace(source[index])) {
    index++;
  }
  if (index >= source.length || source[index] != '"') {
    return false;
  }

  index++;
  var escaped = false;
  while (index < source.length) {
    final character = source[index];
    if (escaped) {
      escaped = false;
    } else if (character == r'\') {
      escaped = true;
    } else if (character == '"') {
      index++;
      break;
    }
    index++;
  }

  while (index < source.length && _isJsonWhitespace(source[index])) {
    index++;
  }
  return index < source.length && source[index] == ':';
}

bool _isJsonWhitespace(String character) {
  return character == ' ' ||
      character == '\n' ||
      character == '\r' ||
      character == '\t';
}
