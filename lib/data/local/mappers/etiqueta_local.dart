import 'dart:convert';
import '../../../models/etiqueta_model.dart';

extension EtiquetaLocalMapper on EtiquetaModel {
  Map<String, dynamic> toLocalMap({
    required String uid,
    required int nowMs,
  }) {
    return {
      'id': id,
      'uid': uid,
      'tipoId': tipoId,
      'tipoNome': tipoNome,
      'produtoNome': produtoNome,
      'categoriaId': categoriaId,
      'categoriaNome': categoriaNome,
      'setorId': setorId,
      'setorNome': setorNome,
      'dataFabricacaoMs': dataFabricacao.millisecondsSinceEpoch,
      'dataValidadeMs': dataValidade.millisecondsSinceEpoch,
      'camposCustomValoresJson': jsonEncode(camposCustomValores),
      'status': status,
      'createdAt': createdAt?.millisecondsSinceEpoch ?? nowMs,
      'updatedAt': nowMs,
    };
  }

  static EtiquetaModel fromLocalMap(Map<String, dynamic> m) {
    DateTime dtMs(dynamic v) => DateTime.fromMillisecondsSinceEpoch((v ?? 0) as int);

    final valoresStr = (m['camposCustomValoresJson'] ?? '{}').toString();
    final valores = (jsonDecode(valoresStr) as Map).map(
      (k, v) => MapEntry(k.toString(), v),
    );

    return EtiquetaModel(
      id: (m['id'] ?? '').toString(),
      tipoId: (m['tipoId'] ?? '').toString(),
      tipoNome: (m['tipoNome'] ?? '').toString(),
      produtoNome: (m['produtoNome'] ?? '').toString(),
      categoriaId: (m['categoriaId'] ?? '').toString(),
      categoriaNome: (m['categoriaNome'] ?? '').toString(),
      setorId: (m['setorId'] ?? '').toString(),
      setorNome: (m['setorNome'] ?? '').toString(),
      dataFabricacao: dtMs(m['dataFabricacaoMs']),
      dataValidade: dtMs(m['dataValidadeMs']),
      camposCustomValores: Map<String, dynamic>.from(valores),
      status: (m['status'] ?? 'ativa').toString(),
      createdAt: m['createdAt'] == null ? null : dtMs(m['createdAt']),
    );
  }
}