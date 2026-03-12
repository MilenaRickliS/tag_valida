import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../utils/etiqueta_qr.dart';
import '../services/etiqueta_open_flow.dart';

class ScannerEtiquetaScreen extends StatefulWidget {
  const ScannerEtiquetaScreen({super.key});

  @override
  State<ScannerEtiquetaScreen> createState() => _ScannerEtiquetaScreenState();
}

class _ScannerEtiquetaScreenState extends State<ScannerEtiquetaScreen> {
  bool _handled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Ler QR da etiqueta")),
      body: MobileScanner(
       onDetect: (capture) async {
        if (_handled) return;

        final barcode = capture.barcodes.firstOrNull;
        final raw = barcode?.rawValue;
        if (raw == null || raw.isEmpty) return;

        debugPrint('QR LIDO: $raw');

        try {
          _handled = true;

          final parsed = parseEtiquetaQrPayload(raw);

          await openEtiquetaPdfFlow(
            context,
            uid: parsed.uid,
            etiquetaId: parsed.id,
          );

          if (context.mounted) Navigator.pop(context);
        } catch (e, s) {
          debugPrint('ERRO AO LER QR: $e');
          debugPrint('$s');

          _handled = false;
          if (!context.mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("QR inválido: $raw")),
          );
        }
      },
      ),
    );
  }
}