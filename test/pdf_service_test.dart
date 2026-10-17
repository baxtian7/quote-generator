import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quote_generator/models/quote_data.dart';
import 'package:quote_generator/services/pdf_service.dart';

void main() {
  test('genera una tabla larga en varias páginas sin desbordarse', () async {
    const columns = [
      QuoteColumn(id: 'date', name: 'FECHA', type: QuoteColumnType.date),
      QuoteColumn(
        id: 'total',
        name: 'TOTAL',
        type: QuoteColumnType.currency,
        includeInTotal: true,
      ),
    ];
    final rows = List.generate(
      40,
      (index) => QuoteRow(
        id: '$index',
        values: {'date': '${index + 1}/10/2026', 'total': '10.000'},
      ),
    );
    final data = QuoteData(
      debtorName: 'CLIENTE DE PRUEBA',
      debtorId: '1.234.567',
      concept: 'SERVICIOS',
      description: 'Detalle de una cuenta de cobro extensa',
      issueDate: DateTime(2026, 10, 16),
      includeTable: true,
      columns: columns,
      rows: rows,
      manualTotal: 450000,
    );

    expect(data.tableCalculatedAmount, 400000);
    expect(data.totalAmount, 450000);

    final bytes = await PdfService.generate(
      data,
      regularFontBytes: await File('assets/fonts/DejaVuSans.ttf').readAsBytes(),
      boldFontBytes: await File('assets/fonts/DejaVuSans-Bold.ttf')
          .readAsBytes(),
    );

    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
    expect(bytes.length, greaterThan(10000));
  });
}
