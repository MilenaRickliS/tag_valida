import 'package:flutter/material.dart';

class AjudaScreen extends StatelessWidget {
  const AjudaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: const Center(
          child: Text(
            'Page Ajuda',
            style: TextStyle(fontSize: 32),
          ),
        ),
    );
  }
}
