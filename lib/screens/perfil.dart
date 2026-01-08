import 'package:flutter/material.dart';

class PerfilScreen extends StatelessWidget {
  const PerfilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: const Center(
          child: Text(
            'Page Perfil',
            style: TextStyle(fontSize: 32),
          ),
        ),
    );
  }
}
