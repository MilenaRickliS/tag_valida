import 'package:flutter/material.dart';

import '../data/local/repos/printer_config_local_repo.dart';
import '../models/printer_config_model.dart';

class PrinterConfigProvider extends ChangeNotifier {
  final PrinterConfigLocalRepo repo;

  PrinterConfigProvider(this.repo);

  bool _loading = false;
  String? _error;

  List<PrinterConfigModel> _items = [];
  PrinterConfigModel? _defaultPrinter;

  bool get loading => _loading;
  String? get error => _error;

  List<PrinterConfigModel> get items => List.unmodifiable(_items);
  PrinterConfigModel? get defaultPrinter => _defaultPrinter;

  Future<void> load(String uid) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _items = await repo.getAll(uid: uid);
      _defaultPrinter = await repo.getDefault(uid: uid);
    } catch (e) {
      _error = 'Erro ao carregar impressoras: $e';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> save(PrinterConfigModel model) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      await repo.save(model: model);
      _items = await repo.getAll(uid: model.uid);
      _defaultPrinter = await repo.getDefault(uid: model.uid);
    } catch (e) {
      _error = 'Erro ao salvar impressora: $e';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> delete({
    required String uid,
    required String id,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      await repo.delete(uid: uid, id: id);
      _items = await repo.getAll(uid: uid);
      _defaultPrinter = await repo.getDefault(uid: uid);
    } catch (e) {
      _error = 'Erro ao excluir impressora: $e';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> setDefault({
    required String uid,
    required String id,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      await repo.setAsDefault(uid: uid, id: id);
      _items = await repo.getAll(uid: uid);
      _defaultPrinter = await repo.getDefault(uid: uid);
    } catch (e) {
      _error = 'Erro ao definir impressora padrão: $e';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> createOrUpdateDefaultElgin({
    required String uid,
    required String ip,
    int porta = 9100,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      await repo.upsertDefaultElgin(uid: uid, ip: ip, porta: porta);
      _items = await repo.getAll(uid: uid);
      _defaultPrinter = await repo.getDefault(uid: uid);
    } catch (e) {
      _error = 'Erro ao salvar impressora Elgin: $e';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}