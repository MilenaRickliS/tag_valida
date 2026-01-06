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
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(size),
        onTap: onPressed,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: const Color(0xFFF2E1BB),
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFF2A2828),
              width: borderW,
            ),
          ),
          child: Icon(
            icon,
            size: iconSize,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }
}
