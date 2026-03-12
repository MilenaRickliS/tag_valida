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
          if (entity == "categorias" || entity == "setores") {
            if (map.containsKey("ativo")) {
              final v = map["ativo"];
              if (v is bool) {
               
              } else if (v is int) {
                map["ativo"] = v == 1;
              } else if (v is num) {
                map["ativo"] = v.toInt() == 1;
              } else if (v is String) {
                map["ativo"] = (v.toLowerCase().trim() == "true" || v == "1");
              }
            }
          }
         if (entity == "tipos_etiqueta") {
          
            if (map["camposCustom"] is String) {
              final str = (map["camposCustom"] ?? "[]").toString();
              try {
                map["camposCustom"] = jsonDecode(str);
              } catch (_) {
                map["camposCustom"] = [];
              }
            }

    
            if (map.containsKey("controlaLote")) {
              final v = map["controlaLote"];
              if (v is int) map["controlaLote"] = v == 1;
              if (v is num) map["controlaLote"] = v.toInt() == 1;
            }
            if (map.containsKey("usarRegraValidadeCategoria")) {
              final v = map["usarRegraValidadeCategoria"];
              if (v is int) map["usarRegraValidadeCategoria"] = v == 1;
              if (v is num) map["usarRegraValidadeCategoria"] = v.toInt() == 1;
            }
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

       
            if (map.containsKey("camposCustomValores")) {
                final v = map["camposCustomValores"];
                if (v is String) {
                  try {
                    map["camposCustomValores"] = jsonDecode(v);
                  } catch (_) {
                    map["camposCustomValores"] = {};
                  }
                }
              }

            if (map.containsKey("soldAtMs")) {
              final v = map["soldAtMs"];
              if (v == null) {
                map["soldAt"] = null;
              } else if (v is int) {
                map["soldAt"] = Timestamp.fromMillisecondsSinceEpoch(v);
              } else if (v is num) {
                map["soldAt"] = Timestamp.fromMillisecondsSinceEpoch(v.toInt());
              }
              map.remove("soldAtMs");
            }
          }

          if (entity == "etiquetas_templates") {
            final v = map["camposCustomValores"];
            if (v is String) {
              try { map["camposCustomValores"] = jsonDecode(v); }
              catch (_) { map["camposCustomValores"] = {}; }
            } else if (v is Map) {
              map["camposCustomValores"] = Map<String, dynamic>.from(v);
            } else {
              map["camposCustomValores"] = {};
            }
          }
          if (entity == "printer_configs") {
            if (map.containsKey("ativo")) {
              final v = map["ativo"];
              if (v is int) map["ativo"] = v == 1;
              if (v is num) map["ativo"] = v.toInt() == 1;
              if (v is String) {
                map["ativo"] = (v.toLowerCase().trim() == "true" || v == "1");
              }
            }

            if (map.containsKey("padrao")) {
              final v = map["padrao"];
              if (v is int) map["padrao"] = v == 1;
              if (v is num) map["padrao"] = v.toInt() == 1;
              if (v is String) {
                map["padrao"] = (v.toLowerCase().trim() == "true" || v == "1");
              }
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

  dynamic _jsonSafe(dynamic v) {
    if (v == null) return null;
    if (v is Timestamp) return v.millisecondsSinceEpoch;
    if (v is DateTime) return v.millisecondsSinceEpoch;
    if (v is Map) return v.map((k, val) => MapEntry(k.toString(), _jsonSafe(val)));
    if (v is List) return v.map(_jsonSafe).toList();
    return v;
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
        "controlaLote": (d["controlaLote"] ?? false) ? 1 : 0,
        "camposCustomJson": jsonEncode(campos),
        "createdAt": (d["createdAt"] as Timestamp?)?.millisecondsSinceEpoch,
        "updatedAt": (d["updatedAt"] as Timestamp?)?.millisecondsSinceEpoch,
      };
    });

    await _pullCollection(uid, "etiquetas", table: "etiquetas", mapToLocal: (doc) {
      final d = doc.data();

      Timestamp? ts(dynamic v) => v is Timestamp ? v : null;
      final safeCampos = _jsonSafe(d["camposCustomValores"] ?? {});

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

        "dataFabricacaoMs": ts(d["dataFabricacao"])?.millisecondsSinceEpoch ?? 0,
        "dataValidadeMs": ts(d["dataValidade"])?.millisecondsSinceEpoch ?? 0,

        "quantidade": (d["quantidade"] as num?) ?? 1,
        "quantidadeRestante": (d["quantidadeRestante"] as num?) ?? (d["quantidade"] as num?) ?? 1,
        "statusEstoque": (d["statusEstoque"] ?? "ativo").toString(),
        "soldAtMs": ts(d["soldAt"])?.millisecondsSinceEpoch,

        "lote": d["lote"]?.toString(),

       
        "camposCustomValoresJson": jsonEncode(safeCampos),

        "status": (d["status"] ?? "ativa").toString(),

        "createdAt": ts(d["createdAt"])?.millisecondsSinceEpoch,
        "updatedAt": ts(d["updatedAt"])?.millisecondsSinceEpoch,
      };
    });

    await _pullCollection(uid, "estoque_mov", table: "estoque_mov", mapToLocal: (doc) {
      final d = doc.data();

      int? ms(dynamic v) {
        if (v is Timestamp) return v.millisecondsSinceEpoch;
        if (v is int) return v;
        if (v is num) return v.toInt();
        return null;
      }

      return {
        "id": doc.id,
        "uid": uid,
        "etiquetaId": (d["etiquetaId"] ?? "").toString(),
        "tipo": (d["tipo"] ?? "").toString(),
        "quantidade": (d["quantidade"] as num?) ?? 0,
        "motivo": d["motivo"]?.toString(),
        "produtoNome": d["produtoNome"]?.toString(),
        "createdAt": ms(d["createdAt"]) ?? ms(d["createdAtMs"]) ?? 0,
        "updatedAt": ms(d["updatedAt"]) ?? ms(d["updatedAtMs"]) ?? 0,
      };
    });

    await _pullCollection(uid, "etiquetas_templates", table: "etiquetas_templates", mapToLocal: (doc) {
      final d = doc.data();

      int? ms(dynamic v) {
        if (v is Timestamp) return v.millisecondsSinceEpoch;
        if (v is int) return v;
        if (v is num) return v.toInt();
        return null;
      }

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

        "camposCustomValoresJson": jsonEncode(d["camposCustomValores"] ?? {}),

        "quantidadePadrao": (d["quantidadePadrao"] as num?) ?? 1,

        "createdAt": ms(d["createdAt"]) ?? ms(d["createdAtMs"]),
        "updatedAt": ms(d["updatedAt"]) ?? ms(d["updatedAtMs"]),
      };
    });
    
    await _pullCollection(uid, "printer_configs", table: "printer_configs", mapToLocal: (doc) {
      final d = doc.data();

      int? ms(dynamic v) {
        if (v is Timestamp) return v.millisecondsSinceEpoch;
        if (v is int) return v;
        if (v is num) return v.toInt();
        return null;
      }

      bool toBool(dynamic v, {bool defaultValue = false}) {
        if (v == null) return defaultValue;
        if (v is bool) return v;
        if (v is int) return v == 1;
        if (v is num) return v.toInt() == 1;
        final s = v.toString().trim().toLowerCase();
        if (s == 'true' || s == '1') return true;
        if (s == 'false' || s == '0') return false;
        return defaultValue;
      }

      return {
        "id": doc.id,
        "uid": uid,
        "nome": (d["nome"] ?? "").toString(),
        "modelo": (d["modelo"] ?? "Elgin L42 Pro").toString(),
        "tipoConexao": (d["tipoConexao"] ?? "network").toString(),
        "ip": (d["ip"] ?? "").toString(),
        "porta": (d["porta"] as num?)?.toInt() ?? 9100,
        "tamanhoEtiqueta": (d["tamanhoEtiqueta"] ?? "60x40").toString(),
        "ativo": toBool(d["ativo"], defaultValue: true) ? 1 : 0,
        "padrao": toBool(d["padrao"], defaultValue: false) ? 1 : 0,
        "createdAt": ms(d["createdAt"]) ?? ms(d["createdAtMs"]),
        "updatedAt": ms(d["updatedAt"]) ?? ms(d["updatedAtMs"]),
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
    await pushOutbox(uid, limit: 200);
    await pullAll(uid);
  }
}