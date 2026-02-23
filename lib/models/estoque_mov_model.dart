import 'package:cloud_firestore/cloud_firestore.dart';

class EstoqueMovModel {
  static const tipoEntrada = "entrada";
  static const tipoVenda = "venda";
  static const tipoCancelamento = "cancelamento";
  static const tipoAjusteEntrada = "ajuste_entrada";
  static const tipoAjusteSaida = "ajuste_saida";
  static const tipoExclusao = "exclusao";

  final String id;
  final String etiquetaId;
  final String? produtoNome;
  final String tipo;
  final num quantidade;
  final String? motivo;
  final DateTime createdAt;
  final DateTime updatedAt;

  EstoqueMovModel({
    required this.id,
    required this.etiquetaId,
    required this.tipo,
    required this.quantidade,
    required this.createdAt,
    required this.updatedAt,
    this.produtoNome,
    this.motivo,
  });


  static DateTime _parseDate(dynamic v) {
    if (v == null) return DateTime.now();
    if (v is Timestamp) return v.toDate();
    if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
    if (v is num) return DateTime.fromMillisecondsSinceEpoch(v.toInt());
    return DateTime.now();
  }

  factory EstoqueMovModel.fromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();

    return EstoqueMovModel(
      id: (data["id"] ?? doc.id).toString(),
      etiquetaId: (data["etiquetaId"] ?? "").toString(),
      produtoNome: data["produtoNome"]?.toString(),
      tipo: (data["tipo"] ?? "").toString(),
      quantidade: (data["quantidade"] as num?) ?? 0,
      motivo: data["motivo"]?.toString(),
      createdAt: _parseDate(data["createdAt"]),
      updatedAt: _parseDate(data["updatedAt"]),
    );
  }
}