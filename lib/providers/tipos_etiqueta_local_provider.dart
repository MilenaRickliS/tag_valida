import 'package:flutter/foundation.dart';
import '../data/local/repos/tipos_etiqueta_local_repo.dart';
import '../models/tipo_etiqueta_model.dart';

class TiposEtiquetaLocalProvider extends ChangeNotifier {
  final TiposEtiquetaLocalRepo repo;
  TiposEtiquetaLocalProvider({required this.repo});

  List<TipoEtiquetaModel> _items = [];
  List<TipoEtiquetaModel> get items => _items;

  bool loading = false;

  Future<void> fetch(String uid) async {
    loading = true;
    notifyListeners();

    _items = await repo.listAll(uid);

    loading = false;
    notifyListeners();
  }

  Future<void> create(String uid, TipoEtiquetaModel tipo) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final novo = TipoEtiquetaModel(
      id: id,
      nome: tipo.nome,
      descricao: tipo.descricao,
      usarRegraValidadeCategoria: tipo.usarRegraValidadeCategoria,
      camposCustom: tipo.camposCustom,
    );

    await repo.upsert(uid, novo);
    await fetch(uid);
  }

  Future<void> update(String uid, TipoEtiquetaModel tipo) async {
    await repo.upsert(uid, tipo);
    await fetch(uid);
  }

  Future<void> delete(String uid, String id) async {
    await repo.delete(uid, id);
    await fetch(uid);
  }
}