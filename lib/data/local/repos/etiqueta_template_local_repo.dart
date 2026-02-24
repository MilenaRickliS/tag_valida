import 'package:sqflite/sqflite.dart';
import '../app_db.dart';
import '../outbox/outbox_helper.dart';
import '../mappers/etiqueta_template_local.dart';
import '../../../models/etiqueta_template_model.dart';

class EtiquetasTemplatesLocalRepo {
  String _norm(String s) => s.toLowerCase().replaceAll(RegExp(r"\s+"), " ").trim();

  Future<bool> existsSameKey({
    required String uid,
    required String produtoNome,
    required String categoriaId,
    required String setorId,
  }) async {
    final db = await AppDb.instance.db;

    final rows = await db.query(
      "etiquetas_templates",
      columns: ["produtoNome"],
      where: "uid = ? AND categoriaId = ? AND setorId = ?",
      whereArgs: [uid, categoriaId, setorId],
    );

    final alvo = _norm(produtoNome);
    for (final r in rows) {
      final nomeRow = (r["produtoNome"] ?? "").toString();
      if (_norm(nomeRow) == alvo) return true;
    }
    return false;
  }

  Future<void> upsert(String uid, EtiquetaTemplateModel t) async {
    final db = await AppDb.instance.db;
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    await db.transaction((txn) async {
      await txn.insert(
        "etiquetas_templates",
        t.toLocalMap(uid: uid, nowMs: nowMs),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      final payload = <String, dynamic>{
        "tipoId": t.tipoId,
        "tipoNome": t.tipoNome,
        "produtoNome": t.produtoNome,
        "categoriaId": t.categoriaId,
        "categoriaNome": t.categoriaNome,
        "setorId": t.setorId,
        "setorNome": t.setorNome,
        "camposCustomValores": t.camposCustomValores,
        "quantidadePadrao": t.quantidadePadrao,
        "createdAtMs": (t.createdAt?.millisecondsSinceEpoch ?? nowMs),
        "updatedAtMs": nowMs,
      };

      await OutboxHelper.enqueueUpsert(
        txn: txn,
        uid: uid,
        entity: "etiquetas_templates",
        entityId: t.id,
        payload: payload,
        nowMs: nowMs,
      );
    });
  }

  Future<List<EtiquetaTemplateModel>> listAll({required String uid}) async {
    final db = await AppDb.instance.db;
    final rows = await db.query(
      "etiquetas_templates",
      where: "uid = ?",
      whereArgs: [uid],
      orderBy: "updatedAt DESC",
    );
    return rows.map(EtiquetaTemplateLocalMapper.fromLocalMap).toList();
  }

  Future<EtiquetaTemplateModel?> getById({required String uid, required String id}) async {
    final db = await AppDb.instance.db;
    final rows = await db.query(
      "etiquetas_templates",
      where: "uid = ? AND id = ?",
      whereArgs: [uid, id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return EtiquetaTemplateLocalMapper.fromLocalMap(rows.first);
  }

  Future<EtiquetaTemplateModel?> findByKey({
    required String uid,
    required String produtoNome,
    required String categoriaId,
    required String setorId,
  }) async {
    final db = await AppDb.instance.db;

    final rows = await db.query(
      "etiquetas_templates",
      where: "uid = ? AND categoriaId = ? AND setorId = ?",
      whereArgs: [uid, categoriaId, setorId],
      orderBy: "updatedAt DESC",
      limit: 200, 
    );

    final alvo = _norm(produtoNome);

    for (final r in rows) {
      final nomeRow = (r["produtoNome"] ?? "").toString();
      if (_norm(nomeRow) == alvo) {
        return EtiquetaTemplateLocalMapper.fromLocalMap(r);
      }
    }
    return null;
  }

  Future<void> delete({required String uid, required String id}) async {
    final db = await AppDb.instance.db;
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    await db.transaction((txn) async {
      await txn.delete(
        "etiquetas_templates",
        where: "uid = ? AND id = ?",
        whereArgs: [uid, id],
      );

      await OutboxHelper.enqueueDelete(
        txn: txn,
        uid: uid,
        entity: "etiquetas_templates",
        entityId: id,
        nowMs: nowMs,
      );
    });
  }
}