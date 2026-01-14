import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/setor_model.dart';
import '../services/firestore_paths.dart';

class SetoresProvider extends ChangeNotifier {
  final FirestorePaths paths;
  SetoresProvider({required this.paths});

  List<SetorModel> _items = [];
  List<SetorModel> get items => _items;

  bool loading = false;

  Future<void> fetch(String empresaId) async {
    loading = true;
    notifyListeners();

    final snap = await paths.setores(empresaId)
        .where("ativo", isEqualTo: true)
        .orderBy("nome")
        .get();

    _items = snap.docs.map((d) => SetorModel.fromDoc(d)).toList();
    loading = false;
    notifyListeners();
  }

  Future<void> create(String empresaId, {required String nome, String? descricao}) async {
    final ref = paths.setores(empresaId).doc();
    final model = SetorModel(
      id: ref.id,
      nome: nome.trim(),
      descricao: descricao?.trim(),
      ativo: true,
    );

    await ref.set(model.toMap());
    await fetch(empresaId);
  }

  Future<void> update(String empresaId, SetorModel s) async {
    await paths.setores(empresaId).doc(s.id).update({
      "nome": s.nome.trim(),
      "descricao": s.descricao?.trim(),
      "ativo": s.ativo,
      "updatedAt": FieldValue.serverTimestamp(),
    });
    await fetch(empresaId);
  }

  Future<void> softDelete(String empresaId, String id) async {
    await paths.setores(empresaId).doc(id).update({
      "ativo": false,
      "updatedAt": FieldValue.serverTimestamp(),
    });
    await fetch(empresaId);
  }
}
