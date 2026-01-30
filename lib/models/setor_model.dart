import 'package:cloud_firestore/cloud_firestore.dart';

class SetorModel {
  final String id;
  final String nome;
  final String? descricao;
  final bool ativo;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  SetorModel({
    required this.id,
    required this.nome,
    this.descricao,
    required this.ativo,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
        "nome": nome,
        "descricao": descricao,
        "ativo": ativo,
        "createdAt": createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
        "updatedAt": FieldValue.serverTimestamp(),
      };

  factory SetorModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    DateTime? dt(dynamic v) => v is Timestamp ? v.toDate() : null;

    return SetorModel(
      id: doc.id,
      nome: (data["nome"] ?? "").toString(),
      descricao: data["descricao"]?.toString(),
      ativo: data["ativo"] ?? true,
      createdAt: dt(data["createdAt"]),
      updatedAt: dt(data["updatedAt"]),
    );
  }
}
