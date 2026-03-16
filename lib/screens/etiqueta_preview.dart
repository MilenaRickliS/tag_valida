// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../data/local/repos/etiquetas_local_repo.dart';
import '../models/etiqueta_model.dart';
import './criar_etiqueta.dart';
import '../utils/etiqueta_qr.dart';
import '../utils/formatar_lote.dart';
import '../providers/estoque_mov_local_provider.dart';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../providers/printer_config_provider.dart';
import '../services/printer_app_service.dart';


class EtiquetaPreviewScreen extends StatelessWidget {
  final String uid;
  final String etiquetaId;

  const EtiquetaPreviewScreen({
    super.key,
    required this.uid,
    required this.etiquetaId,
  });

  static const _lightBg = Color(0xFFFDF7ED);
  static const _lightCard = Colors.white;
  static const _lightText = Color(0xFF2B2B2B);
  static const _lightMuted = Color(0xFF6B6B6B);

  static const _darkBg = Color(0xFF0F0F0F);
  static const _darkCard = Color(0xFF1E1E1E);
  static const _darkCard2 = Color(0xFF181818);
  static const _darkText = Colors.white;
  static const _darkMuted = Color(0xFFD6D6D6);
  static const _gold = Color(0xFFD4AF37);

    bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  Color _bg(BuildContext context) => _isDark(context) ? _darkBg : _lightBg;
  Color _card(BuildContext context) => _isDark(context) ? _darkCard : _lightCard;
  Color _cardAlt(BuildContext context) => _isDark(context) ? _darkCard2 : const Color(0xFFFAF7F1);
  Color _text(BuildContext context) => _isDark(context) ? _darkText : _lightText;
  Color _muted(BuildContext context) => _isDark(context) ? _darkMuted : _lightMuted;
  Color _border(BuildContext context) => _isDark(context)
      ? _gold.withOpacity(0.16)
      : Colors.black.withOpacity(0.06);

    void _openQrFullscreen(BuildContext context, String qrData) {
    final isDark = _isDark(context);
    final cardColor = _card(context);
    final textColor = _text(context);
    final mutedColor = _muted(context);
    final borderColor = _border(context);

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "QR",
      barrierColor: Colors.black.withOpacity(0.85),
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (_, __, ___) {
        return SafeArea(
          child: Material(
            color: Colors.transparent,
            child: Stack(
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: Container(
                      margin: const EdgeInsets.all(18),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "QR Code",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 12),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final side = (constraints.maxWidth < constraints.maxHeight)
                                  ? constraints.maxWidth
                                  : constraints.maxHeight;

                              final qrSize = (side * 0.90).clamp(180.0, 900.0);

                              return Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: SizedBox(
                                  width: qrSize,
                                  height: qrSize,
                                  child: QrImageView(
                                    data: qrData,
                                    size: qrSize,
                                    padding: const EdgeInsets.all(6),
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "Aponte a câmera para abrir",
                            style: TextStyle(
                              fontSize: 12.5,
                              color: mutedColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close_rounded,
                      color: isDark ? _gold : Colors.white,
                      size: 28,
                    ),
                    tooltip: "Fechar",
                  ),
                ),
              ],
            ),
          ),
        );
      },
      transitionBuilder: (_, anim, __, child) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOut);
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween(begin: 0.98, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  int _daysToExpire(DateTime validade) {
    final today = _dateOnly(DateTime.now());
    final exp = _dateOnly(validade);
    return exp.difference(today).inDays; 
  }

  String _validadeLabel(DateTime validade) {
    final days = _daysToExpire(validade);
    if (days < 0) return "Vencida";
    if (days <= 2) return "Em alerta";
    return "Boa";
  }

  Color _validadeColor(DateTime validade) {
    final days = _daysToExpire(validade);
    if (days < 0) return Colors.red;
    if (days <= 2) return Colors.orange;
    return Colors.green;
  }

  String _validadeHint(DateTime validade) {
    final days = _daysToExpire(validade);
    if (days < 0) return "Venceu há ${days.abs()} dia(s)";
    if (days == 0) return "Vence hoje";
    return "Faltam $days dia(s)";
  }

  String _fmtNum(num v) {
    if (v % 1 == 0) return v.toInt().toString();
    return v.toStringAsFixed(2).replaceAll(".", ",");
  }

  String _fmtDate(DateTime d) => DateFormat("dd/MM/yyyy").format(d);

  Color _statusColor(String s) {
    switch (s) {
      case "cancelado":
        return Colors.red;
      case "vendido":
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  String _statusLabel(String s) {
    switch (s) {
      case "cancelado":
        return "Cancelado";
      case "vendido":
        return "Vendido";
      default:
        return "Ativo";
    }
  }


    Future<bool> _confirmDelete(BuildContext context, String nome) async {
    final textColor = _text(context);
    final mutedColor = _muted(context);
    final cardColor = _card(context);
    final cancelColor = _isDark(context) ? _gold : _lightText;

    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (_) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          backgroundColor: cardColor,
          surfaceTintColor: Colors.transparent,
          titlePadding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
          contentPadding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
          actionsPadding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
          title: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.red.withOpacity(0.18)),
                ),
                child: const Icon(Icons.delete_outline, color: Colors.red, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Excluir etiqueta?",
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            "Tem certeza que deseja excluir “$nome”?\nEssa ação não pode ser desfeita.",
            style: TextStyle(color: mutedColor, height: 1.25),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              style: TextButton.styleFrom(
                foregroundColor: cancelColor,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text("Cancelar", style: TextStyle(fontWeight: FontWeight.w700)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text("Excluir", style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ],
        );
      },
    );
    return ok ?? false;
  }

  void _openEdit(BuildContext context, EtiquetaModel e) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CriarEtiquetaScreen(editarEtiquetaId: e.id),
      ),
    );
  }

  Future<Uint8List> _buildPdf({
    required EtiquetaModel e,
    required String qrData,
    required String status,
    required String categoriaNome,
    required String setorNome,
    required String tipoNome,
    required String produtoNome,
    required DateTime fabricacao,
    required DateTime validade,
    required num qtd,
    required num saidas,
    required num restanteView,
    required String? loteLabel,
    required String? loteFormatado,
    required String? lotePrefixo,
    required Map<String, dynamic> customSemLote,
  }) async {
    final pdf = pw.Document();

    PdfColor validadePdfColor;
    final validadeColor = _validadeColor(validade);
    if (validadeColor == Colors.red) {
      validadePdfColor = PdfColors.red;
    } else if (validadeColor == Colors.orange) {
      validadePdfColor = PdfColors.orange;
    } else {
      validadePdfColor = PdfColors.green;
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(18),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#FFFFFF'),
              borderRadius: pw.BorderRadius.circular(16),
              border: pw.Border.all(
                color: PdfColor.fromHex('#E8E2D9'),
                width: 1,
              ),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            tipoNome,
                            style: pw.TextStyle(
                              fontSize: 18,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            produtoNome,
                            style: pw.TextStyle(
                              fontSize: 13,
                              color: PdfColors.grey700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: pw.BoxDecoration(
                            color: PdfColor.fromHex('#F3F4F6'),
                            borderRadius: pw.BorderRadius.circular(20),
                          ),
                          child: pw.Text(
                            _statusLabel(status),
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                        pw.SizedBox(height: 8),
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: pw.BoxDecoration(
                            color: validadePdfColor.shade(0.15),
                            borderRadius: pw.BorderRadius.circular(20),
                            border: pw.Border.all(color: validadePdfColor),
                          ),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                _validadeLabel(validade),
                                style: pw.TextStyle(
                                  color: validadePdfColor,
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                              pw.SizedBox(height: 2),
                              pw.Text(
                                _validadeHint(validade),
                                style: pw.TextStyle(
                                  color: validadePdfColor,
                                  fontSize: 9,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                pw.SizedBox(height: 18),
                pw.Divider(),
                pw.SizedBox(height: 12),

                _pdfLinha("Categoria", categoriaNome),
                _pdfLinha("Setor/Responsável", setorNome),
                _pdfLinha("Fabricação", _fmtDate(fabricacao)),
                _pdfLinha("Validade", _fmtDate(validade), color: validadePdfColor),

                if (loteFormatado != null) _pdfLinha(loteLabel ?? "Lote", loteFormatado),
                if (lotePrefixo != null) _pdfLinha("${loteLabel ?? "Lote"} (prefixo)", lotePrefixo),

                pw.SizedBox(height: 14),

                pw.Row(
                  children: [
                    pw.Expanded(child: _pdfMetric("Quantidade", _fmtNum(qtd))),
                    pw.SizedBox(width: 8),
                    pw.Expanded(child: _pdfMetric("Saídas", _fmtNum(saidas))),
                    pw.SizedBox(width: 8),
                    pw.Expanded(child: _pdfMetric("Restante", _fmtNum(restanteView))),
                  ],
                ),

                if (customSemLote.isNotEmpty) ...[
                  pw.SizedBox(height: 18),
                  pw.Text(
                    "Campos adicionais",
                    style: pw.TextStyle(
                      fontSize: 13,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  ...customSemLote.entries.map((entry) {
                    final obj = Map<String, dynamic>.from(entry.value as Map);
                    final label = (obj["label"] ?? entry.key).toString();
                    final val = obj["value"];

                    String texto;
                    if (val is int) {
                      final dt = DateTime.fromMillisecondsSinceEpoch(val);
                      texto = _fmtDate(dt);
                    } else if (val is bool) {
                      texto = val ? "Sim" : "Não";
                    } else {
                      texto = val?.toString() ?? "";
                    }

                    return _pdfLinha(label, texto);
                  }),
                ],

                pw.SizedBox(height: 22),
                pw.Center(
                  child: pw.Column(
                    children: [
                      pw.BarcodeWidget(
                        barcode: pw.Barcode.qrCode(),
                        data: qrData,
                        width: 150,
                        height: 150,
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        "Escaneie para abrir a etiqueta",
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _pdfLinha(String label, String value, {PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 140,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 11,
                color: PdfColors.grey700,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.SizedBox(width: 8),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 11.5,
                fontWeight: pw.FontWeight.bold,
                color: color ?? PdfColors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _pdfMetric(String label, String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#FAF7F1'),
        borderRadius: pw.BorderRadius.circular(12),
        border: pw.Border.all(color: PdfColor.fromHex('#E8E2D9')),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 10,
              color: PdfColors.grey700,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _salvarPdf(
    BuildContext context, {
    required EtiquetaModel e,
    required String qrData,
    required String status,
    required String categoriaNome,
    required String setorNome,
    required String tipoNome,
    required String produtoNome,
    required DateTime fabricacao,
    required DateTime validade,
    required num qtd,
    required num saidas,
    required num restanteView,
    required String? loteLabel,
    required String? loteFormatado,
    required String? lotePrefixo,
    required Map<String, dynamic> customSemLote,
  }) async {
    try {
      final bytes = await _buildPdf(
        e: e,
        qrData: qrData,
        status: status,
        categoriaNome: categoriaNome,
        setorNome: setorNome,
        tipoNome: tipoNome,
        produtoNome: produtoNome,
        fabricacao: fabricacao,
        validade: validade,
        qtd: qtd,
        saidas: saidas,
        restanteView: restanteView,
        loteLabel: loteLabel,
        loteFormatado: loteFormatado,
        lotePrefixo: lotePrefixo,
        customSemLote: customSemLote,
      );

      await Printing.sharePdf(
        bytes: bytes,
        filename: 'etiqueta_${e.produtoNome}_${_fmtDate(validade).replaceAll("/", "-")}.pdf',
      );
    } catch (err) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar PDF: $err')),
      );
    }
  }

 Future<void> _imprimirComConfigSalva(
    BuildContext context, {
    required String uid,
    required String produtoNome,
    required DateTime validade,
    required String qrData,
    required String lote,
    required String quantidade,
  }) async {
    try {
      final printerProvider = context.read<PrinterConfigProvider>();

      if (printerProvider.defaultPrinter == null) {
        await printerProvider.load(uid);
      }

      final printer = printerProvider.defaultPrinter;
        if (printer == null) {
          throw Exception('Nenhuma impressora padrão configurada.');
        }
        if (!printer.ativo) {
          throw Exception('A impressora padrão está inativa.');
        }
        if (!printer.isValida) {
          throw Exception('A configuração da impressora está incompleta.');
        }
        if (!printer.isNetwork) {
          throw Exception('A impressão disponível no momento é apenas via rede.');
        }

      final appService = PrinterAppService();

      await appService.imprimirEtiquetaCompacta(
        printer: printer,
        produto: produtoNome,
        validade: DateFormat('dd/MM/yyyy').format(validade),
        lote: lote,
        quantidade: quantidade,
        qrData: qrData,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Etiqueta enviada para impressão com sucesso.'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao imprimir: $e'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        );
      }
    }
  }

  void _abrirPreviewImpressao(
  BuildContext context, {
  required String produto,
  required DateTime validade,
  required String lote,
  required String quantidade,
  required String qrData,
}) {
  showDialog(
    context: context,
    builder: (_) {
      final isDark = Theme.of(context).brightness == Brightness.dark;

      return Dialog(
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Pré-visualização da etiqueta',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : _lightText,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Visualização ampliada da etiqueta 60x40 mm',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? const Color(0xFFD6D6D6) : Colors.black.withOpacity(0.58),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 18),
              EtiquetaPrintPreview(
                produto: produto,
                validade: DateFormat('dd/MM/yyyy').format(validade),
                lote: lote,
                quantidade: quantidade,
                qrData: qrData,
              ),
              const SizedBox(height: 18),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.check, color: Colors.black),
                  label: const Text('Fechar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF4D58D),
                    foregroundColor: Colors.black,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    }
  );
}

  @override
  Widget build(BuildContext context) {
    final repo = context.read<EtiquetasLocalRepo>();
    final isDark = _isDark(context);
    final bgColor = _bg(context);
    final cardColor = _card(context);
    final textColor = _text(context);
    final borderColor = _border(context);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "Preview da etiqueta",
          style: TextStyle(color: textColor, fontWeight: FontWeight.w900),
        ),
        iconTheme: IconThemeData(color: isDark ? _gold : textColor),
        actions: [
          FutureBuilder<EtiquetaModel?>(
            future: repo.getById(uid: uid, id: etiquetaId),
            builder: (context, snap) {
              final e = snap.data;
              if (e == null) return const SizedBox.shrink();

              return PopupMenuButton<String>(
                tooltip: "Opções",
                color: isDark ? _darkCard : Colors.white,
                surfaceTintColor: Colors.transparent,
                icon: Icon(
                  Icons.more_horiz_rounded,
                  color: isDark ? _gold : textColor,
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 6,
                onSelected: (v) async {
                  if (v == "edit") {
                    _openEdit(context, e);
                  } else if (v == "delete") {
                    final ok = await _confirmDelete(context, e.produtoNome);
                    if (!ok) return;

                    final mov = context.read<EstoqueMovLocalProvider>();
                    final before = await repo.getById(uid: uid, id: e.id);
                    if (before == null) return;

                    final st = (before.statusEstoque.trim().isEmpty)
                        ? "ativo"
                        : before.statusEstoque.trim().toLowerCase();

                    final rest = before.quantidadeRestante;

                    if (st == "ativo" && rest > 0) {
                      await mov.registrarCancelamento(
                        uid: uid,
                        etiquetaId: before.id,
                        quantidade: rest,
                        produtoNome: before.produtoNome,
                        motivo: "Exclusão da etiqueta (removeu do estoque)",
                      );
                    }

                    await mov.registrarExclusao(
                      uid: uid,
                      etiquetaId: before.id,
                      produtoNome: before.produtoNome,
                      motivo: "Exclusão suave",
                    );

                    await repo.deleteSoft(uid, before.id);

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text("Etiqueta excluída."),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      );
                      Navigator.pop(context);
                    }
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: "edit",
                    child: Row(
                      children: [
                        Icon(
                          Icons.edit_outlined,
                          size: 20,
                          color: isDark ? _gold : textColor,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          "Editar",
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : textColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: "delete",
                    child: Row(
                      children: const [
                        Icon(Icons.delete_outline, size: 20, color: Colors.red),
                        SizedBox(width: 10),
                        Text(
                          "Excluir",
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(width: 6),
        ],
      ),

      body: FutureBuilder<EtiquetaModel?>(
        future: repo.getById(uid: uid, id: etiquetaId),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final e = snap.data;
          if (e == null) {
            return const Center(child: Text("Etiqueta não encontrada."));
          }

          final qrData = buildEtiquetaQrPayload(uid: uid, etiquetaId: e.id);

          final produtoNome = e.produtoNome;
          final categoriaNome = e.categoriaNome;
          final setorNome = e.setorNome;
          final tipoNome = e.tipoNome;
          final fabricacao = e.dataFabricacao;
          final validade = e.dataValidade;
          final qtd = e.quantidade;
          final rest = e.quantidadeRestante;
          final status = (e.statusEstoque.trim().isEmpty) ? "ativo" : e.statusEstoque.trim();

          final num saidas = status == "cancelado" ? qtd : ((qtd - rest) < 0 ? 0 : (qtd - rest));
          final num restanteView = status == "cancelado" ? 0 : rest;

          final custom = Map<String, dynamic>.from(e.camposCustomValores);

          String? loteValue;
          String loteLabel = "Lote";

          final loteRaw = custom["lote"];
          if (loteRaw is Map) {
            final m = Map<String, dynamic>.from(loteRaw);
            loteLabel = (m["label"] ?? "Lote").toString();
            final v = m["value"];
            final s = v?.toString().trim();
            if (s != null && s.isNotEmpty) loteValue = s;
          }

          
          final customSemLote = Map<String, dynamic>.from(custom);
          customSemLote.remove("lote");

          final hasLote = loteValue != null && loteValue.trim().isNotEmpty;

          final loteFormatado = hasLote
              ? formatarLote(loteValue.trim(), formato: LoteFormato.dataHora)
              : null;

          final lotePrefixo = hasLote
              ? formatarLote(loteValue.trim(), formato: LoteFormato.prefixoL)
              : null;

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Column(
                  children: [
                   
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: borderColor),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                         
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      tipoNome,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                        color: textColor,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      produtoNome,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: textColor.withOpacity(0.75),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  _StatusChip(
                                    label: _statusLabel(status),
                                    color: _statusColor(status),
                                  ),
                                  const SizedBox(height: 8),
                                  _BadgeChip(
                                    label: _validadeLabel(validade),
                                    subtitle: _validadeHint(validade),
                                    color: _validadeColor(validade),
                                    icon: Icons.event_outlined,
                                  ),
                                ],
                              ),
                            ],
                          ),

                          const SizedBox(height: 14),
                          Divider(color: Colors.black.withOpacity(0.06), height: 1),
                          const SizedBox(height: 14),

                          _linha(context, "Categoria", categoriaNome),
                          _linha(context, "Setor/Responsável", setorNome),
                          _linha(context, "Fabricação", _fmtDate(fabricacao)),
                          _linhaColor(context, "Validade", _fmtDate(validade), _validadeColor(validade)),
                          if (hasLote) ...[
                            _linha(context, loteLabel, loteFormatado!),
                            const SizedBox(height: 6),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFAF7F1),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.black.withOpacity(0.06)),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.confirmation_number_outlined, size: 18, color: Colors.black.withOpacity(0.55)),
                                  const SizedBox(width: 10),
                                  Text(
                                    "$loteLabel: ",
                                    style: TextStyle(
                                      color: Colors.black.withOpacity(0.55),
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      lotePrefixo!,
                                      style: TextStyle(fontWeight: FontWeight.w900, color: Colors.black.withOpacity(0.55)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(child: _metric(context, "Quantidade", _fmtNum(qtd))),
                              const SizedBox(width: 10),
                              Expanded(child: _metric(context, "Saídas", _fmtNum(saidas))),
                              const SizedBox(width: 10),
                              Expanded(child: _metric(context, "Restante", _fmtNum(restanteView))),
                            ],
                          ),

                          if (customSemLote.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Divider(color: Colors.black.withOpacity(0.06), height: 1),
                            const SizedBox(height: 12),
                            Text(
                              "Campos adicionais",
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: textColor),
                            ),
                            const SizedBox(height: 10),
                            ...customSemLote.entries.map((entry) {
                              final obj = Map<String, dynamic>.from(entry.value as Map);
                              final label = (obj["label"] ?? entry.key).toString();
                              final val = obj["value"];

                              String texto;
                              if (val is int) {
                                final dt = DateTime.fromMillisecondsSinceEpoch(val);
                                texto = _fmtDate(dt);
                              } else if (val is bool) {
                                texto = val ? "Sim" : "Não";
                              } else {
                                texto = val?.toString() ?? "";
                              }

                              return _linha(context, label, texto);
                            }),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: borderColor),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: isDark
                                    ? const Color(0xFFD4AF37).withOpacity(0.25)
                                    : borderColor,
                              ),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(18),
                              onTap: () => _openQrFullscreen(context, qrData),
                              child: Column(
                                children: [
                                  QrImageView(
                                    data: qrData,
                                    size: 180,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "Toque para tela cheia",
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.black, 
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "Escaneie para abrir e gerar PDF",
                            style: TextStyle(fontSize: 12.5, color: textColor),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                   
                   Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _salvarPdf(
                            context,
                            e: e,
                            qrData: qrData,
                            status: status,
                            categoriaNome: categoriaNome,
                            setorNome: setorNome,
                            tipoNome: tipoNome,
                            produtoNome: produtoNome,
                            fabricacao: fabricacao,
                            validade: validade,
                            qtd: qtd,
                            saidas: saidas,
                            restanteView: restanteView,
                            loteLabel: hasLote ? loteLabel : null,
                            loteFormatado: loteFormatado,
                            lotePrefixo: lotePrefixo,
                            customSemLote: customSemLote,
                          ),
                          icon: Icon(
                            Icons.picture_as_pdf_outlined,
                            color: isDark ? Colors.black : Colors.black,
                          ),
                          label: const Text("Salvar PDF"),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: const Color(0xff88be8e),
                            foregroundColor: Colors.black,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _abrirPreviewImpressao(
                            context,
                            produto: produtoNome,
                            validade: validade,
                            lote: lotePrefixo ?? loteFormatado ?? '-',
                            quantidade: _fmtNum(restanteView),
                            qrData: qrData,
                          ),
                          icon: Icon(
                            Icons.remove_red_eye_outlined,
                            color: isDark ? _gold : textColor,
                          ),
                          label: const Text("Pré-visualização"),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            foregroundColor: isDark ? _gold : textColor,
                            backgroundColor: isDark ? _darkCard : Colors.white,
                            side: BorderSide(color: borderColor),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _imprimirComConfigSalva(
                            context,
                            uid: uid,
                            produtoNome: produtoNome,
                            validade: validade,
                            qrData: qrData,
                            lote: lotePrefixo ?? loteFormatado ?? '-',
                            quantidade: _fmtNum(restanteView),
                          ),
                          icon: const Icon(Icons.print_outlined, color: Colors.black),
                          label: const Text("Imprimir"),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: const Color(0xffF4D58D),
                            foregroundColor: Colors.black,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                    const SizedBox(height: 10),

                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        foregroundColor: isDark ? _gold : textColor,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text("Voltar", style: TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  ],
                  
                ),
              ),
            ),
          );
        },
      ),
    );
  }


   Widget _linha(BuildContext context, String label, String value) {
    final textColor = _text(context);
    final mutedColor = _muted(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                color: mutedColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

    Widget _linhaColor(BuildContext context, String label, String value, Color color) {
    final mutedColor = _muted(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                color: mutedColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

    Widget _metric(BuildContext context, String label, String value) {
      final textColor = _text(context);
      final mutedColor = _muted(context);
      final bg = _cardAlt(context);
      final borderColor = _border(context);

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: mutedColor,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: textColor,
              ),
            ),
          ],
        ),
      );
    }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.28)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
    );
  }
}

class _BadgeChip extends StatelessWidget {
  final String label;
  final String? subtitle;
  final Color color;
  final IconData icon;

  const _BadgeChip({
    required this.label,
    required this.color,
    required this.icon,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 1),
                Text(
                  subtitle!,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: color.withOpacity(0.9),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class EtiquetaPrintPreview extends StatelessWidget {
  final String produto;
  final String validade;
  final String lote;
  final String quantidade;
  final String qrData;

  const EtiquetaPrintPreview({
    super.key,
    required this.produto,
    required this.validade,
    required this.lote,
    required this.quantidade,
    required this.qrData,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    const previewWidth = 420.0;
    const ratio = 60 / 40;
    final previewHeight = previewWidth / ratio;

    return Center(
      child: Container(
        width: previewWidth,
        height: previewHeight,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          border: Border.all(
            color: isDark
                ? const Color(0xFFD4AF37).withOpacity(0.16)
                : Colors.black.withOpacity(0.10),
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    produto,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      height: 1.05,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Val: $validade',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Lote: $lote',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Qtd: $quantidade',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              flex: 4,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: QrImageView(
                    data: qrData,
                    size: 125,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}