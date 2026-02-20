import 'package:flutter/foundation.dart';
import '../data/local/repos/etiqueta_template_local_repo.dart';
import '../models/etiqueta_template_model.dart';

class TemplatesProvider extends ChangeNotifier {
  final EtiquetasTemplatesLocalRepo repo;
  TemplatesProvider({required this.repo});

  bool loading = false;
  List<EtiquetaTemplateModel> items = [];

  Future<void> fetch(String uid) async {
    loading = true;
    notifyListeners();

    try {
      items = await repo.listAll(uid: uid);
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> delete({required String uid, required String id}) async {
    await repo.delete(uid: uid, id: id);
    await fetch(uid); 
  }
}