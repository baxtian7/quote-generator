import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/quote_data.dart';
import 'amount_to_words.dart';

class PdfService {
  const PdfService._();

  static const _navy = PdfColor.fromInt(0xff233f6b);
  static const _lightBlue = PdfColor.fromInt(0xffe8eef7);
  static const _gridBlue = PdfColor.fromInt(0xffb7c5dc);

  static Future<Uint8List> generate(
    QuoteData data, {
    required Uint8List regularFontBytes,
    required Uint8List boldFontBytes,
  }) async {
    final regular = pw.Font.ttf(regularFontBytes.buffer.asByteData());
    final bold = pw.Font.ttf(boldFontBytes.buffer.asByteData());
    final document = pw.Document(
      title: 'Cuenta de cobro - ${data.debtorName}',
      author: QuoteData.creditorName,
      creator: 'Cuenta Clara',
      subject: data.concept,
      theme: pw.ThemeData.withFont(base: regular, bold: bold),
    );

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.fromLTRB(72, 61, 72, 54),
        maxPages: 30,
        build: (context) => [
          _centered('CUENTA DE COBRO', size: 17, bold: true),
          pw.SizedBox(height: 21),
          _centered(data.debtorName.trim().toUpperCase(), size: 12, bold: true),
          pw.SizedBox(height: 0.5),
          _centered('C.C. ${data.debtorId.trim()}', size: 9.5),
          pw.SizedBox(height: 26),
          _centered('DEBE A', size: 9.5, bold: true),
          pw.SizedBox(height: 8.5),
          _centered(QuoteData.creditorName, size: 12, bold: true),
          pw.SizedBox(height: 0.5),
          _centered('C.C. ${QuoteData.creditorId}', size: 9.5),
          pw.SizedBox(height: 27),
          _centered(
            'POR CONCEPTO DE ${data.concept.trim().toUpperCase()}',
            size: 9.5,
            bold: true,
          ),
          pw.SizedBox(height: 2),
          _centered(data.description.trim(), size: 9.5),
          if (data.includeTable) ...[
            pw.SizedBox(height: 21),
            ..._buildTable(data),
          ],
          pw.SizedBox(height: data.includeTable ? 23 : 28),
          _centered(
            'SON: ${AmountToWords.pesos(data.totalAmount)}.',
            size: 9.5,
            bold: true,
          ),
          pw.SizedBox(height: 20),
          _centered(
            'Favor consignar a la cuenta de ahorros ${QuoteData.bankName} '
            'N.º ${QuoteData.bankAccount}, a nombre de Juan Pablo Jiménez Escobar.',
            size: 9.5,
            lineSpacing: 2,
          ),
          pw.SizedBox(height: 20),
          _centered(
            'FECHA DE ELABORACIÓN: ${formatLongDate(data.issueDate)}',
            size: 9.5,
            bold: true,
          ),
          pw.SizedBox(height: 47),
          _centered('ATENTAMENTE,', size: 9.5, bold: true),
          pw.SizedBox(height: 37),
          _centered(QuoteData.creditorName, size: 9.5, bold: true),
          pw.SizedBox(height: 2),
          _centered('C.C. ${QuoteData.creditorId}', size: 9.5),
        ],
      ),
    );

    return document.save();
  }

  static List<pw.Widget> _buildTable(QuoteData data) {
    final borderSide = pw.BorderSide(color: _gridBlue, width: 0.55);
    final columnWidths = <int, pw.TableColumnWidth>{};
    for (var index = 0; index < data.columns.length; index++) {
      columnWidths[index] = pw.FlexColumnWidth(
        _columnWeight(data.columns[index]),
      );
    }

    final table = pw.Table(
      columnWidths: columnWidths,
      border: pw.TableBorder(
        left: borderSide,
        top: borderSide,
        right: borderSide,
        bottom: borderSide,
        horizontalInside: borderSide,
        verticalInside: borderSide,
      ),
      children: [
        pw.TableRow(
          repeat: true,
          decoration: const pw.BoxDecoration(color: _navy),
          children: data.columns
              .map(
                (column) => _tableCell(
                  column.name.trim().toUpperCase(),
                  bold: true,
                  height: 25,
                ),
              )
              .toList(),
        ),
        ...data.rows.map(
          (row) => pw.TableRow(
            children: data.columns.map((column) {
              final value = _formatCell(column, row.values[column.id] ?? '');
              return _tableCell(
                value,
                bold: column.includeInTotal,
                alignRight: column.includeInTotal,
                height: 25,
              );
            }).toList(),
          ),
        ),
      ],
    );

    final recordLabel = _recordLabel(data);
    return [
      table,
      pw.Container(
        decoration: const pw.BoxDecoration(
          color: _lightBlue,
          border: pw.Border(
            left: pw.BorderSide(color: _gridBlue, width: 0.55),
            right: pw.BorderSide(color: _gridBlue, width: 0.55),
            bottom: pw.BorderSide(color: _gridBlue, width: 0.55),
            top: pw.BorderSide(color: _navy, width: 1.5),
          ),
        ),
        padding: const pw.EdgeInsets.fromLTRB(5, 8.2, 5, 5.8),
        child: pw.Row(
          children: [
            pw.Expanded(
              child: pw.Text(
                recordLabel,
                style: pw.TextStyle(
                  fontSize: 8.5,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.Text(
              formatCurrency(data.totalAmount),
              textAlign: pw.TextAlign.right,
              style: pw.TextStyle(
                fontSize: 8.5,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    ];
  }

  static pw.Widget _tableCell(
    String value, {
    bool bold = false,
    bool alignRight = false,
    double height = 25,
  }) {
    return pw.Container(
      height: height,
      alignment: alignRight
          ? pw.Alignment.centerRight
          : pw.Alignment.centerLeft,
      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
      child: pw.Text(
        value,
        maxLines: 2,
        overflow: pw.TextOverflow.clip,
        textAlign: alignRight ? pw.TextAlign.right : pw.TextAlign.left,
        style: pw.TextStyle(
          fontSize: 8.5,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  static pw.Widget _centered(
    String value, {
    required double size,
    bool bold = false,
    double lineSpacing = 0.4,
  }) {
    return pw.Container(
      width: double.infinity,
      child: pw.Text(
        value,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(
          fontSize: size,
          lineSpacing: lineSpacing,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  static String _formatCell(QuoteColumn column, String rawValue) {
    if (column.type == QuoteColumnType.currency) {
      return formatCurrency(parseLocalizedNumber(rawValue));
    }
    return rawValue.trim();
  }

  static double _columnWeight(QuoteColumn column) => switch (column.type) {
    QuoteColumnType.text => 1.3,
    QuoteColumnType.date => 1.16,
    QuoteColumnType.time => 1.12,
    QuoteColumnType.number => 0.8,
    QuoteColumnType.currency => 1.2,
  };

  static String _recordLabel(QuoteData data) {
    final hasDateColumn = data.columns.any(
      (column) => column.type == QuoteColumnType.date,
    );
    if (hasDateColumn) {
      return 'TOTAL A PAGAR - ${data.rows.length} '
          '${data.rows.length == 1 ? 'DÍA' : 'DÍAS'}';
    }
    return 'TOTAL A PAGAR - ${data.rows.length} '
        '${data.rows.length == 1 ? 'REGISTRO' : 'REGISTROS'}';
  }

  static String formatCurrency(num value) {
    final formatted = NumberFormat(
      '#,##0',
      'es_CO',
    ).format(value.round().abs());
    return '${value < 0 ? '-' : ''}\$$formatted';
  }

  static String formatLongDate(DateTime date) {
    const months = [
      'ENERO',
      'FEBRERO',
      'MARZO',
      'ABRIL',
      'MAYO',
      'JUNIO',
      'JULIO',
      'AGOSTO',
      'SEPTIEMBRE',
      'OCTUBRE',
      'NOVIEMBRE',
      'DICIEMBRE',
    ];
    return '${date.day} DE ${months[date.month - 1]} DE ${date.year}';
  }

  static String fileName(QuoteData data) {
    final safeName = data.debtorName
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-záéíóúüñ0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    return 'cuenta_de_cobro_${safeName.isEmpty ? 'documento' : safeName}_${data.issueDate.year}';
  }
}
