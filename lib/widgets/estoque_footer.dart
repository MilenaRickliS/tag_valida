// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

class EstoqueFooter extends StatelessWidget {
  final num entradas;
  final num saidas;
  final num total;

  const EstoqueFooter({
    super.key,
    required this.entradas,
    required this.saidas,
    required this.total,
  });

  String _fmt(num v) {
    if (v == v.roundToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(2);
  }

  Widget _pill({
    required BuildContext context,
    required IconData icon,
    required String label,
    required num value,
    required Color bg,
    required Color fg,
    required Color border,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.18 : 0.05),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final containerBg =
        isDark ? const Color(0xFF1E1E1E) : Colors.white.withOpacity(0.70);

    final containerBorder = isDark
        ? const Color(0xFFD4AF37).withOpacity(0.16)
        : Colors.black.withOpacity(0.08);

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: containerBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: containerBorder),
        ),
        child: Row(
          children: [
            _pill(
              context: context,
              icon: Icons.input_rounded,
              label: "Entradas",
              value: entradas,
              bg: isDark
                  ? Colors.green.withOpacity(0.14)
                  : Colors.green.withOpacity(0.08),
              fg: isDark ? Colors.greenAccent.shade200 : Colors.green.shade800,
              border: isDark
                  ? Colors.greenAccent.withOpacity(0.22)
                  : Colors.green.withOpacity(0.20),
            ),
            const SizedBox(width: 10),
            _pill(
              context: context,
              icon: Icons.output_rounded,
              label: "Saídas",
              value: saidas,
              bg: isDark
                  ? Colors.orange.withOpacity(0.14)
                  : Colors.orange.withOpacity(0.08),
              fg: isDark ? Colors.orangeAccent.shade100 : Colors.orange.shade800,
              border: isDark
                  ? Colors.orangeAccent.withOpacity(0.22)
                  : Colors.orange.withOpacity(0.20),
            ),
            const SizedBox(width: 10),
            _pill(
              context: context,
              icon: Icons.inventory_2_outlined,
              label: "Total em estoque",
              value: total,
              bg: isDark
                  ? const Color(0xFFD4AF37).withOpacity(0.12)
                  : Colors.black.withOpacity(0.04),
              fg: isDark ? const Color(0xFFD4AF37) : Colors.black87,
              border: isDark
                  ? const Color(0xFFD4AF37).withOpacity(0.22)
                  : Colors.black.withOpacity(0.12),
            ),
          ],
        ),
      ),
    );
  }
}