// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/categorias_provider.dart';
import '../providers/setores_provider.dart';
import '../providers/tipo_etiqueta_provider.dart';
import '../providers/gerar_etiqueta_provider.dart';

import '../models/tipo_etiqueta_model.dart';
import '../widgets/menu.dart';
import 'etiqueta_preview.dart';

class CriarEtiquetaScreen extends StatefulWidget {
  const CriarEtiquetaScreen({super.key});

  @override
  State<CriarEtiquetaScreen> createState() => _CriarEtiquetaScreenState();
}

class _CriarEtiquetaScreenState extends State<CriarEtiquetaScreen> {
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;

    final uid = context.read<AuthProvider>().user?.uid;
    if (uid != null) {
      context.read<CategoriasProvider>().fetch(uid);
      context.read<SetoresProvider>().fetch(uid);
      context.read<TiposEtiquetaProvider>().fetch(uid);
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

    final cats = context.watch<CategoriasProvider>().items;
    final sets = context.watch<SetoresProvider>().items;
    final tipos = context.watch<TiposEtiquetaProvider>().items;
    final gerar = context.watch<GerarEtiquetaProvider>();

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
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 980),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    Navigator.pushNamed(context, '/tipos-etiqueta');
                  },
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
                      const Text("Gerar etiqueta",
                          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 8),
                      Text(
                        "Selecione o tipo, preencha os dados e gere sua etiqueta.",
                        style: TextStyle(color: Colors.black.withOpacity(0.60)),
                      ),
                      const SizedBox(height: 18),

                      
                      _Dropdown<TipoEtiquetaModel>(
                        label: "Tipo de etiqueta",
                        value: gerar.tipo,
                        items: tipos,
                        getLabel: (t) => t.nome,
                        onChanged: (t) => context.read<GerarEtiquetaProvider>().setTipo(t),
                        emptyHint: "Cadastre um tipo de etiqueta primeiro.",
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

                    
                      _Dropdown(
                        label: "Categoria",
                        value: gerar.categoria,
                        items: cats,
                        getLabel: (c) => c.nome,
                        onChanged: (c) => context.read<GerarEtiquetaProvider>().setCategoria(c),
                        emptyHint: "Cadastre categorias na tela Categorias.",
                      ),

                      const SizedBox(height: 12),

                    
                      _Dropdown(
                        label: "Setor/Responsável",
                        value: gerar.setor,
                        items: sets,
                        getLabel: (s) => s.nome,
                        onChanged: (s) => context.read<GerarEtiquetaProvider>().setSetor(s),
                        emptyHint: "Cadastre setores na tela Setores.",
                      ),

                      const SizedBox(height: 12),

                      
                      Row(
                        children: [
                          Expanded(
                            child: _DateField(
                              label: "Fabricação",
                              value: gerar.fabricacao,
                              onPick: (d) => context.read<GerarEtiquetaProvider>().setFabricacao(d),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _DateField(
                              label: "Validade",
                              value: gerar.validade,
                              onPick: (d) => context.read<GerarEtiquetaProvider>().setValidadeManual(d),
                            ),
                          ),
                        ],
                      ),

                      if (gerar.tipo?.usarRegraValidadeCategoria == true) ...[
                        const SizedBox(height: 8),
                        Text(
                          "A validade é calculada automaticamente pela categoria (você ainda pode ajustar manualmente).",
                          style: TextStyle(color: Colors.black.withOpacity(0.55), fontSize: 12),
                        ),
                      ],

                      const SizedBox(height: 18),

                      
                      if (gerar.tipo != null) ...[
                        const Text("Campos adicionais",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 10),
                        ...gerar.tipo!.camposCustom.map((campo) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildCampoDinamico(context, gerar, campo),
                          );
                        }),
                      ],

                      const SizedBox(height: 18),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: gerar.saving
                              ? null
                              : () async {
                                  final uid = context.read<AuthProvider>().user!.uid;
                                  final prov = context.read<GerarEtiquetaProvider>();

                                  try {
                                    final id = await prov.salvarEtiqueta(uid: uid);

                                    if (!context.mounted) return;
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => EtiquetaPreviewScreen(uid: uid, etiquetaId: id),
                                      ),
                                    );
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(e.toString().replaceAll("Exception: ", ""))),
                                    );
                                  }
                                },
                          icon: gerar.saving
                              ? const SizedBox(
                                  width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.local_offer_outlined),
                          label: Text(gerar.saving ? "Salvando..." : "Gerar etiqueta"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2B2B2B),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ]
            ) 
          ),
        ),
      ),
    );
  }

  Widget _buildCampoDinamico(BuildContext context, GerarEtiquetaProvider gerar, CampoCustomModel campo) {
    final label = campo.obrigatorio ? "${campo.label} *" : campo.label;

    switch (campo.tipo) {
      case CampoTipo.multiline:
        return TextField(
          maxLines: 3,
          decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
          onChanged: (v) => context.read<GerarEtiquetaProvider>().setCampoValor(key: campo.key, label: campo.label, value: v),
        );

      case CampoTipo.number:
        return TextField(
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
          onChanged: (v) => context.read<GerarEtiquetaProvider>().setCampoValor(key: campo.key, label: campo.label, value: num.tryParse(v)),
        );

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
            onChanged: (v) => context.read<GerarEtiquetaProvider>().setCampoValor(key: campo.key, label: campo.label, value: v),
          ),
        );

      case CampoTipo.date:
        final obj = gerar.camposValores[campo.key];
        final val = obj?["value"];

        DateTime? dt;
        if (val is DateTime) {
          dt = val;
        }

        return _DateField(
          label: label,
          value: dt,
          onPick: (d) => context.read<GerarEtiquetaProvider>().setCampoValor(
            key: campo.key,
            label: campo.label,
            value: d,
          ),
        );


      case CampoTipo.text:
      return TextField(
          decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
          onChanged: (v) => context.read<GerarEtiquetaProvider>().setCampoValor(key: campo.key, label: campo.label, value: v),
        );
    }
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final void Function(DateTime d) onPick;

  const _DateField({required this.label, required this.value, required this.onPick});

  @override
  Widget build(BuildContext context) {
    String text;
    if (value == null) {
      text = "Selecionar";
    } else {
      text = "${value!.day.toString().padLeft(2, "0")}/"
          "${value!.month.toString().padLeft(2, "0")}/"
          "${value!.year}";
    }

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
        child: Text(emptyHint, style: TextStyle(color: Colors.black.withOpacity(0.60))),
      );
    }

    return DropdownButtonFormField<T>(
      value: value,
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
