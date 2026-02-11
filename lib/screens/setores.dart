// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/setores_local_provider.dart';
import '../models/setor_model.dart';
import '../widgets/menu.dart';

class SetoresScreen extends StatefulWidget {
  const SetoresScreen({super.key});

  @override
  State<SetoresScreen> createState() => _SetoresScreenState();
}

class _SetoresScreenState extends State<SetoresScreen> {
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
          context.read<SetoresLocalProvider>().fetch(uid);
        });
      }
    }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final compact = w < 835;

    final uid = context.watch<AuthProvider>().user?.uid;
    final prov = context.watch<SetoresLocalProvider>();

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
        onPressed: () => _openSetorDialog(context, uid),
        icon: const Icon(Icons.add),
        label: const Text("Novo setor"),
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
                  "Setores / Responsáveis",
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  "Cadastre os setores ou responsáveis do seu estabelecimento.",
                  style: TextStyle(color: Colors.black.withOpacity(0.60)),
                ),
                const SizedBox(height: 16),

                if (prov.loading)
                  const Expanded(child: Center(child: CircularProgressIndicator()))
                else if (prov.items.isEmpty)
                  Expanded(
                    child: Center(
                      child: Text(
                        "Nenhum setor cadastrado ainda.\nClique em “Novo setor”.",
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
                        final s = prov.items[i];
                        return _SetorCard(
                          setor: s,
                          onEdit: () => _openSetorDialog(context, uid, setor: s),
                          onDelete: () => _confirmDelete(context, uid, s),
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

  Future<void> _confirmDelete(BuildContext context, String uid, SetorModel s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Excluir setor?"),
        content: Text("“${s.nome}” será desativado (não some das etiquetas antigas)."),
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
      await context.read<SetoresLocalProvider>().softDelete(uid, s.id);
    }
  }

  Future<void> _openSetorDialog(BuildContext context, String uid, {SetorModel? setor}) async {
    final nomeCtrl = TextEditingController(text: setor?.nome ?? "");
    final descCtrl = TextEditingController(text: setor?.descricao ?? "");
    final isEdit = setor != null;

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(isEdit ? "Editar setor" : "Novo setor"),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nomeCtrl,
                decoration: const InputDecoration(labelText: "Nome (ex: Padaria / João)"),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: "Descrição (opcional)"),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () async {
              final nome = nomeCtrl.text.trim();
              final desc = descCtrl.text.trim();

              if (nome.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Informe o nome do setor.")),
                );
                return;
              }

              final prov = context.read<SetoresLocalProvider>();

              if (isEdit) {
                await prov.update(
                  uid,
                  SetorModel(
                    id: setor.id,
                    nome: nome,
                    descricao: desc.isEmpty ? null : desc,
                    ativo: true,
                    createdAt: setor.createdAt,
                    updatedAt: setor.updatedAt,
                  ),
                );
              } else {
                await prov.create(uid, nome: nome, descricao: desc.isEmpty ? null : desc);
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

class _SetorCard extends StatelessWidget {
  final SetorModel setor;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _SetorCard({
    required this.setor,
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
          const Icon(Icons.badge_outlined),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(setor.nome, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                if ((setor.descricao ?? "").isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(setor.descricao!, style: TextStyle(color: Colors.black.withOpacity(0.62))),
                ],
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
