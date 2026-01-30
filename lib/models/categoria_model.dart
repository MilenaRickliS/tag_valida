import 'package:cloud_firestore/cloud_firestore.dart';

class CategoriaModel {
  final String id;
  final String nome;
  final int diasVencimento;
  final bool ativo;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  CategoriaModel({
    required this.id,
    required this.nome,
    required this.diasVencimento,
    required this.ativo,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
        "nome": nome,
        "diasVencimento": diasVencimento,
        "ativo": ativo,
        "createdAt": createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
        "updatedAt": FieldValue.serverTimestamp(),
      };

  factory CategoriaModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    DateTime? dt(dynamic v) => v is Timestamp ? v.toDate() : null;

    return CategoriaModel(
      id: doc.id,
      nome: (data["nome"] ?? "").toString(),
      diasVencimento: (data["diasVencimento"] ?? 0) is int
          ? data["diasVencimento"]
          : int.tryParse(data["diasVencimento"].toString()) ?? 0,
      ativo: data["ativo"] ?? true,
      createdAt: dt(data["createdAt"]),
      updatedAt: dt(data["updatedAt"]),
    );
  }
}
