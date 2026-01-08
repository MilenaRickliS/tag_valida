import 'package:flutter/material.dart';

class ConfiguracoesScreen extends StatelessWidget {
  const ConfiguracoesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: const Center(
          child: Text(
            'Page Configurações',
            style: TextStyle(fontSize: 32),
          ),
        ),
    );
  }
}
