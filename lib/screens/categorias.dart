// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

import '../providers/auth_provider.dart';
import '../providers/categorias_local_provider.dart';
import '../models/categoria_model.dart';
import '../widgets/menu.dart';

final _nomeDeny = FilteringTextInputFormatter.deny(
  RegExp(r"[^0-9A-Za-zÀ-ÖØ-öø-ÿÇç ]"),
);

final _diasAllow = FilteringTextInputFormatter.digitsOnly;

class TitleCaseEachWordFormatter extends TextInputFormatter {
  const TitleCaseEachWordFormatter();

  bool _isLetter(String ch) => RegExp(r"[A-Za-zÀ-ÖØ-öø-ÿÇç]").hasMatch(ch);

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final t = newValue.text;
    if (t.isEmpty) return newValue;

    final lower = t.toLowerCase();
    final chars = lower.split('');

    bool capitalizeNext = true;

    for (int i = 0; i < chars.length; i++) {
      final ch = chars[i];

      if (ch == ' ') {
        capitalizeNext = true;
        continue;
      }

      if (capitalizeNext && _isLetter(ch)) {
        chars[i] = ch.toUpperCase();
        capitalizeNext = false;
      } else {
        if (_isLetter(ch)) {
          chars[i] = ch;
        }
        capitalizeNext = false;
      }
    }

    final formatted = chars.join();

    final sel = newValue.selection;
    final clampedBase = sel.baseOffset.clamp(0, formatted.length);
    final clampedExtent = sel.extentOffset.clamp(0, formatted.length);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection(
        baseOffset: clampedBase,
        extentOffset: clampedExtent,
      ),
      composing: TextRange.empty,
    );
  }
}

class CategoriasScreen extends StatefulWidget {
  const CategoriasScreen({super.key});

  @override
  State<CategoriasScreen> createState() => _CategoriasScreenState();
}

class _CategoriasScreenState extends State<CategoriasScreen> {
  bool _loaded = false;

  bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  Color _bg(BuildContext context) =>
      _isDark(context) ? const Color(0xFF0F0F0F) : const Color(0xFFFDF7ED);

  Color _card(BuildContext context) =>
      _isDark(context) ? const Color(0xFF1E1E1E) : Colors.white;

  Color _cardAlt(BuildContext context) =>
      _isDark(context) ? const Color(0xFF181818) : const Color(0xFFFAF7F1);

  Color _text(BuildContext context) =>
      _isDark(context) ? Colors.white : const Color(0xFF2B2B2B);

  Color _muted(BuildContext context) =>
      _isDark(context)
          ? const Color(0xFFD6D6D6)
          : Colors.black.withOpacity(0.60);

  Color _border(BuildContext context) =>
      _isDark(context)
          ? const Color(0xFFD4AF37).withOpacity(0.16)
          : Colors.black.withOpacity(0.07);

  Color _brand(BuildContext context) =>
      _isDark(context) ? const Color(0xFFD4AF37) : const Color(0xFF428E2E);

  Color _iconColor(BuildContext context) =>
      _isDark(context) ? const Color(0xFFD4AF37) : const Color(0xFF2B2B2B);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;

    final uid = context.read<AuthProvider>().user?.uid;
    if (uid != null) {
      _loaded = true;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<CategoriasLocalProvider>().fetch(uid);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final compact = w < 835;

    final uid = context.watch<AuthProvider>().user?.uid;
    final prov = context.watch<CategoriasLocalProvider>();

    final bg = _bg(context);
    final text = _text(context);
    final muted = _muted(context);
    final border = _border(context);
    final brand = _brand(context);

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
              color: Colors.black.withOpacity(_isDark(context) ? 0.18 : 0.10),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          backgroundColor: _isDark(context) ? const Color(0xFF1E1E1E) : Colors.white,
          foregroundColor: _isDark(context) ? const Color(0xFFD4AF37) : brand,
          elevation: 0,
          onPressed: () => _openCategoriaDialog(context, uid),
          icon: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: brand,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.add,
              color: _isDark(context) ? Colors.black : Colors.white,
              size: 20,
            ),
          ),
          label: Text(
            "Nova categoria",
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: _isDark(context) ? const Color(0xFFD4AF37) : null,
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: border),
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
                  "Categorias",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: text,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Crie categorias e defina regras de vencimento (ex: pão = 7 dias).",
                  style: TextStyle(color: muted),
                ),
                const SizedBox(height: 16),
                if (prov.loading)
                  const Expanded(child: Center(child: CircularProgressIndicator()))
                else if (prov.items.isEmpty)
                  Expanded(
                    child: Center(
                      child: Text(
                        "Nenhuma categoria cadastrada ainda.\nClique em “Nova categoria”.",
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
                        final c = prov.items[i];
                        return _CategoriaCard(
                          categoria: c,
                          onEdit: () => _openCategoriaDialog(context, uid, categoria: c),
                          onDelete: () => _confirmDelete(context, uid, c),
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

  Future<void> _confirmDelete(
    BuildContext context,
    String uid,
    CategoriaModel c,
  ) async {
    final text = _text(context);
    final muted = _muted(context);
    final card = _card(context);
    final cancelColor = _isDark(context)
        ? const Color(0xFFD4AF37)
        : const Color(0xFF2B2B2B);

    final ok = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.35),
      builder: (_) => AlertDialog(
        backgroundColor: card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
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
              child: const Icon(
                Icons.delete_outline,
                color: Colors.red,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "Excluir categoria?",
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
            Text(
              "A categoria:",
              style: TextStyle(color: muted),
            ),
            const SizedBox(height: 4),
            Text(
              "“${c.nome}”",
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: text,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Será apenas desativada.\nEla continuará aparecendo em etiquetas antigas.",
              style: TextStyle(
                color: muted,
                height: 1.4,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              foregroundColor: cancelColor,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
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
      await context.read<CategoriasLocalProvider>().softDelete(uid, c.id);
    }
  }

  Future<void> _openCategoriaDialog(
    BuildContext context,
    String uid, {
    CategoriaModel? categoria,
  }) async {
    final nomeCtrl = TextEditingController(text: categoria?.nome ?? "");
    final diasCtrl = TextEditingController(
      text: (categoria?.diasVencimento ?? 0).toString(),
    );

    final isEdit = categoria != null;
    final isDark = _isDark(context);
    final card = _card(context);
    final cardAlt = _cardAlt(context);
    final text = _text(context);
    final muted = _muted(context);
    final border = _border(context);
    final iconColor = _iconColor(context);
    final brand = _brand(context);

    InputDecoration appInputDecoration({
      required String label,
      String? hint,
      Widget? prefixIcon,
    }) {
      return InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon,
        labelStyle: TextStyle(
          color: muted,
          fontWeight: FontWeight.w600,
        ),
        hintStyle: TextStyle(
          color: muted.withOpacity(0.85),
        ),
        floatingLabelStyle: TextStyle(
          color: isDark ? const Color(0xFFD4AF37) : const Color(0xFF2B2B2B),
          fontWeight: FontWeight.w800,
        ),
        filled: true,
        fillColor: cardAlt,
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
          borderSide: BorderSide(
            color: isDark ? const Color(0xFFD4AF37) : const Color(0xFF2B2B2B),
            width: 1.6,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      );
    }

    await showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.35),
      builder: (_) => AlertDialog(
        backgroundColor: card,
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
                color: cardAlt,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: border),
              ),
              child: Icon(
                Icons.category_outlined,
                color: iconColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                isEdit ? "Editar categoria" : "Nova categoria",
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: text,
                ),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nomeCtrl,
                textCapitalization: TextCapitalization.none,
                style: TextStyle(color: text),
                inputFormatters: [
                  const TitleCaseEachWordFormatter(),
                  _nomeDeny,
                  LengthLimitingTextInputFormatter(40),
                ],
                decoration: appInputDecoration(
                  label: "Nome",
                  hint: "Ex: Pão",
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: diasCtrl,
                keyboardType: TextInputType.number,
                style: TextStyle(color: text),
                inputFormatters: [
                  _diasAllow,
                  LengthLimitingTextInputFormatter(4),
                ],
                decoration: appInputDecoration(
                  label: "Dias de vencimento",
                  hint: "Ex: 7",
                  prefixIcon: Icon(
                    Icons.schedule_outlined,
                    color: isDark ? const Color(0xFFD4AF37) : null,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Dica: use 0 para não aplicar vencimento automático.",
                  style: TextStyle(
                    color: muted,
                    fontSize: 12.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor:
                  isDark ? const Color(0xFFD4AF37) : const Color(0xFF2B2B2B),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              "Cancelar",
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final rawNome = nomeCtrl.text;
              final nome = rawNome.trim().replaceAll(RegExp(r"\s+"), " ");
              final diasStr = diasCtrl.text.trim();

              if (nome.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Informe o nome da categoria.")),
                );
                return;
              }

              final nomeOk = RegExp(r"^[A-Za-zÀ-ÖØ-öø-ÿÇç0-9 ]+$").hasMatch(nome);
              if (!nomeOk) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      "Nome inválido. Use apenas letras, números e espaços.",
                    ),
                  ),
                );
                return;
              }

              if (diasStr.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Informe os dias de vencimento (0 ou mais)."),
                  ),
                );
                return;
              }

              final dias = int.tryParse(diasStr);
              if (dias == null || dias < 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      "Dias inválidos. Use apenas números (0 ou mais).",
                    ),
                  ),
                );
                return;
              }

              final prov = context.read<CategoriasLocalProvider>();

              if (isEdit) {
                await prov.update(
                  uid,
                  CategoriaModel(
                    id: categoria.id,
                    nome: nome,
                    diasVencimento: dias,
                    ativo: true,
                    createdAt: categoria.createdAt,
                    updatedAt: categoria.updatedAt,
                  ),
                );
              } else {
                await prov.create(uid, nome: nome, diasVencimento: dias);
              }

              if (context.mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: brand,
              foregroundColor: isDark ? Colors.black : Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Text(
              isEdit ? "Salvar" : "Criar",
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoriaCard extends StatelessWidget {
  final CategoriaModel categoria;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CategoriaCard({
    required this.categoria,
    required this.onEdit,
    required this.onDelete,
  });

  bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  Color _card(BuildContext context) =>
      _isDark(context) ? const Color(0xFF1E1E1E) : Colors.white;

  Color _text(BuildContext context) =>
      _isDark(context) ? Colors.white : const Color(0xFF2B2B2B);

  Color _muted(BuildContext context) =>
      _isDark(context)
          ? const Color(0xFFD6D6D6)
          : Colors.black.withOpacity(0.62);

  Color _border(BuildContext context) =>
      _isDark(context)
          ? const Color(0xFFD4AF37).withOpacity(0.16)
          : Colors.black.withOpacity(0.07);

  Color _iconColor(BuildContext context) =>
      _isDark(context) ? const Color(0xFFD4AF37) : const Color(0xFF2B2B2B);

  @override
  Widget build(BuildContext context) {
    final isDark = _isDark(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.18 : 0.06),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.category_outlined, color: _iconColor(context)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  categoria.nome,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: _text(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Vence em ${categoria.diasVencimento} dias",
                  style: TextStyle(color: _muted(context)),
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