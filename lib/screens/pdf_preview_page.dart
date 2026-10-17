import 'dart:typed_data';

import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import '../models/quote_data.dart';
import '../services/pdf_service.dart';

class PdfPreviewPage extends StatefulWidget {
  const PdfPreviewPage({super.key, required this.data, required this.bytes});

  final QuoteData data;
  final Uint8List bytes;

  @override
  State<PdfPreviewPage> createState() => _PdfPreviewPageState();
}

class _PdfPreviewPageState extends State<PdfPreviewPage> {
  bool _working = false;

  Future<void> _download() async {
    await _runAction(() async {
      await FileSaver.instance.saveAs(
        name: PdfService.fileName(widget.data),
        bytes: widget.bytes,
        fileExtension: 'pdf',
        mimeType: MimeType.pdf,
        dialogTitle: 'Guardar cuenta de cobro',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF guardado correctamente.')),
        );
      }
    });
  }

  Future<void> _share() async {
    await _runAction(() async {
      await Printing.sharePdf(
        bytes: widget.bytes,
        filename: '${PdfService.fileName(widget.data)}.pdf',
        subject: 'Cuenta de cobro',
      );
    });
  }

  Future<void> _runAction(Future<void> Function() action) async {
    if (_working) return;
    setState(() => _working = true);
    try {
      await action();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No fue posible completar la acción: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Vista previa', style: TextStyle(fontWeight: FontWeight.w800)),
            Text(
              'Revisa el documento antes de exportarlo',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _working ? null : _download,
            tooltip: 'Descargar PDF',
            icon: const Icon(Icons.download_rounded),
          ),
          IconButton(
            onPressed: _working ? null : _share,
            tooltip: 'Compartir PDF',
            icon: const Icon(Icons.ios_share_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          PdfPreview(
            build: (_) async => widget.bytes,
            pdfFileName: '${PdfService.fileName(widget.data)}.pdf',
            allowPrinting: false,
            allowSharing: false,
            canChangeOrientation: false,
            canChangePageFormat: false,
            canDebug: false,
            maxPageWidth: 760,
            initialPageFormat: PdfPageFormat.letter,
          ),
          if (_working)
            const Positioned.fill(
              child: ColoredBox(
                color: Color(0x22000000),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _working ? null : _download,
                  icon: const Icon(Icons.download_rounded),
                  label: const Text('Descargar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _working ? null : _share,
                  icon: const Icon(Icons.ios_share_rounded),
                  label: const Text('Compartir'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
