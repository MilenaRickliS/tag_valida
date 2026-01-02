import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/user.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  UserModel? _user;
  UserModel? get user => _user;

  Future<void> signIn(String email, String password) async {
    final result = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = result.user!.uid;
    final doc = await _firestore.collection('usuarios').doc(uid).get();

    if (!doc.exists || doc.data() == null) {
      throw Exception("Usuário não encontrado no Firestore.");
    }

    _user = UserModel.fromMap(doc.data()!);
    notifyListeners();
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> register({
    required String nome,
    required String razao,
    required String email,
    required String senha,
    required String cnpj,
    required String cep,
    required String rua,
    required String numero,
    required String bairro,
    required String complemento,
    required String cidade,
    required String estado,
    required String telefone,
    required String responsavel,
    required String logo,
  }) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: senha,
      );

      final uid = result.user!.uid;

      await _firestore.collection('usuarios').doc(uid).set({
        'uid': uid,
        'nome': nome,
        'razao': razao,
        'email': email,
        'cnpj': cnpj,
        'cep': cep,
        'rua': rua,
        'numero': numero,
        'bairro': bairro,
        'complemento': complemento,
        'cidade': cidade,
        'estado': estado,
        'telefone': telefone,
        'responsavel': responsavel,
        'logo': logo,
        'criadoEm': DateTime.now(),
      });

      final doc = await _firestore.collection('usuarios').doc(uid).get();
      _user = UserModel.fromMap(doc.data()!);

      notifyListeners();
    } catch (e) {
      throw Exception('Erro ao registrar usuário: $e');
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    _user = null;
    notifyListeners();
  }

  Future<void> logout() async => signOut();
}
