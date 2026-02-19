import 'package:flutter/material.dart';
import '../models/categoria_model.dart';
import '../models/setor_model.dart';
import '../models/tipo_etiqueta_model.dart';
import '../models/etiqueta_model.dart';
import '../services/firestore_paths.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GerarEtiquetaProvider extends ChangeNotifier {
  final FirestorePaths paths;
  GerarEtiquetaProvider({required this.paths});

  String? tipoId;
  CategoriaModel? categoria;
  SetorModel? setor;

  final produtoCtrl = TextEditingController();
  final quantidadeCtrl = TextEditingController(text: "1");

  DateTime? fabricacao;
  DateTime? validade;

  final Map<String, Map<String, dynamic>> camposValores = {};
  bool saving = false;

  num _parseQtdOrThrow() {
    final raw = quantidadeCtrl.text.trim().replaceAll(",", ".");
    final v = num.tryParse(raw);
    if (v == null || v <= 0) throw Exception("Quantidade inválida.");
    return v;
  }

  void setTipoId(String? id, {TipoEtiquetaModel? tipoAtual}) {
    tipoId = id;
    camposValores.clear();
    _recalcularValidadeSePossivel(tipoAtual);
    notifyListeners();
  }

  void setCategoria(CategoriaModel? c, {TipoEtiquetaModel? tipoAtual}) {
    categoria = c;
    _recalcularValidadeSePossivel(tipoAtual);
    notifyListeners();
  }

  void setSetor(SetorModel? s) {
    setor = s;
    notifyListeners();
  }

  void setFabricacao(DateTime d, {TipoEtiquetaModel? tipoAtual}) {
    fabricacao = d;
    _recalcularValidadeSePossivel(tipoAtual);
    notifyListeners();
  }

  void setValidadeManual(DateTime d) {
    validade = d;
    notifyListeners();
  }

  void setCampoValor({
    required String key,
    required String label,
    required dynamic value,
  }) {
    camposValores[key] = {"label": label, "value": value};
    notifyListeners();
  }

  void _recalcularValidadeSePossivel(TipoEtiquetaModel? tipoAtual) {
    if (tipoAtual == null || categoria == null || fabricacao == null) return;
    if (tipoAtual.usarRegraValidadeCategoria) {
      validade = fabricacao!.add(Duration(days: categoria!.diasVencimento));
    }
  }

  String? validar(TipoEtiquetaModel? tipoAtual) {
    if (tipoAtual == null) return "Selecione o tipo de etiqueta.";
    if (produtoCtrl.text.trim().isEmpty) return "Informe o nome do produto.";
    if (categoria == null) return "Selecione a categoria.";
    if (setor == null) return "Selecione o setor/responsável.";
    if (fabricacao == null) return "Selecione a data de fabricação.";
    if (validade == null) return "Selecione a data de validade.";

    final raw = quantidadeCtrl.text.trim();
    final qtd = num.tryParse(raw.replaceAll(",", "."));
    if (qtd == null || qtd <= 0) return "Informe uma quantidade válida.";

    for (final c in tipoAtual.camposCustom) {
      if (c.obrigatorio) {
        final v = camposValores[c.key]?["value"];
        final vazio = v == null || (v is String && v.trim().isEmpty);
        if (vazio) return "Preencha o campo obrigatório: ${c.label}.";
      }
    }
    return null;
  }

  Future<String> salvarEtiqueta({
    required String uid,
    required TipoEtiquetaModel tipoAtual,
  }) async {
    final err = validar(tipoAtual);
    if (err != null) throw Exception(err);

    saving = true;
    notifyListeners();

    final ref = paths.etiquetas(uid).doc();
    final qtd = _parseQtdOrThrow();

    final etiqueta = EtiquetaModel(
      id: ref.id,
      tipoId: tipoAtual.id,
      tipoNome: tipoAtual.nome,
      produtoNome: produtoCtrl.text.trim(),
      categoriaId: categoria!.id,
      categoriaNome: categoria!.nome,
      setorId: setor!.id,
      setorNome: setor!.nome,
      dataFabricacao: fabricacao!,
      dataValidade: validade!,
      camposCustomValores: camposValores,
      status: "ativa",

  
      quantidade: qtd,
      quantidadeRestante: qtd,
      statusEstoque: "ativo",
      soldAt: null,
    );

    await ref.set(etiqueta.toMap());

    saving = false;
    notifyListeners();

    return ref.id;
  }


  Future<void> vender({
    required String uid,
    required String etiquetaId,
    required num qtdVendida,
  }) async {
    if (qtdVendida <= 0) throw Exception("Informe uma quantidade > 0.");

    final doc = paths.etiquetas(uid).doc(etiquetaId);

    await FirebaseFirestore.instance.runTransaction((txn) async {
      final snap = await txn.get(doc);
      if (!snap.exists) throw Exception("Etiqueta não encontrada.");

      final data = snap.data() as Map<String, dynamic>;
      final rest = (data["quantidadeRestante"] as num?) ?? (data["quantidade"] as num?) ?? 1;

      final novoRest = rest - qtdVendida;
      if (novoRest < 0) throw Exception("Venda maior que o restante.");

      final statusEstoque = EtiquetaModel.calcStatusEstoque(
        restante: novoRest,
        current: (data["statusEstoque"] ?? "ativo").toString(),
      );

      txn.update(doc, {
        "quantidadeRestante": novoRest,
        "statusEstoque": statusEstoque,
        "soldAt": statusEstoque == "vendido" ? FieldValue.serverTimestamp() : null,
        "updatedAt": FieldValue.serverTimestamp(),
      });
    });

    notifyListeners();
  }

  @override
  void dispose() {
    produtoCtrl.dispose();
    quantidadeCtrl.dispose();
    super.dispose();
  }
}