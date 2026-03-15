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

final _keyDeny = FilteringTextInputFormatter.deny(
  RegExp(r"[^a-zA-Z0-9_]"),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bg = theme.scaffoldBackgroundColor;
    final text = isDark ? Colors.white : const Color(0xFF2B2B2B);
    final muted = isDark ? const Color(0xFFD6D6D6) : Colors.black.withOpacity(0.60);
    final brand = isDark ? const Color(0xFFD4AF37) : const Color(0xFF428E2E);

    final fabBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final fabFg = brand;
    final fabBorder = isDark
        ? const Color(0xFFD4AF37).withOpacity(0.18)
        : Colors.black.withOpacity(0.08);

    final w = MediaQuery.of(context).size.width;
    final compact = w < 835;

    final uid = context.watch<AuthProvider>().user?.uid;
    if (uid == null) {
      return Scaffold(
        backgroundColor: bg,
        body: Center(
          child: Text(
            "Faça login novamente.",
            style: TextStyle(color: text),
          ),
        ),
      );
    }

    final prov = context.watch<TiposEtiquetaLocalProvider>();

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        toolbarHeight: compact ? 160 : 100,
        centerTitle: true,
        title: compact
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset('assets/logo6.png', height: 78),
                  const SizedBox(height: 10),
                  const TopMenu(),
                ],
              )
            : Row(
                children: [
                  Image.asset('assets/logo6.png', height: 92),
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
              color: Colors.black.withOpacity(isDark ? 0.28 : 0.10),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          backgroundColor: fabBg,
          foregroundColor: fabFg,
          elevation: 0,
          onPressed: () => _openTipoDialog(context, uid),
          icon: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: brand,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.add,
              color: isDark ? Colors.black : Colors.white,
              size: 20,
            ),
          ),
          label: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Text(
              "Novo tipo",
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: fabFg,
              ),
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: fabBorder),
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
                Text(
                  "Tipos de etiqueta",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: text,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Crie modelos com campos personalizados para gerar etiquetas rapidamente.",
                  style: TextStyle(color: muted),
                ),
                const SizedBox(height: 16),
                if (prov.loading)
                  const Expanded(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (prov.items.isEmpty)
                  Expanded(
                    child: Center(
                      child: Text(
                        "Nenhum tipo cadastrado ainda.\nClique em “Novo tipo”.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: muted),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final dialogBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final text = isDark ? Colors.white : const Color(0xFF2B2B2B);
    final muted = isDark ? const Color(0xFFD6D6D6) : Colors.black.withOpacity(0.60);

    final ok = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.35),
      builder: (_) => AlertDialog(
        backgroundColor: dialogBg,
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
                color: Colors.red.withOpacity(0.10),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.red.withOpacity(0.18)),
              ),
              child: const Icon(Icons.delete_outline, color: Colors.red),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "Excluir tipo?",
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: text,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("O tipo:", style: TextStyle(color: muted)),
            const SizedBox(height: 4),
            Text(
              "“${t.nome}”",
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: text,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Será removido da sua lista de tipos.",
              style: TextStyle(color: muted, height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              foregroundColor: isDark ? const Color(0xFFD4AF37) : const Color(0xFF2B2B2B),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text(
              "Cancelar",
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
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
            child: const Text(
              "Excluir",
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final dialogBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final sectionBg = isDark ? const Color(0xFF181818) : Colors.white;
    final fieldBg = isDark ? const Color(0xFF141414) : const Color(0xFFFAF7F1);
    final text = isDark ? Colors.white : const Color(0xFF2B2B2B);
    final muted = isDark ? const Color(0xFFD6D6D6) : Colors.black.withOpacity(0.60);
    final border = isDark
        ? const Color(0xFFD4AF37).withOpacity(0.16)
        : Colors.black.withOpacity(0.08);
    final brand = isDark ? const Color(0xFFD4AF37) : const Color(0xFF428E2E);
    final onBrand = isDark ? Colors.black : Colors.white;

    final nomeCtrl = TextEditingController(text: tipo?.nome ?? "");
    final descCtrl = TextEditingController(text: tipo?.descricao ?? "");
    bool usarRegra = tipo?.usarRegraValidadeCategoria ?? true;
    bool controlaLote = tipo?.controlaLote ?? false;

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
            backgroundColor: dialogBg,
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
                    color: brand.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: border),
                  ),
                  child: Icon(Icons.layers_outlined, color: brand),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isEdit ? "Editar tipo" : "Novo tipo",
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: text,
                    ),
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
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    TextField(
                      controller: nomeCtrl,
                      style: TextStyle(color: text),
                      textCapitalization: TextCapitalization.none,
                      inputFormatters: [
                        const TitleCaseEachWordFormatter(),
                        _nomeDeny,
                        LengthLimitingTextInputFormatter(60),
                      ],
                      decoration: _inputDecoration(
                        isDark: isDark,
                        text: text,
                        border: border,
                        fill: fieldBg,
                        brand: brand,
                        labelText: "Nome",
                        hintText: "Ex: Etiqueta Freezer",
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descCtrl,
                      style: TextStyle(color: text),
                      textCapitalization: TextCapitalization.sentences,
                      maxLines: 2,
                      decoration: _inputDecoration(
                        isDark: isDark,
                        text: text,
                        border: border,
                        fill: fieldBg,
                        brand: brand,
                        labelText: "Descrição (opcional)",
                        hintText: "Ex: Modelo para produtos congelados",
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: usarRegra
                              ? brand.withOpacity(0.22)
                              : border,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        color: usarRegra
                            ? brand.withOpacity(0.10)
                            : fieldBg,
                      ),
                      child: SwitchTheme(
                        data: SwitchThemeData(
                          thumbColor: WidgetStateProperty.resolveWith((states) {
                            if (states.contains(WidgetState.selected)) return brand;
                            return null;
                          }),
                          trackColor: WidgetStateProperty.resolveWith((states) {
                            if (states.contains(WidgetState.selected)) {
                              return brand.withOpacity(0.35);
                            }
                            return null;
                          }),
                        ),
                        child: SwitchListTile(
                          title: Text(
                            "Usar regra de validade da categoria",
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: text,
                            ),
                          ),
                          subtitle: Text(
                            "Se marcado, a validade será calculada com base na categoria.",
                            style: TextStyle(
                              color: muted,
                              fontSize: 12,
                            ),
                          ),
                          value: usarRegra,
                          onChanged: (v) => setLocal(() => usarRegra = v),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: controlaLote
                              ? brand.withOpacity(0.22)
                              : border,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        color: controlaLote
                            ? brand.withOpacity(0.10)
                            : fieldBg,
                      ),
                      child: SwitchTheme(
                        data: SwitchThemeData(
                          thumbColor: WidgetStateProperty.resolveWith((states) {
                            if (states.contains(WidgetState.selected)) return brand;
                            return null;
                          }),
                          trackColor: WidgetStateProperty.resolveWith((states) {
                            if (states.contains(WidgetState.selected)) {
                              return brand.withOpacity(0.35);
                            }
                            return null;
                          }),
                        ),
                        child: SwitchListTile(
                          title: Text(
                            "Controlar lote",
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: text,
                            ),
                          ),
                          subtitle: Text(
                            "Se marcado, a etiqueta terá um campo de Lote obrigatório (pode gerar automático).",
                            style: TextStyle(
                              color: muted,
                              fontSize: 12,
                            ),
                          ),
                          value: controlaLote,
                          onChanged: (v) => setLocal(() => controlaLote = v),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: sectionBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  "Campos personalizados",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: text,
                                  ),
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: () async {
                                  final novo = await _openCampoDialog(context, campo: null);
                                  if (novo != null) {
                                    setLocal(() => campos.add(novo));
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: brand,
                                  foregroundColor: onBrand,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                icon: Icon(Icons.add, color: onBrand),
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
                            style: TextStyle(color: muted),
                          ),
                          const SizedBox(height: 12),
                          if (campos.isEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: fieldBg,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: border),
                              ),
                              child: Text(
                                "Nenhum campo adicional.\nToque em “Adicionar” para criar o primeiro.",
                                style: TextStyle(color: muted),
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
                                    color: fieldBg,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: border),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.drag_handle,
                                        color: muted,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "${c.label}${c.obrigatorio ? " *" : ""}",
                                              style: TextStyle(
                                                fontWeight: FontWeight.w900,
                                                color: text,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              "Chave: ${c.key} • Tipo: ${_campoTipoLabel(c.tipo)}",
                                              style: TextStyle(color: muted),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              _campoTipoHint(c.tipo),
                                              style: TextStyle(
                                                color: muted,
                                                fontSize: 12,
                                              ),
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
                                        icon: Icon(
                                          Icons.edit_outlined,
                                          color: isDark ? brand : null,
                                        ),
                                      ),
                                      IconButton(
                                        tooltip: "Remover campo",
                                        onPressed: () => setLocal(() => campos.removeAt(i)),
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          color: Colors.red,
                                        ),
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
                  foregroundColor: isDark ? brand : const Color(0xFF2B2B2B),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text(
                  "Cancelar",
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: brand,
                  foregroundColor: onBrand,
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
                    controlaLote: controlaLote,
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
                child: Text(
                  isEdit ? "Salvar" : "Criar",
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final dialogBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final fieldBg = isDark ? const Color(0xFF141414) : const Color(0xFFFAF7F1);
    final text = isDark ? Colors.white : const Color(0xFF2B2B2B);
    final muted = isDark ? const Color(0xFFD6D6D6) : Colors.black.withOpacity(0.60);
    final border = isDark
        ? const Color(0xFFD4AF37).withOpacity(0.16)
        : Colors.black.withOpacity(0.08);
    final brand = isDark ? const Color(0xFFD4AF37) : const Color(0xFF428E2E);
    final onBrand = isDark ? Colors.black : Colors.white;

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
            backgroundColor: dialogBg,
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
                    color: brand.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: border),
                  ),
                  child: Icon(Icons.tune, color: brand),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isEdit ? "Editar campo" : "Adicionar campo",
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: text,
                    ),
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
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    TextField(
                      controller: labelCtrl,
                      style: TextStyle(color: text),
                      textCapitalization: TextCapitalization.none,
                      inputFormatters: const [
                        TitleCaseEachWordFormatter(),
                      ],
                      decoration: _inputDecoration(
                        isDark: isDark,
                        text: text,
                        border: border,
                        fill: fieldBg,
                        brand: brand,
                        labelText: "Nome do campo (Label)",
                        hintText: "Ex: Lote",
                      ),
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Label é o nome que aparece na etiqueta.",
                        style: TextStyle(color: muted, fontSize: 12.5),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: keyCtrl,
                      style: TextStyle(color: text),
                      readOnly: keyLocked,
                      inputFormatters: keyLocked ? null : [_keyDeny],
                      onChanged: (_) {
                        if (!keyLocked && !userEditedKey) {
                          setLocal(() => userEditedKey = true);
                        }
                      },
                      decoration: _inputDecoration(
                        isDark: isDark,
                        text: text,
                        border: border,
                        fill: fieldBg,
                        brand: brand,
                        labelText: "Chave (Key) — sem espaços",
                        hintText: "Ex: lote",
                        helperText: keyLocked
                            ? "A key não pode ser alterada depois de criada."
                            : (userEditedKey
                                ? "Editada manualmente."
                                : "Gerada automaticamente pelo Label."),
                        prefixIcon: Icon(
                          keyLocked ? Icons.lock_outline : Icons.key_outlined,
                          color: keyLocked ? muted : brand,
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
                                icon: Icon(Icons.auto_fix_high, color: brand),
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
                                icon: Icon(
                                  Icons.copy_outlined,
                                  color: isDark ? brand : null,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Preview da key: $previewKey",
                        style: TextStyle(color: muted, fontSize: 12.5),
                      ),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<CampoTipo>(
                      value: tipo,
                      dropdownColor: dialogBg,
                      style: TextStyle(color: text),
                      decoration: _inputDecoration(
                        isDark: isDark,
                        text: text,
                        border: border,
                        fill: fieldBg,
                        brand: brand,
                        labelText: "Tipo do campo",
                      ),
                      items: [
                        DropdownMenuItem(
                          value: CampoTipo.text,
                          child: Text("Texto", style: TextStyle(color: text)),
                        ),
                        DropdownMenuItem(
                          value: CampoTipo.number,
                          child: Text("Número", style: TextStyle(color: text)),
                        ),
                        DropdownMenuItem(
                          value: CampoTipo.multiline,
                          child: Text("Texto grande", style: TextStyle(color: text)),
                        ),
                        DropdownMenuItem(
                          value: CampoTipo.date,
                          child: Text("Data", style: TextStyle(color: text)),
                        ),
                        DropdownMenuItem(
                          value: CampoTipo.boolType,
                          child: Text("Sim/Não", style: TextStyle(color: text)),
                        ),
                      ],
                      onChanged: (v) => setLocal(() => tipo = v ?? CampoTipo.text),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Como será preenchido: ${_campoTipoHint(tipo)}",
                        style: TextStyle(color: muted, fontSize: 12.5),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: obrigatorio ? brand.withOpacity(0.22) : border,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        color: obrigatorio ? brand.withOpacity(0.10) : fieldBg,
                      ),
                      child: SwitchTheme(
                        data: SwitchThemeData(
                          thumbColor: WidgetStateProperty.resolveWith((states) {
                            if (states.contains(WidgetState.selected)) return brand;
                            return null;
                          }),
                          trackColor: WidgetStateProperty.resolveWith((states) {
                            if (states.contains(WidgetState.selected)) {
                              return brand.withOpacity(0.35);
                            }
                            return null;
                          }),
                        ),
                        child: SwitchListTile(
                          title: Text(
                            "Campo obrigatório",
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: text,
                            ),
                          ),
                          subtitle: Text(
                            "Se ativo, a etiqueta só salva se este campo estiver preenchido.",
                            style: TextStyle(
                              color: muted,
                              fontSize: 12,
                            ),
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
                  foregroundColor: isDark ? brand : const Color(0xFF2B2B2B),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text(
                  "Cancelar",
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: brand,
                  foregroundColor: onBrand,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {
                  final label = labelCtrl.text.trim();

                  if (!keyLocked && !userEditedKey) {
                    final generated = _makeKeyFromLabel(label);
                    keyCtrl.text = generated;
                  }

                  final key = keyCtrl.text.trim();
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
                child: Text(
                  isEdit ? "Salvar" : "Adicionar",
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
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

  InputDecoration _inputDecoration({
    required bool isDark,
    required Color text,
    required Color border,
    required Color fill,
    required Color brand,
    required String labelText,
    String? hintText,
    String? helperText,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    final labelColor = isDark ? const Color(0xFFD6D6D6) : Colors.black.withOpacity(0.6);

    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      helperText: helperText,
      helperStyle: TextStyle(color: labelColor),
      hintStyle: TextStyle(color: labelColor),
      labelStyle: TextStyle(
        color: labelColor,
        fontWeight: FontWeight.w600,
      ),
      floatingLabelStyle: TextStyle(
        color: brand,
        fontWeight: FontWeight.w800,
      ),
      filled: true,
      fillColor: fill,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: brand, width: 1.6),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final count = tipo.camposCustom.length;
    final card = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final border = isDark
        ? const Color(0xFFD4AF37).withOpacity(0.16)
        : Colors.black.withOpacity(0.07);
    final text = isDark ? Colors.white : const Color(0xFF2B2B2B);
    final muted = isDark ? const Color(0xFFD6D6D6) : Colors.black.withOpacity(0.62);
    final iconColor = isDark ? const Color(0xFFD4AF37) : null;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.24 : 0.06),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.layers_outlined, color: iconColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tipo.nome,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "$count campo(s) • validade automática: ${tipo.usarRegraValidadeCategoria ? "sim" : "não"} • lote: ${tipo.controlaLote ? "sim" : "não"}",
                  style: TextStyle(color: muted),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onEdit,
            icon: Icon(
              Icons.edit_outlined,
              color: isDark ? const Color(0xFFD4AF37) : null,
            ),
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline, color: Colors.red),
          ),
        ],
      ),
    );
  }
}