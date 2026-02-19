// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../data/local/repos/etiquetas_local_repo.dart';
import '../models/etiqueta_model.dart';
import './criar_etiqueta.dart'; 

class EtiquetaPreviewScreen extends StatelessWidget {
  final String uid;
  final String etiquetaId;

  const EtiquetaPreviewScreen({
    super.key,
    required this.uid,
    required this.etiquetaId,
  });

  String _fmtNum(num v) {
    if (v % 1 == 0) return v.toInt().toString();
    return v.toStringAsFixed(2).replaceAll(".", ",");
  }

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
  

  String _fmtDate(DateTime d) => DateFormat("dd/MM/yyyy").format(d);

  Future<bool> _confirmDelete(BuildContext context, String nome) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Excluir etiqueta?"),
        content: Text("Tem certeza que deseja excluir “$nome”?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Excluir"),
          ),
        ],
      ),
    );
    return ok ?? false;
  }


  @override
  Widget build(BuildContext context) {
    final repo = context.read<EtiquetasLocalRepo>();

    return Scaffold(
      backgroundColor: const Color(0xFFFDF7ED),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDF7ED),
        elevation: 0,
        title: const Text("Preview da etiqueta"),
        centerTitle: true,
        actions: [
          FutureBuilder<EtiquetaModel?>(
            future: repo.getById(uid: uid, id: etiquetaId),
            builder: (context, snap) {
              final e = snap.data;
              if (e == null) return const SizedBox.shrink();

              return PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (v) async {
                  if (v == "edit") {
                    
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CriarEtiquetaScreen(
                          editarEtiquetaId: e.id,
                        ),
                      ),
                    );
                  }

                  if (v == "delete") {
                    final ok = await _confirmDelete(context, e.produtoNome);
                    if (!ok) return;

                    await repo.deleteSoft(uid, e.id); 
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Etiqueta excluída.")),
                      );
                      Navigator.pop(context);
                    }
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: "edit",
                    child: ListTile(
                      dense: true,
                      leading: Icon(Icons.edit_outlined),
                      title: Text("Editar"),
                    ),
                  ),
                  const PopupMenuItem(
                    value: "delete",
                    child: ListTile(
                      dense: true,
                      leading: Icon(Icons.delete_outline, color: Colors.red),
                      title: Text("Excluir"),
                    ),
                  ),
                ],
              );
            },
          ),
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

          final produtoNome = e.produtoNome;
          final categoriaNome = e.categoriaNome;
          final setorNome = e.setorNome;
          final tipoNome = e.tipoNome;
          final fabricacao = e.dataFabricacao;
          final validade = e.dataValidade;
          final qtd = e.quantidade;
          final rest = e.quantidadeRestante;
          final status = (e.statusEstoque.trim().isEmpty) ? "ativo" : e.statusEstoque.trim();

          final num saidas = status == "cancelado"
              ? qtd
              : ((qtd - rest) < 0 ? 0 : (qtd - rest));

          final num restanteView = status == "cancelado" ? 0 : rest;

          final custom = Map<String, dynamic>.from(e.camposCustomValores);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                    border: Border.all(color: Colors.black.withOpacity(0.07)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tipoNome,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 12),

                      _linha("Produto", produtoNome),
                      _linha("Categoria", categoriaNome),
                      _linha("Setor/Responsável", setorNome),
                      _linha("Fabricação", _fmtDate(fabricacao)),
                      _linha("Validade", _fmtDate(validade)),
                      _linha("Saídas", _fmtNum(saidas)),
                      _linha("Restante", _fmtNum(restanteView)),

                    
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 140,
                              child: Text(
                                "Status",
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.black.withOpacity(0.55),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: _statusColor(status).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(color: _statusColor(status).withOpacity(0.30)),
                              ),
                              child: Text(
                                _statusLabel(status),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: _statusColor(status),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                     
                      _linha("Quantidade", _fmtNum(qtd)),
                      _linha("Saídas", _fmtNum(saidas)),
                      _linha("Restante", _fmtNum(rest)),

                      if (custom.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Divider(color: Colors.black.withOpacity(0.08)),
                        const SizedBox(height: 10),
                        const Text(
                          "Campos adicionais",
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 10),

                        ...custom.entries.map((entry) {
                          
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

                      const SizedBox(height: 18),

                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Em breve: imprimir / gerar PDF")),
                                );
                              },
                              icon: const Icon(Icons.print_outlined),
                              label: const Text("Imprimir / PDF"),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                backgroundColor: const Color(0xFF2B2B2B),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      Center(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Voltar"),
                        ),
                      ),
                    ],
                  ),
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
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.black.withOpacity(0.55),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}