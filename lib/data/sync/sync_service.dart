import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sqflite/sqflite.dart';
import '../local/app_db.dart';

class SyncService {
  final FirebaseFirestore db;
  SyncService(this.db);

  CollectionReference<Map<String, dynamic>> _col(String uid, String entity) {

    return db.collection("usuarios").doc(uid).collection(entity);
  }


  Future<void> pushOutbox(String uid, {int limit = 50}) async {
    final Database local = await AppDb.instance.db;

    final rows = await local.query(
      'outbox',
      where: 'uid = ?',
      whereArgs: [uid],
      orderBy: 'createdAt ASC',
      limit: limit,
    );

    for (final r in rows) {
      final outboxId = r['id'] as int;
      final entity = (r['entity'] ?? '').toString();
      final entityId = (r['entityId'] ?? '').toString();
      final op = (r['op'] ?? '').toString();
      final payloadJson = r['payloadJson']?.toString();

      try {
        if (op == "DELETE") {
          await _col(uid, entity).doc(entityId).delete();
        } else {
          final payload = payloadJson == null ? <String, dynamic>{} : jsonDecode(payloadJson);
          final map = Map<String, dynamic>.from(payload as Map);

     
          if (map.containsKey("createdAtMs")) {
            map["createdAt"] = Timestamp.fromMillisecondsSinceEpoch(map["createdAtMs"]);
            map.remove("createdAtMs");
          }
          if (map.containsKey("updatedAtMs")) {
            map["updatedAt"] = Timestamp.fromMillisecondsSinceEpoch(map["updatedAtMs"]);
            map.remove("updatedAtMs");
          } else {
            map["updatedAt"] = FieldValue.serverTimestamp();
          }
          if (entity == "etiquetas") {
            if (map.containsKey("dataFabricacaoMs")) {
              map["dataFabricacao"] = Timestamp.fromMillisecondsSinceEpoch(map["dataFabricacaoMs"]);
              map.remove("dataFabricacaoMs");
            }
            if (map.containsKey("dataValidadeMs")) {
              map["dataValidade"] = Timestamp.fromMillisecondsSinceEpoch(map["dataValidadeMs"]);
              map.remove("dataValidadeMs");
            }
          }

          await _col(uid, entity).doc(entityId).set(map, SetOptions(merge: true));
        }

        await local.delete('outbox', where: 'id = ?', whereArgs: [outboxId]);
      } catch (e) {
      
        await local.update(
          'outbox',
          {
            'tries': (r['tries'] as int? ?? 0) + 1,
            'lastError': e.toString(),
          },
          where: 'id = ?',
          whereArgs: [outboxId],
        );
       
      }
    }
  }

 
  Future<void> pullAll(String uid) async {
    await _pullCollection(uid, "categorias", table: "categorias", mapToLocal: (doc) {
      final d = doc.data();
      return {
        "id": doc.id,
        "uid": uid,
        "nome": (d["nome"] ?? "").toString(),
        "diasVencimento": (d["diasVencimento"] ?? 0) as int,
        "ativo": (d["ativo"] ?? true) ? 1 : 0,
        "createdAt": (d["createdAt"] as Timestamp?)?.millisecondsSinceEpoch,
        "updatedAt": (d["updatedAt"] as Timestamp?)?.millisecondsSinceEpoch,
      };
    });

    await _pullCollection(uid, "setores", table: "setores", mapToLocal: (doc) {
      final d = doc.data();
      return {
        "id": doc.id,
        "uid": uid,
        "nome": (d["nome"] ?? "").toString(),
        "descricao": d["descricao"]?.toString(),
        "ativo": (d["ativo"] ?? true) ? 1 : 0,
        "createdAt": (d["createdAt"] as Timestamp?)?.millisecondsSinceEpoch,
        "updatedAt": (d["updatedAt"] as Timestamp?)?.millisecondsSinceEpoch,
      };
    });

    await _pullCollection(uid, "tipos_etiqueta", table: "tipos_etiqueta", mapToLocal: (doc) {
      final d = doc.data();
      final campos = (d["camposCustom"] as List? ?? []);
      return {
        "id": doc.id,
        "uid": uid,
        "nome": (d["nome"] ?? "").toString(),
        "descricao": d["descricao"]?.toString(),
        "usarRegraValidadeCategoria": (d["usarRegraValidadeCategoria"] ?? true) ? 1 : 0,
        "camposCustomJson": jsonEncode(campos),
        "createdAt": (d["createdAt"] as Timestamp?)?.millisecondsSinceEpoch,
        "updatedAt": (d["updatedAt"] as Timestamp?)?.millisecondsSinceEpoch,
      };
    });

    await _pullCollection(uid, "etiquetas", table: "etiquetas", mapToLocal: (doc) {
      final d = doc.data();
      return {
        "id": doc.id,
        "uid": uid,
        "tipoId": (d["tipoId"] ?? "").toString(),
        "tipoNome": (d["tipoNome"] ?? "").toString(),
        "produtoNome": (d["produtoNome"] ?? "").toString(),
        "categoriaId": (d["categoriaId"] ?? "").toString(),
        "categoriaNome": (d["categoriaNome"] ?? "").toString(),
        "setorId": (d["setorId"] ?? "").toString(),
        "setorNome": (d["setorNome"] ?? "").toString(),
        "dataFabricacaoMs": (d["dataFabricacao"] as Timestamp).millisecondsSinceEpoch,
        "dataValidadeMs": (d["dataValidade"] as Timestamp).millisecondsSinceEpoch,
        "camposCustomValoresJson": jsonEncode(d["camposCustomValores"] ?? {}),
        "status": (d["status"] ?? "ativa").toString(),
        "createdAt": (d["createdAt"] as Timestamp?)?.millisecondsSinceEpoch,
        "updatedAt": (d["updatedAt"] as Timestamp?)?.millisecondsSinceEpoch,
      };
    });
  }

  Future<void> _pullCollection(
    String uid,
    String entity,
    {required String table,
    required Map<String, dynamic> Function(QueryDocumentSnapshot<Map<String, dynamic>> doc) mapToLocal}
  ) async {
    final Database local = await AppDb.instance.db;

    final snap = await _col(uid, entity).get();

    await local.transaction((txn) async {
      for (final doc in snap.docs) {
        final row = mapToLocal(doc);

        await txn.insert(
          table,
          row,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }


  Future<void> syncNow(String uid) async {

    await pullAll(uid);

    await pushOutbox(uid, limit: 200);
  }
}