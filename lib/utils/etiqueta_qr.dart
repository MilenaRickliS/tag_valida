import 'dart:convert';

String buildEtiquetaQrPayload({required String uid, required String etiquetaId}) {
  return jsonEncode({
    "app": "tagvalida",
    "v": 1,
    "uid": uid,
    "id": etiquetaId,
    "type": "etiqueta",
  });
}

({String uid, String id}) parseEtiquetaQrPayload(String raw) {
  final obj = jsonDecode(raw) as Map<String, dynamic>;

  if (obj["app"] != "tagvalida") {
    throw Exception("QR não pertence ao Tag Valida");
  }
  if ((obj["type"] ?? "etiqueta") != "etiqueta") {
    throw Exception("QR não é de etiqueta");
  }

  return (uid: obj["uid"].toString(), id: obj["id"].toString());
}