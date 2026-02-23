import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/categoria_model.dart';
import '../services/firestore_paths.dart';

class CategoriasProvider extends ChangeNotifier {
  final FirestorePaths paths;
  CategoriasProvider({required this.paths});

  List<CategoriaModel> _items = [];
  List<CategoriaModel> get items => _items;

  bool loading = false;

  Future<void> fetch(String empresaId) async {
    loading = true;
    notifyListeners();

    final snap = await paths.categorias(empresaId)
        .where("ativo", isEqualTo: true)
        .orderBy("nome")
        .get();

    _items = snap.docs.map((d) => CategoriaModel.fromDoc(d)).toList();
    loading = false;
    notifyListeners();
  }

  Future<void> create(String empresaId, {required String nome, required int diasVencimento}) async {
    final ref = paths.categorias(empresaId).doc();
    final model = CategoriaModel(
      id: ref.id,
      nome: nome.trim(),
      diasVencimento: diasVencimento,
      ativo: true,
    );

    await ref.set(model.toMap());
    await fetch(empresaId);
  }

  Future<void> update(String empresaId, CategoriaModel cat) async {
    await paths.categorias(empresaId).doc(cat.id).update({
      "nome": cat.nome.trim(),
      "diasVencimento": cat.diasVencimento,
      "ativo": cat.ativo,
      "createdAt": FieldValue.serverTimestamp(),
      "updatedAt": FieldValue.serverTimestamp(),
    });
    await fetch(empresaId);
  }

  Future<void> softDelete(String empresaId, String id) async {
    await paths.categorias(empresaId).doc(id).update({
      "ativo": false,
      "updatedAt": FieldValue.serverTimestamp(),
    });
    await fetch(empresaId);
  }
}
