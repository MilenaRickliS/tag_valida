import 'package:flutter/material.dart';
import '../models/categoria_model.dart';
import '../models/setor_model.dart';
import '../models/tipo_etiqueta_model.dart';
import '../models/etiqueta_model.dart';
import '../data/local/repos/etiquetas_local_repo.dart';
import '../providers/estoque_mov_local_provider.dart';
import '../models/estoque_mov_model.dart';
import '../models/etiqueta_template_model.dart';
import './../data/local/repos/etiqueta_template_local_repo.dart';
import 'dart:math';

class GerarEtiquetaLocalProvider extends ChangeNotifier {
  final EtiquetasLocalRepo repo;
  final EstoqueMovLocalProvider mov; 
  final EtiquetasTemplatesLocalRepo templateRepo;
  GerarEtiquetaLocalProvider({required this.repo, required this.mov, required this.templateRepo,});

  String? tipoId;
  CategoriaModel? categoria;
  SetorModel? setor;

  final produtoCtrl = TextEditingController();

  DateTime? fabricacao;
  DateTime? validade;


  final quantidadeCtrl = TextEditingController(text: "1"); 

  final Map<String, Map<String, dynamic>> camposValores = {};
  bool saving = false;

  String? editingEtiquetaId;
  DateTime? editingCreatedAt;

  num? editingQuantidade;
  num? editingQuantidadeRestante;
  String? editingStatusEstoque;
  DateTime? editingSoldAt;


  final Map<String, TextEditingController> customCtrls = {};

  Map<String, Map<String, dynamic>> _sanitizeCamposValores(
    Map<String, Map<String, dynamic>> input,
  ) {
    dynamic fix(dynamic v) {
      if (v == null) return null;
      if (v is DateTime) return v.millisecondsSinceEpoch;
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

  void setQuantidadeText(String v) {
    quantidadeCtrl.text = v;
    notifyListeners();
  }

  void setCancelado(bool cancelado) {
    editingStatusEstoque = cancelado ? "cancelado" : "ativo";
    notifyListeners();
  }

  bool get isCancelado => editingStatusEstoque == "cancelado";

  TextEditingController ctrlFor(String key, {String initial = ""}) {
    return customCtrls.putIfAbsent(key, () => TextEditingController(text: initial));
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
    for (final c in customCtrls.values) {
      c.dispose();
    }
    customCtrls.clear();

    notifyListeners();
  }

  num _parseQtdOrThrow() {
    final raw = quantidadeCtrl.text.trim().replaceAll(",", ".");
    final v = num.tryParse(raw);
    if (v == null || v <= 0) throw Exception("Quantidade inválida.");
    return v;
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


    editingQuantidade = e.quantidade;
    editingQuantidadeRestante = e.quantidadeRestante;
    editingStatusEstoque = e.statusEstoque;
    editingSoldAt = e.soldAt;


    quantidadeCtrl.text = e.quantidade.toString();

    camposValores
      ..clear()
      ..addAll((e.camposCustomValores).map((k, v) => MapEntry(k, Map<String, dynamic>.from(v as Map))));

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

    editingStatusEstoque = "ativo";

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

    final lote = _gerarLotePadrao();

    setCampoValor(
      key: "lote",
      label: "Lote",
      value: lote,
    );
  }

  void setStatusEstoqueEdicao(String? v) {
    editingStatusEstoque = v ?? "ativo";
    notifyListeners();
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

    ensureLoteAuto(tipoAtual: tipoAtual);

    saving = true;
    notifyListeners();

    final now = DateTime.now();
    final id = now.millisecondsSinceEpoch.toString();
    final qtd = _parseQtdOrThrow();
    final safeCampos = _sanitizeCamposValores(camposValores);
    final lote = (safeCampos["lote"]?["value"] ?? "").toString().trim();
    final loteFinal = lote.isEmpty ? null : lote;

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
      camposCustomValores: safeCampos,
      lote: loteFinal,
      status: "ativa",
      createdAt: now,
      quantidade: qtd,
      quantidadeRestante: qtd,
      statusEstoque: "ativo",
      soldAt: null,
    );

    await repo.upsert(uid, etiqueta);
    
    final existing = await templateRepo.findByKey(
      uid: uid,
      produtoNome: etiqueta.produtoNome,
      categoriaId: etiqueta.categoriaId,
      setorId: etiqueta.setorId,
    );

  
    final templateId =
        existing?.id ?? DateTime.now().millisecondsSinceEpoch.toString();

    final template = EtiquetaTemplateModel(
      id: templateId,
      tipoId: etiqueta.tipoId,
      tipoNome: etiqueta.tipoNome,
      produtoNome: etiqueta.produtoNome,
      categoriaId: etiqueta.categoriaId,
      categoriaNome: etiqueta.categoriaNome,
      setorId: etiqueta.setorId,
      setorNome: etiqueta.setorNome,
      camposCustomValores: safeCampos,
      quantidadePadrao: etiqueta.quantidade,
      createdAt: existing?.createdAt ?? DateTime.now(),
    );


    await templateRepo.upsert(uid, template);

    await mov.registrarEntrada(
      uid: uid,
      etiquetaId: id,
      quantidade: qtd,
      produtoNome: etiqueta.produtoNome,
      motivo: "Criação da etiqueta",
    );

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

    final now = DateTime.now();
    final qtdNova = _parseQtdOrThrow();
    final statusWanted = (editingStatusEstoque ?? "ativo").trim().toLowerCase();
    
    
    final before = await repo.getById(uid: uid, id: editingEtiquetaId!);
    if (before == null) {
      saving = false;
      notifyListeners();
      throw Exception("Etiqueta não encontrada para edição.");
    }

    final oldQtd = before.quantidade;
    final oldRest = before.quantidadeRestante;
    final oldStatus = (before.statusEstoque).trim().toLowerCase(); 
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
          await mov.registrar(
            uid: uid,
            etiquetaId: before.id,
            tipo: EstoqueMovModel.tipoAjusteEntrada,
            quantidade: voltou,
            produtoNome: before.produtoNome,
            motivo: "Reativação (saindo de cancelado)",
          );
        }
      }

    
    if (!oldCancelado && statusWanted == "cancelado" && oldRest > 0) {
      await mov.registrarCancelamento(
        uid: uid,
        etiquetaId: before.id,
        quantidade: oldRest,
        produtoNome: before.produtoNome,
        motivo: "Cancelado na edição",
      );
    }

    if (statusWanted == "vendido") {
      final vendeu = oldRest - restNovo; 
      if (vendeu > 0) {
        await mov.registrarVenda(
          uid: uid,
          etiquetaId: before.id,
          quantidade: vendeu,
          produtoNome: before.produtoNome,
          motivo: "Venda (na edição)",
        );
      }
    }

   
    if (statusWanted != "cancelado" && statusWanted != "vendido") {
      final diff = restNovo - oldRest;
      if (diff > 0) {
        await mov.registrar(
          uid: uid,
          etiquetaId: before.id,
          tipo: EstoqueMovModel.tipoAjusteEntrada,
          quantidade: diff,
          produtoNome: before.produtoNome,
          motivo: "Ajuste na edição (entrada)",
        );
      } else if (diff < 0) {
        await mov.registrar(
          uid: uid,
          etiquetaId: before.id,
          tipo: EstoqueMovModel.tipoAjusteSaida,
          quantidade: diff.abs(),
          produtoNome: before.produtoNome,
          motivo: "Ajuste na edição (saída)",
        );
      }
    }

    final statusEstoque = EtiquetaModel.calcStatusEstoque(
      restante: restNovo,
      current: statusWanted,
    );

    final safeCampos = _sanitizeCamposValores(camposValores);
    final lote = (safeCampos["lote"]?["value"] ?? "").toString().trim();
    final loteFinal = lote.isEmpty ? null : lote;

    final etiqueta = EtiquetaModel(
      id: before.id,
      tipoId: tipoAtual.id,
      tipoNome: tipoAtual.nome,
      produtoNome: produtoCtrl.text.trim(),
      categoriaId: categoria!.id,
      categoriaNome: categoria!.nome,
      setorId: setor!.id,
      setorNome: setor!.nome,
      dataFabricacao: fabricacao!,
      dataValidade: validade!,
      camposCustomValores: safeCampos,
      lote: loteFinal,
      status: "ativa",
      createdAt: before.createdAt,
      quantidade: qtdNova,
      quantidadeRestante: restNovo,
      statusEstoque: statusEstoque,
      soldAt: statusEstoque == "vendido" ? (before.soldAt ?? now) : null,
    );

    await repo.upsert(uid, etiqueta);

   
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
   final before = await repo.getById(uid: uid, id: etiquetaId);
    if (before == null) throw Exception("Etiqueta não encontrada.");

    final oldRest = before.quantidadeRestante;

    await repo.ajustarQuantidade(uid: uid, etiquetaId: etiquetaId, novoRestante: novoRestante);

    final diff = novoRestante - oldRest;
    if (diff > 0) {
      await mov.registrar(
        uid: uid,
        etiquetaId: etiquetaId,
        tipo: EstoqueMovModel.tipoAjusteEntrada,
        quantidade: diff,
        produtoNome: before.produtoNome,
        motivo: "Ajuste manual (entrada)",
      );
    } else if (diff < 0) {
      await mov.registrar(
        uid: uid,
        etiquetaId: etiquetaId,
        tipo: EstoqueMovModel.tipoAjusteSaida,
        quantidade: diff.abs(),
        produtoNome: before.produtoNome,
        motivo: "Ajuste manual (saída)",
      );
    }
    notifyListeners();
  }

  @override
  void dispose() {
    produtoCtrl.dispose();
    quantidadeCtrl.dispose();
    for (final c in customCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }
}