// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/estoque_mov_local_provider.dart';
import '../models/estoque_mov_model.dart';
import '../models/estoque_mov_resumo.dart';
import '../widgets/menu.dart';
import '../widgets/estoque_footer.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

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

  bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  Color _bg(BuildContext context) =>
      _isDark(context) ? const Color(0xFF0F0F0F) : const Color(0xFFFDF7ED);

  Color _cardAlt(BuildContext context) =>
      _isDark(context) ? const Color(0xFF181818) : Colors.white.withOpacity(0.75);

  Color _muted(BuildContext context) =>
      _isDark(context) ? const Color(0xFFD6D6D6) : Colors.black.withOpacity(0.55);

  Color _border(BuildContext context) => _isDark(context)
      ? const Color(0xFFD4AF37).withOpacity(0.16)
      : Colors.black.withOpacity(0.08);

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
    final isDark = _isDark(context);

    final base = Theme.of(context);
    final seed = isDark ? const Color(0xFFD4AF37) : const Color(0xFF2E7D32);

    final themed = base.copyWith(
      dialogTheme: base.dialogTheme.copyWith(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      colorScheme: base.colorScheme.copyWith(
        primary: seed,
        onPrimary: isDark ? Colors.black : Colors.white,
        surface: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        onSurface: isDark ? Colors.white : Colors.black87,
      ),
      datePickerTheme: base.datePickerTheme.copyWith(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        headerBackgroundColor: seed,
        headerForegroundColor: isDark ? Colors.black : Colors.white,
        rangeSelectionBackgroundColor: seed.withOpacity(0.18),
        rangePickerBackgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
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

  Future<void> _exportPdf(
    BuildContext context, {
    required List<EstoqueMovModel> all,
    required _MovStats stats,
    required DateTimeRange? periodo,
    required String? tipo,
    required String query,
  }) async {
    final doc = pw.Document();

    final filtroPeriodo = (periodo == null)
        ? "Período: Todos"
        : "Período: ${_fmtDateOnly(periodo.start)} a ${_fmtDateOnly(periodo.end)}";
    final filtroTipo = "Tipo: ${tipo ?? "Todos"}";
    final filtroBusca = "Busca: ${query.trim().isEmpty ? "—" : query.trim()}";

    final tableData = <List<String>>[
      ["Data", "Tipo", "Produto", "Qtd", "Motivo", "EtiquetaId"],
      ...all.map((m) {
        return [
          _fmtDt(m.createdAt),
          m.tipo,
          (m.produtoNome ?? "--"),
          _fmtNum(m.quantidade),
          (m.motivo ?? ""),
          m.etiquetaId,
        ];
      }),
    ];

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(28, 28, 28, 28),
        build: (ctx) => [
          pw.Text(
            "Histórico - Movimentações do Estoque",
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            "Relatório gerado conforme filtros aplicados na tela.",
            style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 10),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromInt(0xFFF5F5F5),
              borderRadius: pw.BorderRadius.circular(10),
              border: pw.Border.all(color: PdfColors.grey300),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(filtroPeriodo, style: const pw.TextStyle(fontSize: 10)),
                pw.SizedBox(height: 2),
                pw.Text(filtroTipo, style: const pw.TextStyle(fontSize: 10)),
                pw.SizedBox(height: 2),
                pw.Text(filtroBusca, style: const pw.TextStyle(fontSize: 10)),
                pw.SizedBox(height: 6),
                pw.Text(
                  "Total de registros: ${all.length}",
                  style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 14),
          pw.Text(
            "Gráficos",
            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          _pdfChartCard(
            title: "Volume por tipo",
            subtitle: "Soma das quantidades por categoria.",
            child: _pdfBars(
              items: stats.byTipo.entries.map((e) {
                return _PdfBarItem(
                  label: e.key,
                  value: e.value,
                  color: _TipoColorsPdf.fg(e.key),
                );
              }).toList(),
            ),
          ),
          pw.SizedBox(height: 10),
          _pdfChartCard(
            title: "Movimentações por dia",
            subtitle: "Quantidade de registros por data.",
            child: _pdfBars(
              items: stats.byDay.entries.map((e) {
                return _PdfBarItem(
                  label: e.key,
                  value: e.value.toDouble(),
                  color: PdfColors.grey700,
                );
              }).toList(),
            ),
          ),
          pw.SizedBox(height: 16),
          pw.Text(
            "Dados",
            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Table.fromTextArray(
            data: tableData,
            headerStyle: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headerDecoration: pw.BoxDecoration(
              color: PdfColor.fromInt(0xFF2E2E2E),
            ),
            cellStyle: const pw.TextStyle(fontSize: 8),
            cellAlignment: pw.Alignment.centerLeft,
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            border: pw.TableBorder.all(color: PdfColors.grey300),
            columnWidths: {
              0: const pw.FlexColumnWidth(1.2),
              1: const pw.FlexColumnWidth(1.0),
              2: const pw.FlexColumnWidth(1.8),
              3: const pw.FlexColumnWidth(0.7),
              4: const pw.FlexColumnWidth(1.6),
              5: const pw.FlexColumnWidth(1.2),
            },
          ),
        ],
        footer: (ctx) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            "Página ${ctx.pageNumber} de ${ctx.pagesCount}",
            style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
        ),
      ),
    );

    final bytes = await doc.save();
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }

  static String _fmtDateOnly(DateTime d) {
    String two(int v) => v.toString().padLeft(2, '0');
    return "${two(d.day)}/${two(d.month)}/${d.year}";
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
      backgroundColor: _bg(context),
      appBar: AppBar(
        backgroundColor: _bg(context),
        elevation: 0,
        toolbarHeight: compact ? 160 : 100,
        centerTitle: true,
        title: compact
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset('assets/logo6.png', height: 78),
                  const SizedBox(height: 10),
                  const TopMenu(),
                ],
              )
            : Row(
                children: [
                  Image.asset('assets/logo6.png', height: 92),
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
                                _PdfButton(
                                  onPressed: () async {
                                    await _exportPdf(
                                      context,
                                      all: all,
                                      stats: stats,
                                      periodo: _periodo,
                                      tipo: _tipoFiltro,
                                      query: _q,
                                    );
                                  },
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
                                color: _cardAlt(context),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: _border(context)),
                              ),
                              child: all.isEmpty
                                  ? Center(
                                      child: Text(
                                        "Nenhuma movimentação encontrada.",
                                        style: TextStyle(color: _muted(context)),
                                      ),
                                    )
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

  bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  @override
  Widget build(BuildContext context) {
    final text = _isDark(context) ? Colors.white : Colors.black.withOpacity(0.86);
    final muted =
        _isDark(context) ? const Color(0xFFD6D6D6) : Colors.black.withOpacity(0.55);

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
                  color: text,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Consulte todas as movimentações do estoque. Use filtros por período, tipo e busca para encontrar registros rapidamente.",
                style: TextStyle(
                  fontSize: compact ? 12.5 : 13.5,
                  height: 1.25,
                  color: muted,
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

  bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  @override
  Widget build(BuildContext context) {
    final text = _isDark(context) ? Colors.white : Colors.black87;
    final headingBg =
        _isDark(context) ? const Color(0xFF181818) : const Color(0xFFF5F5F5);

    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: _isDark(context)
            ? const Color(0xFFD4AF37).withOpacity(0.08)
            : Colors.black.withOpacity(0.08),
      ),
      child: SingleChildScrollView(
        key: const ValueKey("tabela"),
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: DataTable(
            headingRowColor: WidgetStatePropertyAll(headingBg),
            headingTextStyle: TextStyle(
              color: text,
              fontWeight: FontWeight.w900,
            ),
            dataTextStyle: TextStyle(
              color: text,
              fontWeight: FontWeight.w600,
            ),
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
                          color: Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFFD4AF37)
                              : Colors.black87,
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

  bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  @override
  Widget build(BuildContext context) {
    final text = _isDark(context) ? Colors.white : Colors.black.withOpacity(0.86);
    final muted =
        _isDark(context) ? const Color(0xFFD6D6D6) : Colors.black.withOpacity(0.55);
    final border = _isDark(context)
        ? const Color(0xFFD4AF37).withOpacity(0.16)
        : Colors.black.withOpacity(0.08);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: _isDark(context) ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(_isDark(context) ? 0.16 : 0.04),
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
              color: text,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12.5,
              color: muted,
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

  bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  @override
  Widget build(BuildContext context) {
    final muted =
        _isDark(context) ? const Color(0xFFD6D6D6) : Colors.black.withOpacity(0.55);

    if (items.isEmpty) {
      return Center(
        child: Text(
          "Sem dados para o período/filtros.",
          style: TextStyle(color: muted),
        ),
      );
    }

    final maxV =
        items.map((e) => e.value).fold<double>(0, (a, b) => a > b ? a : b);
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
                              color: _isDark(context)
                                  ? Colors.white70
                                  : Colors.black.withOpacity(0.70),
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
        backgroundColor: Color(0xFFED7227),
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 0,
      ),
      onPressed: onPressed,
      icon: Icon(
        showGraficos ? Icons.table_rows_rounded : Icons.bar_chart_rounded, color: Colors.black,
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

  bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  @override
  Widget build(BuildContext context) {
    final has = range != null;
    final text = has ? "${_fmt(range!.start)} • ${_fmt(range!.end)}" : "Período";
    final border = _isDark(context)
        ? const Color(0xFFD4AF37).withOpacity(0.16)
        : Colors.black.withOpacity(0.08);
    final fg = _isDark(context) ? Colors.white : Colors.black.withOpacity(0.78);
    final icon = _isDark(context) ? const Color(0xFFD4AF37) : Colors.black.withOpacity(0.55);
    final buttonColor =
        _isDark(context) ? const Color(0xFFD4AF37) : const Color.fromARGB(255, 38, 116, 28);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: _isDark(context) ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(_isDark(context) ? 0.14 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.date_range_rounded, color: icon),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: fg,
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: onPick,
            style: TextButton.styleFrom(
              foregroundColor: buttonColor,
              textStyle: const TextStyle(fontWeight: FontWeight.w900),
            ),
            child: const Text("Selecionar"),
          ),
          if (has)
            IconButton(
              tooltip: "Limpar período",
              onPressed: onClear,
              icon: Icon(
                Icons.close_rounded,
                color: _isDark(context) ? Colors.white70 : Colors.black87,
              ),
            ),
        ],
      ),
    );
  }
}

class _SearchBox extends StatelessWidget {
  final TextEditingController controller;
  const _SearchBox({required this.controller});

  bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  @override
  Widget build(BuildContext context) {
    final border = _isDark(context)
        ? const Color(0xFFD4AF37).withOpacity(0.16)
        : Colors.black.withOpacity(0.08);
    final hint =
        _isDark(context) ? const Color(0xFFD6D6D6) : Colors.black.withOpacity(0.45);
    final icon =
        _isDark(context) ? const Color(0xFFD4AF37) : Colors.black.withOpacity(0.55);
    final text = _isDark(context) ? Colors.white : Colors.black87;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _isDark(context) ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(_isDark(context) ? 0.14 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.search, color: icon),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              style: TextStyle(color: text),
              decoration: InputDecoration(
                hintText: "Buscar por produto, motivo, etiqueta...",
                border: InputBorder.none,
                isDense: true,
                hintStyle: TextStyle(color: hint),
              ),
            ),
          ),
          IconButton(
            tooltip: "Limpar",
            onPressed: () => controller.clear(),
            icon: Icon(
              Icons.close_rounded,
              color: _isDark(context) ? Colors.white70 : Colors.black87,
            ),
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

  bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  @override
  Widget build(BuildContext context) {
    final border = _isDark(context)
        ? const Color(0xFFD4AF37).withOpacity(0.16)
        : Colors.black.withOpacity(0.08);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: _isDark(context) ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: value,
          dropdownColor: _isDark(context) ? const Color(0xFF1E1E1E) : Colors.white,
          style: TextStyle(
            color: _isDark(context) ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w700,
          ),
          iconEnabledColor: _isDark(context) ? const Color(0xFFD4AF37) : Colors.black87,
          hint: Text(
            "Tipo",
            style: TextStyle(
              color: _isDark(context) ? const Color(0xFFD6D6D6) : Colors.black87,
            ),
          ),
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

class _PdfButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _PdfButton({required this.onPressed});

  bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  @override
  Widget build(BuildContext context) {
    final bg =
        _isDark(context) ? const Color(0xFFD4AF37) : const Color(0xFF2E7D32);

    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 0,
      ),
      onPressed: onPressed,
     icon: Icon(
        Icons.picture_as_pdf_rounded,
        color: Colors.black.withOpacity(0.78)
            
      ),
      label: const Text(
        "Gerar PDF",
        style: TextStyle(fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _PdfBarItem {
  final String label;
  final double value;
  final PdfColor color;
  _PdfBarItem({required this.label, required this.value, required this.color});
}

pw.Widget _pdfChartCard({
  required String title,
  required String subtitle,
  required pw.Widget child,
}) {
  return pw.Container(
    padding: const pw.EdgeInsets.all(10),
    decoration: pw.BoxDecoration(
      color: PdfColors.white,
      borderRadius: pw.BorderRadius.circular(12),
      border: pw.Border.all(color: PdfColors.grey300),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(title, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 2),
        pw.Text(subtitle, style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
        pw.SizedBox(height: 8),
        child,
      ],
    ),
  );
}

pw.Widget _pdfBars({required List<_PdfBarItem> items}) {
  if (items.isEmpty) {
    return pw.Text(
      "Sem dados para o período/filtros.",
      style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
    );
  }

  final maxV = items.map((e) => e.value).fold<double>(0, (a, b) => a > b ? a : b);
  final safeMax = maxV <= 0 ? 1.0 : maxV;

  return pw.Column(
    children: items.map((e) {
      final w = (e.value / safeMax).clamp(0.0, 1.0);

      return pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 4),
        child: pw.Row(
          children: [
            pw.SizedBox(
              width: 95,
              child: pw.Text(
                e.label,
                maxLines: 1,
                overflow: pw.TextOverflow.clip,
                style: pw.TextStyle(fontSize: 9, color: PdfColors.grey800),
              ),
            ),
            pw.SizedBox(width: 8),
            pw.Expanded(
              child: pw.LayoutBuilder(
                builder: (context, constraints) {
                  final fullW = constraints!.maxWidth;
                  final barW = fullW * w;

                  return pw.Stack(
                    children: [
                      pw.Container(
                        height: 10,
                        width: fullW,
                        decoration: pw.BoxDecoration(
                          color: PdfColors.grey200,
                          borderRadius: pw.BorderRadius.circular(999),
                        ),
                      ),
                      pw.Container(
                        height: 10,
                        width: barW,
                        decoration: pw.BoxDecoration(
                          color: e.color,
                          borderRadius: pw.BorderRadius.circular(999),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            pw.SizedBox(width: 8),
            pw.SizedBox(
              width: 48,
              child: pw.Text(
                _pdfFmtNum(e.value),
                textAlign: pw.TextAlign.right,
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey800,
                ),
              ),
            ),
          ],
        ),
      );
    }).toList(),
  );
}

String _pdfFmtNum(double v) {
  if (v == v.roundToDouble()) return v.toInt().toString();
  return v.toStringAsFixed(2).replaceAll(".", ",");
}

class _TipoColorsPdf {
  static PdfColor fg(String tipo) {
    if (tipo == EstoqueMovModel.tipoEntrada) return PdfColor.fromInt(0xFF2E7D32);
    if (tipo == EstoqueMovModel.tipoVenda) return PdfColor.fromInt(0xFFF57C00);
    if (tipo == EstoqueMovModel.tipoCancelamento) return PdfColor.fromInt(0xFFC62828);
    if (tipo == EstoqueMovModel.tipoAjusteEntrada) return PdfColor.fromInt(0xFF1565C0);
    if (tipo == EstoqueMovModel.tipoAjusteSaida) return PdfColor.fromInt(0xFF6A1B9A);
    if (tipo == EstoqueMovModel.tipoExclusao) return PdfColor.fromInt(0xFFB71C1C);
    return PdfColors.grey800;
  }
}