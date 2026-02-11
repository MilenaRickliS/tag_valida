// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../data/local/repos/etiquetas_local_repo.dart';
import '../models/etiqueta_model.dart';

class EtiquetaPreviewScreen extends StatelessWidget {
  final String uid;
  final String etiquetaId;

  const EtiquetaPreviewScreen({
    super.key,
    required this.uid,
    required this.etiquetaId,
  });

  String _fmtDate(DateTime d) => DateFormat("dd/MM/yyyy").format(d);

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