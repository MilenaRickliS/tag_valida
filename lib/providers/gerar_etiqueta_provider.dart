import 'package:flutter/material.dart';
import '../models/categoria_model.dart';
import '../models/setor_model.dart';
import '../models/tipo_etiqueta_model.dart';
import '../models/etiqueta_model.dart';
import '../services/firestore_paths.dart';

class GerarEtiquetaProvider extends ChangeNotifier {
  final FirestorePaths paths;
  GerarEtiquetaProvider({required this.paths});

  String? tipoId;
  CategoriaModel? categoria;
  SetorModel? setor;

  final produtoCtrl = TextEditingController();

  DateTime? fabricacao;
  DateTime? validade;

  final Map<String, Map<String, dynamic>> camposValores = {};

  bool saving = false;


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
    );

    await ref.set(etiqueta.toMap());

    saving = false;
    notifyListeners();

    return ref.id;
  }

  @override
  void dispose() {
    produtoCtrl.dispose();
    super.dispose();
  }
}
