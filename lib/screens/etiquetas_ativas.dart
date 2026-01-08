import 'package:flutter/material.dart';

class EtiquetasAtivasScreen extends StatelessWidget {
  const EtiquetasAtivasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: const Center(
          child: Text(
            'Page Etiquetas Ativas',
            style: TextStyle(fontSize: 32),
          ),
        ),
    );
  }
}
