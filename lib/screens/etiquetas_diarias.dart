// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/templates_provider.dart';
import '../widgets/menu.dart';

class EtiquetasDiariasScreen extends StatefulWidget {
  const EtiquetasDiariasScreen({super.key});

  @override
  State<EtiquetasDiariasScreen> createState() => _EtiquetasDiariasScreenState();
}

class _EtiquetasDiariasScreenState extends State<EtiquetasDiariasScreen> {
  bool _loaded = false;

  final _searchCtrl = TextEditingController();
  String _query = "";
  String? _setorSel;
  String? _categoriaSel;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      setState(() => _query = _searchCtrl.text.trim());
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;

    final uid = context.read<AuthProvider>().user?.uid;
    if (uid != null) {
      context.read<TemplatesProvider>().fetch(uid);
      _loaded = true;
    }
  }

  String _norm(String s) => s.toLowerCase().replaceAll(RegExp(r"\s+"), " ").trim();

  bool _match(String value, String query) {
    if (query.isEmpty) return true;
    return _norm(value).contains(_norm(query));
  }

  void _clearAll() {
    setState(() {
      _searchCtrl.clear();
      _setorSel = null;
      _categoriaSel = null;
    });
    FocusManager.instance.primaryFocus?.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final compact = w < 835;

    final uid = context.watch<AuthProvider>().user?.uid;
    if (uid == null) {
      return const Scaffold(body: Center(child: Text("Faça login novamente.")));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFDF7ED),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDF7ED),
        elevation: 0,
        toolbarHeight: compact ? 104 : 92, 
        centerTitle: false,
        titleSpacing: 12,
        title: Row(
          children: [
            Image.asset('assets/logo5.png', height: compact ? 56 : 72),
            const Spacer(),
           
            const TopMenu(),
          ],
        ),
      ),
      body: Consumer<TemplatesProvider>(
        builder: (_, p, __) {
          if (p.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          Widget emptyState({
            required IconData icon,
            required String title,
            required String subtitle,
            required VoidCallback onRefresh,
          }) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Colors.black.withOpacity(0.06)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 18,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Icon(icon, size: 30, color: const Color(0xFF2B2B2B)),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.black.withOpacity(0.65), height: 1.35),
                      ),
                      const SizedBox(height: 14),
                      ElevatedButton.icon(
                        onPressed: onRefresh,
                        icon: const Icon(Icons.refresh, color: Colors.white),
                        label: const Text("Atualizar"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2B2B2B),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          if (p.items.isEmpty) {
            return emptyState(
              icon: Icons.inventory_2_outlined,
              title: "Nenhum modelo salvo ainda.",
              subtitle:
                  "Crie uma etiqueta normal e ela aparece aqui como modelo diário para lançar mais rápido no estoque.",
              onRefresh: () => p.fetch(uid),
            );
          }

          final setores = <String>{
            for (final x in p.items) x.setorNome.trim()
          }.where((e) => e.isNotEmpty).toList()
            ..sort();

          final categorias = <String>{
            for (final x in p.items) x.categoriaNome.trim()
          }.where((e) => e.isNotEmpty).toList()
            ..sort();

          final filtered = p.items.where((t) {
            final okNome = _match(t.produtoNome, _query);
            final okSetor = _setorSel == null || t.setorNome == _setorSel;
            final okCat = _categoriaSel == null || t.categoriaNome == _categoriaSel;
            return okNome && okSetor && okCat;
          }).toList();

          final isPhone = w < 560;

          Widget buildHeader() {
            Widget dropdown({
              required String label,
              required String? value,
              required List<String> items,
              required ValueChanged<String?> onChanged,
              required IconData icon,
            }) {
              return DropdownButtonFormField<String>(
                value: value,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: label,
                  prefixIcon: Icon(icon),
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
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                items: [
                  const DropdownMenuItem<String>(value: null, child: Text("Todos")),
                  ...items.map((e) => DropdownMenuItem<String>(
                        value: e,
                        child: Text(e, overflow: TextOverflow.ellipsis),
                      )),
                ],
                onChanged: onChanged,
              );
            }

            final search = TextField(
              controller: _searchCtrl,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: "Pesquisar por nome do produto...",
                prefixIcon: const Icon(Icons.search),
                suffixIcon: (_query.isEmpty)
                    ? null
                    : IconButton(
                        tooltip: "Limpar",
                        onPressed: () {
                          _searchCtrl.clear();
                          FocusManager.instance.primaryFocus?.unfocus();
                        },
                        icon: const Icon(Icons.close),
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
            );

            final filters = LayoutBuilder(
              builder: (context, c) {
                final wide = c.maxWidth >= 900;

                if (wide) {
                  return Row(
                    children: [
                      Expanded(child: search),
                      const SizedBox(width: 12),
                      Expanded(
                        child: dropdown(
                          label: "Setor",
                          icon: Icons.storefront_outlined,
                          value: _setorSel,
                          items: setores,
                          onChanged: (v) => setState(() => _setorSel = v),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: dropdown(
                          label: "Categoria",
                          icon: Icons.category_outlined,
                          value: _categoriaSel,
                          items: categorias,
                          onChanged: (v) => setState(() => _categoriaSel = v),
                        ),
                      ),
                      const SizedBox(width: 12),
                      _ClearFiltersButton(
                        enabled: _query.isNotEmpty || _setorSel != null || _categoriaSel != null,
                        onPressed: _clearAll,
                      ),
                    ],
                  );
                }

                return Column(
                  children: [
                    search,
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: dropdown(
                            label: "Setor",
                            icon: Icons.storefront_outlined,
                            value: _setorSel,
                            items: setores,
                            onChanged: (v) => setState(() => _setorSel = v),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: dropdown(
                            label: "Categoria",
                            icon: Icons.category_outlined,
                            value: _categoriaSel,
                            items: categorias,
                            onChanged: (v) => setState(() => _categoriaSel = v),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: _ClearFiltersButton(
                        enabled: _query.isNotEmpty || _setorSel != null || _categoriaSel != null,
                        onPressed: _clearAll,
                      ),
                    ),
                  ],
                );
              },
            );

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.black.withOpacity(0.06)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Etiquetas diárias",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Escolha um molde para criar uma nova etiqueta no estoque de forma rápida.",
                    style: TextStyle(color: Colors.black.withOpacity(0.7), height: 1.35),
                  ),
                  const SizedBox(height: 14),
                  filters,
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAF7F1),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: Colors.black.withOpacity(0.08)),
                        ),
                        child: Text(
                          "${filtered.length} item(ns)",
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        tooltip: "Recarregar",
                        onPressed: () => p.fetch(uid),
                        icon: const Icon(Icons.refresh),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }

          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                sliver: SliverToBoxAdapter(child: buildHeader()),
              ),

              if (filtered.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: emptyState(
                    icon: Icons.search_off_rounded,
                    title: "Nada por aqui…",
                    subtitle: "Tente ajustar a pesquisa ou limpe os filtros.",
                    onRefresh: () => p.fetch(uid),
                  ),
                )
              else if (isPhone)
                
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                  sliver: SliverList.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) {
                      final t = filtered[i];
                      return _TemplateCard(
                        dense: true,
                        produtoNome: t.produtoNome,
                        linha2: "${t.tipoNome} • ${t.categoriaNome}",
                        linha3: t.setorNome,
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            "/criar-etiqueta",
                            arguments: {"templateId": t.id},
                          );
                        },
                        onDelete: () async {
                          await context.read<TemplatesProvider>().delete(uid: uid, id: t.id);
                        },
                      );
                    },
                  ),
                )
              else
               
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 360, 
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: w < 900 ? 1.35 : 1.55,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, i) {
                        final t = filtered[i];
                        return _TemplateCard(
                          dense: false,
                          produtoNome: t.produtoNome,
                          linha2: "${t.tipoNome} • ${t.categoriaNome}",
                          linha3: t.setorNome,
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              "/criar-etiqueta",
                              arguments: {"templateId": t.id},
                            );
                          },
                          onDelete: () async {
                            await context.read<TemplatesProvider>().delete(uid: uid, id: t.id);
                          },
                        );
                      },
                      childCount: filtered.length,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ClearFiltersButton extends StatelessWidget {
  final bool enabled;
  final VoidCallback onPressed;

  const _ClearFiltersButton({
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: enabled ? onPressed : null,
      icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
      label: const Text("Limpar"),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF2B2B2B),
        side: BorderSide(color: Colors.black.withOpacity(0.12)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }
}

class _TemplateCard extends StatefulWidget {
  final String produtoNome;
  final String linha2;
  final String linha3;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  final bool dense; 

  const _TemplateCard({
    required this.produtoNome,
    required this.linha2,
    required this.linha3,
    required this.onTap,
    required this.onDelete,
    required this.dense,
  });

  @override
  State<_TemplateCard> createState() => _TemplateCardState();
}

class _TemplateCardState extends State<_TemplateCard> {
  bool _hover = false;
  bool _pressed = false;

  Future<bool> _confirmDelete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.red.withOpacity(0.22)),
              ),
              child: const Icon(Icons.delete_outline, color: Colors.red),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text("Excluir template?", style: TextStyle(fontWeight: FontWeight.w900)),
            ),
          ],
        ),
        content: const Text(
          "Isso remove o modelo diário salvo. Você pode criar novamente depois, se precisar.",
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context, false),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF2B2B2B),
              side: BorderSide(color: Colors.black.withOpacity(0.12)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              elevation: 0,
            ),
            child: const Text("Excluir"),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final scale = _pressed ? 0.985 : (_hover ? 1.01 : 1.0);
    final dy = _hover ? -2.0 : 0.0;

    final parts = widget.linha2.split("•").map((e) => e.trim()).toList();
    final tipo = parts.isNotEmpty ? parts.first : widget.linha2;
    final categoria = parts.length > 1 ? parts[1] : "";

    Widget chip(String text, {IconData? icon}) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFFAF7F1),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.black.withOpacity(0.08)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: const Color(0xFF2B2B2B)),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5),
              ),
            ),
          ],
        ),
      );
    }

    final iconBox = Container(
      width: widget.dense ? 42 : 46,
      height: widget.dense ? 42 : 46,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFFAF7F1),
            const Color(0xFFFAF7F1).withOpacity(0.75),
          ],
        ),
        border: Border.all(color: Colors.black.withOpacity(0.08)),
      ),
      child: const Icon(Icons.local_offer_outlined, color: Color(0xFF2B2B2B)),
    );

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() {
        _hover = false;
        _pressed = false;
      }),
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          transform: Matrix4.identity()..translate(0.0, dy)..scale(scale),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _hover ? Colors.black.withOpacity(0.10) : Colors.black.withOpacity(0.06),
              width: _hover ? 1.2 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(_hover ? 0.08 : 0.05),
                blurRadius: _hover ? 26 : 18,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(widget.dense ? 12 : 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
               
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    iconBox,
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.produtoNome,
                        maxLines: widget.dense ? 2 : 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: widget.dense ? 15.5 : 16.5,
                          height: 1.15,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAF7F1),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: Colors.black.withOpacity(0.08)),
                      ),
                      child: PopupMenuButton<String>(
                        tooltip: "Opções",
                        color: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: EdgeInsets.zero,
                        iconSize: 20,
                        icon: const Icon(Icons.more_horiz, color: Color(0xFF2B2B2B)),
                        onSelected: (v) async {
                          if (v == "delete") {
                            final ok = await _confirmDelete(context);
                            if (ok) widget.onDelete();
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem<String>(
                            value: "delete",
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline, color: Colors.red),
                                SizedBox(width: 10),
                                Text("Excluir"),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

               
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (tipo.isNotEmpty) chip(tipo, icon: Icons.local_offer_outlined),
                    if (categoria.isNotEmpty) chip(categoria, icon: Icons.category_outlined),
                  ],
                ),

                const SizedBox(height: 10),

               
                Row(
                  children: [
                    Icon(Icons.storefront_outlined, size: 15, color: Colors.black.withOpacity(0.55)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        widget.linha3,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.black.withOpacity(0.62),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFF428E2E),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.black.withOpacity(0.08)),
                      ),
                      child: const Icon(Icons.add, size: 18, color: Colors.white),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}