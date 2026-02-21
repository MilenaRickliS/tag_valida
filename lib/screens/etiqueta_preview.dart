// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../data/local/repos/etiquetas_local_repo.dart';
import '../models/etiqueta_model.dart';
import './criar_etiqueta.dart';
import '../utils/etiqueta_qr.dart';
import '../utils/formatar_lote.dart';

class EtiquetaPreviewScreen extends StatelessWidget {
  final String uid;
  final String etiquetaId;

  const EtiquetaPreviewScreen({
    super.key,
    required this.uid,
    required this.etiquetaId,
  });

 
  static const _bg = Color(0xFFFDF7ED);
  static const _card = Colors.white;
  static const _text = Color(0xFF2B2B2B);
  static const _muted = Color(0xFF6B6B6B);

  void _openQrFullscreen(BuildContext context, String qrData) {
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
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            "QR Code",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: _text,
                            ),
                          ),
                          const SizedBox(height: 12),

                          
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final side = (constraints.maxWidth < constraints.maxHeight)
                                  ? constraints.maxWidth
                                  : constraints.maxHeight;

                              final qrSize = (side * 0.90).clamp(180.0, 900.0);

                              return SizedBox(
                                width: qrSize,
                                height: qrSize,
                                child: QrImageView(
                                  data: qrData,
                                  size: qrSize,
                                  padding: const EdgeInsets.all(6),
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 12),
                          Text(
                            "Aponte a câmera para abrir",
                            style: TextStyle(
                              fontSize: 12.5,
                              color: Colors.black.withOpacity(0.62),
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
                    icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
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
          child: ScaleTransition(scale: Tween(begin: 0.98, end: 1.0).animate(curved), child: child),
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
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (_) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          backgroundColor: Colors.white,
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
              const Expanded(
                child: Text(
                  "Excluir etiqueta?",
                  style: TextStyle(
                    color: _text,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            "Tem certeza que deseja excluir “$nome”?\nEssa ação não pode ser desfeita.",
            style: const TextStyle(color: _muted, height: 1.25),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              style: TextButton.styleFrom(
                foregroundColor: _text,
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

  @override
  Widget build(BuildContext context) {
    final repo = context.read<EtiquetasLocalRepo>();

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Preview da etiqueta",
          style: TextStyle(color: _text, fontWeight: FontWeight.w900),
        ),
        iconTheme: const IconThemeData(color: _text),
        actions: [
          FutureBuilder<EtiquetaModel?>(
            future: repo.getById(uid: uid, id: etiquetaId),
            builder: (context, snap) {
              final e = snap.data;
              if (e == null) return const SizedBox.shrink();

              return PopupMenuButton<String>(
                tooltip: "Opções",
                color: Colors.white,
                icon: const Icon(Icons.more_horiz_rounded, color: _text),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 6,
                onSelected: (v) async {
                  if (v == "edit") {
                    _openEdit(context, e);
                  } else if (v == "delete") {
                    final ok = await _confirmDelete(context, e.produtoNome);
                    if (!ok) return;

                    await repo.deleteSoft(uid, e.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text("Etiqueta excluída."),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
                      children: const [
                        Icon(Icons.edit_outlined, size: 20),
                        SizedBox(width: 10),
                        Text("Editar", style: TextStyle(fontWeight: FontWeight.w700)),
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
                        Text("Excluir", style: TextStyle(fontWeight: FontWeight.w800, color: Colors.red)),
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
                        color: _card,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.black.withOpacity(0.06)),
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
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                        color: _text,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      produtoNome,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: _text.withOpacity(0.75),
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

                          _linha("Categoria", categoriaNome),
                          _linha("Setor/Responsável", setorNome),
                          _linha("Fabricação", _fmtDate(fabricacao)),
                          _linhaColor("Validade", _fmtDate(validade), _validadeColor(validade)),
                          if (hasLote) ...[
                            _linha(loteLabel, loteFormatado!),
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
                                  const Icon(Icons.confirmation_number_outlined, size: 18, color: _text),
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
                                      style: const TextStyle(fontWeight: FontWeight.w900, color: _text),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(child: _metric("Quantidade", _fmtNum(qtd))),
                              const SizedBox(width: 10),
                              Expanded(child: _metric("Saídas", _fmtNum(saidas))),
                              const SizedBox(width: 10),
                              Expanded(child: _metric("Restante", _fmtNum(restanteView))),
                            ],
                          ),

                          if (customSemLote.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Divider(color: Colors.black.withOpacity(0.06), height: 1),
                            const SizedBox(height: 12),
                            const Text(
                              "Campos adicionais",
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: _text),
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

                              return _linha(label, texto);
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
                        color: _card,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.black.withOpacity(0.06)),
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
                              color: const Color(0xFFFAF7F1),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: Colors.black.withOpacity(0.06)),
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
                                      color: Colors.black.withOpacity(0.55),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "Escaneie para abrir e gerar PDF",
                            style: TextStyle(fontSize: 12.5, color: Colors.black.withOpacity(0.62)),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                   
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text("Em breve: imprimir / gerar PDF"),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                              );
                            },
                            icon: const Icon(Icons.print_outlined, color: Colors.black,),
                            label: const Text("Imprimir / PDF"),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              backgroundColor: const Color(0xff88be8e),
                              foregroundColor: Colors.black,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        foregroundColor: _text,
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


  Widget _linha(String label, String value) {
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
                color: Colors.black.withOpacity(0.52),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _text,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _linhaColor(String label, String value, Color color) {
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
                color: Colors.black.withOpacity(0.52),
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

  Widget _metric(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF7F1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.black.withOpacity(0.55),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: _text,
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