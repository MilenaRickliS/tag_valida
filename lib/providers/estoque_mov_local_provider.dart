import 'package:flutter/material.dart';
import '../data/local/repos/estoque_mov_local_repo.dart';
import '../models/estoque_mov_model.dart';
import '../models/estoque_mov_resumo.dart';

class EstoqueMovLocalProvider extends ChangeNotifier {
  final EstoqueMovLocalRepo repo;
  EstoqueMovLocalProvider({required this.repo});

  Future<List<EstoqueMovModel>> listAll({required String uid, int limit = 500}) {
    return repo.listAll(uid: uid, limit: limit);
  }

  Future<EstoqueMovResumo> resumo({required String uid}) {
    return repo.resumo(uid: uid);
  }

  Future<void> registrar({
    required String uid,
    required String etiquetaId,
    required String tipo,
    required num quantidade,
    String? produtoNome,
    String? motivo,
  }) async {
    final now = DateTime.now();

    final mov = EstoqueMovModel(
      id: now.millisecondsSinceEpoch.toString(),
      etiquetaId: etiquetaId,
      produtoNome: produtoNome,
      tipo: tipo,
      quantidade: quantidade,
      motivo: motivo,
      createdAt: now,
      updatedAt: now,
    );

    
    await repo.insertAndEnqueue(uid, mov);
    notifyListeners();
  }

  Future<void> registrarEntrada({
    required String uid,
    required String etiquetaId,
    required num quantidade,
    String? produtoNome,
    String? motivo,
  }) async {
    final now = DateTime.now();

    final mov = EstoqueMovModel(
      id: now.millisecondsSinceEpoch.toString(),
      etiquetaId: etiquetaId,
      produtoNome: produtoNome,
      tipo: EstoqueMovModel.tipoEntrada,
      quantidade: quantidade,
      motivo: motivo ?? "Entrada",
      createdAt: now,
      updatedAt: now,
    );

    await repo.insertAndEnqueue(uid, mov);
    notifyListeners();
  }

  Future<void> registrarVenda({
    required String uid,
    required String etiquetaId,
    required num quantidade,
    String? produtoNome,
    String? motivo,
  }) async {
    final now = DateTime.now();

    final mov = EstoqueMovModel(
      id: now.millisecondsSinceEpoch.toString(),
      etiquetaId: etiquetaId,
      produtoNome: produtoNome,
      tipo: EstoqueMovModel.tipoVenda,
      quantidade: quantidade,
      motivo: motivo ?? "Venda",
      createdAt: now,
      updatedAt: now,
    );

    await repo.insertAndEnqueue(uid, mov);
    notifyListeners();
  }

  Future<void> registrarCancelamento({
    required String uid,
    required String etiquetaId,
    required num quantidade,
    String? produtoNome,
    String? motivo,
  }) async {
    final now = DateTime.now();

    final mov = EstoqueMovModel(
      id: now.millisecondsSinceEpoch.toString(),
      etiquetaId: etiquetaId,
      produtoNome: produtoNome,
      tipo: EstoqueMovModel.tipoCancelamento,
      quantidade: quantidade,
      motivo: motivo ?? "Cancelamento",
      createdAt: now,
      updatedAt: now,
    );

    await repo.insertAndEnqueue(uid, mov);
    notifyListeners();
  }

  Future<void> registrarExclusao({
    required String uid,
    required String etiquetaId,
    num quantidade = 0,
    String? produtoNome,
    String? motivo,
  }) async {
    final now = DateTime.now();

    final mov = EstoqueMovModel(
      id: now.millisecondsSinceEpoch.toString(),
      etiquetaId: etiquetaId,
      produtoNome: produtoNome,
      tipo: EstoqueMovModel.tipoExclusao,
      quantidade: quantidade,
      motivo: motivo ?? "Exclusão (suave)",
      createdAt: now,
      updatedAt: now,
    );

    await repo.insertAndEnqueue(uid, mov);
    notifyListeners();
  }
}