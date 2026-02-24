import 'package:cloud_firestore/cloud_firestore.dart';

class FirestorePaths {
  final FirebaseFirestore _db;
  FirestorePaths(this._db);

  CollectionReference<Map<String, dynamic>> categorias(String uid) =>
      _db.collection("usuarios").doc(uid).collection("categorias");

  CollectionReference<Map<String, dynamic>> setores(String uid) =>
      _db.collection("usuarios").doc(uid).collection("setores");

  CollectionReference<Map<String, dynamic>> tiposEtiqueta(String uid) =>
      _db.collection("usuarios").doc(uid).collection("tipos_etiqueta");

  CollectionReference<Map<String, dynamic>> etiquetas(String uid) =>
      _db.collection("usuarios").doc(uid).collection("etiquetas");

  CollectionReference<Map<String, dynamic>> etiquetasTemplates(String uid) =>
      _db.collection("usuarios").doc(uid).collection("etiquetas_templates");

  CollectionReference<Map<String, dynamic>> estoqueMov(String uid) =>
      _db.collection("usuarios").doc(uid).collection("estoque_mov");
}
