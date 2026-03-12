import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/printer_config_model.dart';

class PrinterConfigMapper {
  static Map<String, dynamic> toLocal(PrinterConfigModel model) {
    return {
      'id': model.id,
      'uid': model.uid,
      'nome': model.nome,
      'modelo': model.modelo,
      'tipoConexao': model.tipoConexao,
      'ip': model.ip,
      'porta': model.porta,
      'tamanhoEtiqueta': model.tamanhoEtiqueta,
      'ativo': model.ativo ? 1 : 0,
      'padrao': model.padrao ? 1 : 0,
      'createdAt': model.createdAt?.millisecondsSinceEpoch,
      'updatedAt': model.updatedAt?.millisecondsSinceEpoch,
    };
  }

  static PrinterConfigModel fromLocal(Map<String, dynamic> map) {
    return PrinterConfigModel.fromMap(map);
  }

  static Map<String, dynamic> toFirestore(PrinterConfigModel model) {
    return {
      'id': model.id,
      'uid': model.uid,
      'nome': model.nome,
      'modelo': model.modelo,
      'tipoConexao': model.tipoConexao,
      'ip': model.ip,
      'porta': model.porta,
      'tamanhoEtiqueta': model.tamanhoEtiqueta,
      'ativo': model.ativo,
      'padrao': model.padrao,
      'createdAtMs': model.createdAt?.millisecondsSinceEpoch,
      'updatedAtMs': model.updatedAt?.millisecondsSinceEpoch,
    };
  }

  static Map<String, dynamic> firestoreDocToLocal(
    String uid,
    String docId,
    Map<String, dynamic> d,
  ) {
    int? ms(dynamic v) {
      if (v is Timestamp) return v.millisecondsSinceEpoch;
      if (v is int) return v;
      if (v is num) return v.toInt();
      return null;
    }

    bool toBool(dynamic v, {bool defaultValue = false}) {
      if (v == null) return defaultValue;
      if (v is bool) return v;
      if (v is int) return v == 1;
      if (v is num) return v.toInt() == 1;
      final s = v.toString().trim().toLowerCase();
      if (s == 'true' || s == '1') return true;
      if (s == 'false' || s == '0') return false;
      return defaultValue;
    }

    return {
      'id': docId,
      'uid': uid,
      'nome': (d['nome'] ?? '').toString(),
      'modelo': (d['modelo'] ?? 'Elgin L42 Pro').toString(),
      'tipoConexao': (d['tipoConexao'] ?? 'network').toString(),
      'ip': (d['ip'] ?? '').toString(),
      'porta': (d['porta'] as num?)?.toInt() ?? 9100,
      'tamanhoEtiqueta': (d['tamanhoEtiqueta'] ?? '60x40').toString(),
      'ativo': toBool(d['ativo'], defaultValue: true) ? 1 : 0,
      'padrao': toBool(d['padrao'], defaultValue: false) ? 1 : 0,
      'createdAt': ms(d['createdAt']) ?? ms(d['createdAtMs']),
      'updatedAt': ms(d['updatedAt']) ?? ms(d['updatedAtMs']),
    };
  }
}