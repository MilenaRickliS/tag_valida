// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/estoque_mov_local_provider.dart';
import '../models/estoque_mov_model.dart';
import '../widgets/menu.dart';
import '../widgets/estoque_footer.dart';
import '../models/estoque_mov_resumo.dart';

class HistoricoScreen extends StatefulWidget {
  const HistoricoScreen({super.key});

  @override
  State<HistoricoScreen> createState() => _HistoricoScreenState();
}

class _HistoricoScreenState extends State<HistoricoScreen> {
  final _qCtrl = TextEditingController();
  String _q = "";
  String? _tipoFiltro; 

  @override
  void initState() {
    super.initState();
    _qCtrl.addListener(() => setState(() => _q = _qCtrl.text));
  }

  @override
  void dispose() {
    _qCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final compact = w < 835;

    final uid = context.watch<AuthProvider>().user?.uid;
    if (uid == null) {
      return const Scaffold(body: Center(child: Text("Faça login novamente.")));
    }

    final movProv = context.read<EstoqueMovLocalProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFFDF7ED),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDF7ED),
        elevation: 0,
        toolbarHeight: compact ? 160 : 100,
        centerTitle: true,
        title: compact
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset('assets/logo1.png', height: 78),
                  const SizedBox(height: 10),
                  const TopMenu(),
                ],
              )
            : Row(
                children: [
                  Image.asset('assets/logo1.png', height: 92),
                  const Spacer(),
                  const TopMenu(),
                ],
              ),
      ),
      body: FutureBuilder<EstoqueMovResumo>(
        future: movProv.resumo(uid: uid),
        builder: (context, resumoSnap) {
          return FutureBuilder<List<EstoqueMovModel>>(
            future: movProv.listAll(uid: uid),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snap.hasError) {
                return Center(child: Text("Erro: ${snap.error}"));
              }

              var all = snap.data ?? [];
              all.sort((a, b) => b.createdAt.compareTo(a.createdAt));

              // filtro por tipo
              if (_tipoFiltro != null) {
                all = all.where((m) => m.tipo == _tipoFiltro).toList();
              }

              // filtro por busca (motivo / produtoNome / etiquetaId)
              final q = _q.trim().toLowerCase();
              if (q.isNotEmpty) {
                all = all.where((m) {
                  final s = [
                    m.motivo ?? "",
                    m.produtoNome ?? "",
                    m.etiquetaId,
                    m.tipo,
                  ].join(" ").toLowerCase();
                  return s.contains(q);
                }).toList();
              }

              final resumo = resumoSnap.data;

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: _SearchBox(controller: _qCtrl),
                        ),
                        const SizedBox(width: 10),
                        _TipoDrop(
                          value: _tipoFiltro,
                          onChanged: (v) => setState(() => _tipoFiltro = v),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.75),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Colors.black.withOpacity(0.08)),
                        ),
                        child: all.isEmpty
                            ? const Center(child: Text("Nenhuma movimentação encontrada."))
                            : SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: SingleChildScrollView(
                                  child: DataTable(
                                    headingRowHeight: 44,
                                    dataRowMinHeight: 44,
                                    dataRowMaxHeight: 56,
                                    columns: const [
                                      DataColumn(label: Text("Data")),
                                      DataColumn(label: Text("Tipo")),
                                      DataColumn(label: Text("Produto")),
                                      DataColumn(label: Text("Qtd")),
                                      DataColumn(label: Text("Motivo")),
                                      DataColumn(label: Text("EtiquetaId")),
                                    ],
                                    rows: all.map((m) {
                                      return DataRow(
                                        cells: [
                                          DataCell(Text(_fmtDt(m.createdAt))),
                                          DataCell(_TipoChip(tipo: m.tipo)),
                                          DataCell(Text(m.produtoNome ?? "--")),
                                          DataCell(Text(_fmtNum(m.quantidade))),
                                          DataCell(Text(m.motivo ?? "")),
                                          DataCell(Text(m.etiquetaId)),
                                        ],
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                      ),
                    ),
                  ),

        
                  if (resumo != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
                      child: EstoqueFooter(
                        entradas: resumo.entradas,
                        saidas: resumo.saidasVenda + resumo.saidasCancelamento,
                        total: resumo.saldo, 
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  static String _fmtDt(DateTime d) {
    String two(int v) => v.toString().padLeft(2, '0');
    return "${two(d.day)}/${two(d.month)}/${d.year} ${two(d.hour)}:${two(d.minute)}";
  }

  static String _fmtNum(num v) {
    if (v == v.roundToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(2).replaceAll(".", ",");
  }
}

class _SearchBox extends StatelessWidget {
  final TextEditingController controller;
  const _SearchBox({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.search, color: Colors.black.withOpacity(0.55)),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: "Buscar por produto, motivo, etiqueta...",
                border: InputBorder.none,
                isDense: true,
                hintStyle: TextStyle(color: Colors.black.withOpacity(0.45)),
              ),
            ),
          ),
          IconButton(
            tooltip: "Limpar",
            onPressed: () => controller.clear(),
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }
}

class _TipoDrop extends StatelessWidget {
  final String? value;
  final ValueChanged<String?> onChanged;

  const _TipoDrop({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.08)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: value,
          hint: const Text("Tipo"),
          items: const [
            DropdownMenuItem(value: null, child: Text("Todos")),
            DropdownMenuItem(value: EstoqueMovModel.tipoEntrada, child: Text("Entrada")),
            DropdownMenuItem(value: EstoqueMovModel.tipoVenda, child: Text("Venda")),
            DropdownMenuItem(value: EstoqueMovModel.tipoCancelamento, child: Text("Cancelamento")),
            DropdownMenuItem(value: EstoqueMovModel.tipoAjusteEntrada, child: Text("Ajuste +")),
            DropdownMenuItem(value: EstoqueMovModel.tipoAjusteSaida, child: Text("Ajuste -")),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _TipoChip extends StatelessWidget {
  final String tipo;
  const _TipoChip({required this.tipo});

  @override
  Widget build(BuildContext context) {
    Color fg;
    Color bg;
    switch (tipo) {
      case EstoqueMovModel.tipoEntrada:
        fg = Colors.green.shade800;
        bg = Colors.green.withOpacity(0.10);
        break;
      case EstoqueMovModel.tipoVenda:
        fg = Colors.orange.shade800;
        bg = Colors.orange.withOpacity(0.10);
        break;
      case EstoqueMovModel.tipoCancelamento:
        fg = Colors.red.shade800;
        bg = Colors.red.withOpacity(0.10);
        break;
      case EstoqueMovModel.tipoAjusteEntrada:
        fg = Colors.blue.shade800;
        bg = Colors.blue.withOpacity(0.10);
        break;
      case EstoqueMovModel.tipoAjusteSaida:
        fg = Colors.purple.shade800;
        bg = Colors.purple.withOpacity(0.10);
        break;
      default:
        fg = Colors.black87;
        bg = Colors.black.withOpacity(0.06);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: fg.withOpacity(0.25)),
      ),
      child: Text(
        tipo,
        style: TextStyle(fontWeight: FontWeight.w900, color: fg, fontSize: 12),
      ),
    );
  }
}