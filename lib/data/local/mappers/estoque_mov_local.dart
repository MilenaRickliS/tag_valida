import '../../../models/estoque_mov_model.dart';

extension EstoqueMovLocalMapper on EstoqueMovModel {
  Map<String, dynamic> toLocalMap({required String uid}) {
    return {
      "id": id,
      "uid": uid,
      "etiquetaId": etiquetaId,
      "produtoNome": produtoNome,
      "tipo": tipo,
      "quantidade": quantidade,
      "motivo": motivo,
      "createdAt": createdAt.millisecondsSinceEpoch,
      "updatedAt": updatedAt.millisecondsSinceEpoch,
    };
  }

  static EstoqueMovModel fromLocalMap(Map<String, dynamic> m) {
    DateTime dtMs(dynamic v) {
      if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
      if (v is num) return DateTime.fromMillisecondsSinceEpoch(v.toInt());
      return DateTime.fromMillisecondsSinceEpoch(int.tryParse("$v") ?? 0);
    }

    num asNum(dynamic v, {num def = 0}) {
      if (v == null) return def;
      if (v is num) return v;
      return num.tryParse(v.toString().replaceAll(",", ".")) ?? def;
    }

    return EstoqueMovModel(
      id: (m["id"] ?? "").toString(),
      etiquetaId: (m["etiquetaId"] ?? "").toString(),
      produtoNome: (m["produtoNome"] ?? "").toString().trim().isEmpty
          ? null
          : (m["produtoNome"] ?? "").toString(),
      tipo: (m["tipo"] ?? "").toString(),
      quantidade: asNum(m["quantidade"]),
      motivo: (m["motivo"] ?? "").toString().trim().isEmpty ? null : (m["motivo"] ?? "").toString(),
      createdAt: dtMs(m["createdAt"]),
      updatedAt: dtMs(m["updatedAt"]),
    );
  }
}