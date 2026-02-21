import 'package:cloud_firestore/cloud_firestore.dart';

enum CampoTipo { text, number, multiline, date, boolType }

CampoTipo campoTipoFromString(String s) {
  switch (s) {
    case "number":
      return CampoTipo.number;
    case "multiline":
      return CampoTipo.multiline;
    case "date":
      return CampoTipo.date;
    case "bool":
      return CampoTipo.boolType;
    default:
      return CampoTipo.text;
  }
}

String campoTipoToString(CampoTipo t) {
  switch (t) {
    case CampoTipo.number:
      return "number";
    case CampoTipo.multiline:
      return "multiline";
    case CampoTipo.date:
      return "date";
    case CampoTipo.boolType:
      return "bool";
    case CampoTipo.text:
    return "text";
  }
}

class CampoCustomModel {
  final String key; 
  final String label; 
  final CampoTipo tipo;
  final bool obrigatorio;

  CampoCustomModel({
    required this.key,
    required this.label,
    required this.tipo,
    required this.obrigatorio,
  });

  Map<String, dynamic> toMap() => {
        "key": key,
        "label": label,
        "tipo": campoTipoToString(tipo),
        "obrigatorio": obrigatorio,
      };

  factory CampoCustomModel.fromMap(Map<String, dynamic> m) => CampoCustomModel(
        key: (m["key"] ?? "").toString(),
        label: (m["label"] ?? "").toString(),
        tipo: campoTipoFromString((m["tipo"] ?? "text").toString()),
        obrigatorio: m["obrigatorio"] ?? false,
      );
}

class TipoEtiquetaModel {
  final String id;
  final String nome;
  final String? descricao;
  final bool usarRegraValidadeCategoria;
  final List<CampoCustomModel> camposCustom;
  final bool controlaLote;

  TipoEtiquetaModel({
    required this.id,
    required this.nome,
    this.descricao,
    required this.usarRegraValidadeCategoria,
    required this.controlaLote,
    required this.camposCustom,
  });

  Map<String, dynamic> toMap() => {
        "nome": nome,
        "descricao": descricao,
        "usarRegraValidadeCategoria": usarRegraValidadeCategoria,
        "controlaLote": controlaLote,
        "camposCustom": camposCustom.map((c) => c.toMap()).toList(),
        "updatedAt": FieldValue.serverTimestamp(),
        "createdAt": FieldValue.serverTimestamp(),
      };

  factory TipoEtiquetaModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final list = (data["camposCustom"] as List? ?? [])
        .map((e) => CampoCustomModel.fromMap(Map<String, dynamic>.from(e)))
        .toList();

    return TipoEtiquetaModel(
      id: doc.id,
      nome: (data["nome"] ?? "").toString(),
      descricao: data["descricao"]?.toString(),
      usarRegraValidadeCategoria: data["usarRegraValidadeCategoria"] ?? true,
      camposCustom: list,
      controlaLote: data["controlaLote"] ?? false,
    );
  }
}
