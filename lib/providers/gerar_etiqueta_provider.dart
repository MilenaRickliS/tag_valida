import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/categoria_model.dart';
import '../models/setor_model.dart';
import '../models/tipo_etiqueta_model.dart';
import '../models/etiqueta_model.dart';
import '../models/estoque_mov_model.dart';
import '../services/firestore_paths.dart';

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

 
  String? editingEtiquetaId;
  DateTime? editingCreatedAt;

  num? editingQuantidade;
  num? editingQuantidadeRestante;
  String? editingStatusEstoque; 
  DateTime? editingSoldAt;

  void clearEditing() {
    editingEtiquetaId = null;
    editingCreatedAt = null;
    editingQuantidade = null;
    editingQuantidadeRestante = null;
    editingStatusEstoque = null;
    editingSoldAt = null;
  }

  void resetAll() {
    clearEditing();
    tipoId = null;
    categoria = null;
    setor = null;
    fabricacao = null;
    validade = null;
    produtoCtrl.clear();
    quantidadeCtrl.text = "1";
    editingStatusEstoque = "ativo";
    camposValores.clear();
    notifyListeners();
  }


  Map<String, Map<String, dynamic>> _sanitizeCamposValoresEpoch(
    Map<String, Map<String, dynamic>> input,
  ) {
    dynamic fix(dynamic v) {
      if (v == null) return null;
      if (v is DateTime) return v.millisecondsSinceEpoch;
      if (v is Timestamp) return v.millisecondsSinceEpoch;
      if (v is Map) return v.map((k, val) => MapEntry(k.toString(), fix(val)));
      if (v is List) return v.map(fix).toList();
      return v;
    }

    return input.map((k, v) {
      final map = Map<String, dynamic>.from(v);
      map["label"] = (map["label"] ?? "").toString();
      map["value"] = fix(map["value"]);
      return MapEntry(k, map);
    });
  }

  num _parseQtdOrThrow() {
    final raw = quantidadeCtrl.text.trim().replaceAll(",", ".");
    final v = num.tryParse(raw);
    if (v == null || v <= 0) throw Exception("Quantidade inválida.");
    return v;
  }

  String _gerarLotePadrao() {
    final nowBr = DateTime.now().toUtc().subtract(const Duration(hours: 3));
    String two(int n) => n.toString().padLeft(2, "0");

    final yy = two(nowBr.year % 100);
    final mm = two(nowBr.month);
    final dd = two(nowBr.day);

    final random = Random().nextInt(1000).toString().padLeft(3, "0");
    return "PV-$yy$mm$dd-$random";
  }

  void ensureLoteAuto({required TipoEtiquetaModel tipoAtual}) {
    if (!tipoAtual.controlaLote) return;

    final existing = camposValores["lote"]?["value"]?.toString().trim();
    if (existing != null && existing.isNotEmpty) return;

    setCampoValor(key: "lote", label: "Lote", value: _gerarLotePadrao());
  }

  void setTipoId(String? id, {TipoEtiquetaModel? tipoAtual}) {
    tipoId = id;
    clearEditing();
    editingStatusEstoque = "ativo";
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

  void setStatusEstoqueEdicao(String? v) {
    editingStatusEstoque = (v ?? "ativo").trim().toLowerCase();
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

  Future<void> _movRegistrar({
    required String uid,
    required String etiquetaId,
    required String tipo,
    required num quantidade,
    required String produtoNome,
    required String motivo,
  }) async {
    final ref = paths.estoqueMov(uid).doc();
    final payload = {
      "id": ref.id,
      "etiquetaId": etiquetaId,
      "tipo": tipo, 
      "quantidade": quantidade,
      "produtoNome": produtoNome,
      "motivo": motivo,
      "createdAt": FieldValue.serverTimestamp(),
      
    };
    await ref.set(payload);
  }

  Future<void> _movRegistrarEntrada({
    required String uid,
    required String etiquetaId,
    required num quantidade,
    required String produtoNome,
    required String motivo,
  }) =>
      _movRegistrar(
        uid: uid,
        etiquetaId: etiquetaId,
        tipo: EstoqueMovModel.tipoEntrada,
        quantidade: quantidade,
        produtoNome: produtoNome,
        motivo: motivo,
      );

  Future<void> _movRegistrarVenda({
    required String uid,
    required String etiquetaId,
    required num quantidade,
    required String produtoNome,
    required String motivo,
  }) =>
      _movRegistrar(
        uid: uid,
        etiquetaId: etiquetaId,
        tipo: EstoqueMovModel.tipoVenda,
        quantidade: quantidade,
        produtoNome: produtoNome,
        motivo: motivo,
      );

  Future<void> _movRegistrarCancelamento({
    required String uid,
    required String etiquetaId,
    required num quantidade,
    required String produtoNome,
    required String motivo,
  }) =>
      _movRegistrar(
        uid: uid,
        etiquetaId: etiquetaId,
        tipo: EstoqueMovModel.tipoCancelamento,
        quantidade: quantidade,
        produtoNome: produtoNome,
        motivo: motivo,
      );

  Future<void> _movRegistrarAjusteEntrada({
    required String uid,
    required String etiquetaId,
    required num quantidade,
    required String produtoNome,
    required String motivo,
  }) =>
      _movRegistrar(
        uid: uid,
        etiquetaId: etiquetaId,
        tipo: EstoqueMovModel.tipoAjusteEntrada,
        quantidade: quantidade,
        produtoNome: produtoNome,
        motivo: motivo,
      );

  Future<void> _movRegistrarAjusteSaida({
    required String uid,
    required String etiquetaId,
    required num quantidade,
    required String produtoNome,
    required String motivo,
  }) =>
      _movRegistrar(
        uid: uid,
        etiquetaId: etiquetaId,
        tipo: EstoqueMovModel.tipoAjusteSaida,
        quantidade: quantidade,
        produtoNome: produtoNome,
        motivo: motivo,
      );

  Future<void> _ensureTemplate({
    required String uid,
    required EtiquetaModel etiqueta,
    required Map<String, Map<String, dynamic>> safeCampos,
  }) async {
    
    final q = await paths.etiquetasTemplates(uid)
        .where("produtoNome", isEqualTo: etiqueta.produtoNome)
        .where("categoriaId", isEqualTo: etiqueta.categoriaId)
        .where("setorId", isEqualTo: etiqueta.setorId)
        .limit(1)
        .get();

    if (q.docs.isNotEmpty) return;

    final ref = paths.etiquetasTemplates(uid).doc();
    final payload = {
      "id": ref.id,
      "tipoId": etiqueta.tipoId,
      "tipoNome": etiqueta.tipoNome,
      "produtoNome": etiqueta.produtoNome,
      "categoriaId": etiqueta.categoriaId,
      "categoriaNome": etiqueta.categoriaNome,
      "setorId": etiqueta.setorId,
      "setorNome": etiqueta.setorNome,
      "camposCustomValores": safeCampos,
      "quantidadePadrao": etiqueta.quantidade,
      "createdAt": FieldValue.serverTimestamp(),
    };
    await ref.set(payload);
  }

  Future<String> salvarEtiqueta({
    required String uid,
    required TipoEtiquetaModel tipoAtual,
  }) async {
    final err = validar(tipoAtual);
    if (err != null) throw Exception(err);

    ensureLoteAuto(tipoAtual: tipoAtual);

    saving = true;
    notifyListeners();

    final ref = paths.etiquetas(uid).doc();
    final qtd = _parseQtdOrThrow();

    final safeCampos = _sanitizeCamposValoresEpoch(camposValores);

    final fab = fabricacao!;
    final val = validade!;
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    final payload = {
      "id": ref.id,

      "tipoId": tipoAtual.id,
      "tipoNome": tipoAtual.nome,

      "produtoNome": produtoCtrl.text.trim(),

      "categoriaId": categoria!.id,
      "categoriaNome": categoria!.nome,

      "setorId": setor!.id,
      "setorNome": setor!.nome,

     
      "dataFabricacao": Timestamp.fromDate(fab),
      "dataValidade": Timestamp.fromDate(val),
      "dataFabricacaoMs": fab.millisecondsSinceEpoch,
      "dataValidadeMs": val.millisecondsSinceEpoch,

      "camposCustomValores": safeCampos,

      "status": "ativa",

      "quantidade": qtd,
      "quantidadeRestante": qtd,
      "statusEstoque": "ativo",
      "soldAt": null,

      
      "createdAt": FieldValue.serverTimestamp(),
      "updatedAt": FieldValue.serverTimestamp(),
      "createdAtMs": nowMs,
      "updatedAtMs": nowMs,
    };

    await ref.set(payload);

   
    final etiqueta = EtiquetaModel(
      id: ref.id,
      tipoId: tipoAtual.id,
      tipoNome: tipoAtual.nome,
      produtoNome: produtoCtrl.text.trim(),
      categoriaId: categoria!.id,
      categoriaNome: categoria!.nome,
      setorId: setor!.id,
      setorNome: setor!.nome,
      dataFabricacao: fab,
      dataValidade: val,
      camposCustomValores: safeCampos,
      status: "ativa",
      createdAt: DateTime.fromMillisecondsSinceEpoch(nowMs),
      quantidade: qtd,
      quantidadeRestante: qtd,
      statusEstoque: "ativo",
      soldAt: null,
    );

    await _ensureTemplate(uid: uid, etiqueta: etiqueta, safeCampos: safeCampos);

   
    await _movRegistrarEntrada(
      uid: uid,
      etiquetaId: ref.id,
      quantidade: qtd,
      produtoNome: etiqueta.produtoNome,
      motivo: "Criação da etiqueta",
    );

    saving = false;
    notifyListeners();
    return ref.id;
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

    final doc = paths.etiquetas(uid).doc(editingEtiquetaId!);
    final now = DateTime.now();
    final nowMs = now.millisecondsSinceEpoch;

    final qtdNova = _parseQtdOrThrow();
    final statusWanted = (editingStatusEstoque ?? "ativo").trim().toLowerCase();

   
    final snap = await doc.get();
    if (!snap.exists) {
      saving = false;
      notifyListeners();
      throw Exception("Etiqueta não encontrada para edição.");
    }
    final data = snap.data() as Map<String, dynamic>;

    final oldQtd = (data["quantidade"] as num?) ?? 1;
    final oldRest = (data["quantidadeRestante"] as num?) ?? oldQtd;
    final oldStatus = (data["statusEstoque"] ?? "ativo").toString().trim().toLowerCase();
    final oldCancelado = oldStatus == "cancelado";

    num restNovo;
    if (statusWanted == "cancelado") {
      restNovo = 0;
    } else if (statusWanted == "vendido") {
      restNovo = 0;
    } else {
      final saiuAntes = (oldQtd - oldRest);
      restNovo = max<num>(0, qtdNova - saiuAntes);
    }

 
    if (oldCancelado && statusWanted != "cancelado") {
      final voltou = restNovo;
      if (voltou > 0) {
        await _movRegistrarAjusteEntrada(
          uid: uid,
          etiquetaId: editingEtiquetaId!,
          quantidade: voltou,
          produtoNome: (data["produtoNome"] ?? "").toString(),
          motivo: "Reativação (saindo de cancelado)",
        );
      }
    }

    if (!oldCancelado && statusWanted == "cancelado" && oldRest > 0) {
      await _movRegistrarCancelamento(
        uid: uid,
        etiquetaId: editingEtiquetaId!,
        quantidade: oldRest,
        produtoNome: (data["produtoNome"] ?? "").toString(),
        motivo: "Cancelado na edição",
      );
    }

    if (statusWanted == "vendido") {
      final vendeu = oldRest - restNovo; 
      if (vendeu > 0) {
        await _movRegistrarVenda(
          uid: uid,
          etiquetaId: editingEtiquetaId!,
          quantidade: vendeu,
          produtoNome: (data["produtoNome"] ?? "").toString(),
          motivo: "Venda (na edição)",
        );
      }
    }

    if (statusWanted != "cancelado" && statusWanted != "vendido") {
      final diff = restNovo - oldRest;
      if (diff > 0) {
        await _movRegistrarAjusteEntrada(
          uid: uid,
          etiquetaId: editingEtiquetaId!,
          quantidade: diff,
          produtoNome: (data["produtoNome"] ?? "").toString(),
          motivo: "Ajuste na edição (entrada)",
        );
      } else if (diff < 0) {
        await _movRegistrarAjusteSaida(
          uid: uid,
          etiquetaId: editingEtiquetaId!,
          quantidade: diff.abs(),
          produtoNome: (data["produtoNome"] ?? "").toString(),
          motivo: "Ajuste na edição (saída)",
        );
      }
    }

    final statusEstoque = EtiquetaModel.calcStatusEstoque(
      restante: restNovo,
      current: statusWanted,
    );

    final safeCampos = _sanitizeCamposValoresEpoch(camposValores);

    final fab = fabricacao!;
    final val = validade!;

    final update = {
      "tipoId": tipoAtual.id,
      "tipoNome": tipoAtual.nome,

      "produtoNome": produtoCtrl.text.trim(),

      "categoriaId": categoria!.id,
      "categoriaNome": categoria!.nome,

      "setorId": setor!.id,
      "setorNome": setor!.nome,

      "dataFabricacao": Timestamp.fromDate(fab),
      "dataValidade": Timestamp.fromDate(val),
      "dataFabricacaoMs": fab.millisecondsSinceEpoch,
      "dataValidadeMs": val.millisecondsSinceEpoch,

      "camposCustomValores": safeCampos,

      "status": "ativa",

      "quantidade": qtdNova,
      "quantidadeRestante": restNovo,
      "statusEstoque": statusEstoque,

      "soldAt": statusEstoque == "vendido"
          ? (data["soldAt"] ?? FieldValue.serverTimestamp())
          : null,

      "updatedAt": FieldValue.serverTimestamp(),
      "updatedAtMs": nowMs,
    };

    await doc.update(update);


    editingQuantidade = qtdNova;
    editingQuantidadeRestante = restNovo;

    saving = false;
    notifyListeners();
  }

 
  Future<void> ajustarRestante({
    required String uid,
    required String etiquetaId,
    required num novoRestante,
  }) async {
    final doc = paths.etiquetas(uid).doc(etiquetaId);

    final snap = await doc.get();
    if (!snap.exists) throw Exception("Etiqueta não encontrada.");

    final data = snap.data() as Map<String, dynamic>;
    final oldRest = (data["quantidadeRestante"] as num?) ?? 0;

    await doc.update({
      "quantidadeRestante": novoRestante,
      "statusEstoque": EtiquetaModel.calcStatusEstoque(
        restante: novoRestante,
        current: (data["statusEstoque"] ?? "ativo").toString(),
      ),
      "updatedAt": FieldValue.serverTimestamp(),
      "updatedAtMs": DateTime.now().millisecondsSinceEpoch,
    });

    final diff = novoRestante - oldRest;
    if (diff > 0) {
      await _movRegistrarAjusteEntrada(
        uid: uid,
        etiquetaId: etiquetaId,
        quantidade: diff,
        produtoNome: (data["produtoNome"] ?? "").toString(),
        motivo: "Ajuste manual (entrada)",
      );
    } else if (diff < 0) {
      await _movRegistrarAjusteSaida(
        uid: uid,
        etiquetaId: etiquetaId,
        quantidade: diff.abs(),
        produtoNome: (data["produtoNome"] ?? "").toString(),
        motivo: "Ajuste manual (saída)",
      );
    }

    notifyListeners();
  }

  @override
  void dispose() {
    produtoCtrl.dispose();
    quantidadeCtrl.dispose();
    super.dispose();
  }
}