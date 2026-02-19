// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

import '../providers/tipos_etiqueta_local_provider.dart';
import '../providers/auth_provider.dart';
import '../models/tipo_etiqueta_model.dart';
import '../widgets/menu.dart';

final _nomeDeny = FilteringTextInputFormatter.deny(
  RegExp(r"[^0-9A-Za-zÀ-ÖØ-öø-ÿÇç ]"),
);

class TitleCaseEachWordFormatter extends TextInputFormatter {
  const TitleCaseEachWordFormatter();

  bool _isLetter(String ch) => RegExp(r"[A-Za-zÀ-ÖØ-öø-ÿÇç]").hasMatch(ch);

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final t = newValue.text;
    if (t.isEmpty) return newValue;

    final lower = t.toLowerCase();
    final chars = lower.split('');

    bool capNext = true;

    for (int i = 0; i < chars.length; i++) {
      final ch = chars[i];

      if (ch == ' ') {
        capNext = true;
        continue;
      }

      if (capNext && _isLetter(ch)) {
        chars[i] = ch.toUpperCase();
        capNext = false;
      } else {
        capNext = false;
      }
    }

    final formatted = chars.join();

    final sel = newValue.selection;
    final clampedBase = sel.baseOffset.clamp(0, formatted.length);
    final clampedExtent = sel.extentOffset.clamp(0, formatted.length);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection(baseOffset: clampedBase, extentOffset: clampedExtent),
      composing: TextRange.empty,
    );
  }
}

class TiposEtiquetaScreen extends StatefulWidget {
  const TiposEtiquetaScreen({super.key});

  @override
  State<TiposEtiquetaScreen> createState() => _TiposEtiquetaScreenState();
}

class _TiposEtiquetaScreenState extends State<TiposEtiquetaScreen> {
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;

    final uid = context.read<AuthProvider>().user?.uid;
    if (uid != null) {
      context.read<TiposEtiquetaLocalProvider>().fetch(uid);
      _loaded = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final compact = w < 835;

    final uid = context.watch<AuthProvider>().user?.uid;
    if (uid == null) {
      return const Scaffold(body: Center(child: Text("Faça login novamente.")));
    }

    final prov = context.watch<TiposEtiquetaLocalProvider>();

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

     
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.10),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF428e2e),
          elevation: 0,
          onPressed: () => _openTipoDialog(context, uid),
          icon: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFF428e2e),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.add, color: Colors.white, size: 20),
          ),
          label: const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Text("Novo tipo", style: TextStyle(fontWeight: FontWeight.w800)),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: Colors.black.withOpacity(0.08)),
          ),
        ),
      ),

      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 980),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Tipos de etiqueta",
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  "Crie modelos com campos personalizados para gerar etiquetas rapidamente.",
                  style: TextStyle(color: Colors.black.withOpacity(0.60)),
                ),
                const SizedBox(height: 16),
                if (prov.loading)
                  const Expanded(child: Center(child: CircularProgressIndicator()))
                else if (prov.items.isEmpty)
                  Expanded(
                    child: Center(
                      child: Text(
                        "Nenhum tipo cadastrado ainda.\nClique em “Novo tipo”.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.black.withOpacity(0.6)),
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.separated(
                      itemCount: prov.items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final t = prov.items[i];
                        return _TipoCard(
                          tipo: t,
                          onEdit: () => _openTipoDialog(context, uid, tipo: t),
                          onDelete: () => _confirmDelete(context, uid, t),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  Future<void> _confirmDelete(BuildContext context, String uid, TipoEtiquetaModel t) async {
    final ok = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.35),
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        contentPadding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
        actionsPadding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
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
              child: const Icon(Icons.delete_outline, color: Colors.red),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text("Excluir tipo?", style: TextStyle(fontWeight: FontWeight.w900)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("O tipo:", style: TextStyle(color: Colors.black.withOpacity(0.65))),
            const SizedBox(height: 4),
            Text(
              "“${t.nome}”",
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            const SizedBox(height: 10),
            Text(
              "Será removido da sua lista de tipos.",
              style: TextStyle(color: Colors.black.withOpacity(0.60), height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF2B2B2B),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text("Cancelar", style: TextStyle(fontWeight: FontWeight.w700)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB00020),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text("Excluir", style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );

    if (ok == true && context.mounted) {
      await context.read<TiposEtiquetaLocalProvider>().delete(uid, t.id);
    }
  }


  Future<void> _openTipoDialog(BuildContext context, String uid, {TipoEtiquetaModel? tipo}) async {
    final isEdit = tipo != null;

    final nomeCtrl = TextEditingController(text: tipo?.nome ?? "");
    final descCtrl = TextEditingController(text: tipo?.descricao ?? "");
    bool usarRegra = tipo?.usarRegraValidadeCategoria ?? true;

    final List<CampoCustomModel> campos = [
      ...(tipo?.camposCustom ?? []),
    ];

    String? erro;

    await showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.35),
      barrierDismissible: false,
      builder: (_) => StatefulBuilder(
        builder: (context, setLocal) {
          return AlertDialog(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
            insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
            titlePadding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            contentPadding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
            actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            title: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6F2EA),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.black.withOpacity(0.06)),
                  ),
                  child: const Icon(Icons.layers_outlined, color: Color(0xFF2B2B2B)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isEdit ? "Editar tipo" : "Novo tipo",
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 560,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (erro != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.withOpacity(0.2)),
                        ),
                        child: Text(
                          erro!,
                          style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    TextField(
                      controller: nomeCtrl,
                      textCapitalization: TextCapitalization.none,
                      inputFormatters: [
                        const TitleCaseEachWordFormatter(),
                        _nomeDeny,
                        LengthLimitingTextInputFormatter(60),
                      ],
                      decoration: InputDecoration(
                        labelText: "Nome",
                        hintText: "Ex: Etiqueta Freezer",
                        labelStyle: TextStyle(
                          color: Colors.black.withOpacity(0.6),
                          fontWeight: FontWeight.w600,
                        ),
                        floatingLabelStyle: const TextStyle(
                          color: Color(0xFF2B2B2B),
                          fontWeight: FontWeight.w800,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFFAF7F1),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.black.withOpacity(0.08)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.black.withOpacity(0.08)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Color(0xFF2B2B2B), width: 1.6),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: descCtrl,
                      textCapitalization: TextCapitalization.sentences,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: "Descrição (opcional)",
                        hintText: "Ex: Modelo para produtos congelados",
                        labelStyle: TextStyle(
                          color: Colors.black.withOpacity(0.6),
                          fontWeight: FontWeight.w600,
                        ),
                        floatingLabelStyle: const TextStyle(
                          color: Color(0xFF2B2B2B),
                          fontWeight: FontWeight.w800,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFFAF7F1),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.black.withOpacity(0.08)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.black.withOpacity(0.08)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Color(0xFF2B2B2B), width: 1.6),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 12),

                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: usarRegra
                              ? const Color(0xFF428e2e).withOpacity(0.22)
                              : Colors.black.withOpacity(0.10),
                        ),
                        borderRadius: BorderRadius.circular(14),
                        color: usarRegra
                            ? const Color(0xFF428e2e).withOpacity(0.10) 
                            : const Color(0xFFFAF7F1),
                      ),
                      child: SwitchTheme(
                        data: SwitchThemeData(
                          thumbColor: WidgetStateProperty.resolveWith((states) {
                            if (states.contains(WidgetState.selected)) return const Color(0xFF428e2e);
                            return null;
                          }),
                          trackColor: WidgetStateProperty.resolveWith((states) {
                            if (states.contains(WidgetState.selected)) return const Color(0xFF428e2e).withOpacity(0.35);
                            return null;
                          }),
                        ),
                        child: SwitchListTile(
                          title: const Text(
                            "Usar regra de validade da categoria",
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                          subtitle: Text(
                            "Se marcado, a validade será calculada com base na categoria.",
                            style: TextStyle(color: Colors.black.withOpacity(0.55), fontSize: 12),
                          ),
                          value: usarRegra,
                          onChanged: (v) => setLocal(() => usarRegra = v),
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                  
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.black.withOpacity(0.08)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  "Campos personalizados",
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: () async {
                                  final novo = await _openCampoDialog(context);
                                  if (novo != null) {
                                    setLocal(() => campos.add(novo));
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF428e2e),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                                icon: const Icon(Icons.add, color: Colors.white),
                                label: const Text(
                                  "Adicionar",
                                  style: TextStyle(fontWeight: FontWeight.w900),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Adicione campos que você quer preencher ao criar etiquetas (ex: Lote, Peso, Observações).",
                            style: TextStyle(color: Colors.black.withOpacity(0.60)),
                          ),
                          const SizedBox(height: 12),

                          if (campos.isEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFDF7ED),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.black.withOpacity(0.10)),
                              ),
                              child: Text(
                                "Nenhum campo adicional.\nToque em “Adicionar” para criar o primeiro.",
                                style: TextStyle(color: Colors.black.withOpacity(0.60)),
                              ),
                            )
                          else
                            ReorderableListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: campos.length,
                              onReorder: (oldIndex, newIndex) {
                                setLocal(() {
                                  if (newIndex > oldIndex) newIndex--;
                                  final item = campos.removeAt(oldIndex);
                                  campos.insert(newIndex, item);
                                });
                              },
                              itemBuilder: (context, i) {
                                final c = campos[i];
                                return Container(
                                  key: ValueKey("${c.key}-$i"),
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: Colors.black.withOpacity(0.10)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.drag_handle),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "${c.label}${c.obrigatorio ? " *" : ""}",
                                              style: const TextStyle(fontWeight: FontWeight.w900),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              "Chave: ${c.key} • Tipo: ${_campoTipoLabel(c.tipo)}",
                                              style: TextStyle(color: Colors.black.withOpacity(0.60)),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              _campoTipoHint(c.tipo),
                                              style: TextStyle(color: Colors.black.withOpacity(0.55), fontSize: 12),
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        tooltip: "Editar campo",
                                        onPressed: () async {
                                          final editado = await _openCampoDialog(context, campo: c);
                                          if (editado != null) {
                                            setLocal(() => campos[i] = editado);
                                          }
                                        },
                                        icon: const Icon(Icons.edit_outlined),
                                      ),
                                      IconButton(
                                        tooltip: "Remover campo",
                                        onPressed: () => setLocal(() => campos.removeAt(i)),
                                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF2B2B2B),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text("Cancelar", style: TextStyle(fontWeight: FontWeight.w700)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF428e2e),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () async {
                  final rawNome = nomeCtrl.text;
                  final nome = rawNome.trim().replaceAll(RegExp(r"\s+"), " ");
                  final desc = descCtrl.text.trim();

                  final msg = _validarTipo(nome, campos);
                  if (msg != null) {
                    setLocal(() => erro = msg);
                    return;
                  }

                  final novoTipo = TipoEtiquetaModel(
                    id: tipo?.id ?? "",
                    nome: nome,
                    descricao: desc.isEmpty ? null : desc,
                    usarRegraValidadeCategoria: usarRegra,
                    camposCustom: campos,
                  );

                  final prov = context.read<TiposEtiquetaLocalProvider>();

                  if (isEdit) {
                    await prov.update(uid, novoTipo);
                  } else {
                    await prov.create(uid, novoTipo);
                  }

                  if (context.mounted) Navigator.pop(context);
                },
                child: Text(isEdit ? "Salvar" : "Criar", style: const TextStyle(fontWeight: FontWeight.w900)),
              ),
            ],
          );
        },
      ),
    );
  }

  
  String? _validarTipo(String nome, List<CampoCustomModel> campos) {
    if (nome.isEmpty) return "Informe o nome do tipo.";

    final nomeOk = RegExp(r"^[A-Za-zÀ-ÖØ-öø-ÿÇç0-9 ]+$").hasMatch(nome);
    if (!nomeOk) return "Nome inválido. Use apenas letras, números e espaços.";

    if (nome.length > 40) return "O nome deve ter no máximo 40 caracteres.";

    final set = <String>{};
    for (final c in campos) {
      if (c.key.trim().isEmpty) return "Existe um campo com chave vazia.";
      if (c.label.trim().isEmpty) return "Existe um campo com nome (label) vazio.";
      if (set.contains(c.key.trim())) return "Chave duplicada: ${c.key}.";
      set.add(c.key.trim());
    }
    return null;
  }

  String _removeDiacritics(String s) {
    const from = 'áàãâäéèêëíìîïóòõôöúùûüçñÁÀÃÂÄÉÈÊËÍÌÎÏÓÒÕÔÖÚÙÛÜÇÑ';
    const to   = 'aaaaaeeeeiiiiooooouuuucnAAAAAEEEEIIIIOOOOOUUUUCN';
    for (int i = 0; i < from.length; i++) {
      s = s.replaceAll(from[i], to[i]);
    }
    return s;
  }

  String _makeKeyFromLabel(String label) {
    var s = label.trim().toLowerCase();
    s = _removeDiacritics(s);

    s = s.replaceAll(RegExp(r'[^a-z0-9_\s]'), '');

    s = s.replaceAll(RegExp(r'\s+'), '_');

    s = s.replaceAll(RegExp(r'_+'), '_');

    s = s.replaceAll(RegExp(r'^_+|_+$'), '');

    return s;
  }

 
  Future<CampoCustomModel?> _openCampoDialog(BuildContext context, {CampoCustomModel? campo}) async {
    final isEdit = campo != null;

    final labelCtrl = TextEditingController(text: campo?.label ?? "");
    final keyCtrl = TextEditingController(text: campo?.key ?? "");

    CampoTipo tipo = campo?.tipo ?? CampoTipo.text;
    bool obrigatorio = campo?.obrigatorio ?? false;

    String? erro;
    CampoCustomModel? result;

    final bool keyLocked = isEdit;

    bool userEditedKey = isEdit; 
    void syncKeyFromLabel() {
      if (keyLocked) return;
      if (userEditedKey) return;

      final generated = _makeKeyFromLabel(labelCtrl.text);

      if (keyCtrl.text != generated) {
        keyCtrl.text = generated;
      }
    }

   
    void labelListener() => syncKeyFromLabel();
    labelCtrl.addListener(labelListener);

    await showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.35),
      builder: (_) => StatefulBuilder(
        builder: (context, setLocal) {
        
          final previewKey = _makeKeyFromLabel(labelCtrl.text);

          return AlertDialog(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
            insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
            titlePadding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            contentPadding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
            actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),

            title: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6F2EA),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.black.withOpacity(0.06)),
                  ),
                  child: const Icon(Icons.tune, color: Color(0xFF2B2B2B)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isEdit ? "Editar campo" : "Adicionar campo",
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),

            content: SizedBox(
              width: 520,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (erro != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.withOpacity(0.2)),
                        ),
                        child: Text(
                          erro!,
                          style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                 
                    TextField(
                      controller: labelCtrl,
                      textCapitalization: TextCapitalization.none,
                      inputFormatters: const [
                        const TitleCaseEachWordFormatter(),
                      ],
                      decoration: InputDecoration(
                        labelText: "Nome do campo (Label)",
                        hintText: "Ex: Lote",
                        labelStyle: TextStyle(
                          color: Colors.black.withOpacity(0.6),
                          fontWeight: FontWeight.w600,
                        ),
                        floatingLabelStyle: const TextStyle(
                          color: Color(0xFF2B2B2B),
                          fontWeight: FontWeight.w800,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFFAF7F1),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.black.withOpacity(0.08)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Color(0xFF2B2B2B), width: 1.6),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 10),

                
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Label é o nome que aparece na etiqueta.",
                        style: TextStyle(color: Colors.black.withOpacity(0.55), fontSize: 12.5),
                      ),
                    ),

                    const SizedBox(height: 12),

                 
                    TextField(
                      controller: keyCtrl,
                      readOnly: keyLocked,
                      onTap: () {
                      
                        if (!keyLocked) {
                          
                        }
                      },
                      onChanged: (_) {
                        if (!keyLocked) {
                         
                          if (!userEditedKey) {
                            setLocal(() => userEditedKey = true);
                          }
                        }
                      },
                      decoration: InputDecoration(
                        labelText: "Chave (Key) — sem espaços",
                        hintText: "Ex: lote",
                        labelStyle: TextStyle(
                          color: Colors.black.withOpacity(0.6),
                          fontWeight: FontWeight.w600,
                        ),
                        floatingLabelStyle: const TextStyle(
                          color: Color(0xFF2B2B2B),
                          fontWeight: FontWeight.w800,
                        ),
                        helperText: keyLocked
                            ? "A key não pode ser alterada depois de criada."
                            : (userEditedKey
                                ? "Editada manualmente."
                                : "Gerada automaticamente pelo Label."),
                        prefixIcon: Icon(
                          keyLocked ? Icons.lock_outline : Icons.key_outlined,
                          color: keyLocked ? Colors.black.withOpacity(0.55) : const Color(0xFF2B2B2B),
                        ),
                        suffixIcon: (!keyLocked && userEditedKey)
                            ? IconButton(
                                tooltip: "Voltar a gerar automaticamente",
                                onPressed: () {
                                  setLocal(() {
                                    userEditedKey = false;
                                    syncKeyFromLabel();
                                  });
                                },
                                icon: const Icon(Icons.auto_fix_high),
                              )
                            : IconButton(
                                tooltip: "Copiar key",
                                onPressed: () async {
                                  await Clipboard.setData(ClipboardData(text: keyCtrl.text.trim()));
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text("Key copiada.")),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.copy_outlined),
                              ),
                        filled: true,
                        fillColor: const Color(0xFFFAF7F1),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.black.withOpacity(0.08)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Color(0xFF2B2B2B), width: 1.6),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      ),
                    ),

                    const SizedBox(height: 8),

                   
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Preview da key: $previewKey",
                        style: TextStyle(color: Colors.black.withOpacity(0.60), fontSize: 12.5),
                      ),
                    ),

                    const SizedBox(height: 14),

                
                    DropdownButtonFormField<CampoTipo>(
                      value: tipo,
                      decoration: InputDecoration(
                        labelText: "Tipo do campo",
                        labelStyle: TextStyle(
                          color: Colors.black.withOpacity(0.6),
                          fontWeight: FontWeight.w600,
                        ),
                        floatingLabelStyle: const TextStyle(
                          color: Color(0xFF2B2B2B),
                          fontWeight: FontWeight.w800,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFFAF7F1),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.black.withOpacity(0.08)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Color(0xFF2B2B2B), width: 1.6),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      ),
                      items: const [
                        DropdownMenuItem(value: CampoTipo.text, child: Text("Texto")),
                        DropdownMenuItem(value: CampoTipo.number, child: Text("Número")),
                        DropdownMenuItem(value: CampoTipo.multiline, child: Text("Texto grande")),
                        DropdownMenuItem(value: CampoTipo.date, child: Text("Data")),
                        DropdownMenuItem(value: CampoTipo.boolType, child: Text("Sim/Não")),
                      ],
                      onChanged: (v) => setLocal(() => tipo = v ?? CampoTipo.text),
                    ),

                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Como será preenchido: ${_campoTipoHint(tipo)}",
                        style: TextStyle(color: Colors.black.withOpacity(0.60), fontSize: 12.5),
                      ),
                    ),

                    const SizedBox(height: 12),

                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: obrigatorio
                              ? const Color(0xFF428e2e).withOpacity(0.22)
                              : Colors.black.withOpacity(0.10),
                        ),
                        borderRadius: BorderRadius.circular(14),
                        color: obrigatorio
                            ? const Color(0xFF428e2e).withOpacity(0.10)
                            : const Color(0xFFFAF7F1),
                      ),
                      child: SwitchTheme(
                        data: SwitchThemeData(
                          thumbColor: WidgetStateProperty.resolveWith((states) {
                            if (states.contains(WidgetState.selected)) return const Color(0xFF428e2e);
                            return null;
                          }),
                          trackColor: WidgetStateProperty.resolveWith((states) {
                            if (states.contains(WidgetState.selected)) {
                              return const Color(0xFF428e2e).withOpacity(0.35);
                            }
                            return null;
                          }),
                        ),
                        child: SwitchListTile(
                          title: const Text(
                            "Campo obrigatório",
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                          subtitle: Text(
                            "Se ativo, a etiqueta só salva se este campo estiver preenchido.",
                            style: TextStyle(color: Colors.black.withOpacity(0.55), fontSize: 12),
                          ),
                          value: obrigatorio,
                          onChanged: (v) => setLocal(() => obrigatorio = v),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF2B2B2B),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text("Cancelar", style: TextStyle(fontWeight: FontWeight.w700)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF428e2e),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {
                  final label = labelCtrl.text.trim();
                  final key = keyCtrl.text.trim();

              
                  if (!keyLocked && !userEditedKey) {
                    final generated = _makeKeyFromLabel(label);
                    keyCtrl.text = generated;
                  }

                  final keyOk = RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(key);

                  if (label.isEmpty) {
                    setLocal(() => erro = "Informe o nome do campo (label).");
                    return;
                  }
                  if (key.isEmpty) {
                    setLocal(() => erro = "A key ficou vazia. Ajuste o label ou edite a key.");
                    return;
                  }
                  if (!keyOk) {
                    setLocal(() => erro = "A key deve conter apenas letras, números e _ (sem espaços/acentos).");
                    return;
                  }

                  result = CampoCustomModel(
                    key: key,
                    label: label,
                    tipo: tipo,
                    obrigatorio: obrigatorio,
                  );

                  Navigator.pop(context);
                },
                child: Text(isEdit ? "Salvar" : "Adicionar", style: const TextStyle(fontWeight: FontWeight.w900)),
              ),
            ],
          );
        },
      ),
    );

 
    labelCtrl.removeListener(labelListener);
    labelCtrl.dispose();
    keyCtrl.dispose();

    return result;
  }

  String _campoTipoLabel(CampoTipo t) {
    switch (t) {
      case CampoTipo.text:
        return "Texto";
      case CampoTipo.number:
        return "Número";
      case CampoTipo.multiline:
        return "Texto grande";
      case CampoTipo.date:
        return "Data";
      case CampoTipo.boolType:
        return "Sim/Não";
    }
  }

  String _campoTipoHint(CampoTipo t) {
    switch (t) {
      case CampoTipo.text:
        return "Campo simples (ex: Lote, Marca)";
      case CampoTipo.number:
        return "Somente números (ex: Peso, Quantidade)";
      case CampoTipo.multiline:
        return "Texto com mais linhas (ex: Observações)";
      case CampoTipo.date:
        return "Selecionador de data (ex: Fabricação)";
      case CampoTipo.boolType:
        return "Alternância Sim/Não (ex: Conferido?)";
    }
  }
}

class _TipoCard extends StatelessWidget {
  final TipoEtiquetaModel tipo;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TipoCard({
    required this.tipo,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final count = tipo.camposCustom.length;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.07)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.layers_outlined),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tipo.nome, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(
                  "$count campo(s) • validade automática: ${tipo.usarRegraValidadeCategoria ? "sim" : "não"}",
                  style: TextStyle(color: Colors.black.withOpacity(0.62)),
                ),
              ],
            ),
          ),
          IconButton(onPressed: onEdit, icon: const Icon(Icons.edit_outlined)),
          IconButton(onPressed: onDelete, icon: const Icon(Icons.delete_outline, color: Colors.red)),
        ],
      ),
    );
  }
}