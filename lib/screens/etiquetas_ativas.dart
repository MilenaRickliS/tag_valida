// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../models/tipo_etiqueta_model.dart';
import '../widgets/menu.dart';
import 'etiqueta_preview.dart';
import '../providers/tipos_etiqueta_local_provider.dart';
import '../data/local/repos/etiquetas_local_repo.dart';
import '../models/etiqueta_model.dart';
import '../widgets/estoque_footer.dart';
import '../screens/criar_etiqueta.dart';
import '../providers/estoque_mov_local_provider.dart';


class EtiquetasAtivasScreen extends StatefulWidget {
  const EtiquetasAtivasScreen({super.key});

  @override
  State<EtiquetasAtivasScreen> createState() => _EtiquetasAtivasScreenState();
}

class _EtiquetasAtivasScreenState extends State<EtiquetasAtivasScreen> {
  bool _loaded = false;
  String? _tipoSelecionadoId;

   String? _statusFiltro;

  bool _showTop = true;
  bool _showFooter = true;

  Widget _viewToggles() {
    Widget pill({
      required IconData icon,
      required String label,
      required bool on,
      required VoidCallback tap,
    }) {
      return Material(
        color: on ? Colors.white : Colors.black,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: tap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: on ? Colors.black.withOpacity(0.35) : Colors.white,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 6),
                )
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: on ? Colors.black : Colors.white),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: on ? Colors.black : Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, c) {
        
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            pill(
              icon: _showTop ? Icons.expand_less_rounded : Icons.expand_more_rounded,
              label: _showTop ? "Esconder topo" : "Mostrar topo",
              on: _showTop,
              tap: () => setState(() => _showTop = !_showTop),
            ),
            pill(
              icon: _showFooter ? Icons.expand_more_rounded : Icons.expand_less_rounded,
              label: _showFooter ? "Esconder estoque" : "Mostrar estoque",
              on: _showFooter,
              tap: () => setState(() => _showFooter = !_showFooter),
            ),
          ],
        );
      },
    );
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;

    final uid = context.read<AuthProvider>().user?.uid;
    if (uid != null) {
      context.read<TiposEtiquetaLocalProvider>().fetch(uid);
      _loaded = true;
    }

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      _statusFiltro = args["statusFiltro"]?.toString();
    }

    _loaded = true;
  
  }

  

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final compact = w < 835;
    

    final uid = context.watch<AuthProvider>().user?.uid;
    if (uid == null) {
      return const Scaffold(body: Center(child: Text("Faça login novamente.")));
    }

    final tiposProv = context.watch<TiposEtiquetaLocalProvider>();
    final tipos = tiposProv.items;

    if (_tipoSelecionadoId == null && tipos.isNotEmpty) {
      _tipoSelecionadoId = tipos.first.id;
    }

    final TipoEtiquetaModel? tipoAtual = (_tipoSelecionadoId == null)
        ? null
        : tipos.any((t) => t.id == _tipoSelecionadoId)
            ? tipos.firstWhere((t) => t.id == _tipoSelecionadoId)
            : null;

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
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LayoutBuilder(
                  builder: (context, c) {
                    final isNarrow = c.maxWidth < 600;

                    final titleWidget = Text(
                      _statusFiltro == "vencido"
                          ? "Produtos vencidos"
                          : _statusFiltro == "alerta"
                              ? "Produtos em alerta"
                              : "Etiquetas ativas",
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
                    );

                    final refreshBtn = IconButton(
                      tooltip: "Atualizar tipos",
                      onPressed: tiposProv.loading
                          ? null
                          : () => context.read<TiposEtiquetaLocalProvider>().fetch(uid),
                      icon: tiposProv.loading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh),
                    );

                    if (!isNarrow) {
                      return Row(
                        children: [
                          Expanded(child: titleWidget),
                          _viewToggles(),
                          const SizedBox(width: 10),
                          refreshBtn,
                        ],
                      );
                    }

                    
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(child: titleWidget),
                            refreshBtn,
                          ],
                        ),
                        const SizedBox(height: 10),
                        Align(alignment: Alignment.centerLeft, child: _viewToggles()),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 6),
                Text(
                  "Clique em um tipo para ver as etiquetas ativas dele.",
                  style: TextStyle(color: Colors.black.withOpacity(0.60)),
                ),
                const SizedBox(height: 14),
                _TiposChips(
                  loading: tiposProv.loading,
                  tipos: tipos,
                  selectedId: _tipoSelecionadoId,
                  onSelected: (id) => setState(() => _tipoSelecionadoId = id),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: (_tipoSelecionadoId == null)
                      ? const _EmptyBox(
                          icon: Icons.label_outline,
                          title: "Nenhum tipo cadastrado",
                          subtitle:
                              "Cadastre um tipo de etiqueta para começar.",
                        )
                      : _EtiquetasPorTipoList(
                        uid: uid,
                        tipoId: _tipoSelecionadoId!,
                        tipo: tipoAtual,
                        initialStatusFiltro: _statusFiltro,

                        showTop: _showTop,
                        showFooter: _showFooter,
                        onShowTopChanged: (v) => setState(() => _showTop = v),
                        onShowFooterChanged: (v) => setState(() => _showFooter = v),
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TiposChips extends StatelessWidget {
  final bool loading;
  final List<TipoEtiquetaModel> tipos;
  final String? selectedId;
  final ValueChanged<String> onSelected;

  const _TiposChips({
    required this.loading,
    required this.tipos,
    required this.selectedId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (loading && tipos.isEmpty) {
      return const LinearProgressIndicator(minHeight: 3);
    }

    if (tipos.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFDF7ED),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black.withOpacity(0.10)),
        ),
        child: Text(
          "Nenhum tipo encontrado. Cadastre em “Tipos de etiqueta”.",
          style: TextStyle(color: Colors.black.withOpacity(0.60)),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: tipos.map((t) {
          final selected = t.id == selectedId;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: ChoiceChip(
              label: Text(t.nome),
              selected: selected,
              onSelected: (_) => onSelected(t.id),
              selectedColor: const Color(0xff428e2e),
              labelStyle: TextStyle(
                color: selected ? Colors.white : const Color(0xff428e2e),
                fontWeight: FontWeight.w700,
              ),
              backgroundColor: Colors.white,
              shape: StadiumBorder(
                side: BorderSide(color: Colors.black.withOpacity(0.12)),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _EtiquetasPorTipoList extends StatefulWidget {
  final String uid;
  final String tipoId;
  final TipoEtiquetaModel? tipo;
  final String? initialStatusFiltro; 
  final bool showTop;
  final bool showFooter;
  final ValueChanged<bool> onShowTopChanged;
  final ValueChanged<bool> onShowFooterChanged;

  const _EtiquetasPorTipoList({
    required this.uid,
    required this.tipoId,
    required this.tipo,
    this.initialStatusFiltro, 
    required this.showTop, 
    required this.showFooter, 
    required this.onShowTopChanged, 
    required this.onShowFooterChanged,
  });

  @override
  State<_EtiquetasPorTipoList> createState() => _EtiquetasPorTipoListState();
}

class _EtiquetasPorTipoListState extends State<_EtiquetasPorTipoList> {
  final _searchCtrl = TextEditingController();
  String _q = "";

  bool _fBom = true;
  bool _fAlerta = true;
  bool _fVencido = true;

  String? _setorFiltro;
  String? _categoriaFiltro;

  @override
  void initState() {
    super.initState();

  
    if (widget.initialStatusFiltro == "vencido") {
      _fBom = false;
      _fAlerta = false;
      _fVencido = true;
    } else if (widget.initialStatusFiltro == "alerta") {
      _fBom = false;
      _fAlerta = true;
      _fVencido = false;
    }

    _searchCtrl.addListener(() {
      setState(() => _q = _searchCtrl.text);
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  bool _isVencida(DateTime val) {
    final now = DateTime.now();
    final hoje = DateTime(now.year, now.month, now.day);
    return val.isBefore(hoje);
  }

  bool _isAlerta(DateTime val) {
    final now = DateTime.now();
    final hoje = DateTime(now.year, now.month, now.day);
    return !val.isBefore(hoje) && val.difference(hoje).inDays <= 3;
  }

  bool _isBom(DateTime val) => !_isVencida(val) && !_isAlerta(val);

 
  List<_ActiveChip> _buildActiveChips({
    required List<String> setores,
    required List<String> categorias,
  }) {
    final chips = <_ActiveChip>[];

   
    final allStatus = _fBom && _fAlerta && _fVencido;
    if (!allStatus) {
      if (_fBom) chips.add(_ActiveChip(text: "Bom"));
      if (_fAlerta) chips.add(_ActiveChip(text: "Em alerta"));
      if (_fVencido) chips.add(_ActiveChip(text: "Vencido"));
    }

    if (_setorFiltro != null) {
      chips.add(_ActiveChip(
        text: "Setor: $_setorFiltro",
        onRemove: () => setState(() => _setorFiltro = null),
      ));
    }
    if (_categoriaFiltro != null) {
      chips.add(_ActiveChip(
        text: "Categoria: $_categoriaFiltro",
        onRemove: () => setState(() => _categoriaFiltro = null),
      ));
    }

    if (_q.trim().isNotEmpty) {
      chips.add(_ActiveChip(
        text: "Busca: ${_q.trim()}",
        onRemove: () => setState(() => _searchCtrl.clear()),
      ));
    }

   
    return chips;
  }

  void _clearAll() {
    setState(() {
      _fBom = true;
      _fAlerta = true;
      _fVencido = true;
      _setorFiltro = null;
      _categoriaFiltro = null;
      _searchCtrl.clear();
    });
  }


 void _openFiltersModal({
  required List<String> setores,
  required List<String> categorias,
  required Map<String, int> countBySetor,
  required Map<String, int> countByCategoria,
  required int countBom,
  required int countAlerta,
  required int countVencido,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withOpacity(0.35),
    builder: (_) {
      return DraggableScrollableSheet(
        initialChildSize: 0.70,
        minChildSize: 0.45,
        maxChildSize: 0.92,
        builder: (context, scrollCtrl) {
          return Container(
            decoration: BoxDecoration(
              color: const Color(0xFFFDF7ED),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border.all(color: Colors.black.withOpacity(0.08)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.18),
                  blurRadius: 26,
                  spreadRadius: 2,
                  offset: const Offset(0, -10),
                ),
              ],
            ),
            child: Column(
              children: [
                const SizedBox(height: 10),

                
                Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),

                const SizedBox(height: 10),

              
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 2, 12, 10),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          "Filtros",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                        ),
                      ),
                      IconButton(
                        tooltip: "Fechar",
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),

               
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollCtrl,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _FiltersBarPretty(
                          fBom: _fBom,
                          fAlerta: _fAlerta,
                          fVencido: _fVencido,
                          onToggleBom: () => setState(() => _fBom = !_fBom),
                          onToggleAlerta: () => setState(() => _fAlerta = !_fAlerta),
                          onToggleVencido: () => setState(() => _fVencido = !_fVencido),
                          setores: setores,
                          categorias: categorias,
                          setorSelecionado: _setorFiltro,
                          categoriaSelecionada: _categoriaFiltro,
                          onSetorChanged: (v) => setState(() => _setorFiltro = v),
                          onCategoriaChanged: (v) => setState(() => _categoriaFiltro = v),
                          onClearAll: _clearAll,
                          countBySetor: countBySetor,
                          countByCategoria: countByCategoria,
                          countBom: countBom,
                          countAlerta: countAlerta,
                          countVencido: countVencido,
                        ),

                        const SizedBox(height: 14),

                      
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.black.withOpacity(0.08)),
                          ),
                          child: Text(
                            "Você pode combinar status + setor + categoria + busca.",
                            style: TextStyle(
                              color: Colors.black.withOpacity(0.65),
                              height: 1.35,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),

                        const SizedBox(height: 90),  
                      ],
                    ),
                  ),
                ),

              
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDF7ED),
                    border: Border(
                      top: BorderSide(color: Colors.black.withOpacity(0.08)),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextButton.icon(
                          onPressed: () {
                            _clearAll();
                            Navigator.pop(context);
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF2B2B2B),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          icon: const Icon(Icons.restart_alt_rounded, size: 18, color: Colors.black,),
                          label: const Text(
                            "Limpar",
                            style: TextStyle(fontWeight: FontWeight.w800, color: Colors.black),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff428e2e),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          icon: const Icon(Icons.check_rounded, size: 18, color: Colors.white,),
                          label: const Text(
                            "Aplicar",
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

  Widget _topBar({
    required int activeCount,
    required VoidCallback onOpenFilters,
    required VoidCallback onClearFilters,
  }) {
    return LayoutBuilder(
      builder: (context, c) {
        final isNarrow = c.maxWidth < 600;

        final searchBox = Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black.withOpacity(0.08)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 6),
              )
            ],
          ),
          child: Row(
            children: [
              Icon(Icons.search, color: Colors.black.withOpacity(0.55)),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: "Pesquisar por nome do produto...",
                    border: InputBorder.none,
                    isDense: true,
                    hintStyle: TextStyle(color: Colors.black.withOpacity(0.45)),
                  ),
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 160),
                child: (_q.trim().isNotEmpty)
                    ? IconButton(
                        key: const ValueKey("clearSearch"),
                        tooltip: "Limpar busca",
                        onPressed: () => _searchCtrl.clear(),
                        icon: const Icon(Icons.close_rounded),
                      )
                    : const SizedBox(key: ValueKey("noClear"), width: 0, height: 0),
              ),
            ],
          ),
        );

        final filtersBtn = _FilterButtonAnimated(
          activeCount: activeCount,
          onPressed: onOpenFilters,
        );

        final clearBtn = _IconSquareButton(
          tooltip: "Limpar tudo",
          icon: Icons.restart_alt_rounded,
          onPressed: onClearFilters,
        );

        if (!isNarrow) {
          return Row(
            children: [
              Expanded(child: searchBox),
              const SizedBox(width: 10),
              filtersBtn,
              const SizedBox(width: 8),
              clearBtn,
            ],
          );
        }

        
        return Column(
          children: [
            searchBox,
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: filtersBtn),
                const SizedBox(width: 10),
                clearBtn,
              ],
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.read<EtiquetasLocalRepo>();

    return FutureBuilder<List<EtiquetaModel>>(
      future: repo.listByPeriodo(
        uid: widget.uid,
        inicio: DateTime(2000, 1, 1),
        fim: DateTime(2100, 1, 1),
        status: "ativa",
        tipoId: widget.tipoId,
      ),
      builder: (context, snap) {
        if (snap.hasError) {
          return _EmptyBox(
            icon: Icons.error_outline,
            title: "Erro ao carregar",
            subtitle: snap.error.toString(),
          );
        }
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        var all = snap.data!;

        num entradasTotal = 0;
        num saidasTotal = 0;
        num geralTotal = 0;

        
        for (final e in all) {
          final qtd = e.quantidade;
          final rest = e.quantidadeRestante;
          final status = (e.statusEstoque.trim().isEmpty) ? "ativo" : e.statusEstoque.trim();

          entradasTotal += qtd;
          geralTotal += (status == "cancelado") ? 0 : rest;
          final saiu = (status == "cancelado") ? qtd : (qtd - rest);
          if (saiu > 0) saidasTotal += saiu;
        }

        if (all.isEmpty) {
          return ListView(
            padding: const EdgeInsets.only(bottom: 14),
            children: [
              _topBar(activeCount: 0, onOpenFilters: () {}, onClearFilters: _clearAll),
              const SizedBox(height: 12),
              _EmptyBox(
                icon: Icons.inbox_outlined,
                title: "Nenhuma etiqueta ativa",
                subtitle: (widget.tipo == null)
                    ? "Não há etiquetas ativas para este tipo."
                    : "Não há etiquetas ativas para “${widget.tipo!.nome}”.",
              ),
            ],
          );
        }

       
        all.sort((a, b) => a.dataValidade.compareTo(b.dataValidade));

        String setorKey(EtiquetaModel e) =>
            (e.setorNome.trim().isEmpty) ? "Sem setor" : e.setorNome.trim();

        String categoriaKey(EtiquetaModel e) => (e.categoriaNome.trim().isEmpty)
            ? "Sem categoria"
            : e.categoriaNome.trim();

        final setores = all.map(setorKey).toSet().toList()..sort();
        final categorias = all.map(categoriaKey).toSet().toList()..sort();

        if (_setorFiltro != null && !setores.contains(_setorFiltro)) {
          _setorFiltro = null;
        }
        if (_categoriaFiltro != null && !categorias.contains(_categoriaFiltro)) {
          _categoriaFiltro = null;
        }

        
        int countBom = 0, countAlerta = 0, countVencido = 0;
        final countBySetor = <String, int>{};
        final countByCategoria = <String, int>{};

        for (final e in all) {
          final val = e.dataValidade;
          if (_isVencida(val)) {
            countVencido++;
          } else if (_isAlerta(val)) {
            countAlerta++;
          } else {
            countBom++;
          }

          final s = setorKey(e);
          final c = categoriaKey(e);
          countBySetor[s] = (countBySetor[s] ?? 0) + 1;
          countByCategoria[c] = (countByCategoria[c] ?? 0) + 1;
        }

 
        int activeCount = 0;
        if (!(_fBom && _fAlerta && _fVencido)) {
          if (_fBom) activeCount++;
          if (_fAlerta) activeCount++;
          if (_fVencido) activeCount++;
        }
        if (_setorFiltro != null) activeCount++;
        if (_categoriaFiltro != null) activeCount++;
        if (_q.trim().isNotEmpty) activeCount++;

       
        final q = _q.trim().toLowerCase();
          var items = all.where((e) {
                  final st = (e.statusEstoque.trim().isEmpty)
              ? "ativo"
              : e.statusEstoque.trim().toLowerCase();

        
          if (st != "ativo") return false;
          final val = e.dataValidade;

          final okStatus = (_fVencido && _isVencida(val)) ||
              (_fAlerta && _isAlerta(val)) ||
              (_fBom && _isBom(val));
          if (!okStatus) return false;

          if (_setorFiltro != null && setorKey(e) != _setorFiltro) return false;
          if (_categoriaFiltro != null && categoriaKey(e) != _categoriaFiltro) {
            return false;
          }

          if (q.isNotEmpty) {
            final nome = (e.produtoNome).trim().toLowerCase();
            if (!nome.contains(q)) return false;
          }

          return true;
        }).toList();

        
        final activeChips = _buildActiveChips(setores: setores, categorias: categorias);

        if (items.isEmpty) {
          return Column(
            children: [
              _topBar(
                activeCount: activeCount,
                onOpenFilters: () => _openFiltersModal(
                  setores: setores,
                  categorias: categorias,
                  countBySetor: countBySetor,
                  countByCategoria: countByCategoria,
                  countBom: countBom,
                  countAlerta: countAlerta,
                  countVencido: countVencido,
                ),
                onClearFilters: _clearAll,
              ),
              if (activeChips.isNotEmpty) ...[
                const SizedBox(height: 10),
                _ActiveChipsRow(
                  chips: activeChips,
                  onClearAll: _clearAll,
                ),
              ],
              const SizedBox(height: 12),
              const Expanded(
                child: _EmptyBox(
                  icon: Icons.search_off_rounded,
                  title: "Nada encontrado",
                  subtitle: "Ajuste os filtros ou a busca.",
                ),
              ),
            ],
          );
        }

      
        final Map<String, Map<String, List<EtiquetaModel>>> grouped = {};
        for (final e in items) {
          final s = setorKey(e);
          final c = categoriaKey(e);
          grouped.putIfAbsent(s, () => {});
          grouped[s]!.putIfAbsent(c, () => []);
          grouped[s]![c]!.add(e);
        }

        DateTime minValidadeOf(List<EtiquetaModel> list) =>
            list.map((x) => x.dataValidade).reduce((a, b) => a.isBefore(b) ? a : b);

        final setoresOrdenados = grouped.entries.toList()
          ..sort((a, b) {
            final minA = minValidadeOf(a.value.values.expand((v) => v).toList());
            final minB = minValidadeOf(b.value.values.expand((v) => v).toList());
            return minA.compareTo(minB);
          });

        return ListView(
          padding: const EdgeInsets.only(bottom: 14),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          children: [
           
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              child: widget.showTop
                  ? Column(
                      children: [
                        _topBar(
                          activeCount: activeCount,
                          onOpenFilters: () => _openFiltersModal(
                            setores: setores,
                            categorias: categorias,
                            countBySetor: countBySetor,
                            countByCategoria: countByCategoria,
                            countBom: countBom,
                            countAlerta: countAlerta,
                            countVencido: countVencido,
                          ),
                          onClearFilters: _clearAll,
                        ),
                        if (activeChips.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          _ActiveChipsRow(
                            chips: activeChips,
                            onClearAll: _clearAll,
                          ),
                        ],
                        const SizedBox(height: 12),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),

          
            for (final setorEntry in setoresOrdenados) ...[
              _SetorSection(
                setorNome: setorEntry.key,
                categoriasMap: setorEntry.value,
                minValidadeOf: minValidadeOf,
                uid: widget.uid,
              ),
              const SizedBox(height: 12),
            ],

          
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              child: widget.showFooter
                  ? Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: EstoqueFooter(
                        entradas: entradasTotal,
                        saidas: saidasTotal,
                        total: geralTotal,
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        );
      },
    );
  }
}


class _ActiveChip {
  final String text;
  final VoidCallback? onRemove;
  _ActiveChip({required this.text, this.onRemove});
}

class _ActiveChipsRow extends StatelessWidget {
  final List<_ActiveChip> chips;
  final VoidCallback onClearAll;

  const _ActiveChipsRow({
    required this.chips,
    required this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final c in chips) ...[
                  _ActiveFilterChip(
                    text: c.text,
                    onRemove: c.onRemove,
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        TextButton.icon(
          onPressed: onClearAll,
          icon: const Icon(Icons.clear_all_rounded, size: 18, color: Colors.black),
          label: const Text("Limpar", style: TextStyle(color: Colors.black),),
        ),
      ],
    );
  }
}

class _ActiveFilterChip extends StatelessWidget {
  final String text;
  final VoidCallback? onRemove;

  const _ActiveFilterChip({
    required this.text,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.black.withOpacity(0.10)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: Colors.black.withOpacity(0.80),
              fontSize: 12.5,
            ),
          ),
          if (onRemove != null) ...[
            const SizedBox(width: 6),
            InkWell(
              onTap: onRemove,
              borderRadius: BorderRadius.circular(999),
              child: Icon(
                Icons.close_rounded,
                size: 16,
                color: Colors.black.withOpacity(0.65),
              ),
            )
          ],
        ],
      ),
    );
  }
}


class _FilterButtonAnimated extends StatelessWidget {
  final int activeCount;
  final VoidCallback onPressed;

  const _FilterButtonAnimated({
    required this.activeCount,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onPressed,
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black.withOpacity(0.12)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 6),
              )
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.tune_rounded,
                  size: 20, color: Colors.black.withOpacity(0.75)),
              const SizedBox(width: 8),
              const Text(
                "Filtros",
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(width: 8),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                transitionBuilder: (child, anim) => ScaleTransition(
                  scale: anim,
                  child: FadeTransition(opacity: anim, child: child),
                ),
                child: activeCount > 0
                    ? Container(
                        key: ValueKey(activeCount),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          "$activeCount",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                          ),
                        ),
                      )
                    : const SizedBox(
                        key: ValueKey(0),
                        width: 0,
                        height: 0,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconSquareButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  const _IconSquareButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onPressed,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black.withOpacity(0.12)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                )
              ],
            ),
            child: Icon(icon, color: Colors.black.withOpacity(0.75)),
          ),
        ),
      ),
    );
  }
}


class _FiltersBarPretty extends StatelessWidget {
  final bool fBom;
  final bool fAlerta;
  final bool fVencido;

  final VoidCallback onToggleBom;
  final VoidCallback onToggleAlerta;
  final VoidCallback onToggleVencido;

  final List<String> setores;
  final List<String> categorias;

  final String? setorSelecionado;
  final String? categoriaSelecionada;

  final ValueChanged<String?> onSetorChanged;
  final ValueChanged<String?> onCategoriaChanged;

  final VoidCallback onClearAll;

  final Map<String, int> countBySetor;
  final Map<String, int> countByCategoria;

  final int countBom;
  final int countAlerta;
  final int countVencido;

  const _FiltersBarPretty({
    required this.fBom,
    required this.fAlerta,
    required this.fVencido,
    required this.onToggleBom,
    required this.onToggleAlerta,
    required this.onToggleVencido,
    required this.setores,
    required this.categorias,
    required this.setorSelecionado,
    required this.categoriaSelecionada,
    required this.onSetorChanged,
    required this.onCategoriaChanged,
    required this.onClearAll,
    required this.countBySetor,
    required this.countByCategoria,
    required this.countBom,
    required this.countAlerta,
    required this.countVencido,
  });

@override
Widget build(BuildContext context) {

  Widget statusChip({
  required String label,
  required bool selected,
  required VoidCallback onTap,
  required int count,
  required IconData icon,
}) {

  Color base;
  Color lightBg;

  switch (label) {
    case "Vencido":
      base = const Color(0xFFB00020);      
      lightBg = const Color(0xFFFFEBEE);   
      break;
    case "Em alerta":
      base = const Color(0xFFEF6C00);      
      lightBg = const Color(0xFFFFF3E0);   
      break;
    default: 
      base = const Color(0xff428e2e);      
      lightBg = const Color(0xFFE8F5E9);   
  }

  final bg = selected ? lightBg : Colors.white;
  final fg = selected ? base : const Color.fromARGB(255, 24, 44, 18);
  final border = selected ? base.withOpacity(0.35) : Colors.black.withOpacity(0.10);

  return Material(
    color: bg,
    borderRadius: BorderRadius.circular(999),
    child: InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(selected ? 0.06 : 0.03),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: fg),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: fg,
                letterSpacing: 0.1,
              ),
            ),
            const SizedBox(width: 8),

          
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: selected ? base : base.withOpacity(0.10),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: selected ? base.withOpacity(0.20) : base.withOpacity(0.25),
                ),
              ),
              child: Text(
                "$count",
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: selected ? Colors.white : base,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget clearChip() {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onClearAll,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.black.withOpacity(0.10)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.restart_alt_rounded, size: 16, color: Colors.black.withOpacity(0.75)),
              const SizedBox(width: 8),
              Text(
                "Limpar",
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: Colors.black.withOpacity(0.80),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  return Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: Colors.black.withOpacity(0.08)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 16,
          offset: const Offset(0, 8),
        )
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Status",
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: Colors.black.withOpacity(0.75),
          ),
        ),
        const SizedBox(height: 10),

        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            statusChip(
              label: "Bom",
              selected: fBom,
              onTap: onToggleBom,
              count: countBom,
              icon: Icons.check_circle_outline_rounded,
            ),
            statusChip(
              label: "Em alerta",
              selected: fAlerta,
              onTap: onToggleAlerta,
              count: countAlerta,
              icon: Icons.notification_important_outlined,
            ),
            statusChip(
              label: "Vencido",
              selected: fVencido,
              onTap: onToggleVencido,
              count: countVencido,
              icon: Icons.warning_amber_rounded,
            ),
            clearChip(),
          ],
        ),

        const SizedBox(height: 14),

        Text(
          "Refinar por",
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: Colors.black.withOpacity(0.75),
          ),
        ),
        const SizedBox(height: 10),

        LayoutBuilder(
          builder: (context, c) {
            final isNarrow = c.maxWidth < 600;

            if (!isNarrow) {
              return Row(
                children: [
                  Expanded(
                    child: _DropCount(
                      label: "Setor",
                      value: setorSelecionado,
                      items: setores,
                      onChanged: onSetorChanged,
                      counts: countBySetor,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _DropCount(
                      label: "Categoria",
                      value: categoriaSelecionada,
                      items: categorias,
                      onChanged: onCategoriaChanged,
                      counts: countByCategoria,
                    ),
                  ),
                ],
              );
            }

           
            return Column(
              children: [
                _DropCount(
                  label: "Setor",
                  value: setorSelecionado,
                  items: setores,
                  onChanged: onSetorChanged,
                  counts: countBySetor,
                ),
                const SizedBox(height: 10),
                _DropCount(
                  label: "Categoria",
                  value: categoriaSelecionada,
                  items: categorias,
                  onChanged: onCategoriaChanged,
                  counts: countByCategoria,
                ),
              ],
            );
          },
        ),
      ],
    ),
  );
}
}

class _DropCount extends StatelessWidget {
  final String label;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final Map<String, int> counts;

  const _DropCount({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.counts,
  });

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xff428e2e);

    final hasValue = value != null;

    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: hasValue ? primary.withOpacity(0.35) : Colors.black.withOpacity(0.10),
            width: hasValue ? 1.4 : 1.0,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: primary.withOpacity(0.70), width: 1.8),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        filled: true,
        fillColor: hasValue ? const Color(0xFFE8F5E9) : Colors.white, 
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: value,
          isExpanded: true,
          dropdownColor: Colors.white,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: hasValue ? primary : Colors.black.withOpacity(0.65),
          ),

          selectedItemBuilder: (context) {
            return [
              Text(
                "Todos",
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Colors.black.withOpacity(0.75),
                ),
              ),
              ...items.map((s) {
                final c = counts[s] ?? 0;
                return Row(
                  children: [
                    Expanded(
                      child: Text(
                        s,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          color: Color(0xff428e2e),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: primary,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        "$c",
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ];
          },

          hint: Text(
            "Todos",
            style: TextStyle(color: Colors.black.withOpacity(0.60)),
          ),

          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text("Todos"),
            ),
            ...items.map((s) {
              final c = counts[s] ?? 0;
              final isSel = s == value;

              return DropdownMenuItem<String?>(
                value: s,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: isSel ? const Color(0xFFE8F5E9) : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          s,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: isSel ? FontWeight.w900 : FontWeight.w700,
                            color: isSel ? primary : Colors.black.withOpacity(0.85),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isSel ? primary : Colors.black.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          "$c",
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: isSel ? Colors.white : Colors.black.withOpacity(0.75),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _SetorSection extends StatelessWidget {
  final String setorNome;
  final Map<String, List<EtiquetaModel>> categoriasMap;
  final DateTime Function(List<EtiquetaModel>) minValidadeOf;
  final String uid;

  const _SetorSection({
    required this.setorNome,
    required this.categoriasMap,
    required this.minValidadeOf,
    required this.uid,
  });

  @override
  Widget build(BuildContext context) {
    final categoriasOrdenadas = categoriasMap.entries.toList()
      ..sort((a, b) => minValidadeOf(a.value).compareTo(minValidadeOf(b.value)));

    final minSetor =
        minValidadeOf(categoriasMap.values.expand((v) => v).toList());

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.55),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.07)),
      ),
      child: ExpansionTile(
        initiallyExpanded: true,
        tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        title: Row(
          children: [
            Expanded(
              child: Text(
                setorNome,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
              ),
            ),
            _Badge(text: "Mais próximo a vencer: ${_fmt(minSetor)}"),
          ],
        ),
        children: [
          for (final catEntry in categoriasOrdenadas) ...[
            _CategoriaSection(
              categoriaNome: catEntry.key,
              etiquetas: catEntry.value,
              uid: uid,
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }

  static String _fmt(DateTime d) {
    final dd = d.day.toString().padLeft(2, "0");
    final mm = d.month.toString().padLeft(2, "0");
    final yy = d.year.toString();
    return "$dd/$mm/$yy";
  }
}

class _CategoriaSection extends StatelessWidget {
  final String categoriaNome;
  final List<EtiquetaModel> etiquetas;
  final String uid;

  const _CategoriaSection({
    required this.categoriaNome,
    required this.etiquetas,
    required this.uid,
  });

  @override
  Widget build(BuildContext context) {
    etiquetas.sort((a, b) => a.dataValidade.compareTo(b.dataValidade));
    final minCat = etiquetas.first.dataValidade;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      child: ExpansionTile(
        initiallyExpanded: true,
        tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        title: Row(
          children: [
            Expanded(
              child: Text(
                categoriaNome,
                style: const TextStyle(
                    fontSize: 14.5, fontWeight: FontWeight.w900),
              ),
            ),
            _Badge(text: "Mais próximo a vencer: ${_fmt(minCat)}"),
          ],
        ),
        children: [
          for (final e in etiquetas) ...[
            _EtiquetaCard(uid: uid, e: e),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }

  static String _fmt(DateTime d) {
    final dd = d.day.toString().padLeft(2, "0");
    final mm = d.month.toString().padLeft(2, "0");
    final yy = d.year.toString();
    return "$dd/$mm/$yy";
  }
}

class _EtiquetaCard extends StatelessWidget {
  final String uid;
  final EtiquetaModel e;

  const _EtiquetaCard({required this.uid, required this.e});

Future<bool> _confirmDeleteEtiqueta(BuildContext context, String produtoNome) async {
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
            child: Text(
              "Excluir etiqueta?",
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),

      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Produto:", style: TextStyle(color: Colors.black.withOpacity(0.65))),
          const SizedBox(height: 4),
          Text(
            "“${produtoNome.isEmpty ? "Sem nome" : produtoNome}”",
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const SizedBox(height: 10),
          Text(
            "A etiqueta será desativada (exclusão suave).\nEla pode continuar aparecendo em históricos.",
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

  return ok ?? false;
}


  @override
  Widget build(BuildContext context) {
    final repo = context.read<EtiquetasLocalRepo>();

    final produto = e.produtoNome;
    final categoria = e.categoriaNome;
    final setor = e.setorNome;

    final fab = e.dataFabricacao;
    final val = e.dataValidade;

    final now = DateTime.now();
    final hoje = DateTime(now.year, now.month, now.day);
    final vencida = val.isBefore(hoje);
    final alerta = !vencida && val.difference(hoje).inDays <= 3;

    return Stack(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    EtiquetaPreviewScreen(uid: uid, etiquetaId: e.id),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black.withOpacity(0.07)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                )
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: vencida
                        ? Colors.red.withOpacity(0.12)
                        : alerta
                            ? Colors.orange.withOpacity(0.12)
                            : Colors.black.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    vencida
                        ? Icons.warning_amber_rounded
                        : alerta
                            ? Icons.notification_important_outlined
                            : Icons.local_offer_outlined,
                    color: vencida
                        ? Colors.red
                        : alerta
                            ? Colors.orange
                            : Colors.black87,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        produto.isEmpty ? "Sem nome" : produto,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        [
                          if (categoria.isNotEmpty) categoria,
                          if (setor.isNotEmpty) setor,
                        ].join(" • "),
                        style:
                            TextStyle(color: Colors.black.withOpacity(0.60)),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 10,
                        runSpacing: 6,
                        children: [
                          _MiniPill(
                            icon: Icons.calendar_month_outlined,
                            text: "Fab: ${_fmtDate(fab)}",
                          ),
                          _MiniPill(
                            icon: Icons.event_available_outlined,
                            text: "Val: ${_fmtDate(val)}",
                            danger: vencida,
                            warn: alerta,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

       Positioned(
        top: 6,
        right: 6,
        child: PopupMenuButton<String>(
          tooltip: "Opções",
          splashRadius: 22,
          offset: const Offset(0, 44),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          color: Colors.white,
          elevation: 10,

          
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.92),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black.withOpacity(0.10)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.10),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(
              Icons.more_vert,
              size: 18,
              color: Colors.black.withOpacity(0.75),
            ),
          ),

          onSelected: (v) async {
            if (v == "edit") {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CriarEtiquetaScreen(editarEtiquetaId: e.id),
                ),
              );
            }

            if (v == "delete") {
              final ok = await _confirmDeleteEtiqueta(context, produto);
              if (!ok) return;

              final mov = context.read<EstoqueMovLocalProvider>();

              final before = await repo.getById(uid: uid, id: e.id);
              if (before == null) return;

              final st = (before.statusEstoque.trim().isEmpty)
                  ? "ativo"
                  : before.statusEstoque.trim().toLowerCase();

              final rest = before.quantidadeRestante;

              if (st == "ativo" && rest > 0) {
                await mov.registrarCancelamento(
                  uid: uid,
                  etiquetaId: before.id,
                  quantidade: rest,
                  produtoNome: before.produtoNome,
                  motivo: "Exclusão da etiqueta (removeu do estoque)",
                );
              }

              await mov.registrarExclusao(
                uid: uid,
                etiquetaId: before.id,
                produtoNome: before.produtoNome,
                motivo: "Exclusão suave (tela de ativas)",
              );

              await repo.deleteSoft(uid, before.id);

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Etiqueta excluída.")),
                );
                (context as Element).markNeedsBuild();
              }
            }
          },

          itemBuilder: (_) => const [
            PopupMenuItem(
              value: "edit",
              child: ListTile(
                dense: true,
                leading: Icon(Icons.edit_outlined),
                title: Text("Editar"),
              ),
            ),
            PopupMenuItem(
              value: "delete",
              child: ListTile(
                dense: true,
                leading: Icon(Icons.delete_outline, color: Colors.red),
                title: Text("Excluir"),
              ),
            ),
          ],
        ),
      ),
      ],
    );
  }

  String _fmtDate(DateTime? d) {
    if (d == null) return "--/--/----";
    final dd = d.day.toString().padLeft(2, "0");
    final mm = d.month.toString().padLeft(2, "0");
    final yy = d.year.toString();
    return "$dd/$mm/$yy";
  }
}

class _Badge extends StatelessWidget {
  final String text;
  const _Badge({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.black.withOpacity(0.10)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w800,
          color: Colors.black.withOpacity(0.70),
          fontSize: 12,
        ),
      ),
    );
  }
}

class _MiniPill extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool danger;
  final bool warn;

  const _MiniPill({
    required this.icon,
    required this.text,
    this.danger = false,
    this.warn = false,
  });

  @override
  Widget build(BuildContext context) {
    final border = danger
        ? Colors.red.withOpacity(0.30)
        : warn
            ? Colors.orange.withOpacity(0.30)
            : Colors.black.withOpacity(0.12);

    final bg = danger
        ? Colors.red.withOpacity(0.07)
        : warn
            ? Colors.orange.withOpacity(0.07)
            : Colors.black.withOpacity(0.04);

    final fg = danger
        ? Colors.red
        : warn
            ? Colors.orange
            : Colors.black87;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: fg),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(color: fg, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _EmptyBox extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyBox({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withOpacity(0.07)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 42, color: Colors.black.withOpacity(0.75)),
          const SizedBox(height: 10),
          Text(title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black.withOpacity(0.60)),
          ),
        ],
      ),
    );
  }
}