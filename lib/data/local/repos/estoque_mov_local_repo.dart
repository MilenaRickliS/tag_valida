import 'package:sqflite/sqflite.dart';
import '../app_db.dart';
import '../mappers/estoque_mov_local.dart';
import '../../../models/estoque_mov_model.dart';
import '../../../models/estoque_mov_resumo.dart';
import '../outbox/outbox_helper.dart'; 

class EstoqueMovLocalRepo {
  Future<void> insert(String uid, EstoqueMovModel mov) async {
    final db = await AppDb.instance.db;
    await db.insert(
      "estoque_mov",
      mov.toLocalMap(uid: uid),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> insertAndEnqueue(String uid, EstoqueMovModel mov) async {
    final db = await AppDb.instance.db;
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    await db.transaction((txn) async {
  
      await txn.insert(
        "estoque_mov",
        mov.toLocalMap(uid: uid),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

     
      final payload = mov.toLocalMap(uid: uid);


      payload["createdAtMs"] = mov.createdAt.millisecondsSinceEpoch;
      payload["updatedAtMs"] = mov.updatedAt.millisecondsSinceEpoch;

      await OutboxHelper.enqueueUpsert(
        txn: txn,
        uid: uid,
        entity: "estoque_mov",
        entityId: mov.id,
        payload: payload,
        nowMs: nowMs,
      );
    });
  }

  Future<List<EstoqueMovModel>> listAll({required String uid, int limit = 500}) async {
    final db = await AppDb.instance.db;
    final rows = await db.query(
      "estoque_mov",
      where: "uid = ?",
      whereArgs: [uid],
      orderBy: "createdAt DESC",
      limit: limit,
    );
    return rows.map(EstoqueMovLocalMapper.fromLocalMap).toList();
  }

  Future<EstoqueMovResumo> resumo({required String uid}) async {
    final db = await AppDb.instance.db;

  
    Future<num> sumTipo(String tipo) async {
      final r = await db.rawQuery(
        "SELECT COALESCE(SUM(quantidade), 0) AS s FROM estoque_mov WHERE uid = ? AND tipo = ?",
        [uid, tipo],
      );
      return (r.first["s"] as num?) ?? 0;
    }

    final entradas = await sumTipo(EstoqueMovModel.tipoEntrada)
        + await sumTipo(EstoqueMovModel.tipoAjusteEntrada);

    final saidasVenda = await sumTipo(EstoqueMovModel.tipoVenda);
    final saidasCancelamento = await sumTipo(EstoqueMovModel.tipoCancelamento)
        + await sumTipo(EstoqueMovModel.tipoAjusteSaida);

    final saldo = entradas - (saidasVenda + saidasCancelamento);

    return EstoqueMovResumo(
      entradas: entradas,
      saidasVenda: saidasVenda,
      saidasCancelamento: saidasCancelamento,
      saldo: saldo,
    );
  }
}