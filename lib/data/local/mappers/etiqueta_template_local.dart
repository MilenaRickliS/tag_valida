import 'dart:convert';
import '../../../models/etiqueta_template_model.dart';

extension EtiquetaTemplateLocalMapper on EtiquetaTemplateModel {
  Map<String, dynamic> toLocalMap({
    required String uid,
    required int nowMs,
  }) {
    return {
      "id": id,
      "uid": uid,
      "tipoId": tipoId,
      "tipoNome": tipoNome,
      "produtoNome": produtoNome,
      "categoriaId": categoriaId,
      "categoriaNome": categoriaNome,
      "setorId": setorId,
      "setorNome": setorNome,
      "camposCustomValoresJson": jsonEncode(camposCustomValores),
      "quantidadePadrao": quantidadePadrao,
      "createdAt": createdAt?.millisecondsSinceEpoch ?? nowMs,
      "updatedAt": nowMs,
    };
  }

  static EtiquetaTemplateModel fromLocalMap(Map<String, dynamic> m) {
    DateTime? dt(dynamic v) {
      if (v == null) return null;
      final n = (v is num) ? v.toInt() : int.tryParse(v.toString());
      return n == null ? null : DateTime.fromMillisecondsSinceEpoch(n);
    }

    num asNum(dynamic v, {num def = 1}) {
      if (v == null) return def;
      if (v is num) return v;
      return num.tryParse(v.toString().replaceAll(",", ".")) ?? def;
    }

    final valoresStr = (m["camposCustomValoresJson"] ?? "{}").toString();
    final Map<String, dynamic> valores = (jsonDecode(valoresStr) as Map).map(
      (k, v) => MapEntry(k.toString(), v),
    );

    return EtiquetaTemplateModel(
      id: (m["id"] ?? "").toString(),
      tipoId: (m["tipoId"] ?? "").toString(),
      tipoNome: (m["tipoNome"] ?? "").toString(),
      produtoNome: (m["produtoNome"] ?? "").toString(),
      categoriaId: (m["categoriaId"] ?? "").toString(),
      categoriaNome: (m["categoriaNome"] ?? "").toString(),
      setorId: (m["setorId"] ?? "").toString(),
      setorNome: (m["setorNome"] ?? "").toString(),
      camposCustomValores: valores,
      quantidadePadrao: asNum(m["quantidadePadrao"], def: 1),
      createdAt: dt(m["createdAt"]),
      updatedAt: dt(m["updatedAt"]),
    );
  }
}