import 'dart:io';

import 'package:quote_generator/models/quote_data.dart';
import 'package:quote_generator/services/pdf_service.dart';

Future<void> main() async {
  final data = QuoteData(
    debtorName: 'ELKIN ANTONIO GIRALDO YEPES',
    debtorId: '98.664.461',
    concept: 'SERVICIO DE MESERO',
    description: 'Prestado los días 28, 29 y 30 de julio de 2026',
    issueDate: DateTime(2026, 8, 5),
    includeTable: true,
    columns: const [
      QuoteColumn(id: 'date', name: 'FECHA', type: QuoteColumnType.date),
      QuoteColumn(id: 'start', name: 'ENTRADA', type: QuoteColumnType.time),
      QuoteColumn(id: 'end', name: 'SALIDA', type: QuoteColumnType.time),
      QuoteColumn(id: 'hours', name: 'HORAS', type: QuoteColumnType.number),
      QuoteColumn(
        id: 'rate',
        name: 'VALOR/HORA',
        type: QuoteColumnType.currency,
      ),
      QuoteColumn(
        id: 'total',
        name: 'TOTAL',
        type: QuoteColumnType.currency,
        includeInTotal: true,
      ),
    ],
    rows: const [
      QuoteRow(
        id: '1',
        values: {
          'date': '28/07/2026',
          'start': '9:00 a. m.',
          'end': '5:30 p. m.',
          'hours': '8,5',
          'rate': '27.000',
          'total': '229.500',
        },
      ),
      QuoteRow(
        id: '2',
        values: {
          'date': '29/07/2026',
          'start': '9:00 a. m.',
          'end': '5:30 p. m.',
          'hours': '8,5',
          'rate': '27.000',
          'total': '229.500',
        },
      ),
      QuoteRow(
        id: '3',
        values: {
          'date': '30/07/2026',
          'start': '9:00 a. m.',
          'end': '5:30 p. m.',
          'hours': '8,5',
          'rate': '27.000',
          'total': '229.500',
        },
      ),
    ],
    manualTotal: 0,
  );

  final bytes = await PdfService.generate(
    data,
    regularFontBytes: await File('assets/fonts/DejaVuSans.ttf').readAsBytes(),
    boldFontBytes: await File('assets/fonts/DejaVuSans-Bold.ttf').readAsBytes(),
  );
  final directory = Directory('output/pdf')..createSync(recursive: true);
  final output = File('${directory.path}/cuenta_de_cobro_ejemplo.pdf');
  await output.writeAsBytes(bytes, flush: true);
  stdout.writeln(output.absolute.path);
}
