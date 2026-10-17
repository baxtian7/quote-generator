import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../models/quote_data.dart';
import '../services/amount_to_words.dart';
import '../services/pdf_service.dart';
import '../widgets/section_card.dart';
import 'pdf_preview_page.dart';

class QuoteFormPage extends StatefulWidget {
  const QuoteFormPage({super.key});

  @override
  State<QuoteFormPage> createState() => _QuoteFormPageState();
}

class _QuoteFormPageState extends State<QuoteFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _debtorName = TextEditingController();
  final _debtorId = TextEditingController();
  final _concept = TextEditingController();
  final _description = TextEditingController();
  final _manualTotal = TextEditingController();
  final _issueDateController = TextEditingController();
  final _cellControllers = <String, TextEditingController>{};

  final _columns = <QuoteColumn>[
    const QuoteColumn(id: 'date', name: 'FECHA', type: QuoteColumnType.date),
    const QuoteColumn(id: 'start', name: 'ENTRADA', type: QuoteColumnType.time),
    const QuoteColumn(id: 'end', name: 'SALIDA', type: QuoteColumnType.time),
    const QuoteColumn(id: 'hours', name: 'HORAS', type: QuoteColumnType.number),
    const QuoteColumn(
      id: 'rate',
      name: 'VALOR/HORA',
      type: QuoteColumnType.currency,
    ),
    const QuoteColumn(
      id: 'total',
      name: 'TOTAL',
      type: QuoteColumnType.currency,
      includeInTotal: true,
    ),
  ];
  final _rowIds = <String>['row_1'];

  late DateTime _issueDate;
  bool _includeTable = true;
  bool _generating = false;
  int _nextId = 2;

  @override
  void initState() {
    super.initState();
    _issueDate = DateTime.now();
    _issueDateController.text = _shortDate(_issueDate);
    _manualTotal.addListener(_refreshTotal);
  }

  @override
  void dispose() {
    _debtorName.dispose();
    _debtorId.dispose();
    _concept.dispose();
    _description.dispose();
    _manualTotal
      ..removeListener(_refreshTotal)
      ..dispose();
    _issueDateController.dispose();
    for (final controller in _cellControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _refreshTotal() {
    if (mounted) setState(() {});
  }

  TextEditingController _cellController(String rowId, String columnId) {
    final key = '$rowId::$columnId';
    return _cellControllers.putIfAbsent(key, () {
      final controller = TextEditingController();
      controller.addListener(_refreshTotal);
      return controller;
    });
  }

  double get _currentTotal => parseLocalizedNumber(_manualTotal.text);

  double get _tableCalculatedTotal {
    final totalColumns = _columns.where((column) => column.includeInTotal);
    if (_includeTable && totalColumns.isNotEmpty) {
      return _rowIds.fold<double>(0, (sum, rowId) {
        return sum +
            totalColumns.fold<double>(0, (rowSum, column) {
              return rowSum +
                  parseLocalizedNumber(_cellController(rowId, column.id).text);
            });
      });
    }
    return 0;
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Este campo es obligatorio';
    }
    return null;
  }

  String? _requiredCell(String? value, QuoteColumn column) {
    if (value == null || value.trim().isEmpty) return 'Obligatorio';
    if (column.type.isNumeric && !RegExp(r'\d').hasMatch(value)) {
      return 'Valor inválido';
    }
    return null;
  }

  Future<void> _pickIssueDate() async {
    final result = await showDatePicker(
      context: context,
      initialDate: _issueDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (result == null) return;
    setState(() {
      _issueDate = result;
      _issueDateController.text = _shortDate(result);
    });
  }

  Future<void> _pickCellDate(TextEditingController controller) async {
    final result = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (result != null) controller.text = _shortDate(result);
  }

  Future<void> _pickCellTime(TextEditingController controller) async {
    final result = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (result != null && mounted) {
      controller.text = MaterialLocalizations.of(context)
          .formatTimeOfDay(result);
    }
  }

  void _addRow() {
    setState(() => _rowIds.add('row_${_nextId++}'));
  }

  void _removeRow(String rowId) {
    if (_rowIds.length == 1) return;
    setState(() {
      _rowIds.remove(rowId);
      for (final column in _columns) {
        final controller = _cellControllers.remove('$rowId::${column.id}');
        controller
          ?..removeListener(_refreshTotal)
          ..dispose();
      }
    });
  }

  Future<void> _editColumn([QuoteColumn? existing]) async {
    final nameController = TextEditingController(text: existing?.name ?? '');
    var type = existing?.type ?? QuoteColumnType.text;
    var includeInTotal = existing?.includeInTotal ?? false;
    final dialogKey = GlobalKey<FormState>();

    final result = await showDialog<QuoteColumn>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(existing == null ? 'Nueva columna' : 'Editar columna'),
          content: Form(
            key: dialogKey,
            child: SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    autofocus: true,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'Nombre de la columna',
                      hintText: 'Ej. DESCRIPCIÓN',
                    ),
                    validator: _required,
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<QuoteColumnType>(
                    key: ValueKey(type),
                    initialValue: type,
                    decoration: const InputDecoration(
                      labelText: 'Tipo de dato',
                    ),
                    items: QuoteColumnType.values
                        .map(
                          (option) => DropdownMenuItem(
                            value: option,
                            child: Text(option.label),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setDialogState(() {
                        type = value;
                        if (!type.isNumeric) includeInTotal = false;
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    value: type.isNumeric && includeInTotal,
                    onChanged: type.isNumeric
                        ? (value) =>
                              setDialogState(() => includeInTotal = value)
                        : null,
                    title: const Text('Usar para calcular el total'),
                    subtitle: const Text('La app sumará esta columna.'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                if (!(dialogKey.currentState?.validate() ?? false)) return;
                Navigator.pop(
                  dialogContext,
                  QuoteColumn(
                    id: existing?.id ?? 'column_${_nextId++}',
                    name: nameController.text.trim().toUpperCase(),
                    type: type,
                    includeInTotal: type.isNumeric && includeInTotal,
                  ),
                );
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
    nameController.dispose();
    if (result == null) return;

    setState(() {
      if (result.includeInTotal) {
        for (var index = 0; index < _columns.length; index++) {
          _columns[index] = _columns[index].copyWith(includeInTotal: false);
        }
      }
      if (existing == null) {
        _columns.add(result);
      } else {
        final index = _columns.indexWhere((column) => column.id == existing.id);
        if (index >= 0) _columns[index] = result;
      }
    });
  }

  void _removeColumn(QuoteColumn column) {
    if (_columns.length == 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La tabla debe conservar al menos una columna.'),
        ),
      );
      return;
    }
    setState(() {
      _columns.removeWhere((item) => item.id == column.id);
      for (final rowId in _rowIds) {
        final controller = _cellControllers.remove('$rowId::${column.id}');
        controller
          ?..removeListener(_refreshTotal)
          ..dispose();
      }
    });
  }

  void _moveColumn(int index, int delta) {
    final target = index + delta;
    if (target < 0 || target >= _columns.length) return;
    setState(() {
      final column = _columns.removeAt(index);
      _columns.insert(target, column);
    });
  }

  QuoteData _buildData() {
    final rows = _rowIds.map((rowId) {
      return QuoteRow(
        id: rowId,
        values: {
          for (final column in _columns)
            column.id: _cellController(rowId, column.id).text.trim(),
        },
      );
    }).toList();

    return QuoteData(
      debtorName: _debtorName.text.trim(),
      debtorId: _debtorId.text.trim(),
      concept: _concept.text.trim(),
      description: _description.text.trim(),
      issueDate: _issueDate,
      includeTable: _includeTable,
      columns: List.unmodifiable(_columns),
      rows: List.unmodifiable(rows),
      manualTotal: parseLocalizedNumber(_manualTotal.text),
    );
  }

  Future<void> _preview() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Revisa los campos marcados antes de continuar.'),
        ),
      );
      return;
    }
    if (_currentTotal <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El total a pagar debe ser mayor que cero.'),
        ),
      );
      return;
    }

    setState(() => _generating = true);
    try {
      final regularData = await rootBundle.load('assets/fonts/DejaVuSans.ttf');
      final boldData = await rootBundle.load(
        'assets/fonts/DejaVuSans-Bold.ttf',
      );
      final data = _buildData();
      final bytes = await PdfService.generate(
        data,
        regularFontBytes: _asBytes(regularData),
        boldFontBytes: _asBytes(boldData),
      );
      if (!mounted) return;
      setState(() => _generating = false);
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PdfPreviewPage(data: data, bytes: bytes),
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No fue posible crear el PDF: $error')),
        );
      }
    } finally {
      if (mounted && _generating) setState(() => _generating = false);
    }
  }

  Uint8List _asBytes(ByteData data) {
    return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        titleSpacing: 20,
        title: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(Icons.description_rounded, color: Colors.white),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cuenta Clara',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  Text(
                    'Generador de cuentas de cobro',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 36),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _intro(),
                  const SizedBox(height: 18),
                  SectionCard(
                    step: 1,
                    title: 'Datos fijos del documento',
                    subtitle:
                        'Estos datos siempre aparecerán en la cuenta de cobro.',
                    child: _fixedInformation(),
                  ),
                  const SizedBox(height: 16),
                  SectionCard(
                    step: 2,
                    title: 'Quién debe pagar',
                    subtitle:
                        'Ingresa el nombre y la identificación del deudor.',
                    child: _twoFields(
                      TextFormField(
                        controller: _debtorName,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Nombre completo o empresa',
                          hintText: 'Ej. Elkin Antonio Giraldo Yepes',
                          prefixIcon: Icon(Icons.person_outline_rounded),
                        ),
                        validator: _required,
                      ),
                      TextFormField(
                        controller: _debtorId,
                        keyboardType: TextInputType.text,
                        decoration: const InputDecoration(
                          labelText: 'Cédula o NIT',
                          hintText: 'Ej. 98.664.461',
                          prefixIcon: Icon(Icons.badge_outlined),
                        ),
                        validator: _required,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SectionCard(
                    step: 3,
                    title: 'Detalle del cobro',
                    subtitle:
                        'Describe claramente el servicio o producto cobrado.',
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _concept,
                          textCapitalization: TextCapitalization.characters,
                          decoration: const InputDecoration(
                            labelText: 'Concepto',
                            hintText: 'Ej. SERVICIO DE MESERO',
                            prefixIcon: Icon(Icons.work_outline_rounded),
                          ),
                          validator: _required,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _description,
                          minLines: 2,
                          maxLines: 4,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: const InputDecoration(
                            labelText: 'Descripción',
                            hintText: 'Ej. Prestado los días 28, 29 y 30 de julio de 2026',
                            prefixIcon: Icon(Icons.notes_rounded),
                            alignLabelWithHint: true,
                          ),
                          validator: _required,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SectionCard(
                    step: 4,
                    title: 'Tabla de detalle',
                    subtitle: 'Es opcional. Define las columnas y luego llena cada fila.',
                    trailing: Switch.adaptive(
                      value: _includeTable,
                      onChanged: (value) =>
                          setState(() => _includeTable = value),
                    ),
                    child: _includeTable
                        ? _tableBuilder()
                        : _tableDisabledMessage(),
                  ),
                  const SizedBox(height: 16),
                  SectionCard(
                    step: 5,
                    title: 'Total y fecha',
                    subtitle:
                        'Confirma el valor final y la fecha de elaboración.',
                    child: _totalAndDate(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: _bottomBar(),
    );
  }

  Widget _intro() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xff193b67), Color(0xff2f5b8d)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Crea tu cuenta de cobro',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Completa los datos, revisa la vista previa y descarga o comparte el PDF.',
            style: TextStyle(color: Color(0xffdce8f7), fontSize: 15),
          ),
        ],
      ),
    );
  }

  Widget _fixedInformation() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xfff1f5fa),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xffd6e0ed)),
      ),
      child: const Wrap(
        spacing: 30,
        runSpacing: 18,
        children: [
          _FixedItem(
            icon: Icons.account_balance_wallet_outlined,
            label: 'Beneficiario',
            value: '${QuoteData.creditorName}\nC.C. ${QuoteData.creditorId}',
          ),
          _FixedItem(
            icon: Icons.account_balance_outlined,
            label: 'Cuenta para consignar',
            value:
                '${QuoteData.bankName} · Ahorros\nN.º ${QuoteData.bankAccount}',
          ),
          _FixedItem(
            icon: Icons.draw_outlined,
            label: 'Firma del documento',
            value: 'Atentamente,\n${QuoteData.creditorName}',
          ),
        ],
      ),
    );
  }

  Widget _twoFields(Widget first, Widget second) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 680) {
          return Column(children: [first, const SizedBox(height: 14), second]);
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: first),
            const SizedBox(width: 14),
            Expanded(child: second),
          ],
        );
      },
    );
  }

  Widget _tableDisabledMessage() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xfffff8e7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xfff0dbab)),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline_rounded, color: Color(0xff8a6420)),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'El PDF se generará sin tabla. El valor total se ingresa manualmente en el paso 5.',
            ),
          ),
        ],
      ),
    );
  }

  Widget _tableBuilder() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Columnas',
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            OutlinedButton.icon(
              onPressed: () => _editColumn(),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Agregar columna'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (var index = 0; index < _columns.length; index++)
              _columnCard(_columns[index], index),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: Text(
                'Filas',
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            FilledButton.tonalIcon(
              onPressed: _addRow,
              icon: const Icon(Icons.playlist_add_rounded),
              label: const Text('Agregar fila'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _rowsGrid(),
      ],
    );
  }

  Widget _columnCard(QuoteColumn column, int index) {
    return Container(
      width: 240,
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: column.includeInTotal
            ? const Color(0xffe7f1ff)
            : const Color(0xfff8fafc),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: column.includeInTotal
              ? const Color(0xff91b6e3)
              : const Color(0xffdde3eb),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  column.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  column.includeInTotal
                      ? '${column.type.label} · calcula total'
                      : column.type.label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xff65758a),
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'Opciones de columna',
            onSelected: (action) {
              switch (action) {
                case 'edit':
                  _editColumn(column);
                case 'left':
                  _moveColumn(index, -1);
                case 'right':
                  _moveColumn(index, 1);
                case 'delete':
                  _removeColumn(column);
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'edit', child: Text('Editar')),
              PopupMenuItem(
                value: 'left',
                enabled: index > 0,
                child: const Text('Mover a la izquierda'),
              ),
              PopupMenuItem(
                value: 'right',
                enabled: index < _columns.length - 1,
                child: const Text('Mover a la derecha'),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'delete', child: Text('Eliminar')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _rowsGrid() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xffdce3ec)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const SizedBox(width: 48),
                    for (final column in _columns)
                      SizedBox(
                        width: _fieldWidth(column),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          child: Text(
                            column.name,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Color(0xff43546a),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                for (var index = 0; index < _rowIds.length; index++) ...[
                  _rowEditor(_rowIds[index], index),
                  if (index < _rowIds.length - 1) const SizedBox(height: 8),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _rowEditor(String rowId, int rowIndex) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 48,
          height: 54,
          child: Column(
            children: [
              Text(
                '${rowIndex + 1}',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              SizedBox(
                width: 32,
                height: 32,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  tooltip: 'Eliminar fila',
                  onPressed: _rowIds.length == 1
                      ? null
                      : () => _removeRow(rowId),
                  icon: const Icon(Icons.delete_outline_rounded, size: 20),
                ),
              ),
            ],
          ),
        ),
        for (final column in _columns)
          SizedBox(
            width: _fieldWidth(column),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: _cellField(rowId, column),
            ),
          ),
      ],
    );
  }

  Widget _cellField(String rowId, QuoteColumn column) {
    final controller = _cellController(rowId, column.id);
    final isDate = column.type == QuoteColumnType.date;
    final isTime = column.type == QuoteColumnType.time;
    return TextFormField(
      controller: controller,
      readOnly: isDate || isTime,
      keyboardType: column.type.isNumeric
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      decoration: InputDecoration(
        isDense: true,
        hintText: _cellHint(column.type),
        suffixIcon: isDate
            ? const Icon(Icons.calendar_today_outlined, size: 18)
            : isTime
            ? const Icon(Icons.schedule_rounded, size: 18)
            : null,
      ),
      onTap: isDate
          ? () => _pickCellDate(controller)
          : isTime
          ? () => _pickCellTime(controller)
          : null,
      validator: (value) => _requiredCell(value, column),
    );
  }

  Widget _totalAndDate() {
    final calculatesFromTable =
        _includeTable && _columns.any((column) => column.includeInTotal);
    final totalField = TextFormField(
      controller: _manualTotal,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: 'Total a pagar',
        hintText: 'Ej. 688.500',
        prefixIcon: const Icon(Icons.attach_money_rounded),
        helperText: calculatesFromTable
            ? 'Suma de la tabla: ${PdfService.formatCurrency(_tableCalculatedTotal)}'
            : null,
      ),
      validator: (value) {
        final requiredError = _required(value);
        if (requiredError != null) return requiredError;
        if (parseLocalizedNumber(value!) <= 0) {
          return 'Ingresa un valor mayor que cero';
        }
        return null;
      },
    );

    return Column(
      children: [
        _twoFields(
          totalField,
          TextFormField(
            controller: _issueDateController,
            readOnly: true,
            onTap: _pickIssueDate,
            decoration: const InputDecoration(
              labelText: 'Fecha de elaboración',
              prefixIcon: Icon(Icons.event_outlined),
              suffixIcon: Icon(Icons.calendar_month_outlined),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xfff8fafc),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xffdde4ed)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Valor en letras que aparecerá en el PDF',
                style: TextStyle(fontSize: 12, color: Color(0xff65758a)),
              ),
              const SizedBox(height: 4),
              Text(
                AmountToWords.pesos(_currentTotal),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _bottomBar() {
    final button = FilledButton.icon(
      onPressed: _generating ? null : _preview,
      icon: _generating
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.picture_as_pdf_rounded),
      label: Text(_generating ? 'Creando PDF…' : 'Vista previa del PDF'),
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
      ),
    );
    final summary = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'TOTAL A PAGAR',
          style: TextStyle(fontSize: 11, color: Color(0xff65758a)),
        ),
        Text(
          PdfService.formatCurrency(_currentTotal),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: Color(0xff193b67),
          ),
        ),
      ],
    );
    final isCompact = MediaQuery.sizeOf(context).width < 520;

    return Material(
      color: Colors.white,
      elevation: 12,
      child: SafeArea(
        top: false,
        child: Align(
          alignment: Alignment.center,
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              child: isCompact
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [summary, const SizedBox(height: 10), button],
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Expanded(child: summary),
                        button,
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  double _fieldWidth(QuoteColumn column) => switch (column.type) {
    QuoteColumnType.text => 190,
    QuoteColumnType.date => 150,
    QuoteColumnType.time => 145,
    QuoteColumnType.number => 120,
    QuoteColumnType.currency => 150,
  };

  String _cellHint(QuoteColumnType type) => switch (type) {
    QuoteColumnType.text => 'Texto',
    QuoteColumnType.date => 'dd/mm/aaaa',
    QuoteColumnType.time => 'Hora',
    QuoteColumnType.number => '0',
    QuoteColumnType.currency => '\$0',
  };

  String _shortDate(DateTime date) => DateFormat('dd/MM/yyyy').format(date);
}

class _FixedItem extends StatelessWidget {
  const _FixedItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 285,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xff315f91)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xff65758a),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
