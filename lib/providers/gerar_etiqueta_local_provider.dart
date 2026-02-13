import 'package:flutter/material.dart';

import '../models/categoria_model.dart';
import '../models/setor_model.dart';
import '../models/tipo_etiqueta_model.dart';
import '../models/etiqueta_model.dart';
import '../data/local/repos/etiquetas_local_repo.dart';

class GerarEtiquetaLocalProvider extends ChangeNotifier {
  final EtiquetasLocalRepo repo;
  GerarEtiquetaLocalProvider({required this.repo});

  String? tipoId;
  CategoriaModel? categoria;
  SetorModel? setor;

  final produtoCtrl = TextEditingController();

  DateTime? fabricacao;
  DateTime? validade;

  final Map<String, Map<String, dynamic>> camposValores = {};

  bool saving = false;

  String? editingEtiquetaId;
  DateTime? editingCreatedAt;

 
  final Map<String, TextEditingController> customCtrls = {};

  TextEditingController ctrlFor(String key, {String initial = ""}) {
    return customCtrls.putIfAbsent(
      key,
      () => TextEditingController(text: initial),
    );
  }

  void _setCtrlText(String key, String text) {
    final c = customCtrls[key];
    if (c == null) {
      customCtrls[key] = TextEditingController(text: text);
    } else {
      if (c.text != text) c.text = text;
    }
  }

  void clearEditing() {
    editingEtiquetaId = null;
    editingCreatedAt = null;
  }

  void resetAll() {
    clearEditing();
    tipoId = null;
    categoria = null;
    setor = null;
    fabricacao = null;
    validade = null;
    produtoCtrl.clear();
    camposValores.clear();

    for (final c in customCtrls.values) {
      c.dispose();
    }
    customCtrls.clear();

    notifyListeners();
  }


  void loadFromEtiqueta({
    required EtiquetaModel e,
    required CategoriaModel? categoriaObj,
    required SetorModel? setorObj,
    required TipoEtiquetaModel? tipoAtual,
  }) {
    editingEtiquetaId = e.id;
    editingCreatedAt = e.createdAt;

    tipoId = e.tipoId;
    produtoCtrl.text = e.produtoNome;

    categoria = categoriaObj;
    setor = setorObj;

    fabricacao = e.dataFabricacao;
    validade = e.dataValidade;

    camposValores
      ..clear()
      ..addAll(
        (e.camposCustomValores).map(
          (k, v) => MapEntry(k, Map<String, dynamic>.from(v as Map)),
        ),
      );

    
    if (tipoAtual != null) {
      for (final c in tipoAtual.camposCustom) {
        final v = camposValores[c.key]?["value"];

        if (c.tipo == CampoTipo.text || c.tipo == CampoTipo.multiline) {
          _setCtrlText(c.key, (v ?? "").toString());
        } else if (c.tipo == CampoTipo.number) {
          _setCtrlText(c.key, v == null ? "" : v.toString());
        }
      }
    }

    _recalcularValidadeSePossivel(tipoAtual);
    notifyListeners();
  }


  void setTipoId(String? id, {TipoEtiquetaModel? tipoAtual}) {
    tipoId = id;

   
    clearEditing();

    
    camposValores.clear();
    for (final c in customCtrls.values) {
      c.dispose();
    }
    customCtrls.clear();

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

    final id = DateTime.now().millisecondsSinceEpoch.toString();

    final etiqueta = EtiquetaModel(
      id: id,
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
      createdAt: DateTime.now(),
    );

    await repo.upsert(uid, etiqueta);

    saving = false;
    notifyListeners();

    return id;
  }

 
  Future<void> salvarEdicao({
    required String uid,
    required TipoEtiquetaModel tipoAtual,
  }) async {
    final err = validar(tipoAtual);
    if (err != null) throw Exception(err);
    if (editingEtiquetaId == null) throw Exception("Nada para editar.");

    saving = true;
    notifyListeners();

    final etiqueta = EtiquetaModel(
      id: editingEtiquetaId!,
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
      createdAt: editingCreatedAt, 
    );

   
    await repo.upsert(uid, etiqueta);

    saving = false;
    notifyListeners();
  }

  @override
  void dispose() {
    produtoCtrl.dispose();
    for (final c in customCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }
}