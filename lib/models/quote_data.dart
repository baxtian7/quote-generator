enum QuoteColumnType { text, date, time, number, currency }

extension QuoteColumnTypeX on QuoteColumnType {
  String get label => switch (this) {
    QuoteColumnType.text => 'Texto',
    QuoteColumnType.date => 'Fecha',
    QuoteColumnType.time => 'Hora',
    QuoteColumnType.number => 'Número',
    QuoteColumnType.currency => 'Moneda',
  };

  bool get isNumeric =>
      this == QuoteColumnType.number || this == QuoteColumnType.currency;
}

class QuoteColumn {
  const QuoteColumn({
    required this.id,
    required this.name,
    required this.type,
    this.includeInTotal = false,
  });

  final String id;
  final String name;
  final QuoteColumnType type;
  final bool includeInTotal;

  QuoteColumn copyWith({
    String? name,
    QuoteColumnType? type,
    bool? includeInTotal,
  }) {
    return QuoteColumn(
      id: id,
      name: name ?? this.name,
      type: type ?? this.type,
      includeInTotal: includeInTotal ?? this.includeInTotal,
    );
  }
}

class QuoteRow {
  const QuoteRow({required this.id, required this.values});

  final String id;
  final Map<String, String> values;
}

class QuoteData {
  const QuoteData({
    required this.debtorName,
    required this.debtorId,
    required this.concept,
    required this.description,
    required this.issueDate,
    required this.includeTable,
    required this.columns,
    required this.rows,
    required this.manualTotal,
  });

  static const creditorName = 'JUAN PABLO JIMÉNEZ ESCOBAR';
  static const creditorId = '8.355.412';
  static const bankName = 'Bancolombia';
  static const bankAccount = '52791286425';

  final String debtorName;
  final String debtorId;
  final String concept;
  final String description;
  final DateTime issueDate;
  final bool includeTable;
  final List<QuoteColumn> columns;
  final List<QuoteRow> rows;
  final double manualTotal;

  double get totalAmount => manualTotal;

  double get tableCalculatedAmount {
    if (!includeTable) return 0;
    final totalColumnIds = columns
        .where((column) => column.includeInTotal)
        .map((column) => column.id)
        .toSet();
    if (totalColumnIds.isEmpty) return 0;

    return rows.fold<double>(0, (sum, row) {
      final rowTotal = totalColumnIds.fold<double>(0, (subtotal, columnId) {
        return subtotal + parseLocalizedNumber(row.values[columnId] ?? '');
      });
      return sum + rowTotal;
    });
  }
}

double parseLocalizedNumber(String value) {
  var cleaned = value.trim().replaceAll(RegExp(r'[^0-9,.-]'), '');
  if (cleaned.isEmpty || cleaned == '-') return 0;

  final isNegative = cleaned.startsWith('-');
  cleaned = cleaned.replaceAll('-', '');
  final lastComma = cleaned.lastIndexOf(',');
  final lastDot = cleaned.lastIndexOf('.');

  String normalized;
  if (lastComma >= 0 && lastDot >= 0) {
    final decimalSeparator = lastComma > lastDot ? ',' : '.';
    final decimalIndex = cleaned.lastIndexOf(decimalSeparator);
    final decimals = cleaned.length - decimalIndex - 1;
    if (decimals == 1 || decimals == 2) {
      final integerPart = cleaned
          .substring(0, decimalIndex)
          .replaceAll(RegExp(r'[.,]'), '');
      final decimalPart = cleaned.substring(decimalIndex + 1);
      normalized = '$integerPart.$decimalPart';
    } else {
      normalized = cleaned.replaceAll(RegExp(r'[.,]'), '');
    }
  } else if (lastComma >= 0 || lastDot >= 0) {
    final separator = lastComma >= 0 ? ',' : '.';
    final parts = cleaned.split(separator);
    final decimals = parts.last.length;
    if (parts.length == 2 && (decimals == 1 || decimals == 2)) {
      normalized = '${parts.first}.${parts.last}';
    } else {
      normalized = parts.join();
    }
  } else {
    normalized = cleaned;
  }

  final parsed = double.tryParse(normalized) ?? 0;
  return isNegative ? -parsed : parsed;
}
