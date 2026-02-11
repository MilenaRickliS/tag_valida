import 'package:sqflite/sqflite.dart';

import '../app_db.dart';
import '../outbox/outbox_helper.dart';
import '../mappers/setor_local.dart';
import '../../../models/setor_model.dart';

class SetoresLocalRepo {
  Future<List<SetorModel>> listActive(String uid) async {
    final db = await AppDb.instance.db;

    final rows = await db.query(
      'setores',
      where: 'uid = ? AND ativo = 1',
      whereArgs: [uid],
      orderBy: 'nome COLLATE NOCASE ASC',
    );

    return rows.map(SetorLocalMapper.fromLocalMap).toList();
  }

  Future<void> upsert(String uid, SetorModel setor) async {
    final db = await AppDb.instance.db;
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    await db.transaction((txn) async {
      await txn.insert(
        'setores',
        setor.toLocalMap(uid: uid, nowMs: nowMs),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      final payload = {
        "nome": setor.nome,
        "descricao": setor.descricao,
        "ativo": setor.ativo,
        "createdAtMs": (setor.createdAt?.millisecondsSinceEpoch ?? nowMs),
        "updatedAtMs": nowMs,
      };

      await OutboxHelper.enqueueUpsert(
        txn: txn,
        uid: uid,
        entity: "setores",
        entityId: setor.id,
        payload: payload,
        nowMs: nowMs,
      );
    });
  }


  Future<void> softDelete(String uid, String id) async {
    final db = await AppDb.instance.db;
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    await db.transaction((txn) async {
      await txn.update(
        'setores',
        {'ativo': 0, 'updatedAt': nowMs},
        where: 'uid = ? AND id = ?',
        whereArgs: [uid, id],
      );

      await OutboxHelper.enqueueUpsert(
        txn: txn,
        uid: uid,
        entity: "setores",
        entityId: id,
        payload: {
          "ativo": false,
          "updatedAtMs": nowMs,
        },
        nowMs: nowMs,
      );
    });
  }
}