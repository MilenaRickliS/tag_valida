import 'dart:convert';
import '../../../models/tipo_etiqueta_model.dart';

extension TipoEtiquetaLocalMapper on TipoEtiquetaModel {
  Map<String, dynamic> toLocalMap({
    required String uid,
    required int nowMs,
  }) {
    final camposJson = jsonEncode(camposCustom.map((c) => c.toMap()).toList());

    return {
      'id': id,
      'uid': uid,
      'nome': nome,
      'descricao': descricao,
      'usarRegraValidadeCategoria': usarRegraValidadeCategoria ? 1 : 0,
      'controlaLote': controlaLote ? 1 : 0,
      'camposCustomJson': camposJson,
      'createdAt': nowMs,
      'updatedAt': nowMs,
    };
  }

  static TipoEtiquetaModel fromLocalMap(Map<String, dynamic> m) {
    final camposStr = (m['camposCustomJson'] ?? '[]').toString();
    final decoded = jsonDecode(camposStr) as List;
    final campos = decoded
        .map((e) => CampoCustomModel.fromMap(Map<String, dynamic>.from(e)))
        .toList();

    return TipoEtiquetaModel(
      id: (m['id'] ?? '').toString(),
      nome: (m['nome'] ?? '').toString(),
      descricao: m['descricao']?.toString(),
      usarRegraValidadeCategoria: (m['usarRegraValidadeCategoria'] ?? 1) == 1,
      camposCustom: campos,
      controlaLote: (m['controlaLote'] ?? 0) == 1,
    );
  }
}