// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../data/local/repos/etiquetas_local_repo.dart';
import '../models/etiqueta_model.dart';
import '../widgets/menu.dart';
import '../screens/etiqueta_preview.dart';


class EtiquetasFinalizadasScreen extends StatefulWidget {
  const EtiquetasFinalizadasScreen({super.key});

  @override
  State<EtiquetasFinalizadasScreen> createState() => _EtiquetasFinalizadasScreenState();
}

class _EtiquetasFinalizadasScreenState extends State<EtiquetasFinalizadasScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  final _searchCtrl = TextEditingController();
  String _q = "";

  bool _loadedArgs = false;
  String? _initialTab; 

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _searchCtrl.addListener(() => setState(() => _q = _searchCtrl.text));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loadedArgs) return;

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      _initialTab = args["tab"]?.toString(); 
    }


    final idx = switch (_initialTab) {
      "vendido" => 0,
      "cancelado" => 1,
      "todas" => 2,
      _ => 0,
    };
    _tabCtrl.index = idx;

    _loadedArgs = true;
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _searchCtrl.dispose();
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

    return Scaffold(
      backgroundColor: const Color(0xFFFDF7ED),

      appBar: AppBar(
        backgroundColor: const Color(0xFFFDF7ED),
        elevation: 0,
        centerTitle: true,
        toolbarHeight: compact ? 120 : 92,
        title: compact
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset('assets/logo5.png', height: 64),
                  const SizedBox(height: 8),
                  const TopMenu(),
                ],
              )
            : Row(
                children: [
                  Image.asset('assets/logo5.png', height: 72),
                  const Spacer(),
                  const TopMenu(),
                ],
              ),
      ),

      body: SafeArea(
        top: false, 
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                 
                  const _HeaderTitle(),
                  const SizedBox(height: 12),

                
                  _SearchBox(
                    controller: _searchCtrl,
                    onClear: () => _searchCtrl.clear(),
                  ),
                  const SizedBox(height: 12),

                
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: Colors.black.withOpacity(0.10)),
                    ),
                    child: TabBar(
                      controller: _tabCtrl,
                      indicator: BoxDecoration(
                        color: const Color(0xff428e2e),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.black.withOpacity(0.75),
                      labelStyle: const TextStyle(fontWeight: FontWeight.w900),
                      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w900),
                      dividerColor: Colors.transparent,
                      tabs: const [
                        Tab(text: "Vendidas"),
                        Tab(text: "Canceladas"),
                        Tab(text: "Todas"),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                 
                  Expanded(
                    child: TabBarView(
                      controller: _tabCtrl,
                      children: [
                        _FinalizadasList(
                          uid: uid,
                          statusEstoqueFilter: "vendido",
                          query: _q,
                        ),
                        _FinalizadasList(
                          uid: uid,
                          statusEstoqueFilter: "cancelado",
                          query: _q,
                        ),
                        _FinalizadasList(
                          uid: uid,
                          statusEstoqueFilter: null,
                          query: _q,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderTitle extends StatelessWidget {
  const _HeaderTitle();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Etiquetas finalizadas",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 3),
          Text(
            "Vendidas e canceladas (arquivo). Abra para ver o preview ou reativar.",
            style: TextStyle(color: Colors.black.withOpacity(0.60), fontSize: 12.8),
          ),
        ],
      ),
    );
  }
}

class _FinalizadasList extends StatelessWidget {
  final String uid;
  final String? statusEstoqueFilter; 
  final String query;

  const _FinalizadasList({
    required this.uid,
    required this.statusEstoqueFilter,
    required this.query,
  });

  @override
  Widget build(BuildContext context) {
    final repo = context.read<EtiquetasLocalRepo>();

    return FutureBuilder<List<EtiquetaModel>>(
      future: repo.listByPeriodo(
        uid: uid,
        inicio: DateTime(2000, 1, 1),
        fim: DateTime(2100, 1, 1),
        status: "ativa",  
        tipoId: null,
      ),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return _EmptyBox(
            icon: Icons.error_outline,
            title: "Erro ao carregar",
            subtitle: snap.error.toString(),
          );
        }

        var all = snap.data ?? [];

       
        all = all.where((e) {
          final st = (e.statusEstoque.trim().isEmpty) ? "ativo" : e.statusEstoque.trim().toLowerCase();
          final isFinal = st == "vendido" || st == "cancelado";
          if (!isFinal) return false;

          if (statusEstoqueFilter != null && st != statusEstoqueFilter) return false;

          final q = query.trim().toLowerCase();
          if (q.isNotEmpty) {
            final s = [
              e.produtoNome,
              e.categoriaNome,
              e.setorNome,
              e.tipoNome,
              e.id,
              st,
            ].join(" ").toLowerCase();
            if (!s.contains(q)) return false;
          }
          return true;
        }).toList();

        
        DateTime sortKey(EtiquetaModel e) {
          return e.soldAt ??
              e.createdAt ??
              DateTime.fromMillisecondsSinceEpoch(int.tryParse(e.id) ?? 0);
        }

        all.sort((a, b) => sortKey(b).compareTo(sortKey(a)));

        if (all.isEmpty) {
          return const _EmptyBox(
            icon: Icons.inventory_2_outlined,
            title: "Nada por aqui",
            subtitle: "Não há etiquetas finalizadas nesse filtro.",
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 14),
          itemCount: all.length,
          itemBuilder: (_, i) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _EtiquetaFinalizadaCard(uid: uid, e: all[i]),
          ),
        );
      },
    );
  }
}

class _EtiquetaFinalizadaCard extends StatelessWidget {
  final String uid;
  final EtiquetaModel e;

  const _EtiquetaFinalizadaCard({
    required this.uid,
    required this.e,
  });

  @override
  Widget build(BuildContext context) {
    final produto = e.produtoNome.trim().isEmpty ? "Sem nome" : e.produtoNome;
    final setor = e.setorNome.trim();
    final categoria = e.categoriaNome.trim();

    final st = (e.statusEstoque.trim().isEmpty) ? "ativo" : e.statusEstoque.trim().toLowerCase();
    final isVendido = st == "vendido";
    final isCancelado = st == "cancelado";

    final badgeBg = isVendido
        ? Colors.orange.withOpacity(0.12)
        : isCancelado
            ? Colors.red.withOpacity(0.10)
            : Colors.black.withOpacity(0.06);

    final badgeFg = isVendido
        ? Colors.orange.shade900
        : isCancelado
            ? Colors.red.shade800
            : Colors.black87;

    String badgeText() => isVendido ? "Vendido" : "Cancelado";

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => EtiquetaPreviewScreen(uid: uid, etiquetaId: e.id)),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black.withOpacity(0.07)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 6),
            )
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: badgeBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: badgeFg.withOpacity(0.18)),
              ),
              child: Icon(
                isVendido ? Icons.local_mall_outlined : Icons.block_outlined,
                color: badgeFg,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          produto,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                        ),
                      ),
                      const SizedBox(width: 10),
                      _MiniBadge(text: badgeText(), fg: badgeFg, bg: badgeBg),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    [
                      if (e.tipoNome.trim().isNotEmpty) e.tipoNome.trim(),
                      if (categoria.isNotEmpty) categoria,
                      if (setor.isNotEmpty) setor,
                    ].join(" • "),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.black.withOpacity(0.60)),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      _Pill(icon: Icons.numbers_outlined, text: "Qtd: ${_fmtNum(e.quantidade)}"),
                      _Pill(icon: Icons.inventory_2_outlined, text: "Rest: ${_fmtNum(e.quantidadeRestante)}"),
                      _Pill(icon: Icons.event_available_outlined, text: "Val: ${_fmtDate(e.dataValidade)}"),
                      if (e.soldAt != null)
                        _Pill(icon: Icons.schedule_rounded, text: "Final: ${_fmtDt(e.soldAt!)}"),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                     
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                           
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Reabrir no estoque (implementar)")),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff428e2e),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                          ),
                          icon: const Icon(Icons.restart_alt_rounded, size: 18, color: Colors.white,),
                          label: const Text("Reabrir", style: TextStyle(fontWeight: FontWeight.w900)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _fmtDate(DateTime? d) {
    if (d == null) return "--/--/----";
    final dd = d.day.toString().padLeft(2, "0");
    final mm = d.month.toString().padLeft(2, "0");
    final yy = d.year.toString();
    return "$dd/$mm/$yy";
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

class _MiniBadge extends StatelessWidget {
  final String text;
  final Color fg;
  final Color bg;

  const _MiniBadge({
    required this.text,
    required this.fg,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: fg.withOpacity(0.20)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w900,
          color: fg,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Pill({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.04),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.black.withOpacity(0.10)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.black.withOpacity(0.70)),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: Colors.black.withOpacity(0.80),
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchBox extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onClear;

  const _SearchBox({
    required this.controller,
    required this.onClear,
  });

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
                hintText: "Buscar por produto, setor, categoria, tipo...",
                border: InputBorder.none,
                isDense: true,
                hintStyle: TextStyle(color: Colors.black.withOpacity(0.45)),
              ),
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 160),
            child: (controller.text.trim().isNotEmpty)
                ? IconButton(
                    key: const ValueKey("clear"),
                    tooltip: "Limpar",
                    onPressed: onClear,
                    icon: const Icon(Icons.close_rounded),
                  )
                : const SizedBox(key: ValueKey("noClear"), width: 0, height: 0),
          ),
        ],
      ),
    );
  }
}

class _EmptyBox extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyBox({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withOpacity(0.07)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 42, color: Colors.black.withOpacity(0.75)),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black.withOpacity(0.60)),
          ),
        ],
      ),
    );
  }
}