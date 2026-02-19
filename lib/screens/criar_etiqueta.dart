// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/categorias_local_provider.dart';
import '../providers/setores_local_provider.dart';
import '../providers/tipos_etiqueta_local_provider.dart';
import '../providers/gerar_etiqueta_local_provider.dart';

import '../models/tipo_etiqueta_model.dart';
import '../models/categoria_model.dart';
import '../models/setor_model.dart';
import '../models/etiqueta_model.dart';

import '../data/local/repos/etiquetas_local_repo.dart';
import '../data/local/repos/etiqueta_template_local_repo.dart';

import '../widgets/menu.dart';
import 'etiqueta_preview.dart';
import 'package:flutter/services.dart';


class TitleCaseFormatter extends TextInputFormatter {
  TitleCaseFormatter({required this.allowed, required this.maxLen});
  final RegExp allowed;
  final int maxLen;

  String _toTitleCase(String input) {
    final cleaned = input.replaceAll(RegExp(r"\s+"), " ").trimLeft();
    final words = cleaned.split(" ");
    final fixed = words.map((w) {
      if (w.isEmpty) return w;
      final lower = w.toLowerCase();
      final first = lower.substring(0, 1).toUpperCase();
      final rest = lower.length > 1 ? lower.substring(1) : "";
      return "$first$rest";
    }).join(" ");
    return fixed;
  }

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var t = newValue.text;

    if (t.length > maxLen) t = t.substring(0, maxLen);

  
    final buf = StringBuffer();
    for (final ch in t.characters) {
      if (allowed.hasMatch(ch) || ch == " ") buf.write(ch);
    }
    t = buf.toString();

    t = _toTitleCase(t);

    return TextEditingValue(
      text: t,
      selection: TextSelection.collapsed(offset: t.length),
    );
  }
}

class CriarEtiquetaScreen extends StatefulWidget {
  final String? editarEtiquetaId;
  final String? templateId;

  const CriarEtiquetaScreen({
    super.key,
    this.editarEtiquetaId,
    this.templateId,
  });

  @override
  State<CriarEtiquetaScreen> createState() => _CriarEtiquetaScreenState();
}

class _CriarEtiquetaScreenState extends State<CriarEtiquetaScreen> {
  bool _loaded = false;
  bool _loadedEdit = false;
  bool _loadedTemplate = false;
  final _formKey = GlobalKey<FormState>();
  final _allowedBasic = RegExp(r"^[0-9A-Za-zÀ-ÿçÇ\s]+$");

  String? _validateDates(DateTime? fab, DateTime? val) {
    if (fab == null) return "Selecione a data de fabricação.";
    if (val == null) return "Selecione a data de validade.";
    if (val.isBefore(fab)) return "Validade deve ser igual ou após a fabricação.";
    return null;
  }

  InputDecoration appInputDecoration(String label) {
    const radius = 16.0;

    OutlineInputBorder border(Color c) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide(color: c, width: 1.2),
        );

    return InputDecoration(
      labelText: label,
      border: border(Colors.black.withOpacity(0.18)),
      enabledBorder: border(Colors.black.withOpacity(0.18)),
      focusedBorder: border(const Color(0xFF2B2B2B)),
      errorBorder: border(Colors.red.withOpacity(0.75)),
      focusedErrorBorder: border(Colors.red),
      labelStyle: TextStyle(
        color: Colors.black.withOpacity(0.6),
        fontWeight: FontWeight.w600,
      ),
      floatingLabelStyle: const TextStyle(
        color: Color(0xFF2B2B2B),
        fontWeight: FontWeight.w800,
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;

    final uid = context.read<AuthProvider>().user?.uid;
    if (uid != null) {
      context.read<CategoriasLocalProvider>().fetch(uid);
      context.read<SetoresLocalProvider>().fetch(uid);
      context.read<TiposEtiquetaLocalProvider>().fetch(uid);
      _loaded = true;
    }
  }

  Future<void> _tryLoadEditIfNeeded({
    required String uid,
    required List<CategoriaModel> cats,
    required List<SetorModel> sets,
    required List<TipoEtiquetaModel> tipos,
  }) async {
    if (_loadedEdit) return;

    if (widget.editarEtiquetaId == null) {
      _loadedEdit = true;
      return;
    }

    if (cats.isEmpty || sets.isEmpty || tipos.isEmpty) return;

    final repo = context.read<EtiquetasLocalRepo>();
    final gerar = context.read<GerarEtiquetaLocalProvider>();

    final e = await repo.getById(uid: uid, id: widget.editarEtiquetaId!);

    if (e == null) {
      _loadedEdit = true;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Etiqueta para edição não encontrada.")),
      );
      Navigator.pop(context);
      return;
    }

    final categoriaObj = cats.any((c) => c.id == e.categoriaId)
        ? cats.firstWhere((c) => c.id == e.categoriaId)
        : null;

    final setorObj = sets.any((s) => s.id == e.setorId)
        ? sets.firstWhere((s) => s.id == e.setorId)
        : null;

    final tipoAtual = tipos.any((t) => t.id == e.tipoId)
        ? tipos.firstWhere((t) => t.id == e.tipoId)
        : null;

    gerar.loadFromEtiqueta(
      e: e,
      categoriaObj: categoriaObj,
      setorObj: setorObj,
      tipoAtual: tipoAtual,
    );

    _loadedEdit = true;
  }

  Future<void> _tryLoadTemplateIfNeeded({
    required String uid,
    required List<CategoriaModel> cats,
    required List<SetorModel> sets,
    required List<TipoEtiquetaModel> tipos,
  }) async {
    if (_loadedTemplate) return;

    if (widget.templateId == null) {
      _loadedTemplate = true;
      return;
    }

  
    if (widget.editarEtiquetaId != null) {
      _loadedTemplate = true;
      return;
    }

    if (cats.isEmpty || sets.isEmpty || tipos.isEmpty) return;

    final tplRepo = context.read<EtiquetasTemplatesLocalRepo>();
    final gerar = context.read<GerarEtiquetaLocalProvider>();

    final t = await tplRepo.getById(uid: uid, id: widget.templateId!);

    if (t == null) {
      _loadedTemplate = true;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Modelo diário não encontrado.")),
      );
      Navigator.pop(context);
      return;
    }

    final categoriaObj = cats.any((c) => c.id == t.categoriaId)
        ? cats.firstWhere((c) => c.id == t.categoriaId)
        : null;

    final setorObj = sets.any((s) => s.id == t.setorId)
        ? sets.firstWhere((s) => s.id == t.setorId)
        : null;

    final tipoAtual = tipos.any((x) => x.id == t.tipoId)
        ? tipos.firstWhere((x) => x.id == t.tipoId)
        : null;

    final now = DateTime.now();

    final fake = EtiquetaModel(
      id: "temp",
      tipoId: t.tipoId,
      tipoNome: t.tipoNome,
      produtoNome: t.produtoNome,
      categoriaId: t.categoriaId,
      categoriaNome: t.categoriaNome,
      setorId: t.setorId,
      setorNome: t.setorNome,
      dataFabricacao: now,
      dataValidade: now, 
      camposCustomValores: t.camposCustomValores,
      status: "ativa",
      quantidade: t.quantidadePadrao,
      quantidadeRestante: t.quantidadePadrao,
      statusEstoque: "ativo",
      soldAt: null,
      createdAt: now,
    );

    gerar.resetAll();
    gerar.loadFromEtiqueta(
      e: fake,
      categoriaObj: categoriaObj,
      setorObj: setorObj,
      tipoAtual: tipoAtual,
    );

    _loadedTemplate = true;
  }

  Future<bool> _confirmSaveWithWarning({
    required BuildContext context,
    required String title,
    required String message,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          titlePadding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
          contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          title: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF2F2),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.red.withOpacity(0.15)),
                ),
                child: const Icon(Icons.warning_amber_rounded, color: Colors.red),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: TextStyle(color: Colors.black.withOpacity(0.75)),
          ),
          actions: [
            SizedBox(
              height: 44,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  side: BorderSide(color: Colors.black.withOpacity(0.14)),
                  foregroundColor: Colors.black.withOpacity(0.85),
                ),
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancelar", style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
            SizedBox(
              height: 44,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Salvar mesmo assim", style: TextStyle(fontWeight: FontWeight.w900)),
              ),
            ),
          ],
        );
      },
    );
    return ok ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final compact = w < 835;

    final uid = context.watch<AuthProvider>().user?.uid;
    if (uid == null) {
      return const Scaffold(body: Center(child: Text("Faça login novamente.")));
    }

    final cats = context.watch<CategoriasLocalProvider>().items;
    final sets = context.watch<SetoresLocalProvider>().items;
    final tipos = context.watch<TiposEtiquetaLocalProvider>().items;
    final gerar = context.watch<GerarEtiquetaLocalProvider>();

   
    if (widget.editarEtiquetaId != null) {
      _tryLoadEditIfNeeded(uid: uid, cats: cats, sets: sets, tipos: tipos);
      _loadedTemplate = true;
    } else {
      _tryLoadTemplateIfNeeded(uid: uid, cats: cats, sets: sets, tipos: tipos);
    }

    final bool isEditing = widget.editarEtiquetaId != null;

    final TipoEtiquetaModel? tipoAtual = (gerar.tipoId == null)
        ? null
        : (tipos.any((t) => t.id == gerar.tipoId) ? tipos.firstWhere((t) => t.id == gerar.tipoId) : null);

  
    final deveAutoValidade = tipoAtual?.usarRegraValidadeCategoria == true &&
        gerar.categoria != null &&
        gerar.fabricacao != null;

    if (deveAutoValidade) {
      final novaValidade =
          gerar.fabricacao!.add(Duration(days: gerar.categoria!.diasVencimento));

      if (gerar.validade != novaValidade) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          context.read<GerarEtiquetaLocalProvider>().setValidadeManual(novaValidade);
        });
      }
    }

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
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 980),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => Navigator.pushNamed(context, '/tipos-etiqueta'),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                    margin: const EdgeInsets.only(bottom: 18),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFDF7ED),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.black.withOpacity(0.10)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFed7227),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.label_outline, color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Form(
                            key: _formKey,
                            child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Gerenciar tipos de etiqueta",
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Crie ou edite os modelos de etiquetas e campos personalizados",
                                style: TextStyle(fontSize: 13, color: Colors.black.withOpacity(0.60)),
                              ),
                            ],
                          ),
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.black54),
                      ],
                    ),
                  ),
                ),

                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.black.withOpacity(0.07)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEditing ? "Editar etiqueta" : "Gerar etiqueta",
                        style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isEditing ? "Altere os dados e salve as mudanças." : "Selecione o tipo, preencha os dados e gere sua etiqueta.",
                        style: TextStyle(color: Colors.black.withOpacity(0.60)),
                      ),
                      const SizedBox(height: 18),

                      if (tipos.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFDF7ED),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.black.withOpacity(0.10)),
                          ),
                          child: Text(
                            "Cadastre um tipo de etiqueta primeiro.",
                            style: TextStyle(color: Colors.black.withOpacity(0.60)),
                          ),
                        )
                      else
                        DropdownButtonFormField<String>(
                          value: (gerar.tipoId != null && tipos.any((t) => t.id == gerar.tipoId)) ? gerar.tipoId : null,
                          items: tipos.map((t) => DropdownMenuItem<String>(value: t.id, child: Text(t.nome))).toList(),
                          onChanged: (id) {
                            if (id == null) return;
                            final novoTipo = tipos.firstWhere((t) => t.id == id);
                            context.read<GerarEtiquetaLocalProvider>().setTipoId(id, tipoAtual: novoTipo);
                          },
                          decoration: appInputDecoration(
                             "Tipo de etiqueta",
                           
                          ),
                        ),

                      const SizedBox(height: 12),

                      TextFormField(
                        controller: gerar.produtoCtrl,
                        decoration: appInputDecoration("Nome do produto"),
                        inputFormatters: [
                          TitleCaseFormatter(allowed: RegExp(r"[0-9A-Za-zÀ-ÿçÇ]"), maxLen: 40),
                        ],
                        validator: (v) {
                          final s = (v ?? "").trim();
                          if (s.isEmpty) return "Informe o nome do produto.";
                          if (!_allowedBasic.hasMatch(s)) return "Use apenas letras, números, espaços, acentos e ç.";
                          if (s.length > 40) return "Máximo de 40 caracteres.";
                          return null;
                        },
                      ),

                      const SizedBox(height: 12),

                      TextFormField(
                        controller: gerar.quantidadeCtrl,
                        keyboardType: TextInputType.number,
                        decoration: appInputDecoration("Quantidade"),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(4),
                        ],
                        validator: (v) {
                          final s = (v ?? "").trim();
                          if (s.isEmpty) return "Informe a quantidade.";
                          final n = int.tryParse(s);
                          if (n == null) return "Quantidade inválida.";
                          if (n <= 0) return "Quantidade deve ser maior que 0.";
                          return null;
                        },
                      ),

                      const SizedBox(height: 12),

                      if (!isEditing)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green.withOpacity(0.30)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.check_circle_outline, color: Colors.green.withOpacity(0.90)),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Text("Status do estoque: Ativo", style: TextStyle(fontWeight: FontWeight.w800)),
                              ),
                            ],
                          ),
                        )
                      else
                        DropdownButtonFormField<String>(
                          value: (gerar.editingStatusEstoque == null || gerar.editingStatusEstoque!.isEmpty) ? "ativo" : gerar.editingStatusEstoque,
                          items: const [
                            DropdownMenuItem(value: "ativo", child: Text("Ativo")),
                            DropdownMenuItem(value: "cancelado", child: Text("Cancelado")),
                          ],
                          onChanged: (v) => context.read<GerarEtiquetaLocalProvider>().setStatusEstoqueEdicao(v),
                          decoration: appInputDecoration(
                            "Status do estoque",
                            ),
                        ),

                      const SizedBox(height: 12),

                      _Dropdown<CategoriaModel>(
                        label: "Categoria",
                        value: gerar.categoria,
                        items: cats,
                        getLabel: (c) => c.nome,
                        onChanged: (c) => context.read<GerarEtiquetaLocalProvider>().setCategoria(c, tipoAtual: tipoAtual),
                        emptyHint: "Cadastre categorias na tela Categorias.",
                      ),

                      const SizedBox(height: 12),

                      _Dropdown<SetorModel>(
                        label: "Setor/Responsável",
                        value: gerar.setor,
                        items: sets,
                        getLabel: (s) => s.nome,
                        onChanged: (s) => context.read<GerarEtiquetaLocalProvider>().setSetor(s),
                        emptyHint: "Cadastre setores na tela Setores.",
                      ),

                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: _DateField(
                              label: "Fabricação",
                              value: gerar.fabricacao,
                              onPick: (d) => context.read<GerarEtiquetaLocalProvider>().setFabricacao(d, tipoAtual: tipoAtual),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _DateField(
                              label: "Validade",
                              value: gerar.validade,
                              onPick: (d) => context.read<GerarEtiquetaLocalProvider>().setValidadeManual(d),
                            ),
                          ),
                        ],
                      ),

                      if (tipoAtual?.usarRegraValidadeCategoria == true) ...[
                        const SizedBox(height: 8),
                        Text(
                          "A validade é calculada automaticamente pela categoria (você ainda pode ajustar manualmente).",
                          style: TextStyle(color: Colors.black.withOpacity(0.55), fontSize: 12),
                        ),
                      ],

                      const SizedBox(height: 18),

                      if (tipoAtual != null) ...[
                        const Text(
                          "Campos adicionais",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 10),
                        ...tipoAtual.camposCustom.map((campo) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildCampoDinamico(context, gerar, campo),
                          );
                        }),
                        const SizedBox(height: 6),
                      ],

                      const SizedBox(height: 18),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: gerar.saving
                              ? null
                              : () async {
                               
                                final okForm = _formKey.currentState?.validate() ?? false;
                                if (!okForm) return;

                                
                                final dateErr = _validateDates(gerar.fabricacao, gerar.validade);
                                if (dateErr != null) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(dateErr)));
                                  return;
                                }

                                final now = DateTime.now();
                                final val = gerar.validade!;
                                final days = val.difference(DateTime(now.year, now.month, now.day)).inDays;

                                if (val.isBefore(DateTime(now.year, now.month, now.day))) {
                                  final go = await _confirmSaveWithWarning(
                                    context: context,
                                    title: "Validade vencida",
                                    message: "Essa etiqueta ficará com validade no passado. Deseja salvar mesmo assim?",
                                  );
                                  if (!go) return;
                                } else if (days <= 1) {
                                  final go = await _confirmSaveWithWarning(
                                    context: context,
                                    title: "Validade em alerta",
                                    message: "A validade está muito próxima (até 1 dia). Deseja salvar mesmo assim?",
                                  );
                                  if (!go) return;
                                }
                                  final prov = context.read<GerarEtiquetaLocalProvider>();

                                  final TipoEtiquetaModel? tipoParaSalvar = tipoAtual;
                                  if (tipoParaSalvar == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text("Selecione o tipo de etiqueta.")),
                                    );
                                    return;
                                  }

                                  try {
                                    if (isEditing) {
                                      await prov.salvarEdicao(uid: uid, tipoAtual: tipoParaSalvar);

                                      if (!context.mounted) return;
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => EtiquetaPreviewScreen(
                                            uid: uid,
                                            etiquetaId: widget.editarEtiquetaId!,
                                          ),
                                        ),
                                      );
                                    } else {
                                      final id = await prov.salvarEtiqueta(uid: uid, tipoAtual: tipoParaSalvar);

                                      if (!context.mounted) return;
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => EtiquetaPreviewScreen(uid: uid, etiquetaId: id),
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(e.toString().replaceAll("Exception: ", "")),
                                      ),
                                    );
                                  }
                                },
                          icon: gerar.saving
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                              : Icon(isEditing ? Icons.save_outlined : Icons.local_offer_outlined, color: Colors.white,),
                          label: Text(gerar.saving ? "Salvando..." : (isEditing ? "Salvar alterações" : "Gerar etiqueta")),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF428e2e),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCampoDinamico(
    BuildContext context,
    GerarEtiquetaLocalProvider gerar,
    CampoCustomModel campo,
  ) {
    final label = campo.obrigatorio ? "${campo.label} *" : campo.label;

    switch (campo.tipo) {
      case CampoTipo.multiline: {
        final ctrl = gerar.ctrlFor(
          campo.key,
          initial: (gerar.camposValores[campo.key]?["value"] ?? "").toString(),
        );

        return TextFormField(
          controller: ctrl,
          maxLines: 3,
          decoration: appInputDecoration(label),
          validator: (v) {
            if (campo.obrigatorio && (v ?? "").trim().isEmpty) return "Campo obrigatório.";
            return null;
          },
          onChanged: (v) => context.read<GerarEtiquetaLocalProvider>().setCampoValor(
            key: campo.key, label: campo.label, value: v,
          ),
        );
      }

      case CampoTipo.number: {
        final raw = gerar.camposValores[campo.key]?["value"];
        final ctrl = gerar.ctrlFor(
          campo.key,
          initial: raw == null ? "" : raw.toString(),
        );

        return TextFormField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: appInputDecoration(label),
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10), 
          ],
          validator: (v) {
            if (campo.obrigatorio && (v ?? "").trim().isEmpty) return "Campo obrigatório.";
            final s = (v ?? "").trim();
            if (s.isNotEmpty && int.tryParse(s) == null) return "Número inválido.";
            return null;
          },
          onChanged: (v) => context.read<GerarEtiquetaLocalProvider>().setCampoValor(
            key: campo.key, label: campo.label, value: int.tryParse(v),
          ),
        );
      }

      case CampoTipo.boolType:
        final obj = gerar.camposValores[campo.key];
        final bool boolVal = (obj?["value"] as bool?) ?? false;

        return Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black.withOpacity(0.12)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: CheckboxListTile(
            value: boolVal,
            activeColor: const Color(0xFF428e2e),
            checkColor: Colors.white,
            title: Text(label),
            controlAffinity: ListTileControlAffinity.leading,
            onChanged: (v) => context.read<GerarEtiquetaLocalProvider>().setCampoValor(
              key: campo.key,
              label: campo.label,
              value: v ?? false,
            ),
          ),
        );

      case CampoTipo.date:
        final val = gerar.camposValores[campo.key]?["value"];
        DateTime? dt;
        if (val is DateTime) dt = val;
        if (val is int) dt = DateTime.fromMillisecondsSinceEpoch(val);

        return _DateField(
          label: label,
          value: dt,
          onPick: (d) => context.read<GerarEtiquetaLocalProvider>().setCampoValor(
                key: campo.key,
                label: campo.label,
                value: d,
              ),
        );

      case CampoTipo.text: {
        final ctrl = gerar.ctrlFor(
          campo.key,
          initial: (gerar.camposValores[campo.key]?["value"] ?? "").toString(),
        );

        return TextFormField(
          controller: ctrl,
          decoration: appInputDecoration(label),
          inputFormatters: [
            TitleCaseFormatter(allowed: RegExp(r"[0-9A-Za-zÀ-ÿçÇ]"), maxLen: 40),
          ],
          validator: (v) {
            if (campo.obrigatorio && (v ?? "").trim().isEmpty) return "Campo obrigatório.";
            final s = (v ?? "").trim();
            if (s.isNotEmpty && !_allowedBasic.hasMatch(s)) {
              return "Use apenas letras, números, espaços, acentos e ç.";
            }
            if (s.length > 40) return "Máximo de 40 caracteres.";
            return null;
          },
          onChanged: (v) => context.read<GerarEtiquetaLocalProvider>().setCampoValor(
            key: campo.key, label: campo.label, value: v,
          ),
        );
      }
    }
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final void Function(DateTime d) onPick;

  const _DateField({
    required this.label,
    required this.value,
    required this.onPick,
  });

  InputDecoration _decoration(String label) {
    const radius = 16.0;

    OutlineInputBorder border(Color c) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide(color: c, width: 1.2),
        );

    return InputDecoration(
      labelText: label,
      border: border(Colors.black.withOpacity(0.18)),
      enabledBorder: border(Colors.black.withOpacity(0.18)),
      focusedBorder: border(const Color(0xFF2B2B2B)),
      errorBorder: border(Colors.red.withOpacity(0.75)),
      focusedErrorBorder: border(Colors.red),
      labelStyle: TextStyle(
        color: Colors.black.withOpacity(0.6),
        fontWeight: FontWeight.w600,
      ),
      floatingLabelStyle: const TextStyle(
        color: Color(0xFF2B2B2B),
        fontWeight: FontWeight.w800,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = (value == null)
        ? "Selecionar"
        : "${value!.day.toString().padLeft(2, "0")}/"
          "${value!.month.toString().padLeft(2, "0")}/"
          "${value!.year}";

    return InkWell(
      onTap: () async {
        final rootContext = Navigator.of(context, rootNavigator: true).context;

        final d = await showDatePicker(
          context: rootContext,
          locale: const Locale('pt', 'BR'),
          firstDate: DateTime(2020),
          lastDate: DateTime(2100),
          initialDate: value ?? DateTime.now(),
          builder: (context, child) {
            final base = Theme.of(context);

            const primary = Color(0xFFed7227);
            const onPrimary = Colors.white;

            final dialogShape = RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            );

            return Theme(
              data: base.copyWith(
                useMaterial3: true,
                colorScheme: base.colorScheme.copyWith(
                  primary: primary,
                  onPrimary: onPrimary,
                  surface: Colors.white,
                  onSurface: const Color(0xFF1E1E1E),
                ),
                dialogTheme: DialogTheme(shape: dialogShape),
                textButtonTheme: TextButtonThemeData(
                  style: TextButton.styleFrom(
                    foregroundColor: primary,
                    textStyle: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                datePickerTheme: DatePickerThemeData(
                  shape: dialogShape,
                  backgroundColor: Colors.white,

                  headerBackgroundColor: primary,
                  headerForegroundColor: onPrimary,
                  headerHeadlineStyle: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                  headerHelpStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: onPrimary.withOpacity(0.9),
                  ),

                  dayForegroundColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) return onPrimary;
                    return const Color(0xFF1E1E1E);
                  }),
                  dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) return primary;
                    return Colors.transparent;
                  }),
                 todayForegroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) return onPrimary;
                  return const Color(0xFF1E1E1E); 
                }),
                todayBackgroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) return primary; 
                  return primary.withOpacity(0.14); 
                }),
                todayBorder: BorderSide(
                  color: primary.withOpacity(0.45),
                  width: 1.6,
                ),

                  yearForegroundColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) return onPrimary;
                    return const Color(0xFF1E1E1E);
                  }),
                  yearBackgroundColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) return primary;
                    return Colors.transparent;
                  }),

                  weekdayStyle: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Colors.black.withOpacity(0.55),
                  ),
                  dayStyle: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              child: child!,
            );
          },
        );

        if (d != null) onPick(d);
      },
      child: InputDecorator(
        decoration: _decoration(label),
        child: Row(
          children: [
            Expanded(child: Text(text)),
            const Icon(Icons.calendar_month_outlined, size: 18),
          ],
        ),
      ),
    );
  }
}

class _Dropdown<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<T> items;
  final String Function(T) getLabel;
  final void Function(T?) onChanged;
  final String emptyHint;

  const _Dropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.getLabel,
    required this.onChanged,
    required this.emptyHint,
  });

  InputDecoration appInputDecorationGlobal(String label) {
    const radius = 16.0;

    OutlineInputBorder border(Color c) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide(color: c, width: 1.2),
        );

    return InputDecoration(
      labelText: label,
      border: border(Colors.black.withOpacity(0.18)),
      enabledBorder: border(Colors.black.withOpacity(0.18)),
      focusedBorder: border(const Color(0xFF2B2B2B)),
      errorBorder: border(Colors.red.withOpacity(0.75)),
      focusedErrorBorder: border(Colors.red),
      labelStyle: TextStyle(
        color: Colors.black.withOpacity(0.6),
        fontWeight: FontWeight.w600,
      ),
      floatingLabelStyle: const TextStyle(
        color: Color(0xFF2B2B2B),
        fontWeight: FontWeight.w800,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFDF7ED),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black.withOpacity(0.10)),
        ),
        child: Text(
          emptyHint,
          style: TextStyle(color: Colors.black.withOpacity(0.60)),
        ),
      );
    }

    final safeValue = (value != null && items.contains(value)) ? value : null;

    return DropdownButtonFormField<T>(
      value: safeValue,
      items: items
          .map((e) => DropdownMenuItem<T>(
                value: e,
                child: Text(getLabel(e)),
              ))
          .toList(),
      onChanged: onChanged,
       decoration: appInputDecorationGlobal(label),
    );
  }
}