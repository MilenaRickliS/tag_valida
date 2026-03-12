
import 'package:sqflite/sqflite.dart';
import '../app_db.dart';
import '../outbox/outbox_helper.dart';
import '../mappers/etiqueta_local.dart';
import '../../../models/etiqueta_model.dart';

class EtiquetasLocalRepo {
  Future<void> upsert(String uid, EtiquetaModel e) async {
    final db = await AppDb.instance.db;
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    await db.transaction((txn) async {
     
      await txn.insert(
        'etiquetas',
        e.toLocalMap(uid: uid, nowMs: nowMs),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

    
      final payload = <String, dynamic>{
        "tipoId": e.tipoId,
        "tipoNome": e.tipoNome,
        "produtoNome": e.produtoNome,
        "categoriaId": e.categoriaId,
        "categoriaNome": e.categoriaNome,
        "setorId": e.setorId,
        "setorNome": e.setorNome,

       
        "dataFabricacaoMs": e.dataFabricacao.millisecondsSinceEpoch,
        "dataValidadeMs": e.dataValidade.millisecondsSinceEpoch,

        "camposCustomValores": e.camposCustomValores, 
        "status": e.status,

        "quantidade": e.quantidade,
        "quantidadeRestante": e.quantidadeRestante,
        "statusEstoque": e.statusEstoque,
        "soldAtMs": e.soldAt?.millisecondsSinceEpoch,
        "lote": e.lote ?? (e.camposCustomValores["lote"]?["value"]?.toString()),

      
        "createdAtMs": (e.createdAt?.millisecondsSinceEpoch ?? nowMs),
        "updatedAtMs": nowMs,
      };

      await OutboxHelper.enqueueUpsert(
        txn: txn,
        uid: uid,
        entity: "etiquetas",
        entityId: e.id,
        payload: payload,
        nowMs: nowMs,
      );
    });
  }

  Future<void> update(String uid, EtiquetaModel e) async {
    
    await upsert(uid, e);
  }

  Future<void> deleteSoft(String uid, String id) async {
    final db = await AppDb.instance.db;
    final nowMs = DateTime.now().millisecondsSinceEpoch;

  
    final current = await getById(uid: uid, id: id);
    if (current == null) return;

    final updated = EtiquetaModel(
      id: current.id,
      tipoId: current.tipoId,
      tipoNome: current.tipoNome,
      produtoNome: current.produtoNome,
      categoriaId: current.categoriaId,
      categoriaNome: current.categoriaNome,
      setorId: current.setorId,
      setorNome: current.setorNome,
      dataFabricacao: current.dataFabricacao,
      dataValidade: current.dataValidade,
      camposCustomValores: current.camposCustomValores,
      quantidade: current.quantidade,
      quantidadeRestante: current.quantidadeRestante,
      statusEstoque: "cancelado", 
      soldAt: current.soldAt,
      status: "excluida",
      lote: current.lote,
      createdAt: current.createdAt,
    );

    await db.transaction((txn) async {
      await txn.insert(
        'etiquetas',
        updated.toLocalMap(uid: uid, nowMs: nowMs),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      final payload = <String, dynamic>{
        "tipoId": updated.tipoId,
        "tipoNome": updated.tipoNome,
        "produtoNome": updated.produtoNome,
        "categoriaId": updated.categoriaId,
        "categoriaNome": updated.categoriaNome,
        "setorId": updated.setorId,
        "setorNome": updated.setorNome,
        "dataFabricacaoMs": updated.dataFabricacao.millisecondsSinceEpoch,
        "dataValidadeMs": updated.dataValidade.millisecondsSinceEpoch,
        "camposCustomValores": updated.camposCustomValores,
        "status": updated.status,
        "lote": updated.lote ?? (updated.camposCustomValores["lote"]?["value"]?.toString()),
        "quantidade": updated.quantidade,
        "quantidadeRestante": updated.quantidadeRestante,
        "statusEstoque": updated.statusEstoque,
        "soldAtMs": updated.soldAt?.millisecondsSinceEpoch,
        "createdAtMs": (updated.createdAt?.millisecondsSinceEpoch ?? nowMs),
        "updatedAtMs": nowMs,
      };

      await OutboxHelper.enqueueUpsert(
        txn: txn,
        uid: uid,
        entity: "etiquetas",
        entityId: updated.id,
        payload: payload,
        nowMs: nowMs,
      );
    });
  }


  
  Future<void> deleteHard(String uid, String id) async {
    final db = await AppDb.instance.db;
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    await db.transaction((txn) async {
      await txn.delete(
        'etiquetas',
        where: 'uid = ? AND id = ?',
        whereArgs: [uid, id],
      );

      await OutboxHelper.enqueueDelete(
        txn: txn,
        uid: uid,
        entity: "etiquetas",
        entityId: id,
        nowMs: nowMs,
      );
    });
  }



 Future<List<EtiquetaModel>> listByPeriodo({
    required String uid,
    required DateTime inicio,
    required DateTime fim,
    String? status,
    String? categoriaId,
    String? setorId,
    String? tipoId,
    String? statusEstoque,
  }) async {
    final db = await AppDb.instance.db;

    final where = <String>[
      'uid = ?',
      'createdAt >= ?',
      'createdAt <= ?',
    ];

    final args = <Object>[
      uid,
      inicio.millisecondsSinceEpoch,
      fim.millisecondsSinceEpoch,
    ];

    if (status != null) {
      where.add('status = ?');
      args.add(status);
    }
    if (categoriaId != null) {
      where.add('categoriaId = ?');
      args.add(categoriaId);
    }
    if (setorId != null) {
      where.add('setorId = ?');
      args.add(setorId);
    }
    if (tipoId != null) {
      where.add('tipoId = ?');
      args.add(tipoId);
    }
    if (statusEstoque != null) {
      where.add('statusEstoque = ?');
      args.add(statusEstoque);
    }

    final rows = await db.query(
      'etiquetas',
      where: where.join(' AND '),
      whereArgs: args,
      orderBy: 'createdAt DESC',
    );

    return rows.map(EtiquetaLocalMapper.fromLocalMap).toList();
  }

  // Future<void> debugPrintEtiquetas(String uid) async {
  //   final db = await AppDb.instance.db;

  //   final rows = await db.query(
  //     'etiquetas',
  //     where: 'uid = ?',
  //     whereArgs: [uid],
  //     orderBy: 'createdAt DESC',
  //   );

  //   print('====== ETIQUETAS ======');
  //   print('Total: ${rows.length}');

  //   for (final row in rows) {
  //     print('-------------------------------');
  //     row.forEach((key, value) {
  //       print('$key: $value');
  //     });
  //   }

  //   print('======================================');
  // }

  Future<List<Map<String, Object?>>> countPorCategoria({
    required String uid,
    required DateTime inicio,
    required DateTime fim,
    String? status,
  }) async {
    final db = await AppDb.instance.db;

    final where = <String>['uid = ?', 'createdAt >= ?', 'createdAt <= ?'];
    final args = <Object>[
      uid,
      inicio.millisecondsSinceEpoch,
      fim.millisecondsSinceEpoch,
    ];
    if (status != null) { where.add('status = ?'); args.add(status); }

    return db.rawQuery('''
      SELECT categoriaId, categoriaNome, COUNT(*) as total
      FROM etiquetas
      WHERE ${where.join(' AND ')}
      GROUP BY categoriaId, categoriaNome
      ORDER BY total DESC
    ''', args);
  }

  Future<List<Map<String, Object?>>> countPorSetor({
    required String uid,
    required DateTime inicio,
    required DateTime fim,
    String? status,
  }) async {
    final db = await AppDb.instance.db;

    final where = <String>['uid = ?', 'createdAt >= ?', 'createdAt <= ?'];
    final args = <Object>[
      uid,
      inicio.millisecondsSinceEpoch,
      fim.millisecondsSinceEpoch,
    ];
    if (status != null) { where.add('status = ?'); args.add(status); }

    return db.rawQuery('''
      SELECT setorId, setorNome, COUNT(*) as total
      FROM etiquetas
      WHERE ${where.join(' AND ')}
      GROUP BY setorId, setorNome
      ORDER BY total DESC
    ''', args);
  }

  Future<int> countVencidasAtivas({
    required String uid,
    required DateTime hoje,
  }) async {
    final db = await AppDb.instance.db;
    final hojeStart = DateTime(hoje.year, hoje.month, hoje.day).millisecondsSinceEpoch;

    final r = await db.rawQuery('''
      SELECT COUNT(*) as total
      FROM etiquetas
      WHERE uid = ?
        AND status = 'ativa'
        AND dataValidadeMs < ?
    ''', [uid, hojeStart]);

    return (r.first['total'] as int?) ?? 0;
  }

  Future<EtiquetaModel?> getById({required String uid, required String id}) async {
    final db = await AppDb.instance.db;
    final rows = await db.query(
      'etiquetas',
      where: 'uid = ? AND id = ?',
      whereArgs: [uid, id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return EtiquetaLocalMapper.fromLocalMap(rows.first);
  }

  Future<void> vender({
    required String uid,
    required String etiquetaId,
    required num quantidadeVendida,
  }) async {
    final db = await AppDb.instance.db;
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    if (quantidadeVendida <= 0) {
      throw Exception("Informe uma quantidade > 0.");
    }

    final current = await getById(uid: uid, id: etiquetaId);
    if (current == null) throw Exception("Etiqueta não encontrada.");

    if (current.status != "ativa") {
      throw Exception("Etiqueta não está ativa.");
    }

    if (current.statusEstoque == "vendido" || current.statusEstoque == "cancelado") {
      throw Exception("Esta etiqueta já foi finalizada (${current.statusEstoque}).");
    }

    final restanteAtual = current.quantidadeRestante;
    final novoRestante = restanteAtual - quantidadeVendida;

    if (novoRestante < 0) {
      throw Exception("Venda maior que o restante em estoque.");
    }

    final novoStatusEstoque = (novoRestante <= 0) ? "vendido" : "ativo";
    final soldAt = (novoStatusEstoque == "vendido")
        ? (current.soldAt ?? DateTime.fromMillisecondsSinceEpoch(nowMs))
        : null;

    final updated = EtiquetaModel(
      id: current.id,
      tipoId: current.tipoId,
      tipoNome: current.tipoNome,
      produtoNome: current.produtoNome,
      categoriaId: current.categoriaId,
      categoriaNome: current.categoriaNome,
      setorId: current.setorId,
      setorNome: current.setorNome,
      dataFabricacao: current.dataFabricacao,
      dataValidade: current.dataValidade,
      camposCustomValores: current.camposCustomValores,
      status: current.status,
      lote: current.lote,
      createdAt: current.createdAt,
      quantidade: current.quantidade,
      quantidadeRestante: novoRestante,
      statusEstoque: novoStatusEstoque,
      soldAt: soldAt,
    );

    await db.transaction((txn) async {
      await txn.insert(
        'etiquetas',
        updated.toLocalMap(uid: uid, nowMs: nowMs),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      final payload = <String, dynamic>{
        "tipoId": updated.tipoId,
        "tipoNome": updated.tipoNome,
        "produtoNome": updated.produtoNome,
        "categoriaId": updated.categoriaId,
        "categoriaNome": updated.categoriaNome,
        "setorId": updated.setorId,
        "setorNome": updated.setorNome,
        "dataFabricacaoMs": updated.dataFabricacao.millisecondsSinceEpoch,
        "dataValidadeMs": updated.dataValidade.millisecondsSinceEpoch,
        "camposCustomValores": updated.camposCustomValores,
        "status": updated.status,       
        "quantidade": updated.quantidade,
        "quantidadeRestante": updated.quantidadeRestante,
        "statusEstoque": updated.statusEstoque,
        "soldAtMs": updated.soldAt?.millisecondsSinceEpoch,
        "lote": updated.lote ?? (updated.camposCustomValores["lote"]?["value"]?.toString()),
        "createdAtMs": (updated.createdAt?.millisecondsSinceEpoch ?? nowMs),
        "updatedAtMs": nowMs,
      };

      await OutboxHelper.enqueueUpsert(
        txn: txn,
        uid: uid,
        entity: "etiquetas",
        entityId: updated.id,
        payload: payload,
        nowMs: nowMs,
      );
    });
  }

  Future<void> ajustarQuantidade({
    required String uid,
    required String etiquetaId,
    required num novoRestante,
  }) async {
    final db = await AppDb.instance.db;
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    if (novoRestante < 0) throw Exception("Restante não pode ser negativo.");

    final current = await getById(uid: uid, id: etiquetaId);
    if (current == null) throw Exception("Etiqueta não encontrada.");

    if (current.status != "ativa") {
      throw Exception("Etiqueta não está ativa.");
    }

    
    if (current.statusEstoque == "cancelado") {
      throw Exception("Etiqueta cancelada não pode ser ajustada.");
    }

    final statusEstoque = (novoRestante <= 0) ? "vendido" : "ativo";
    final soldAt = (statusEstoque == "vendido")
        ? (current.soldAt ?? DateTime.fromMillisecondsSinceEpoch(nowMs))
        : null;

    final updated = EtiquetaModel(
      id: current.id,
      tipoId: current.tipoId,
      tipoNome: current.tipoNome,
      produtoNome: current.produtoNome,
      categoriaId: current.categoriaId,
      categoriaNome: current.categoriaNome,
      setorId: current.setorId,
      setorNome: current.setorNome,
      dataFabricacao: current.dataFabricacao,
      dataValidade: current.dataValidade,
      camposCustomValores: current.camposCustomValores,
      status: current.status,
      lote: current.lote,
      createdAt: current.createdAt,
      quantidade: current.quantidade,
      quantidadeRestante: novoRestante,
      statusEstoque: statusEstoque,
      soldAt: soldAt,
    );

    await db.transaction((txn) async {
      await txn.insert(
        'etiquetas',
        updated.toLocalMap(uid: uid, nowMs: nowMs),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      final payload = <String, dynamic>{
        "tipoId": updated.tipoId,
        "tipoNome": updated.tipoNome,
        "produtoNome": updated.produtoNome,
        "categoriaId": updated.categoriaId,
        "categoriaNome": updated.categoriaNome,
        "setorId": updated.setorId,
        "setorNome": updated.setorNome,
        "dataFabricacaoMs": updated.dataFabricacao.millisecondsSinceEpoch,
        "dataValidadeMs": updated.dataValidade.millisecondsSinceEpoch,
        "camposCustomValores": updated.camposCustomValores,
        "status": updated.status,
        "quantidade": updated.quantidade,
        "quantidadeRestante": updated.quantidadeRestante,
        "statusEstoque": updated.statusEstoque,
        "soldAtMs": updated.soldAt?.millisecondsSinceEpoch,
        "lote": updated.lote ?? (updated.camposCustomValores["lote"]?["value"]?.toString()),
        "createdAtMs": (updated.createdAt?.millisecondsSinceEpoch ?? nowMs),
        "updatedAtMs": nowMs,
      };

      await OutboxHelper.enqueueUpsert(
        txn: txn,
        uid: uid,
        entity: "etiquetas",
        entityId: updated.id,
        payload: payload,
        nowMs: nowMs,
      );
    });
  }
}