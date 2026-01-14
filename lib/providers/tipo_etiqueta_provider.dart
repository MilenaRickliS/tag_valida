import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/tipo_etiqueta_model.dart';
import '../services/firestore_paths.dart';

class TiposEtiquetaProvider extends ChangeNotifier {
  final FirestorePaths paths;
  TiposEtiquetaProvider({required this.paths});

  List<TipoEtiquetaModel> _items = [];
  List<TipoEtiquetaModel> get items => _items;

  bool loading = false;

  Future<void> fetch(String empresaId) async {
    loading = true;
    notifyListeners();

    final snap = await paths.tiposEtiqueta(empresaId)
        .orderBy("nome")
        .get();

    _items = snap.docs.map((d) => TipoEtiquetaModel.fromDoc(d)).toList();
    loading = false;
    notifyListeners();
  }

  Future<void> create(String empresaId, TipoEtiquetaModel tipo) async {
    final ref = paths.tiposEtiqueta(empresaId).doc();
    await ref.set({
      "nome": tipo.nome.trim(),
      "descricao": tipo.descricao?.trim(),
      "usarRegraValidadeCategoria": tipo.usarRegraValidadeCategoria,
      "camposCustom": tipo.camposCustom.map((c) => c.toMap()).toList(),
      "createdAt": FieldValue.serverTimestamp(),
      "updatedAt": FieldValue.serverTimestamp(),
    });
    await fetch(empresaId);
  }

  Future<void> update(String empresaId, TipoEtiquetaModel tipo) async {
    await paths.tiposEtiqueta(empresaId).doc(tipo.id).update({
      "nome": tipo.nome.trim(),
      "descricao": tipo.descricao?.trim(),
      "usarRegraValidadeCategoria": tipo.usarRegraValidadeCategoria,
      "camposCustom": tipo.camposCustom.map((c) => c.toMap()).toList(),
      "updatedAt": FieldValue.serverTimestamp(),
    });
    await fetch(empresaId);
  }

  Future<void> delete(String empresaId, String id) async {
    await paths.tiposEtiqueta(empresaId).doc(id).delete();
    await fetch(empresaId);
  }
}
