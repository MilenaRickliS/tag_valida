// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/categorias_local_provider.dart';
import '../models/categoria_model.dart';
import '../widgets/menu.dart';

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
                  Image.asset('assets/logo1.png', height: 78),
                  const SizedBox(height: 10),
                  const TopMenu(),
                ],
              )
            : Row(
                children: [
                  Image.asset('assets/logo1.png', height: 92),
                  const Spacer(),
                  const TopMenu(),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF2B2B2B),
        foregroundColor: Colors.white,
        onPressed: () => _openCategoriaDialog(context, uid),
        icon: const Icon(Icons.add),
        label: const Text("Nova categoria"),
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

  Future<void> _confirmDelete(BuildContext context, String uid, CategoriaModel c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Excluir categoria?"),
        content: Text("“${c.nome}” será desativada (não some das etiquetas antigas)."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Excluir"),
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
      builder: (_) => AlertDialog(
        title: Text(isEdit ? "Editar categoria" : "Nova categoria"),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nomeCtrl,
                decoration: const InputDecoration(labelText: "Nome (ex: Pão)"),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: diasCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Dias de vencimento (ex: 7)"),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () async {
              final nome = nomeCtrl.text.trim();
              final dias = int.tryParse(diasCtrl.text.trim()) ?? 0;

              if (nome.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Informe o nome da categoria.")),
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
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2B2B2B)),
            child: Text(isEdit ? "Salvar" : "Criar"),
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
