// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:flutter/rendering.dart';
import 'package:pdf/pdf.dart';
import '../widgets/menu.dart';
import '../providers/estoque_mov_local_provider.dart';
import '../models/estoque_mov_model.dart';

class RelatoriosScreen extends StatefulWidget {
  final String uid;
  const RelatoriosScreen({super.key, required this.uid});

  @override
  State<RelatoriosScreen> createState() => _RelatoriosScreenState();
}

class _RelatoriosScreenState extends State<RelatoriosScreen> {
  DateTimeRange? _range;
  bool _loading = true;

  List<EstoqueMovModel> _movs = [];
  List<EstoqueMovModel> _filtered = [];

  final _df = DateFormat('dd/MM/yyyy');

 
  final GlobalKey _pieKey = GlobalKey();
  final GlobalKey _barKey = GlobalKey();

  final GlobalKey _pieKeyPrint = GlobalKey();
  final GlobalKey _barKeyPrint = GlobalKey();
  bool _printing = false;

  @override
  void initState() {
    super.initState();
    _initDefaultRangeAndLoad();
  }

  Future<void> _initDefaultRangeAndLoad() async {
    final now = DateTime.now();
    _range = DateTimeRange(
      start: DateTime(now.year, now.month, now.day).subtract(const Duration(days: 29)),
      end: DateTime(now.year, now.month, now.day, 23, 59, 59),
    );
    await _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    final provider = context.read<EstoqueMovLocalProvider>();
    final list = await provider.listAll(uid: widget.uid, limit: 2000);

    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    setState(() {
      _movs = list;
      _applyFilter();
      _loading = false;
    });
  }

  void _applyFilter() {
    final r = _range;
    if (r == null) {
      _filtered = List.of(_movs);
      return;
    }

   
    final start = DateTime(r.start.year, r.start.month, r.start.day, 0, 0, 0);
    final end = DateTime(r.end.year, r.end.month, r.end.day, 23, 59, 59, 999);

    _filtered = _movs.where((m) {
    
      final d = m.createdAt.toLocal();
      return !d.isBefore(start) && !d.isAfter(end);
    }).toList();
  }

  Future<void> _pickRange() async {
    final now = DateTime.now();

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
      initialDateRange: _range,
      helpText: 'Selecione o período do relatório',
      locale: const Locale('pt', 'BR'),
      builder: (context, child) {
       
        final base = Theme.of(context);
        final scheme = base.colorScheme.copyWith(
          primary: const Color(0xff428e2e),
          onPrimary: Colors.white,
          surface: const Color(0xFFFDF7ED),
          onSurface: Colors.black87,
        );

        return Theme(
          data: base.copyWith(
            colorScheme: scheme,
            dialogTheme: DialogTheme(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              backgroundColor: const Color(0xFFFDF7ED),
            ),
            datePickerTheme: DatePickerThemeData(
              backgroundColor: const Color(0xFFFDF7ED),
              headerBackgroundColor: const Color(0xff428e2e),
              headerForegroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              todayBackgroundColor: WidgetStateProperty.all(const Color(0x1a428e2e)),
              todayForegroundColor: WidgetStateProperty.all(const Color(0xff428e2e)),
              rangeSelectionBackgroundColor: const Color(0x26428e2e),
              rangePickerBackgroundColor: const Color(0xFFFDF7ED),
              dayForegroundColor: WidgetStateProperty.all(Colors.black87),
              dayStyle: const TextStyle(fontWeight: FontWeight.w600),
              weekdayStyle: const TextStyle(fontWeight: FontWeight.w700),
              yearStyle: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked == null) return;

    setState(() {
      _range = DateTimeRange(
        start: DateTime(picked.start.year, picked.start.month, picked.start.day),
        end: DateTime(picked.end.year, picked.end.month, picked.end.day),
      );
      _applyFilter();
    });
  }

  Future<void> _exportPdf() async {
    setState(() => _printing = true);

    await Future.delayed(const Duration(milliseconds: 150));
    await WidgetsBinding.instance.endOfFrame;
    await Future.delayed(const Duration(milliseconds: 150));

    final piePng = await _capturePng(_pieKeyPrint, pixelRatio: 3.0);
    final barPng = await _capturePng(_barKeyPrint, pixelRatio: 3.0);

    setState(() => _printing = false);

    final bytes = await _buildPdfBytes(
      range: _range,
      movs: _filtered,
      piePng: piePng,
      barPng: barPng,
    );

    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }

  Future<Uint8List?> _capturePng(GlobalKey key, {double pixelRatio = 2.0}) async {
    for (int attempt = 0; attempt < 3; attempt++) {
      try {
        await WidgetsBinding.instance.endOfFrame;

        final ctx = key.currentContext;
        if (ctx == null) {
          await Future.delayed(const Duration(milliseconds: 80));
          continue;
        }

        final ro = ctx.findRenderObject();
        if (ro is! RenderRepaintBoundary) {
          await Future.delayed(const Duration(milliseconds: 80));
          continue;
        }

        if (ro.debugNeedsPaint) {
          await Future.delayed(const Duration(milliseconds: 80));
          continue;
        }

        final image = await ro.toImage(pixelRatio: pixelRatio);
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        final bytes = byteData?.buffer.asUint8List();
        if (bytes != null && bytes.isNotEmpty) return bytes;
      } catch (_) {
        await Future.delayed(const Duration(milliseconds: 80));
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final compact = w < 835;
    final isPhone = w < 600;

    final periodLabel = _range == null
        ? 'Período: Tudo'
        : 'Período: ${_df.format(_range!.start)} até ${_df.format(_range!.end)}';

    final kpis = _computeKpis(_filtered);
    final topSold = _topByType(_filtered, EstoqueMovModel.tipoVenda, topN: 5);
    final topLost = _topLosses(_filtered, topN: 5);

    return Stack(
      children: [
        Scaffold(
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
          body: _loading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                    children: [
                      _HeaderActions(
                        isPhone: isPhone,
                        title: 'Relatórios',
                        subtitle: periodLabel,
                        onPickRange: _pickRange,
                        onExportPdf: _exportPdf,
                      ),
                      const SizedBox(height: 14),

                      _KpiGrid(kpis: kpis),
                      const SizedBox(height: 14),

                      _SectionCard(
                        title: 'Insights rápidos',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _InsightLine(
                              label: 'Produto mais vendido',
                              value: topSold.isEmpty ? '—' : '${topSold.first.name} (${_fmtNum(topSold.first.value)})',
                              chipBg: RelatorioCores.bg(EstoqueMovModel.tipoVenda),
                              chipFg: RelatorioCores.fg(EstoqueMovModel.tipoVenda),
                            ),
                            const SizedBox(height: 8),
                            _InsightLine(
                              label: 'Produto com mais perda',
                              value: topLost.isEmpty ? '—' : '${topLost.first.name} (${_fmtNum(topLost.first.value)})',
                              chipBg: RelatorioCores.bg(EstoqueMovModel.tipoExclusao),
                              chipFg: RelatorioCores.fg(EstoqueMovModel.tipoExclusao),
                            ),
                            const SizedBox(height: 8),
                            _InsightLine(
                              label: 'Total de movimentações no período',
                              value: '${_filtered.length}',
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      
                      _ChartsRow(
                        pieKey: _pieKey,
                        barKey: _barKey,
                        movs: _filtered,
                      ),

                      const SizedBox(height: 14),

                      _RankingsRow(
                        topSold: topSold,
                        topLost: topLost,
                      ),

                      const SizedBox(height: 14),

                      _SectionCard(
                        title: 'Movimentações (últimas do período)',
                        child: _MovList(movs: _filtered.take(25).toList()),
                      ),
                    ],
                  ),
                ),
        ),

       
        Offstage(
          offstage: !_printing,
          child: Material(
            type: MaterialType.transparency,
            child: SizedBox(
              width: 900, 
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RepaintBoundary(
                      key: _pieKeyPrint,
                      child: _ChartOnlyPie(movs: _filtered),
                    ),
                    const SizedBox(height: 12),
                    RepaintBoundary(
                      key: _barKeyPrint,
                      child: _ChartOnlyBar(movs: _filtered),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  static String _fmtNum(num v) {
    if (v % 1 == 0) return v.toInt().toString();
    return v.toStringAsFixed(2);
  }

  Map<String, num> _computeKpis(List<EstoqueMovModel> movs) {
    num entradas = 0;
    num vendas = 0;
    num cancel = 0;
    num excl = 0;

   
    num ajusteEnt = 0;
    num ajusteSai = 0;

    for (final m in movs) {
      final q = m.quantidade;

      if (m.tipo == EstoqueMovModel.tipoEntrada) entradas += q;
      if (m.tipo == EstoqueMovModel.tipoVenda) vendas += q;
      if (m.tipo == EstoqueMovModel.tipoCancelamento) cancel += q;
      if (m.tipo == EstoqueMovModel.tipoExclusao) excl += q;

     
      if (_hasAjusteEntrada(m)) ajusteEnt += q;
      if (_hasAjusteSaida(m)) ajusteSai += q;
    }

    final perdas = cancel + excl;
    final saldo = entradas + ajusteEnt - vendas - perdas - ajusteSai;

    final map = <String, num>{
      'Entradas': entradas,
      'Vendas': vendas,
      'Cancelamentos': cancel,
      'Exclusões': excl,
      'Perdas': perdas,
      'Saldo': saldo,
    };

  
    if (_existsTipoAjusteEntrada()) map['Ajuste Entrada'] = ajusteEnt;
    if (_existsTipoAjusteSaida()) map['Ajuste Saída'] = ajusteSai;

    return map;
  }

  bool _existsTipoAjusteEntrada() {
    
    try {
      
      EstoqueMovModel.tipoAjusteEntrada;
      return true;
    } catch (_) {
      return false;
    }
  }

  bool _existsTipoAjusteSaida() {
    try {
     
      EstoqueMovModel.tipoAjusteSaida;
      return true;
    } catch (_) {
      return false;
    }
  }

  bool _hasAjusteEntrada(EstoqueMovModel m) {
    try {
      return m.tipo == EstoqueMovModel.tipoAjusteEntrada;
    } catch (_) {
      return false;
    }
  }

  bool _hasAjusteSaida(EstoqueMovModel m) {
    try {
      return m.tipo == EstoqueMovModel.tipoAjusteSaida;
    } catch (_) {
      return false;
    }
  }

  List<_NamedValue> _topByType(List<EstoqueMovModel> movs, String tipo, {int topN = 5}) {
    final map = <String, num>{};
    for (final m in movs) {
      if (m.tipo != tipo) continue;
      final name = (m.produtoNome?.trim().isNotEmpty ?? false) ? m.produtoNome!.trim() : 'Sem nome';
      map[name] = (map[name] ?? 0) + m.quantidade;
    }
    final list = map.entries.map((e) => _NamedValue(e.key, e.value)).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return list.take(topN).toList();
  }

  List<_NamedValue> _topLosses(List<EstoqueMovModel> movs, {int topN = 5}) {
    final map = <String, num>{};
    for (final m in movs) {
      final isLoss = m.tipo == EstoqueMovModel.tipoCancelamento || m.tipo == EstoqueMovModel.tipoExclusao;
      if (!isLoss) continue;
      final name = (m.produtoNome?.trim().isNotEmpty ?? false) ? m.produtoNome!.trim() : 'Sem nome';
      map[name] = (map[name] ?? 0) + m.quantidade;
    }
    final list = map.entries.map((e) => _NamedValue(e.key, e.value)).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return list.take(topN).toList();
  }

  Future<Uint8List> _buildPdfBytes({
    required DateTimeRange? range,
    required List<EstoqueMovModel> movs,
    required Uint8List? piePng,
    required Uint8List? barPng,
  }) async {
    final kpis = _computeKpis(movs);
    final topSold = _topByType(movs, EstoqueMovModel.tipoVenda, topN: 10);
    final topLost = _topLosses(movs, topN: 10);

    final doc = pw.Document();

    final period = range == null
        ? 'Tudo'
        : '${_df.format(range.start)} até ${_df.format(range.end)}';

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Text('Relatório de Estoque', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          pw.Text('Período: $period'),
          pw.SizedBox(height: 12),

       
          pw.Text('Gráficos', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),

          if (piePng != null) ...[
            pw.Text('Distribuição por tipo', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            pw.Center(child: pw.Image(pw.MemoryImage(piePng), width: 420)),
            pw.SizedBox(height: 10),
          ],

          if (barPng != null) ...[
            pw.Text('Top vendidos (barras)', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            pw.Center(child: pw.Image(pw.MemoryImage(barPng), width: 420)),
            pw.SizedBox(height: 12),
          ],

          pw.Text('Resumo', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          pw.Table(
            border: pw.TableBorder.all(width: 0.5),
            children: kpis.entries.map((e) {
              return pw.TableRow(children: [
                pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(e.key)),
                pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(_fmtNum(e.value))),
              ]);
            }).toList(),
          ),

          pw.SizedBox(height: 14),
          pw.Text('Top produtos vendidos', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          _pdfRankTable(topSold),

          pw.SizedBox(height: 14),
          pw.Text('Top perdas (cancelamento/exclusão)', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          _pdfRankTable(topLost),

          pw.SizedBox(height: 14),
          pw.Text('Movimentações (amostra)', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          pw.Table(
            border: pw.TableBorder.all(width: 0.5),
            children: [
              pw.TableRow(
                children: [
                  _pdfCell('Data', bold: true),
                  _pdfCell('Produto', bold: true),
                  _pdfCell('Tipo', bold: true),
                  _pdfCell('Qtd', bold: true),
                  _pdfCell('Motivo', bold: true),
                ],
              ),
              ...movs.take(35).map((m) => pw.TableRow(children: [
                    _pdfCell(_df.format(m.createdAt)),
                    _pdfCell((m.produtoNome?.trim().isNotEmpty ?? false) ? m.produtoNome!.trim() : 'Sem nome'),
                    _pdfCell(m.tipo),
                    _pdfCell(_fmtNum(m.quantidade)),
                    _pdfCell(m.motivo ?? ''),
                  ])),
            ],
          ),
        ],
      ),
    );

    return doc.save();
  }

  pw.Widget _pdfRankTable(List<_NamedValue> items) {
    if (items.isEmpty) return pw.Text('Sem dados no período.');
    return pw.Table(
      border: pw.TableBorder.all(width: 0.5),
      children: [
        pw.TableRow(children: [_pdfCell('Produto', bold: true), _pdfCell('Quantidade', bold: true)]),
        ...items.map((e) => pw.TableRow(children: [_pdfCell(e.name), _pdfCell(_fmtNum(e.value))])),
      ],
    );
  }

  pw.Widget _pdfCell(String text, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(text, style: pw.TextStyle(fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
    );
  }
}

class RelatorioCores {
  static Color bg(String tipo) {
    switch (tipo) {
      case EstoqueMovModel.tipoEntrada:
        return Colors.green.withOpacity(0.10);
      case EstoqueMovModel.tipoVenda:
        return Colors.orange.withOpacity(0.10);
      case EstoqueMovModel.tipoCancelamento:
        return Colors.red.withOpacity(0.10);
      case EstoqueMovModel.tipoExclusao:
        return Colors.red.withOpacity(0.08);
      default:
       
        try {
          if (tipo == EstoqueMovModel.tipoAjusteEntrada) return Colors.blue.withOpacity(0.10);
        } catch (_) {}
        try {
          if (tipo == EstoqueMovModel.tipoAjusteSaida) return Colors.purple.withOpacity(0.10);
        } catch (_) {}
        return Colors.black.withOpacity(0.06);
    }
  }

  static Color fg(String tipo) {
    switch (tipo) {
      case EstoqueMovModel.tipoEntrada:
        return const Color(0xff2e7d32);
      case EstoqueMovModel.tipoVenda:
        return const Color(0xffef6c00);
      case EstoqueMovModel.tipoCancelamento:
        return const Color(0xffc62828);
      case EstoqueMovModel.tipoExclusao:
        return const Color(0xffc62828);
      default:
        try {
          if (tipo == EstoqueMovModel.tipoAjusteEntrada) return const Color(0xff1565c0);
        } catch (_) {}
        try {
          if (tipo == EstoqueMovModel.tipoAjusteSaida) return const Color(0xff6a1b9a);
        } catch (_) {}
        return Colors.black87;
    }
  }

  static Color solid(String tipo) => fg(tipo);
}

class _NamedValue {
  final String name;
  final num value;
  _NamedValue(this.name, this.value);
}



class _HeaderActions extends StatelessWidget {
  final bool isPhone;
  final String title;
  final String subtitle;
  final VoidCallback onPickRange;
  final VoidCallback onExportPdf;

  const _HeaderActions({
    required this.isPhone,
    required this.title,
    required this.subtitle,
    required this.onPickRange,
    required this.onExportPdf,
  });

  @override
  Widget build(BuildContext context) {
    final trailing = Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        OutlinedButton.icon(
          onPressed: onPickRange,
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0xff428e2e)),
            foregroundColor: const Color(0xff428e2e),
          ),
          icon: const Icon(Icons.date_range, color: Color(0xff428e2e)),
          label: const Text('Período', style: TextStyle(color: Color(0xff428e2e))),
        ),
        FilledButton.icon(
          onPressed: onExportPdf,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xff428e2e),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          icon: const Icon(Icons.picture_as_pdf),
          label: const Text('Salvar PDF'),
        ),
      ],
    );

    return _SectionCard(
      title: title,
      trailing: isPhone ? null : trailing,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(subtitle, style: const TextStyle(fontSize: 14, color: Color(0xFF6B5E4B))),
          if (isPhone) ...[
            const SizedBox(height: 12),
            Align(alignment: Alignment.centerLeft, child: trailing),
          ],
        ],
      ),
    );
  }
}

class _KpiGrid extends StatelessWidget {
  final Map<String, num> kpis;
  const _KpiGrid({required this.kpis});

  @override
  Widget build(BuildContext context) {
    final entries = kpis.entries.toList();

    String tipoForLabel(String label) {
      switch (label) {
        case 'Entradas':
          return EstoqueMovModel.tipoEntrada;
        case 'Vendas':
          return EstoqueMovModel.tipoVenda;
        case 'Cancelamentos':
          return EstoqueMovModel.tipoCancelamento;
        case 'Exclusões':
          return EstoqueMovModel.tipoExclusao;
        case 'Perdas':
          return EstoqueMovModel.tipoExclusao;
        case 'Saldo':
          return EstoqueMovModel.tipoEntrada;
        case 'Ajuste Entrada':
          try {
            return EstoqueMovModel.tipoAjusteEntrada;
          } catch (_) {
            return EstoqueMovModel.tipoEntrada;
          }
        case 'Ajuste Saída':
          try {
            return EstoqueMovModel.tipoAjusteSaida;
          } catch (_) {
            return EstoqueMovModel.tipoCancelamento;
          }
        default:
          return EstoqueMovModel.tipoEntrada;
      }
    }

    return LayoutBuilder(
      builder: (context, c) {
        final cols = c.maxWidth < 650 ? 2 : 3;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: entries.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 2.6,
          ),
          itemBuilder: (context, i) {
            final e = entries[i];
            final tipo = tipoForLabel(e.key);
            return _KpiCard(
              label: e.key,
              value: e.value,
              bg: RelatorioCores.bg(tipo),
              fg: RelatorioCores.fg(tipo),
            );
          },
        );
      },
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final num value;
  final Color bg;
  final Color fg;

  const _KpiCard({
    required this.label,
    required this.value,
    required this.bg,
    required this.fg,
  });

  @override
  Widget build(BuildContext context) {
    final v = (value % 1 == 0) ? value.toInt().toString() : value.toStringAsFixed(2);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: fg.withOpacity(0.18)),
        boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 8, offset: Offset(0, 3))],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: fg.withOpacity(0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_iconFor(label), color: fg, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label, style: TextStyle(fontSize: 13, color: fg.withOpacity(0.95), fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text(v, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: fg)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconFor(String label) {
    switch (label) {
      case 'Entradas':
        return Icons.add_circle_outline;
      case 'Vendas':
        return Icons.shopping_cart_outlined;
      case 'Cancelamentos':
        return Icons.cancel_outlined;
      case 'Exclusões':
        return Icons.delete_outline;
      case 'Perdas':
        return Icons.warning_amber_rounded;
      case 'Saldo':
        return Icons.account_balance_wallet_outlined;
      case 'Ajuste Entrada':
        return Icons.tune;
      case 'Ajuste Saída':
        return Icons.tune;
      default:
        return Icons.analytics_outlined;
    }
  }
}

class _ChartsRow extends StatelessWidget {
  final GlobalKey pieKey;
  final GlobalKey barKey;
  final List<EstoqueMovModel> movs;

  const _ChartsRow({
    required this.pieKey,
    required this.barKey,
    required this.movs,
  });

  @override
  Widget build(BuildContext context) {
    final byType = <String, num>{};
    for (final m in movs) {
      byType[m.tipo] = (byType[m.tipo] ?? 0) + m.quantidade;
    }

    final total = byType.values.fold<num>(0, (a, b) => a + b);
    final entries = byType.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return LayoutBuilder(
      builder: (context, c) {
        final isNarrow = c.maxWidth < 900;

        final pieCard = _SectionCard(
          title: 'Distribuição por tipo',
          child: RepaintBoundary(
            key: pieKey,
            child: SizedBox(
              height: 240,
              child: total == 0
                  ? const Center(child: Text('Sem dados no período'))
                  : PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 48,
                        sections: List.generate(entries.length, (i) {
                          final e = entries[i];
                          final pct = total == 0 ? 0 : (e.value / total * 100);
                          final color = RelatorioCores.solid(e.key);
                          return PieChartSectionData(
                            value: e.value.toDouble(),
                            title: '${e.key}\n${pct.toStringAsFixed(0)}%',
                            radius: 78,
                            color: color,
                            titleStyle: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          );
                        }),
                      ),
                    ),
            ),
          ),
        );

        final barCard = _SectionCard(
          title: 'Top vendidos (barras)',
          child: RepaintBoundary(
            key: barKey,
            child: SizedBox(height: 240, child: _TopSoldBarChart(movs: movs)),
          ),
        );

        if (isNarrow) {
          return Column(children: [pieCard, const SizedBox(height: 12), barCard]);
        }

        return Row(
          children: [
            Expanded(child: pieCard),
            const SizedBox(width: 12),
            Expanded(child: barCard),
          ],
        );
      },
    );
  }
}

class _TopSoldBarChart extends StatelessWidget {
  final List<EstoqueMovModel> movs;
  const _TopSoldBarChart({required this.movs});

  @override
  Widget build(BuildContext context) {
    final map = <String, num>{};
    for (final m in movs) {
      if (m.tipo != EstoqueMovModel.tipoVenda) continue;
      final name = (m.produtoNome?.trim().isNotEmpty ?? false) ? m.produtoNome!.trim() : 'Sem nome';
      map[name] = (map[name] ?? 0) + m.quantidade;
    }

    final list = map.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final top = list.take(6).toList();

    if (top.isEmpty) {
      return const Center(child: Text('Sem vendas no período'));
    }

    final rodColor = RelatorioCores.solid(EstoqueMovModel.tipoVenda);

    return BarChart(
      BarChartData(
        gridData: const FlGridData(show: true),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 34)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= top.length) return const SizedBox.shrink();
                final name = top[i].key;
                final short = name.length > 10 ? '${name.substring(0, 10)}…' : name;
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(short, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
                );
              },
            ),
          ),
        ),
        barGroups: List.generate(top.length, (i) {
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: top[i].value.toDouble(),
                width: 16,
                color: rodColor,
                borderRadius: BorderRadius.circular(8),
              )
            ],
          );
        }),
      ),
    );
  }
}

class _RankingsRow extends StatelessWidget {
  final List<_NamedValue> topSold;
  final List<_NamedValue> topLost;

  const _RankingsRow({required this.topSold, required this.topLost});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final isNarrow = c.maxWidth < 900;

        final soldCard = _SectionCard(
          title: 'Top 5 vendidos',
          child: _RankList(items: topSold, tipo: EstoqueMovModel.tipoVenda),
        );

        final lostCard = _SectionCard(
          title: 'Top 5 perdas',
          child: _RankList(items: topLost, tipo: EstoqueMovModel.tipoExclusao),
        );

        if (isNarrow) {
          return Column(children: [soldCard, const SizedBox(height: 12), lostCard]);
        }
        return Row(
          children: [
            Expanded(child: soldCard),
            const SizedBox(width: 12),
            Expanded(child: lostCard),
          ],
        );
      },
    );
  }
}

class _RankList extends StatelessWidget {
  final List<_NamedValue> items;
  final String tipo;
  const _RankList({required this.items, required this.tipo});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const Text('Sem dados no período.');

    final bg = RelatorioCores.bg(tipo);
    final fg = RelatorioCores.fg(tipo);

    return Column(
      children: List.generate(items.length, (i) {
        final it = items[i];
        final v = (it.value % 1 == 0) ? it.value.toInt().toString() : it.value.toStringAsFixed(2);

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: fg.withOpacity(0.18)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: fg.withOpacity(0.18),
                child: Text('${i + 1}', style: TextStyle(fontWeight: FontWeight.w900, color: fg)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  it.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 10),
              Text(v, style: TextStyle(fontWeight: FontWeight.w900, color: fg)),
            ],
          ),
        );
      }),
    );
  }
}

class _MovList extends StatelessWidget {
  final List<EstoqueMovModel> movs;
  const _MovList({required this.movs});

  @override
  Widget build(BuildContext context) {
    if (movs.isEmpty) return const Text('Sem movimentações no período.');

    final df = DateFormat('dd/MM HH:mm');

    return Column(
      children: movs.map((m) {
        final produto = (m.produtoNome?.trim().isNotEmpty ?? false) ? m.produtoNome!.trim() : 'Sem nome';
        final bg = RelatorioCores.bg(m.tipo);
        final fg = RelatorioCores.fg(m.tipo);

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: fg.withOpacity(0.18)),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: fg.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_iconForTipo(m.tipo), color: fg, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(produto, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    Text('${df.format(m.createdAt)} • ${m.tipo} • ${m.motivo ?? ""}', style: TextStyle(color: Colors.black.withOpacity(0.65), fontSize: 12.5)),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                (m.quantidade % 1 == 0) ? m.quantidade.toInt().toString() : m.quantidade.toStringAsFixed(2),
                style: TextStyle(fontWeight: FontWeight.w900, color: fg),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  IconData _iconForTipo(String tipo) {
    switch (tipo) {
      case EstoqueMovModel.tipoEntrada:
        return Icons.add_circle_outline;
      case EstoqueMovModel.tipoVenda:
        return Icons.shopping_cart_outlined;
      case EstoqueMovModel.tipoCancelamento:
        return Icons.cancel_outlined;
      case EstoqueMovModel.tipoExclusao:
        return Icons.delete_outline;
      default:
        try {
          if (tipo == EstoqueMovModel.tipoAjusteEntrada) return Icons.tune;
        } catch (_) {}
        try {
          if (tipo == EstoqueMovModel.tipoAjusteSaida) return Icons.tune;
        } catch (_) {}
        return Icons.analytics_outlined;
    }
  }
}

class _InsightLine extends StatelessWidget {
  final String label;
  final String value;
  final Color? chipBg;
  final Color? chipFg;

  const _InsightLine({
    required this.label,
    required this.value,
    this.chipBg,
    this.chipFg,
  });

  @override
  Widget build(BuildContext context) {
    final hasChip = chipBg != null && chipFg != null;

    return Row(
      children: [
        Expanded(child: Text(label, style: const TextStyle(color: Color(0xFF6B5E4B), fontWeight: FontWeight.w700))),
        const SizedBox(width: 12),
        if (!hasChip)
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900))
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: chipBg,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: chipFg!.withOpacity(0.25)),
            ),
            child: Text(value, style: TextStyle(fontWeight: FontWeight.w900, color: chipFg)),
          ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;

  const _SectionCard({required this.title, required this.child, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE7D8C2)),
        boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900))),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _ChartOnlyPie extends StatelessWidget {
  final List<EstoqueMovModel> movs;
  const _ChartOnlyPie({required this.movs});

  @override
  Widget build(BuildContext context) {
    final byType = <String, num>{};
    for (final m in movs) {
      byType[m.tipo] = (byType[m.tipo] ?? 0) + m.quantidade;
    }
    final total = byType.values.fold<num>(0, (a, b) => a + b);
    final entries = byType.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE7D8C2)),
      ),
      child: SizedBox(
        height: 260,
        child: total == 0
            ? const Center(child: Text('Sem dados no período'))
            : PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 50,
                  sections: List.generate(entries.length, (i) {
                    final e = entries[i];
                    final pct = total == 0 ? 0 : (e.value / total * 100);
                    return PieChartSectionData(
                      value: e.value.toDouble(),
                      title: '${e.key}\n${pct.toStringAsFixed(0)}%',
                      radius: 85,
                      color: RelatorioCores.solid(e.key),
                      titleStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    );
                  }),
                ),
              ),
      ),
    );
  }
}

class _ChartOnlyBar extends StatelessWidget {
  final List<EstoqueMovModel> movs;
  const _ChartOnlyBar({required this.movs});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE7D8C2)),
      ),
      child: SizedBox(height: 260, child: _TopSoldBarChart(movs: movs)),
    );
  }
}