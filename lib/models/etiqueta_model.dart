import 'package:cloud_firestore/cloud_firestore.dart';

class EtiquetaModel {
  final String id;
  final String tipoId;
  final String tipoNome;

  final String produtoNome;

  final String categoriaId;
  final String categoriaNome;

  final String setorId;
  final String setorNome;

  final DateTime dataFabricacao;
  final DateTime dataValidade;

  final Map<String, dynamic> camposCustomValores;

  final String status; 
  final String? lote;


  final num quantidade; 
  final num quantidadeRestante; 
  final String statusEstoque; 
  final DateTime? soldAt; 
  final DateTime? createdAt;

  EtiquetaModel({
    required this.id,
    required this.tipoId,
    required this.tipoNome,
    required this.produtoNome,
    required this.categoriaId,
    required this.categoriaNome,
    required this.setorId,
    required this.setorNome,
    required this.dataFabricacao,
    required this.dataValidade,
    required this.camposCustomValores,
    required this.status,
    required this.lote,
    required this.quantidade,
    required this.quantidadeRestante,
    required this.statusEstoque,
    this.soldAt,
    this.createdAt,
  });

  static String calcStatusEstoque({
    required num restante,
    String? current,
  }) {
    final c = (current ?? "").trim().toLowerCase();
    if (c == "cancelado") return "cancelado";
    if (restante <= 0) return "vendido";
    return "ativo";
  }

  Map<String, dynamic> toMap() => {
        "tipoId": tipoId,
        "tipoNome": tipoNome,
        "produtoNome": produtoNome,
        "categoriaId": categoriaId,
        "categoriaNome": categoriaNome,
        "setorId": setorId,
        "setorNome": setorNome,
        "dataFabricacao": Timestamp.fromDate(dataFabricacao),
        "dataValidade": Timestamp.fromDate(dataValidade),
        "camposCustomValores": camposCustomValores,
        "status": status,
        "lote": lote,
        "quantidade": quantidade,
        "quantidadeRestante": quantidadeRestante,
        "statusEstoque": statusEstoque,
        "soldAt": soldAt == null ? null : Timestamp.fromDate(soldAt!),
        "createdAt": FieldValue.serverTimestamp(),
        "updatedAt": FieldValue.serverTimestamp(),
      };
}