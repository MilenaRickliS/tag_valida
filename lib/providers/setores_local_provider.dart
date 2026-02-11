import 'package:flutter/foundation.dart';
import '../data/local/repos/setores_local_repo.dart';
import '../models/setor_model.dart';

class SetoresLocalProvider extends ChangeNotifier {
  final SetoresLocalRepo repo;
  SetoresLocalProvider({required this.repo});

  List<SetorModel> _items = [];
  List<SetorModel> get items => _items;

  bool loading = false;

  Future<void> fetch(String uid) async {
    loading = true;
    notifyListeners();

    _items = await repo.listActive(uid);

    loading = false;
    notifyListeners();
  }

  Future<void> create(String uid, {required String nome, String? descricao}) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();

    final model = SetorModel(
      id: id,
      nome: nome.trim(),
      descricao: (descricao ?? '').trim().isEmpty ? null : descricao!.trim(),
      ativo: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await repo.upsert(uid, model);
    await fetch(uid);
  }

  Future<void> update(String uid, SetorModel s) async {
    await repo.upsert(uid, s);
    await fetch(uid);
  }

  Future<void> softDelete(String uid, String id) async {
    await repo.softDelete(uid, id);
    await fetch(uid);
  }
}