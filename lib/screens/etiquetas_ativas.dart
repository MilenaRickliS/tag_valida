// ignore_for_file: deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/tipo_etiqueta_provider.dart';
import '../models/tipo_etiqueta_model.dart';
import '../services/firestore_paths.dart';
import '../widgets/menu.dart';
import 'etiqueta_preview.dart';

class EtiquetasAtivasScreen extends StatefulWidget {
  const EtiquetasAtivasScreen({super.key});

  @override
  State<EtiquetasAtivasScreen> createState() => _EtiquetasAtivasScreenState();
}

class _EtiquetasAtivasScreenState extends State<EtiquetasAtivasScreen> {
  bool _loaded = false;
  String? _tipoSelecionadoId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;

    final uid = context.read<AuthProvider>().user?.uid;
    if (uid != null) {
      context.read<TiposEtiquetaProvider>().fetch(uid);
      _loaded = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final compact = w < 835;

    final uid = context.watch<AuthProvider>().user?.uid;
    if (uid == null) {
      return const Scaffold(body: Center(child: Text("Faça login novamente.")));
    }

    final tiposProv = context.watch<TiposEtiquetaProvider>();
    final tipos = tiposProv.items;

    if (_tipoSelecionadoId == null && tipos.isNotEmpty) {
      _tipoSelecionadoId = tipos.first.id;
    }

    final TipoEtiquetaModel? tipoAtual = (_tipoSelecionadoId == null)
        ? null
        : tipos.any((t) => t.id == _tipoSelecionadoId)
            ? tipos.firstWhere((t) => t.id == _tipoSelecionadoId)
            : null;

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
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        "Etiquetas ativas",
                        style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
                      ),
                    ),
                    IconButton(
                      tooltip: "Atualizar tipos",
                      onPressed: tiposProv.loading
                          ? null
                          : () => context.read<TiposEtiquetaProvider>().fetch(uid),
                      icon: tiposProv.loading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh),
                    )
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  "Clique em um tipo para ver as etiquetas ativas dele.",
                  style: TextStyle(color: Colors.black.withOpacity(0.60)),
                ),
                const SizedBox(height: 14),

                _TiposChips(
                  loading: tiposProv.loading,
                  tipos: tipos,
                  selectedId: _tipoSelecionadoId,
                  onSelected: (id) => setState(() => _tipoSelecionadoId = id),
                ),

                const SizedBox(height: 16),

                Expanded(
                  child: (_tipoSelecionadoId == null)
                      ? const _EmptyBox(
                          icon: Icons.label_outline,
                          title: "Nenhum tipo cadastrado",
                          subtitle: "Cadastre um tipo de etiqueta para começar.",
                        )
                      : _EtiquetasPorTipoList(
                          uid: uid,
                          tipoId: _tipoSelecionadoId!,
                          tipo: tipoAtual,
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TiposChips extends StatelessWidget {
  final bool loading;
  final List<TipoEtiquetaModel> tipos;
  final String? selectedId;
  final ValueChanged<String> onSelected;

  const _TiposChips({
    required this.loading,
    required this.tipos,
    required this.selectedId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (loading && tipos.isEmpty) {
      return const LinearProgressIndicator(minHeight: 3);
    }

    if (tipos.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFDF7ED),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black.withOpacity(0.10)),
        ),
        child: Text(
          "Nenhum tipo encontrado. Cadastre em “Tipos de etiqueta”.",
          style: TextStyle(color: Colors.black.withOpacity(0.60)),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: tipos.map((t) {
          final selected = t.id == selectedId;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: ChoiceChip(
              label: Text(t.nome),
              selected: selected,
              onSelected: (_) => onSelected(t.id),
              selectedColor: Colors.black,
              labelStyle: TextStyle(
                color: selected ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w700,
              ),
              backgroundColor: Colors.white,
              shape: StadiumBorder(
                side: BorderSide(color: Colors.black.withOpacity(0.12)),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _EtiquetasPorTipoList extends StatelessWidget {
  final String uid;
  final String tipoId;
  final TipoEtiquetaModel? tipo;

  const _EtiquetasPorTipoList({
    required this.uid,
    required this.tipoId,
    required this.tipo,
  });

  @override
  Widget build(BuildContext context) {
    final paths = context.read<FirestorePaths>();

    final query = paths
        .etiquetas(uid)
        .where("status", isEqualTo: "ativa")
        .where("tipoId", isEqualTo: tipoId)
        .orderBy("dataValidade");

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snap) {
        if (snap.hasError) {
          return _EmptyBox(
            icon: Icons.error_outline,
            title: "Erro ao carregar",
            subtitle: snap.error.toString(),
          );
        }

        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snap.data!.docs;
        if (docs.isEmpty) {
          return _EmptyBox(
            icon: Icons.inbox_outlined,
            title: "Nenhuma etiqueta ativa",
            subtitle: (tipo == null)
                ? "Não há etiquetas ativas para este tipo."
                : "Não há etiquetas ativas para “${tipo!.nome}”.",
          );
        }

        return ListView.separated(
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            final doc = docs[i];
            final d = doc.data() as Map<String, dynamic>;

            final produto = (d["produtoNome"] ?? "").toString();
            final categoria = (d["categoriaNome"] ?? "").toString();
            final setor = (d["setorNome"] ?? "").toString();

            final fab = _tsToDate(d["dataFabricacao"]);
            final val = _tsToDate(d["dataValidade"]);

            final now = DateTime.now();
            final vencida = (val != null) ? val.isBefore(DateTime(now.year, now.month, now.day)) : false;

           
            final alerta = (!vencida && val != null)
                ? val.difference(DateTime(now.year, now.month, now.day)).inDays <= 3
                : false;

            return Container(
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
                      color: vencida
                          ? Colors.red.withOpacity(0.12)
                          : alerta
                              ? Colors.orange.withOpacity(0.12)
                              : Colors.black.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      vencida
                          ? Icons.warning_amber_rounded
                          : alerta
                              ? Icons.notification_important_outlined
                              : Icons.local_offer_outlined,
                      color: vencida
                          ? Colors.red
                          : alerta
                              ? Colors.orange
                              : Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          produto.isEmpty ? "Sem nome" : produto,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          [
                            if (categoria.isNotEmpty) categoria,
                            if (setor.isNotEmpty) setor,
                          ].join(" • "),
                          style: TextStyle(color: Colors.black.withOpacity(0.60)),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 10,
                          runSpacing: 6,
                          children: [
                            _MiniPill(
                              icon: Icons.calendar_month_outlined,
                              text: "Fab: ${_fmtDate(fab)}",
                            ),
                            _MiniPill(
                              icon: Icons.event_available_outlined,
                              text: "Val: ${_fmtDate(val)}",
                              danger: vencida,
                              warn: alerta,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  IconButton(
                    tooltip: "Abrir",
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EtiquetaPreviewScreen(uid: uid, etiquetaId: doc.id),
                        ),
                      );
                    },
                    icon: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  DateTime? _tsToDate(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    return null;
  }

  String _fmtDate(DateTime? d) {
    if (d == null) return "--/--/----";
    final dd = d.day.toString().padLeft(2, "0");
    final mm = d.month.toString().padLeft(2, "0");
    final yy = d.year.toString();
    return "$dd/$mm/$yy";
  }
}

class _MiniPill extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool danger;
  final bool warn;

  const _MiniPill({
    required this.icon,
    required this.text,
    this.danger = false,
    this.warn = false,
  });

  @override
  Widget build(BuildContext context) {
    final border = danger
        ? Colors.red.withOpacity(0.30)
        : warn
            ? Colors.orange.withOpacity(0.30)
            : Colors.black.withOpacity(0.12);

    final bg = danger
        ? Colors.red.withOpacity(0.07)
        : warn
            ? Colors.orange.withOpacity(0.07)
            : Colors.black.withOpacity(0.04);

    final fg = danger
        ? Colors.red
        : warn
            ? Colors.orange
            : Colors.black87;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: fg),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(color: fg, fontWeight: FontWeight.w700)),
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

  const _EmptyBox.error(String subtitle, {super.key})
      : icon = Icons.error_outline,
        title = "Erro",
        subtitle = subtitle;

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
