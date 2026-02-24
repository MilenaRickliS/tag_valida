// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/estoque_mov_local_provider.dart';
import '../models/estoque_mov_model.dart';
import '../models/estoque_mov_resumo.dart';
import '../widgets/menu.dart';
import '../widgets/estoque_footer.dart';

class HistoricoScreen extends StatefulWidget {
  const HistoricoScreen({super.key});

  @override
  State<HistoricoScreen> createState() => _HistoricoScreenState();
}

class _HistoricoScreenState extends State<HistoricoScreen> {
  final _qCtrl = TextEditingController();
  String _q = "";
  String? _tipoFiltro;

  DateTimeRange? _periodo;
  bool _showGraficos = false;

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

  Future<void> _pickPeriodo(BuildContext context) async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year - 5, 1, 1);
    final lastDate = DateTime(now.year + 1, 12, 31);

   
    final base = Theme.of(context);
    const seed = Color(0xFF2E7D32); 
    final themed = base.copyWith(
      dialogTheme: base.dialogTheme.copyWith(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      colorScheme: base.colorScheme.copyWith(
        primary: seed,
        onPrimary: Colors.white,
        surface: Colors.white,
        onSurface: Colors.black87,
      ),
      datePickerTheme: base.datePickerTheme.copyWith(
        backgroundColor: Colors.white,
        headerBackgroundColor: seed,
        headerForegroundColor: Colors.white,
        rangeSelectionBackgroundColor: seed.withOpacity(0.18),
        rangePickerBackgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );

    final picked = await showDateRangePicker(
      context: context,
      firstDate: firstDate,
      lastDate: lastDate,
      initialDateRange: _periodo ??
          DateTimeRange(
            start: DateTime(now.year, now.month, now.day - 7),
            end: now,
          ),
      helpText: "Selecionar período",
      builder: (ctx, child) {
        return Theme(data: themed, child: child ?? const SizedBox.shrink());
      },
    );

    if (picked != null) {
      setState(() => _periodo = picked);
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
                  Image.asset('assets/logo5.png', height: 78),
                  const SizedBox(height: 10),
                  const TopMenu(),
                ],
              )
            : Row(
                children: [
                  Image.asset('assets/logo5.png', height: 92),
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

            
              if (_periodo != null) {
                final start = DateTime(
                  _periodo!.start.year,
                  _periodo!.start.month,
                  _periodo!.start.day,
                  0,
                  0,
                  0,
                );
                final end = DateTime(
                  _periodo!.end.year,
                  _periodo!.end.month,
                  _periodo!.end.day,
                  23,
                  59,
                  59,
                );
                all = all.where((m) {
                  final d = m.createdAt;
                  return !d.isBefore(start) && !d.isAfter(end);
                }).toList();
              }

             
              if (_tipoFiltro != null) {
                all = all.where((m) => m.tipo == _tipoFiltro).toList();
              }

              
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
              final stats = _MovStats.fromMovs(all);

              return LayoutBuilder(
                builder: (context, constraints) {
                  final footerH = (resumo != null) ? 92.0 : 0.0;
                  final headerH = compact ? 86.0 : 78.0;
                  final filtersH = compact ? 160.0 : 86.0;

                 
                  final cardH = (constraints.maxHeight - headerH - filtersH - footerH - 24)
                      .clamp(320.0, 700.0);

                  return CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
                          child: _PageHeader(compact: compact),
                        ),
                      ),

                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
                          child: LayoutBuilder(
                            builder: (context, c) {
                              final isNarrow = c.maxWidth < 680;

                              final controls = <Widget>[
                                SizedBox(
                                  width: isNarrow ? c.maxWidth : 360,
                                  child: _SearchBox(controller: _qCtrl),
                                ),
                                _TipoDrop(
                                  value: _tipoFiltro,
                                  onChanged: (v) => setState(() => _tipoFiltro = v),
                                ),
                                _PeriodoButton(
                                  range: _periodo,
                                  onPick: () => _pickPeriodo(context),
                                  onClear: () => setState(() => _periodo = null),
                                ),
                                _ToggleViewButton(
                                  showGraficos: _showGraficos,
                                  onPressed: () => setState(() => _showGraficos = !_showGraficos),
                                ),
                              ];

                              return isNarrow
                                  ? Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        controls[0],
                                        const SizedBox(height: 10),
                                        Wrap(
                                          spacing: 10,
                                          runSpacing: 10,
                                          children: controls.sublist(1),
                                        ),
                                      ],
                                    )
                                  : Wrap(
                                      spacing: 10,
                                      runSpacing: 10,
                                      crossAxisAlignment: WrapCrossAlignment.center,
                                      children: controls,
                                    );
                            },
                          ),
                        ),
                      ),

                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          child: SizedBox(
                            height: cardH,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.75),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: Colors.black.withOpacity(0.08)),
                              ),
                              child: all.isEmpty
                                  ? const Center(child: Text("Nenhuma movimentação encontrada."))
                                  : AnimatedSwitcher(
                                      duration: const Duration(milliseconds: 220),
                                      child: _showGraficos
                                          ? _GraficosView(stats: stats)
                                          : _TabelaView(all: all),
                                    ),
                            ),
                          ),
                        ),
                      ),

                      if (resumo != null)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
                            child: EstoqueFooter(
                              entradas: resumo.entradas,
                              saidas: resumo.saidasVenda + resumo.saidasCancelamento,
                              total: resumo.saldo,
                            ),
                          ),
                        ),
                    ],
                  );
                },
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

class _PageHeader extends StatelessWidget {
  final bool compact;
  const _PageHeader({required this.compact});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Histórico",
                style: TextStyle(
                  fontSize: compact ? 22 : 26,
                  fontWeight: FontWeight.w900,
                  color: Colors.black.withOpacity(0.86),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Consulte todas as movimentações do estoque. Use filtros por período, tipo e busca para encontrar registros rapidamente.",
                style: TextStyle(
                  fontSize: compact ? 12.5 : 13.5,
                  height: 1.25,
                  color: Colors.black.withOpacity(0.55),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TabelaView extends StatelessWidget {
  final List<EstoqueMovModel> all;
  const _TabelaView({required this.all});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      key: const ValueKey("tabela"),
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
                DataCell(Text(_HistoricoScreenState._fmtDt(m.createdAt))),
                DataCell(_TipoChip(tipo: m.tipo)),
                DataCell(Text(m.produtoNome ?? "--")),
                DataCell(Text(_HistoricoScreenState._fmtNum(m.quantidade))),
                DataCell(Text(m.motivo ?? "")),
                DataCell(Text(m.etiquetaId)),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _GraficosView extends StatelessWidget {
  final _MovStats stats;
  const _GraficosView({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: const ValueKey("graficos"),
      padding: const EdgeInsets.all(14),
      child: LayoutBuilder(
        builder: (context, c) {
          final narrow = c.maxWidth < 860;

          final cards = <Widget>[
            _ChartCard(
              title: "Volume por tipo",
              subtitle: "Soma das quantidades por categoria.",
              child: _BarChart(
                items: stats.byTipo.entries
                    .map((e) => _BarItem(
                          label: e.key,
                          value: e.value,
                          color: _TipoColors.fg(e.key),
                        ))
                    .toList(),
              ),
            ),
            _ChartCard(
              title: "Movimentações por dia",
              subtitle: "Quantidade de registros por data.",
              child: _BarChart(
                items: stats.byDay.entries
                    .map((e) => _BarItem(
                          label: e.key,
                          value: e.value.toDouble(),
                         
                          color: Colors.black87,
                        ))
                    .toList(),
              ),
            ),
          ];

          if (narrow) {
            return ListView.separated(
              itemCount: cards.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) => cards[i],
            );
          }

          return Row(
            children: [
              Expanded(child: cards[0]),
              const SizedBox(width: 12),
              Expanded(child: cards[1]),
            ],
          );
        },
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _ChartCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 15,
              color: Colors.black.withOpacity(0.86),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12.5,
              color: Colors.black.withOpacity(0.55),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(height: 220, child: child),
        ],
      ),
    );
  }
}

class _BarItem {
  final String label;
  final double value;
  final Color color; 
  _BarItem({required this.label, required this.value, required this.color});
}

class _BarChart extends StatelessWidget {
  final List<_BarItem> items;
  const _BarChart({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Text(
          "Sem dados para o período/filtros.",
          style: TextStyle(color: Colors.black.withOpacity(0.55)),
        ),
      );
    }

    final maxV = items.map((e) => e.value).fold<double>(0, (a, b) => a > b ? a : b);
    final safeMax = maxV <= 0 ? 1.0 : maxV;

    return LayoutBuilder(
      builder: (context, c) {
        final barW = (c.maxWidth / items.length).clamp(34.0, 86.0);

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: barW * items.length,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: items.map((e) {
                final ratio = (e.value / safeMax).clamp(0.0, 1.0);
                final fill = e.color.withOpacity(0.18);
                final border = e.color.withOpacity(0.40);
                final labelColor = e.color.withOpacity(0.95);

                return SizedBox(
                  width: barW,
                  child: Column(
                    children: [
                      
                      SizedBox(
                        height: 18,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            e.value % 1 == 0
                                ? e.value.toInt().toString()
                                : e.value.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: Colors.black.withOpacity(0.70),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),

                     
                      Expanded(
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: FractionallySizedBox(
                            heightFactor: ratio,
                            widthFactor: 0.62,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: fill,
                                border: Border.all(color: border),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                  
                      SizedBox(
                        height: 32,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Text(
                            e.label,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: labelColor,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }
}

class _MovStats {
  final Map<String, double> byTipo; 
  final Map<String, int> byDay;

  _MovStats({required this.byTipo, required this.byDay});

  static _MovStats fromMovs(List<EstoqueMovModel> all) {
    final tipo = <String, double>{};
    final day = <String, int>{};

    String two(int v) => v.toString().padLeft(2, '0');
    String dayKey(DateTime d) => "${two(d.day)}/${two(d.month)}";

    for (final m in all) {
      tipo[m.tipo] = (tipo[m.tipo] ?? 0) + (m.quantidade.toDouble());
      final k = dayKey(m.createdAt);
      day[k] = (day[k] ?? 0) + 1;
    }

    final sortedDayKeys = day.keys.toList()
      ..sort((a, b) {
        int toNum(String s) {
          final parts = s.split('/');
          final dd = int.tryParse(parts[0]) ?? 0;
          final mm = int.tryParse(parts[1]) ?? 0;
          return mm * 100 + dd;
        }

        return toNum(a).compareTo(toNum(b));
      });

    final daySorted = <String, int>{};
    for (final k in sortedDayKeys) {
      daySorted[k] = day[k]!;
    }

    final tipoKeys = tipo.keys.toList()
      ..sort((a, b) => (tipo[b] ?? 0).compareTo(tipo[a] ?? 0));
    final tipoSorted = <String, double>{};
    for (final k in tipoKeys) {
      tipoSorted[k] = tipo[k]!;
    }

    return _MovStats(byTipo: tipoSorted, byDay: daySorted);
  }
}

class _ToggleViewButton extends StatelessWidget {
  final bool showGraficos;
  final VoidCallback onPressed;

  const _ToggleViewButton({
    required this.showGraficos,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.black.withOpacity(0.86),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 0,
      ),
      onPressed: onPressed,
      icon: Icon(
        showGraficos ? Icons.table_rows_rounded : Icons.bar_chart_rounded,
        color: Colors.white,
      ),
      label: Text(
        showGraficos ? "Ver tabela" : "Ver gráficos",
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _PeriodoButton extends StatelessWidget {
  final DateTimeRange? range;
  final VoidCallback onPick;
  final VoidCallback onClear;

  const _PeriodoButton({
    required this.range,
    required this.onPick,
    required this.onClear,
  });

  String _fmt(DateTime d) {
    String two(int v) => v.toString().padLeft(2, '0');
    return "${two(d.day)}/${two(d.month)}/${d.year}";
  }

  @override
  Widget build(BuildContext context) {
    final has = range != null;
    final text = has ? "${_fmt(range!.start)} • ${_fmt(range!.end)}" : "Período";

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.date_range_rounded, color: Colors.black.withOpacity(0.55)),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: Colors.black.withOpacity(0.78),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: onPick,
            style: TextButton.styleFrom(
              foregroundColor: const Color.fromARGB(255, 38, 116, 28),
              textStyle: const TextStyle(fontWeight: FontWeight.w900),
            ),
            child: const Text("Selecionar"),
          ),
          if (has)
            IconButton(
              tooltip: "Limpar período",
              onPressed: onClear,
              icon: const Icon(Icons.close_rounded),
            ),
        ],
      ),
    );
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
          ),
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
            DropdownMenuItem(value: EstoqueMovModel.tipoExclusao, child: Text("Exclusão")),
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
    final fg = _TipoColors.fg(tipo);
    final bg = _TipoColors.bg(tipo);

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


class _TipoColors {
  static Color fg(String tipo) {
    switch (tipo) {
      case EstoqueMovModel.tipoEntrada:
        return Colors.green.shade800;
      case EstoqueMovModel.tipoVenda:
        return Colors.orange.shade800;
      case EstoqueMovModel.tipoCancelamento:
        return Colors.red.shade800;
      case EstoqueMovModel.tipoAjusteEntrada:
        return Colors.blue.shade800;
      case EstoqueMovModel.tipoAjusteSaida:
        return Colors.purple.shade800;
      case EstoqueMovModel.tipoExclusao:
        return Colors.red.shade900;
      default:
        return Colors.black87;
    }
  }

  static Color bg(String tipo) {
    switch (tipo) {
      case EstoqueMovModel.tipoEntrada:
        return Colors.green.withOpacity(0.10);
      case EstoqueMovModel.tipoVenda:
        return Colors.orange.withOpacity(0.10);
      case EstoqueMovModel.tipoCancelamento:
        return Colors.red.withOpacity(0.10);
      case EstoqueMovModel.tipoAjusteEntrada:
        return Colors.blue.withOpacity(0.10);
      case EstoqueMovModel.tipoAjusteSaida:
        return Colors.purple.withOpacity(0.10);
      case EstoqueMovModel.tipoExclusao:
        return Colors.red.withOpacity(0.08);
      default:
        return Colors.black.withOpacity(0.06);
    }
  }
}