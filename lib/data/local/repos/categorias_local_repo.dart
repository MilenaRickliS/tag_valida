import 'package:sqflite/sqflite.dart';

import '../app_db.dart';
import '../mappers/categoria_local.dart';
import '../../../models/categoria_model.dart';

class CategoriasLocalRepo {
  Future<List<CategoriaModel>> listActive(String uid) async {
    final db = await AppDb.instance.db;

    final rows = await db.query(
      'categorias',
      where: 'uid = ? AND ativo = 1',
      whereArgs: [uid],
      orderBy: 'nome COLLATE NOCASE ASC',
    );

    return rows.map(CategoriaLocalMapper.fromLocalMap).toList();
  }

  Future<void> upsert(String uid, CategoriaModel cat) async {
    final db = await AppDb.instance.db;
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    await db.insert(
      'categorias',
      cat.toLocalMap(uid: uid, nowMs: nowMs),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> softDelete(String uid, String id) async {
    final db = await AppDb.instance.db;
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    await db.update(
      'categorias',
      {'ativo': 0, 'updatedAt': nowMs},
      where: 'uid = ? AND id = ?',
      whereArgs: [uid, id],
    );
  }
}