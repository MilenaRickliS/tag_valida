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
    this.createdAt,
  });

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
        "createdAt": FieldValue.serverTimestamp(),
        "updatedAt": FieldValue.serverTimestamp(),
      };
}
