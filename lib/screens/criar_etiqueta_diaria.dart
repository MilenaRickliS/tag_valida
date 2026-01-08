import 'package:flutter/material.dart';

class CriarEtiquetaDiariaScreen extends StatelessWidget {
  const CriarEtiquetaDiariaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: const Center(
          child: Text(
            'Page Criar Etiqueta Diaria',
            style: TextStyle(fontSize: 32),
          ),
        ),
    );
  }
}
