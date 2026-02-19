import 'package:sqflite/sqflite.dart';
import '../app_db.dart';
import '../mappers/etiqueta_template_local.dart';
import '../../../models/etiqueta_template_model.dart';

class EtiquetasTemplatesLocalRepo {
  Future<void> upsert(String uid, EtiquetaTemplateModel t) async {
    final db = await AppDb.instance.db;
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    await db.insert(
      "etiquetas_templates",
      t.toLocalMap(uid: uid, nowMs: nowMs),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
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

  Future<void> delete({required String uid, required String id}) async {
    final db = await AppDb.instance.db;
    await db.delete(
      "etiquetas_templates",
      where: "uid = ? AND id = ?",
      whereArgs: [uid, id],
    );
  }
}