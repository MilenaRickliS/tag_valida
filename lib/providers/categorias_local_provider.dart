import 'package:flutter/foundation.dart';
import '../data/local/repos/categorias_local_repo.dart';
import '../models/categoria_model.dart';

class CategoriasLocalProvider extends ChangeNotifier {
  final CategoriasLocalRepo repo;
  CategoriasLocalProvider({required this.repo});

  List<CategoriaModel> _items = [];
  List<CategoriaModel> get items => _items;

  bool loading = false;

  Future<void> fetch(String uid) async {
    loading = true;
    notifyListeners();

    _items = await repo.listActive(uid);

    loading = false;
    notifyListeners();
  }

  Future<void> create(String uid, {required String nome, required int diasVencimento}) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString(); // simples por enquanto
    final model = CategoriaModel(
      id: id,
      nome: nome.trim(),
      diasVencimento: diasVencimento,
      ativo: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await repo.upsert(uid, model);
    await fetch(uid);
  }

  Future<void> update(String uid, CategoriaModel cat) async {
    await repo.upsert(uid, cat);
    await fetch(uid);
  }

  Future<void> softDelete(String uid, String id) async {
    await repo.softDelete(uid, id);
    await fetch(uid);
  }
}