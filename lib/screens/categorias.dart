// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/categorias_local_provider.dart';
import '../models/categoria_model.dart';
import '../widgets/menu.dart';
import 'package:flutter/services.dart';

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
      selection: TextSelection(baseOffset: clampedBase, extentOffset: clampedExtent),
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

    if (uid == null) {
      return const Scaffold(body: Center(child: Text("Faça login novamente.")));
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
          onPressed: () => _openCategoriaDialog(context, uid),
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
            child: Text(
              "Nova categoria",
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
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
                  "Categorias",
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  "Crie categorias e defina regras de vencimento (ex: pão = 7 dias).",
                  style: TextStyle(color: Colors.black.withOpacity(0.60)),
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
    final ok = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.35),
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
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
            const Expanded(
              child: Text(
                "Excluir categoria?",
                style: TextStyle(
                  fontWeight: FontWeight.w900,
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
              style: TextStyle(
                color: Colors.black.withOpacity(0.65),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "“${c.nome}”",
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Será apenas desativada.\nEla continuará aparecendo em etiquetas antigas.",
              style: TextStyle(
                color: Colors.black.withOpacity(0.60),
                height: 1.4,
              ),
            ),
          ],
        ),

        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF2B2B2B),
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

  Future<void> _openCategoriaDialog(BuildContext context, String uid, {CategoriaModel? categoria}) async {
    final nomeCtrl = TextEditingController(text: categoria?.nome ?? "");
    final diasCtrl = TextEditingController(text: (categoria?.diasVencimento ?? 0).toString());

    final isEdit = categoria != null;

    await showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.35),
      builder: (_) => AlertDialog(
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
              child: const Icon(Icons.category_outlined, color: Color(0xFF2B2B2B)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                isEdit ? "Editar categoria" : "Nova categoria",
                style: const TextStyle(fontWeight: FontWeight.w900),
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
                inputFormatters: [
                  const TitleCaseEachWordFormatter(),
                  _nomeDeny,
                  LengthLimitingTextInputFormatter(40),
                ],
                decoration: InputDecoration(
                  labelText: "Nome",
                  hintText: "Ex: Pão",
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
                controller: diasCtrl,
                keyboardType: TextInputType.number,
                 inputFormatters: [
                  _diasAllow,
                  LengthLimitingTextInputFormatter(4),
                ],
                decoration: InputDecoration(
                  labelText: "Dias de vencimento",
                  hintText: "Ex: 7",

                  labelStyle: TextStyle(
                    color: Colors.black.withOpacity(0.6),
                    fontWeight: FontWeight.w600,
                  ),

                  floatingLabelStyle: const TextStyle(
                    color: Color(0xFF2B2B2B),
                    fontWeight: FontWeight.w800,
                  ),
                  prefixIcon: const Icon(Icons.schedule_outlined),
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
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Dica: use 0 para não aplicar vencimento automático.",
                  style: TextStyle(color: Colors.black.withOpacity(0.55), fontSize: 12.5),
                ),
              ),
            ],
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
                  const SnackBar(content: Text("Nome inválido. Use apenas letras, números e espaços.")),
                );
                return;
              }

              
              if (diasStr.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Informe os dias de vencimento (0 ou mais).")),
                );
                return;
              }

              final dias = int.tryParse(diasStr);
              if (dias == null || dias < 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Dias inválidos. Use apenas números (0 ou mais).")),
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
              backgroundColor: const Color(0xFF428e2e),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Text(isEdit ? "Salvar" : "Criar", style: const TextStyle(fontWeight: FontWeight.w900)),
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

  @override
  Widget build(BuildContext context) {
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
          const Icon(Icons.category_outlined),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(categoria.nome, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(
                  "Vence em ${categoria.diasVencimento} dias",
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


