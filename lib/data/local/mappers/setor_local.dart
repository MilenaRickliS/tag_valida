import '../../../models/setor_model.dart';

extension SetorLocalMapper on SetorModel {
  Map<String, dynamic> toLocalMap({
    required String uid,
    required int nowMs,
  }) {
    return {
      'id': id,
      'uid': uid,
      'nome': nome,
      'descricao': descricao,
      'ativo': ativo ? 1 : 0,
      'createdAt': createdAt?.millisecondsSinceEpoch,
      'updatedAt': nowMs,
    };
  }

  static SetorModel fromLocalMap(Map<String, dynamic> m) {
    DateTime? dt(dynamic v) =>
        v == null ? null : DateTime.fromMillisecondsSinceEpoch(v as int);

    return SetorModel(
      id: (m['id'] ?? '').toString(),
      nome: (m['nome'] ?? '').toString(),
      descricao: m['descricao']?.toString(),
      ativo: (m['ativo'] ?? 1) == 1,
      createdAt: dt(m['createdAt']),
      updatedAt: dt(m['updatedAt']),
    );
  }
}