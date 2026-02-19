// ignore_for_file: deprecated_member_use

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

import '../widgets/menu.dart';
import 'etiqueta_preview.dart';

class CriarEtiquetaScreen extends StatefulWidget {
  
  final String? editarEtiquetaId;

  const CriarEtiquetaScreen({
    super.key,
    this.editarEtiquetaId,
  });

  @override
  State<CriarEtiquetaScreen> createState() => _CriarEtiquetaScreenState();
}

class _CriarEtiquetaScreenState extends State<CriarEtiquetaScreen> {
  bool _loaded = false;
  bool _loadedEdit = false;

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

    final EtiquetaModel? e =
        await repo.getById(uid: uid, id: widget.editarEtiquetaId!);

    if (e == null) {
      _loadedEdit = true;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Etiqueta para edição não encontrada.")),
      );
      Navigator.pop(context);
      return;
    }

    final categoriaObj =
        cats.where((c) => c.id == e.categoriaId).isNotEmpty
            ? cats.firstWhere((c) => c.id == e.categoriaId)
            : null;

    final setorObj = sets.where((s) => s.id == e.setorId).isNotEmpty
        ? sets.firstWhere((s) => s.id == e.setorId)
        : null;

    final tipoAtual = tipos.where((t) => t.id == e.tipoId).isNotEmpty
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


    _tryLoadEditIfNeeded(uid: uid, cats: cats, sets: sets, tipos: tipos);

    final bool isEditing = widget.editarEtiquetaId != null;

    final TipoEtiquetaModel? tipoAtual = (gerar.tipoId == null)
        ? null
        : tipos.where((t) => t.id == gerar.tipoId).isNotEmpty
            ? tipos.firstWhere((t) => t.id == gerar.tipoId)
            : null;

  
    final deveAutoValidade = tipoAtual?.usarRegraValidadeCategoria == true &&
        gerar.categoria != null &&
        gerar.fabricacao != null;

    if (deveAutoValidade) {
      final novaValidade =
          gerar.fabricacao!.add(Duration(days: gerar.categoria!.diasVencimento));
      if (gerar.validade != novaValidade) {
        gerar.validade = novaValidade; 
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 16),
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
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.label_outline,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Gerenciar tipos de etiqueta",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Crie ou edite os modelos de etiquetas e campos personalizados",
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.black.withOpacity(0.60),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 16,
                          color: Colors.black54,
                        ),
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
                        style: const TextStyle(
                            fontSize: 26, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isEditing
                            ? "Altere os dados e salve as mudanças."
                            : "Selecione o tipo, preencha os dados e gere sua etiqueta.",
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
                            border: Border.all(
                                color: Colors.black.withOpacity(0.10)),
                          ),
                          child: Text(
                            "Cadastre um tipo de etiqueta primeiro.",
                            style:
                                TextStyle(color: Colors.black.withOpacity(0.60)),
                          ),
                        )
                      else
                        DropdownButtonFormField<String>(
                          value: (gerar.tipoId != null &&
                                  tipos.any((t) => t.id == gerar.tipoId))
                              ? gerar.tipoId
                              : null,
                          items: tipos
                              .map((t) => DropdownMenuItem<String>(
                                    value: t.id,
                                    child: Text(t.nome),
                                  ))
                              .toList(),
                          onChanged: (id) {
                            if (id == null) return;
                            final novoTipo =
                                tipos.firstWhere((t) => t.id == id);
                            context
                                .read<GerarEtiquetaLocalProvider>()
                                .setTipoId(id, tipoAtual: novoTipo);
                          },
                          decoration: const InputDecoration(
                            labelText: "Tipo de etiqueta",
                            border: OutlineInputBorder(),
                          ),
                        ),

                      const SizedBox(height: 12),

                      TextField(
                        controller: gerar.produtoCtrl,
                        decoration: const InputDecoration(
                          labelText: "Nome do produto",
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 12),

                      TextField(
                        controller: gerar.quantidadeCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: "Quantidade",
                          border: OutlineInputBorder(),
                        ),
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
                                child: Text(
                                  "Status do estoque: Ativo",
                                  style: TextStyle(fontWeight: FontWeight.w800),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        DropdownButtonFormField<String>(
                          value: (gerar.editingStatusEstoque == null || gerar.editingStatusEstoque!.isEmpty)
                              ? "ativo"
                              : gerar.editingStatusEstoque,
                          items: const [
                            DropdownMenuItem(value: "ativo", child: Text("Ativo")),
                            DropdownMenuItem(value: "cancelado", child: Text("Cancelado")),
                          ],
                          onChanged: (v) => context.read<GerarEtiquetaLocalProvider>().setStatusEstoqueEdicao(v),
                          decoration: const InputDecoration(
                            labelText: "Status do estoque",
                            border: OutlineInputBorder(),
                          ),
                        ),

                        const SizedBox(height: 12),

                      _Dropdown(
                        label: "Categoria",
                        value: gerar.categoria,
                        items: cats,
                        getLabel: (c) => c.nome,
                        onChanged: (c) => context
                            .read<GerarEtiquetaLocalProvider>()
                            .setCategoria(c, tipoAtual: tipoAtual),
                        emptyHint: "Cadastre categorias na tela Categorias.",
                      ),

                      const SizedBox(height: 12),

                      _Dropdown(
                        label: "Setor/Responsável",
                        value: gerar.setor,
                        items: sets,
                        getLabel: (s) => s.nome,
                        onChanged: (s) => context
                            .read<GerarEtiquetaLocalProvider>()
                            .setSetor(s),
                        emptyHint: "Cadastre setores na tela Setores.",
                      ),

                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: _DateField(
                              label: "Fabricação",
                              value: gerar.fabricacao,
                              onPick: (d) => context
                                  .read<GerarEtiquetaLocalProvider>()
                                  .setFabricacao(d, tipoAtual: tipoAtual),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _DateField(
                              label: "Validade",
                              value: gerar.validade,
                              onPick: (d) => context
                                  .read<GerarEtiquetaLocalProvider>()
                                  .setValidadeManual(d),
                            ),
                          ),
                        ],
                      ),

                      if (tipoAtual?.usarRegraValidadeCategoria == true) ...[
                        const SizedBox(height: 8),
                        Text(
                          "A validade é calculada automaticamente pela categoria (você ainda pode ajustar manualmente).",
                          style: TextStyle(
                              color: Colors.black.withOpacity(0.55),
                              fontSize: 12),
                        ),
                      ],

                      const SizedBox(height: 18),

                      if (tipoAtual != null) ...[
                        const Text(
                          "Campos adicionais",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w800),
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
                                  final prov =
                                      context.read<GerarEtiquetaLocalProvider>();

                                  final TipoEtiquetaModel? tipoParaSalvar =
                                      tipoAtual;
                                  if (tipoParaSalvar == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content:
                                              Text("Selecione o tipo de etiqueta.")),
                                    );
                                    return;
                                  }

                                  try {
                                    if (isEditing) {
                                      await prov.salvarEdicao(
                                        uid: uid,
                                        tipoAtual: tipoParaSalvar,
                                      );

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
                                      final id = await prov.salvarEtiqueta(
                                        uid: uid,
                                        tipoAtual: tipoParaSalvar,
                                      );

                                      if (!context.mounted) return;
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => EtiquetaPreviewScreen(
                                            uid: uid,
                                            etiquetaId: id,
                                          ),
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          e.toString().replaceAll("Exception: ", ""),
                                        ),
                                      ),
                                    );
                                  }
                                },
                          icon: gerar.saving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Icon(isEditing
                                  ? Icons.save_outlined
                                  : Icons.local_offer_outlined),
                          label: Text(gerar.saving
                              ? "Salvando..."
                              : (isEditing ? "Salvar alterações" : "Gerar etiqueta")),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2B2B2B),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
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

        return TextField(
          controller: ctrl,
          maxLines: 3,
          decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
          onChanged: (v) => context.read<GerarEtiquetaLocalProvider>().setCampoValor(
            key: campo.key,
            label: campo.label,
            value: v,
          ),
        );
      }

      case CampoTipo.number: {
        final raw = gerar.camposValores[campo.key]?["value"];
        final ctrl = gerar.ctrlFor(
          campo.key,
          initial: raw == null ? "" : raw.toString(),
        );

        return TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
          onChanged: (v) => context.read<GerarEtiquetaLocalProvider>().setCampoValor(
            key: campo.key,
            label: campo.label,
            value: num.tryParse(v),
          ),
        );
      }

      case CampoTipo.boolType:
        final obj = gerar.camposValores[campo.key];
        final boolVal = (obj?["value"] as bool?) ?? false;

        return Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black.withOpacity(0.12)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: SwitchListTile(
            title: Text(label),
            value: boolVal,
            onChanged: (v) => context.read<GerarEtiquetaLocalProvider>().setCampoValor(
                  key: campo.key,
                  label: campo.label,
                  value: v,
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

        return TextField(
          controller: ctrl,
          decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
          onChanged: (v) => context.read<GerarEtiquetaLocalProvider>().setCampoValor(
            key: campo.key,
            label: campo.label,
            value: v,
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

  @override
  Widget build(BuildContext context) {
    final text = (value == null)
        ? "Selecionar"
        : "${value!.day.toString().padLeft(2, "0")}/"
            "${value!.month.toString().padLeft(2, "0")}/"
            "${value!.year}";

    return InkWell(
      onTap: () async {
        final d = await showDatePicker(
          context: context,
          firstDate: DateTime(2020),
          lastDate: DateTime(2100),
          initialDate: value ?? DateTime.now(),
        );
        if (d != null) onPick(d);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
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
        child: Text(emptyHint,
            style: TextStyle(color: Colors.black.withOpacity(0.60))),
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
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }
}