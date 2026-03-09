// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

class MenuIcon extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  final double size;
  final double iconSize;
  final double borderW;

  const MenuIcon({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.size = 56,
    this.iconSize = 28,
    this.borderW = 2,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark
        ? const Color(0xFF2D2D2D)
        : const Color(0xFFF2E1BB);

    final borderColor = isDark
        ? const Color(0xFFF2E1BB)
        : const Color(0xFF2A2828);

    final iconColor = isDark
        ? const Color(0xFFF2E1BB)
        : Colors.black87;

    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(size),
        onTap: onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
            border: Border.all(
              color: borderColor,
              width: borderW,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.28 : 0.12),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            icon,
            size: iconSize,
            color: iconColor,
          ),
        ),
      ),
    );
  }
}