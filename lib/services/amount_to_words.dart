class AmountToWords {
  const AmountToWords._();

  static String pesos(num value) {
    final amount = value.round().abs();
    if (amount == 0) return 'CERO PESOS';

    final words = _apocopate(_number(amount));
    final currency = amount == 1 ? 'PESO' : 'PESOS';
    final needsDe = amount >= 1000000 && amount % 1000000 == 0;
    return '$words${needsDe ? ' DE' : ''} $currency';
  }

  static String _number(int value) {
    if (value < 1000) return _underThousand(value);
    if (value < 1000000) {
      final thousands = value ~/ 1000;
      final remainder = value % 1000;
      final prefix = thousands == 1
          ? 'MIL'
          : '${_apocopate(_underThousand(thousands))} MIL';
      return remainder == 0 ? prefix : '$prefix ${_underThousand(remainder)}';
    }
    if (value < 1000000000000) {
      final millions = value ~/ 1000000;
      final remainder = value % 1000000;
      final prefix = millions == 1
          ? 'UN MILLÓN'
          : '${_apocopate(_number(millions))} MILLONES';
      return remainder == 0 ? prefix : '$prefix ${_number(remainder)}';
    }
    throw ArgumentError.value(value, 'value', 'El valor es demasiado grande');
  }

  static String _underThousand(int value) {
    if (value == 0) return '';
    if (value < 30) return _small[value]!;
    if (value < 100) {
      final tens = value ~/ 10 * 10;
      final units = value % 10;
      return units == 0 ? _tens[tens]! : '${_tens[tens]} Y ${_small[units]}';
    }

    final hundreds = value ~/ 100;
    final remainder = value % 100;
    final prefix = value == 100 ? 'CIEN' : _hundreds[hundreds]!;
    return remainder == 0 ? prefix : '$prefix ${_underThousand(remainder)}';
  }

  static String _apocopate(String value) {
    if (value == 'UNO') return 'UN';
    if (value.endsWith('VEINTIUNO')) {
      return '${value.substring(0, value.length - 9)}VEINTIÚN';
    }
    if (value.endsWith(' Y UNO')) {
      return '${value.substring(0, value.length - 6)} Y UN';
    }
    return value;
  }

  static const _small = <int, String>{
    0: 'CERO',
    1: 'UNO',
    2: 'DOS',
    3: 'TRES',
    4: 'CUATRO',
    5: 'CINCO',
    6: 'SEIS',
    7: 'SIETE',
    8: 'OCHO',
    9: 'NUEVE',
    10: 'DIEZ',
    11: 'ONCE',
    12: 'DOCE',
    13: 'TRECE',
    14: 'CATORCE',
    15: 'QUINCE',
    16: 'DIECISÉIS',
    17: 'DIECISIETE',
    18: 'DIECIOCHO',
    19: 'DIECINUEVE',
    20: 'VEINTE',
    21: 'VEINTIUNO',
    22: 'VEINTIDÓS',
    23: 'VEINTITRÉS',
    24: 'VEINTICUATRO',
    25: 'VEINTICINCO',
    26: 'VEINTISÉIS',
    27: 'VEINTISIETE',
    28: 'VEINTIOCHO',
    29: 'VEINTINUEVE',
  };

  static const _tens = <int, String>{
    30: 'TREINTA',
    40: 'CUARENTA',
    50: 'CINCUENTA',
    60: 'SESENTA',
    70: 'SETENTA',
    80: 'OCHENTA',
    90: 'NOVENTA',
  };

  static const _hundreds = <int, String>{
    1: 'CIENTO',
    2: 'DOSCIENTOS',
    3: 'TRESCIENTOS',
    4: 'CUATROCIENTOS',
    5: 'QUINIENTOS',
    6: 'SEISCIENTOS',
    7: 'SETECIENTOS',
    8: 'OCHOCIENTOS',
    9: 'NOVECIENTOS',
  };
}
