import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../models/etiqueta_model.dart';

class EtiquetaPdfService {
  static final _df = DateFormat("dd/MM/yyyy");

  static String _fmtNum(num v) {
    if (v % 1 == 0) return v.toInt().toString();
    return v.toStringAsFixed(2).replaceAll(".", ",");
  }

  static Future<List<int>> generateBytes(EtiquetaModel e) async {
    final doc = pw.Document();

    final status = (e.statusEstoque.trim().isEmpty) ? "ativo" : e.statusEstoque.trim();
    final qtd = e.quantidade;
    final rest = e.quantidadeRestante;

    final num saidas = status == "cancelado"
        ? qtd
        : ((qtd - rest) < 0 ? 0 : (qtd - rest));

    final num restanteView = status == "cancelado" ? 0 : rest;

    pw.Widget row(String label, String value) {
      return pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 6),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(
              width: 120,
              child: pw.Text(label, style: pw.TextStyle(color: PdfColors.grey700, fontSize: 10)),
            ),
            pw.Expanded(child: pw.Text(value, style: pw.TextStyle(fontSize: 11))),
          ],
        ),
      );
    }

    final custom = Map<String, dynamic>.from(e.camposCustomValores);
    final customRows = <pw.Widget>[];
    custom.forEach((key, value) {
      final obj = Map<String, dynamic>.from(value as Map);
      final label = (obj["label"] ?? key).toString();
      final val = obj["value"];

      String texto;
      if (val is int) {
        texto = _df.format(DateTime.fromMillisecondsSinceEpoch(val));
      } else if (val is bool) {
        texto = val ? "Sim" : "Não";
      } else {
        texto = val?.toString() ?? "";
      }
      customRows.add(row(label, texto));
    });

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (_) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text("Etiqueta - ${e.tipoNome}", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 14),

                row("Produto", e.produtoNome),
                row("Categoria", e.categoriaNome),
                row("Setor/Resp.", e.setorNome),
                row("Fabricação", _df.format(e.dataFabricacao)),
                row("Validade", _df.format(e.dataValidade)),
                row("Quantidade", _fmtNum(qtd)),
                row("Saídas", _fmtNum(saidas)),
                row("Restante", _fmtNum(restanteView)),
                row("Status", status),

                if (customRows.isNotEmpty) ...[
                  pw.SizedBox(height: 12),
                  pw.Divider(),
                  pw.SizedBox(height: 8),
                  pw.Text("Campos adicionais", style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 8),
                  ...customRows,
                ],
              ],
            ),
          );
        },
      ),
    );

    return doc.save();
  }
}