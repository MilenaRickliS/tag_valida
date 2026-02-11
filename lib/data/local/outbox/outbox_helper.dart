import 'dart:convert';
import 'package:sqflite/sqflite.dart';

class OutboxHelper {
  static Future<void> enqueueUpsert({
    required Transaction txn,
    required String uid,
    required String entity,
    required String entityId,
    required Map<String, dynamic> payload,
    required int nowMs,
  }) async {
    await txn.insert("outbox", {
      "uid": uid,
      "entity": entity,
      "entityId": entityId,
      "op": "UPSERT",
      "payloadJson": jsonEncode(payload),
      "createdAt": nowMs,
      "tries": 0,
      "lastError": null,
    });
  }

  static Future<void> enqueueDelete({
    required Transaction txn,
    required String uid,
    required String entity,
    required String entityId,
    required int nowMs,
  }) async {
    await txn.insert("outbox", {
      "uid": uid,
      "entity": entity,
      "entityId": entityId,
      "op": "DELETE",
      "payloadJson": null,
      "createdAt": nowMs,
      "tries": 0,
      "lastError": null,
    });
  }
}