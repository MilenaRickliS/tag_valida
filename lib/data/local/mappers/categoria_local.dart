import '../../../models/categoria_model.dart';

extension CategoriaLocalMapper on CategoriaModel {
  Map<String, dynamic> toLocalMap({
    required String uid,
    required int nowMs,
  }) {
    return {
      'id': id,
      'uid': uid,
      'nome': nome,
      'diasVencimento': diasVencimento,
      'ativo': ativo ? 1 : 0,
      'createdAt': (createdAt?.millisecondsSinceEpoch),
      'updatedAt': nowMs,
    };
  }

  static CategoriaModel fromLocalMap(Map<String, dynamic> m) {
    DateTime? dt(dynamic v) =>
        v == null ? null : DateTime.fromMillisecondsSinceEpoch(v as int);

    return CategoriaModel(
      id: (m['id'] ?? '').toString(),
      nome: (m['nome'] ?? '').toString(),
      diasVencimento: (m['diasVencimento'] ?? 0) as int,
      ativo: (m['ativo'] ?? 1) == 1,
      createdAt: dt(m['createdAt']),
      updatedAt: dt(m['updatedAt']),
    );
  }
}