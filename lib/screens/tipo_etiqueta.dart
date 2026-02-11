// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/tipos_etiqueta_local_provider.dart';
import '../providers/auth_provider.dart';
import '../models/tipo_etiqueta_model.dart';
import '../widgets/menu.dart';

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
        icon: const Icon(Icons.add),
        label: const Text("Novo tipo"),
        onPressed: () => _openTipoDialog(context, uid),
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
      builder: (_) => AlertDialog(
        title: const Text("Excluir tipo?"),
        content: Text("Deseja excluir “${t.nome}”?"),
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
      barrierDismissible: false,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setLocal) {
            return AlertDialog(
              title: Text(isEdit ? "Editar tipo" : "Novo tipo"),
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
                            style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      TextField(
                        controller: nomeCtrl,
                        decoration: const InputDecoration(
                          labelText: "Nome do tipo (ex: Etiqueta Freezer)",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: descCtrl,
                        decoration: const InputDecoration(
                          labelText: "Descrição (opcional)",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),

                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black.withOpacity(0.12)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: SwitchListTile(
                          title: const Text("Usar regra de validade da categoria"),
                          subtitle: Text(
                            "Se marcado, a validade será calculada com base na categoria.",
                            style: TextStyle(color: Colors.black.withOpacity(0.55), fontSize: 12),
                          ),
                          value: usarRegra,
                          onChanged: (v) => setLocal(() => usarRegra = v),
                        ),
                      ),

                      const SizedBox(height: 18),

                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              "Campos personalizados",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () async {
                              final novo = await _openCampoDialog(context);
                              if (novo != null) {
                                setLocal(() => campos.add(novo));
                              }
                            },
                            icon: const Icon(Icons.add),
                            label: const Text("Adicionar campo"),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

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
                            "Nenhum campo adicional. Você pode adicionar campos como Lote, Peso, Observações...",
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
                                          style: const TextStyle(fontWeight: FontWeight.w800),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "key: ${c.key} • tipo: ${campoTipoToString(c.tipo)}",
                                          style: TextStyle(color: Colors.black.withOpacity(0.60)),
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
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancelar"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2B2B2B)),
                  onPressed: () async {
                    final nome = nomeCtrl.text.trim();
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
                  child: Text(isEdit ? "Salvar" : "Criar"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String? _validarTipo(String nome, List<CampoCustomModel> campos) {
    if (nome.isEmpty) return "Informe o nome do tipo.";
   
    final set = <String>{};
    for (final c in campos) {
      if (c.key.trim().isEmpty) return "Existe um campo com key vazia.";
      if (c.label.trim().isEmpty) return "Existe um campo com label vazia.";
      if (set.contains(c.key.trim())) return "Key duplicada: ${c.key}.";
      set.add(c.key.trim());
    }
    return null;
  }

  Future<CampoCustomModel?> _openCampoDialog(BuildContext context, {CampoCustomModel? campo}) async {
    final isEdit = campo != null;

    final labelCtrl = TextEditingController(text: campo?.label ?? "");
    final keyCtrl = TextEditingController(text: campo?.key ?? "");
    CampoTipo tipo = campo?.tipo ?? CampoTipo.text;
    bool obrigatorio = campo?.obrigatorio ?? false;

    String? erro;

    CampoCustomModel? result;

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setLocal) {
          return AlertDialog(
            title: Text(isEdit ? "Editar campo" : "Adicionar campo"),
            content: SizedBox(
              width: 520,
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
                        style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextField(
                    controller: labelCtrl,
                    decoration: const InputDecoration(
                      labelText: "Label (ex: Lote)",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: keyCtrl,
                    decoration: const InputDecoration(
                      labelText: "Key (ex: lote) — sem espaços",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  DropdownButtonFormField<CampoTipo>(
                    value: tipo,
                    decoration: const InputDecoration(
                      labelText: "Tipo do campo",
                      border: OutlineInputBorder(),
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

                  const SizedBox(height: 12),

                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black.withOpacity(0.12)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SwitchListTile(
                      title: const Text("Campo obrigatório"),
                      value: obrigatorio,
                      onChanged: (v) => setLocal(() => obrigatorio = v),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancelar"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2B2B2B)),
                onPressed: () {
                  final label = labelCtrl.text.trim();
                  final key = keyCtrl.text.trim();

                  final keyOk = RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(key);

                  if (label.isEmpty) {
                    setLocal(() => erro = "Informe o label.");
                    return;
                  }
                  if (key.isEmpty) {
                    setLocal(() => erro = "Informe a key.");
                    return;
                  }
                  if (!keyOk) {
                    setLocal(() => erro = "A key deve conter apenas letras, números e _ (sem espaços).");
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
                child: Text(isEdit ? "Salvar" : "Adicionar"),
              ),
            ],
          );
        },
      ),
    );

    return result;
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
