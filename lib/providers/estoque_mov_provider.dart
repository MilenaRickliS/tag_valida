import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/estoque_mov_model.dart';
import '../models/estoque_mov_resumo.dart';
import '../services/firestore_paths.dart';

class EstoqueMovProvider extends ChangeNotifier {
  final FirestorePaths paths;
  EstoqueMovProvider({required this.paths});


  Future<List<EstoqueMovModel>> listAll({
    required String uid,
    int limit = 500,
  }) async {
    final snap = await paths
        .estoqueMov(uid)
        .orderBy("createdAt", descending: true)
        .limit(limit)
        .get();

    return snap.docs.map((d) => EstoqueMovModel.fromDoc(d)).toList();
  }

 
  Future<EstoqueMovResumo> resumo({
    required String uid,
    int limit = 2000,
  }) async {
    final list = await listAll(uid: uid, limit: limit);

    num entradas = 0;
    num saidasVenda = 0;
    num saidasCancelamento = 0;

    for (final m in list) {
      final t = m.tipo.toLowerCase().trim();

    
      if (t == EstoqueMovModel.tipoEntrada ||
          t == EstoqueMovModel.tipoAjusteEntrada) {
        entradas += m.quantidade;
      }

      
      else if (t == EstoqueMovModel.tipoVenda) {
        saidasVenda += m.quantidade.abs();
      } else if (t == EstoqueMovModel.tipoCancelamento) {
        saidasCancelamento += m.quantidade.abs();
      }

    }

    final saldo = entradas - (saidasVenda + saidasCancelamento);

    return EstoqueMovResumo(
      entradas: entradas,
      saidasVenda: saidasVenda,
      saidasCancelamento: saidasCancelamento,
      saldo: saldo,
    );
  }


  Future<void> registrar({
    required String uid,
    required String etiquetaId,
    required String tipo,
    required num quantidade,
    String? produtoNome,
    String? motivo,
  }) async {
    final ref = paths.estoqueMov(uid).doc();

    final payload = {
      "id": ref.id,
      "etiquetaId": etiquetaId,
      "produtoNome": _trimOrNull(produtoNome),
      "tipo": tipo.trim(),
      "quantidade": quantidade,
      "motivo": _trimOrNull(motivo),
      "createdAt": FieldValue.serverTimestamp(),
      "updatedAt": FieldValue.serverTimestamp(),

      "createdAtMs": DateTime.now().millisecondsSinceEpoch,
      "updatedAtMs": DateTime.now().millisecondsSinceEpoch,
    };

    await ref.set(payload);
    notifyListeners();
  }

  Future<void> registrarEntrada({
    required String uid,
    required String etiquetaId,
    required num quantidade,
    String? produtoNome,
    String? motivo,
  }) {
    return registrar(
      uid: uid,
      etiquetaId: etiquetaId,
      tipo: EstoqueMovModel.tipoEntrada,
      quantidade: quantidade,
      produtoNome: produtoNome,
      motivo: motivo ?? "Entrada",
    );
  }

  Future<void> registrarVenda({
    required String uid,
    required String etiquetaId,
    required num quantidade,
    String? produtoNome,
    String? motivo,
  }) {
    return registrar(
      uid: uid,
      etiquetaId: etiquetaId,
      tipo: EstoqueMovModel.tipoVenda,
      quantidade: quantidade,
      produtoNome: produtoNome,
      motivo: motivo ?? "Venda",
    );
  }

  Future<void> registrarCancelamento({
    required String uid,
    required String etiquetaId,
    required num quantidade,
    String? produtoNome,
    String? motivo,
  }) {
    return registrar(
      uid: uid,
      etiquetaId: etiquetaId,
      tipo: EstoqueMovModel.tipoCancelamento,
      quantidade: quantidade,
      produtoNome: produtoNome,
      motivo: motivo ?? "Cancelamento",
    );
  }

  Future<void> registrarExclusao({
    required String uid,
    required String etiquetaId,
    num quantidade = 0,
    String? produtoNome,
    String? motivo,
  }) {
    return registrar(
      uid: uid,
      etiquetaId: etiquetaId,
      tipo: EstoqueMovModel.tipoExclusao,
      quantidade: quantidade,
      produtoNome: produtoNome,
      motivo: motivo ?? "Exclusão (suave)",
    );
  }

  String? _trimOrNull(String? s) {
    final t = s?.trim();
    if (t == null || t.isEmpty) return null;
    return t;
  }
}