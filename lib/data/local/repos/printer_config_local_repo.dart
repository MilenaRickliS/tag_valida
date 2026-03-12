import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../app_db.dart';
import '../outbox/outbox_helper.dart';
import '../../../models/printer_config_model.dart';
import '../mappers/printer_config_mapper.dart';

class PrinterConfigLocalRepo {
  final _uuid = const Uuid();

  Future<Database> get _db async => AppDb.instance.db;

  Future<List<PrinterConfigModel>> getAll({required String uid}) async {
    final db = await _db;

    final rows = await db.query(
      'printer_configs',
      where: 'uid = ?',
      whereArgs: [uid],
      orderBy: 'padrao DESC, updatedAt DESC',
    );

    return rows.map(PrinterConfigMapper.fromLocal).toList();
  }

  Future<PrinterConfigModel?> getDefault({required String uid}) async {
    final db = await _db;

    final rows = await db.query(
      'printer_configs',
      where: 'uid = ? AND ativo = 1',
      whereArgs: [uid],
      orderBy: 'padrao DESC, updatedAt DESC',
      limit: 1,
    );

    if (rows.isEmpty) return null;
    return PrinterConfigMapper.fromLocal(rows.first);
  }

  Future<PrinterConfigModel?> getById({
    required String uid,
    required String id,
  }) async {
    final db = await _db;

    final rows = await db.query(
      'printer_configs',
      where: 'uid = ? AND id = ?',
      whereArgs: [uid, id],
      limit: 1,
    );

    if (rows.isEmpty) return null;
    return PrinterConfigMapper.fromLocal(rows.first);
  }

  Future<PrinterConfigModel> save({
    required PrinterConfigModel model,
  }) async {
    final db = await _db;
    final now = DateTime.now();

    final toSave = model.id.trim().isEmpty
        ? model.copyWith(
            id: _uuid.v4(),
            createdAt: now,
            updatedAt: now,
          )
        : model.copyWith(updatedAt: now);

    await db.transaction((txn) async {
      await txn.insert(
        'printer_configs',
        PrinterConfigMapper.toLocal(toSave),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      if (toSave.padrao) {
        final nowMs = now.millisecondsSinceEpoch;

        await txn.update(
          'printer_configs',
          {
            'padrao': 0,
            'updatedAt': nowMs,
          },
          where: 'uid = ? AND id != ?',
          whereArgs: [toSave.uid, toSave.id],
        );

        await txn.update(
          'printer_configs',
          {
            'padrao': 1,
            'updatedAt': nowMs,
          },
          where: 'uid = ? AND id = ?',
          whereArgs: [toSave.uid, toSave.id],
        );
      }

      await OutboxHelper.enqueueUpsert(
        txn: txn,
        uid: toSave.uid,
        entity: 'printer_configs',
        entityId: toSave.id,
        payload: PrinterConfigMapper.toFirestore(toSave),
        nowMs: now.millisecondsSinceEpoch,
      );
    });

    return toSave;
  }

  Future<void> delete({
    required String uid,
    required String id,
  }) async {
    final db = await _db;
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    await db.transaction((txn) async {
      await txn.delete(
        'printer_configs',
        where: 'uid = ? AND id = ?',
        whereArgs: [uid, id],
      );

      await OutboxHelper.enqueueDelete(
        txn: txn,
        uid: uid,
        entity: 'printer_configs',
        entityId: id,
        nowMs: nowMs,
      );
    });
  }

  Future<void> setAsDefault({
      required String uid,
      required String id,
    }) async {
      final db = await _db;
      final nowMs = DateTime.now().millisecondsSinceEpoch;

      await db.transaction((txn) async {
        await txn.update(
          'printer_configs',
          {
            'padrao': 0,
            'updatedAt': nowMs,
          },
          where: 'uid = ?',
          whereArgs: [uid],
        );

        await txn.update(
          'printer_configs',
          {
            'padrao': 1,
            'updatedAt': nowMs,
          },
          where: 'uid = ? AND id = ?',
          whereArgs: [uid, id],
        );

        final rows = await txn.query(
          'printer_configs',
          where: 'uid = ? AND id = ?',
          whereArgs: [uid, id],
          limit: 1,
        );

        if (rows.isNotEmpty) {
          final row = Map<String, dynamic>.from(rows.first);

          await OutboxHelper.enqueueUpsert(
            txn: txn,
            uid: uid,
            entity: 'printer_configs',
            entityId: id,
            payload: {
              'id': row['id'],
              'uid': row['uid'],
              'nome': row['nome'],
              'modelo': row['modelo'],
              'tipoConexao': row['tipoConexao'],
              'ip': row['ip'],
              'porta': row['porta'],
              'tamanhoEtiqueta': row['tamanhoEtiqueta'],
              'ativo': (row['ativo'] ?? 1) == 1,
              'padrao': true,
              'createdAtMs': row['createdAt'],
              'updatedAtMs': nowMs,
            },
            nowMs: nowMs,
          );
        }
      });
    }

    Future<void> upsertDefaultElgin({
      required String uid,
      required String ip,
      int porta = 9100,
    }) async {
      final existing = await getDefault(uid: uid);
      final now = DateTime.now();

      final model = (existing ?? PrinterConfigModel.empty(uid)).copyWith(
        nome: 'Impressora principal',
        modelo: 'Elgin L42 Pro',
        tipoConexao: 'network',
        ip: ip,
        porta: porta,
        tamanhoEtiqueta: '60x40',
        ativo: true,
        padrao: true,
        createdAt: existing?.createdAt ?? now,
        updatedAt: now,
      );

      await save(model: model);
    }
}