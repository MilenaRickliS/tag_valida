
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

class EstoqueFooter extends StatelessWidget {
  final num entradas;
  final num saidas;
  final num total;

  const EstoqueFooter({super.key, 
    required this.entradas,
    required this.saidas,
    required this.total,
  });

  String _fmt(num v) {
  
    if (v == v.roundToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(2);
  }

  Widget _pill({
    required IconData icon,
    required String label,
    required num value,
    required Color bg,
    required Color fg,
    required Color border,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: fg, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: fg.withOpacity(0.90),
                  fontSize: 12.5,
                ),
              ),
            ),
            Text(
              _fmt(value),
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: fg,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.70),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.black.withOpacity(0.08)),
        ),
        child: Row(
          children: [
            _pill(
              icon: Icons.input_rounded,
              label: "Entradas",
              value: entradas,
              bg: Colors.green.withOpacity(0.08),
              fg: Colors.green.shade800,
              border: Colors.green.withOpacity(0.20),
            ),
            const SizedBox(width: 10),
            _pill(
              icon: Icons.output_rounded,
              label: "Saídas",
              value: saidas,
              bg: Colors.orange.withOpacity(0.08),
              fg: Colors.orange.shade800,
              border: Colors.orange.withOpacity(0.20),
            ),
            const SizedBox(width: 10),
            _pill(
              icon: Icons.inventory_2_outlined,
              label: "Total em estoque",
              value: total,
              bg: Colors.black.withOpacity(0.04),
              fg: Colors.black87,
              border: Colors.black.withOpacity(0.12),
            ),
          ],
        ),
      ),
    );
  }
}