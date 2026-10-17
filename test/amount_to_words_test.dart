import 'package:flutter_test/flutter_test.dart';
import 'package:quote_generator/models/quote_data.dart';
import 'package:quote_generator/services/amount_to_words.dart';

void main() {
  group('AmountToWords', () {
    test('convierte el total del documento de referencia', () {
      expect(
        AmountToWords.pesos(688500),
        'SEISCIENTOS OCHENTA Y OCHO MIL QUINIENTOS PESOS',
      );
    });

    test('usa singular y la preposición de en millones exactos', () {
      expect(AmountToWords.pesos(1), 'UN PESO');
      expect(AmountToWords.pesos(1000000), 'UN MILLÓN DE PESOS');
      expect(AmountToWords.pesos(21000000), 'VEINTIÚN MILLONES DE PESOS');
    });
  });

  group('parseLocalizedNumber', () {
    test('entiende separadores colombianos', () {
      expect(parseLocalizedNumber(r'$229.500'), 229500);
      expect(parseLocalizedNumber('8,5'), 8.5);
      expect(parseLocalizedNumber('1.234.567,89'), 1234567.89);
    });
  });
}
