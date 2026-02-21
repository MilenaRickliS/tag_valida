import 'package:sqflite/sqflite.dart';
import '../app_db.dart';
import '../outbox/outbox_helper.dart';
import '../mappers/tipo_etiqueta_local.dart';
import '../../../models/tipo_etiqueta_model.dart';

class TiposEtiquetaLocalRepo {
  Future<List<TipoEtiquetaModel>> listAll(String uid) async {
    final db = await AppDb.instance.db;
    final rows = await db.query(
      'tipos_etiqueta',
      where: 'uid = ?',
      whereArgs: [uid],
      orderBy: 'nome COLLATE NOCASE ASC',
    );
    return rows.map(TipoEtiquetaLocalMapper.fromLocalMap).toList();
  }

  Future<void> upsert(String uid, TipoEtiquetaModel tipo) async {
    final db = await AppDb.instance.db;
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    await db.transaction((txn) async {
      await txn.insert(
        'tipos_etiqueta',
        tipo.toLocalMap(uid: uid, nowMs: nowMs),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      final payload = {
        "nome": tipo.nome,
        "descricao": tipo.descricao,
        "usarRegraValidadeCategoria": tipo.usarRegraValidadeCategoria,
        "controlaLote": tipo.controlaLote,
        "camposCustom": tipo.camposCustom.map((c) => c.toMap()).toList(),
        "createdAtMs": nowMs,
        "updatedAtMs": nowMs,
      };

      await OutboxHelper.enqueueUpsert(
        txn: txn,
        uid: uid,
        entity: "tipos_etiqueta",
        entityId: tipo.id,
        payload: payload,
        nowMs: nowMs,
      );
    });
  }


  Future<void> delete(String uid, String id, {bool enqueueFirestoreDelete = true}) async {
    final db = await AppDb.instance.db;
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    await db.transaction((txn) async {
      await txn.delete(
        'tipos_etiqueta',
        where: 'uid = ? AND id = ?',
        whereArgs: [uid, id],
      );

      if (enqueueFirestoreDelete) {
        await OutboxHelper.enqueueDelete(
          txn: txn,
          uid: uid,
          entity: "tipos_etiqueta",
          entityId: id,
          nowMs: nowMs,
        );
      }
    });
  }
}