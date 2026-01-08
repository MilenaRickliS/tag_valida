import 'package:flutter/material.dart';

class CriarEtiquetaScreen extends StatelessWidget {
  const CriarEtiquetaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: const Center(
          child: Text(
            'Page Criar Etiqueta',
            style: TextStyle(fontSize: 32),
          ),
        ),
    );
  }
}
