import 'package:flutter/material.dart';
import 'menu_icon.dart';

class TopMenu extends StatelessWidget {
  const TopMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final compact = w < 835;

    final gap = compact ? 16.0 : 70.0;
    final btnSize = compact ? 42.0 : 56.0;
    final iconSize = compact ? 22.0 : 28.0;
    final borderW = compact ? 1.6 : 2.0;

    final padding = compact
        ? const EdgeInsets.symmetric(horizontal: 10, vertical: 6)
        : const EdgeInsets.symmetric(horizontal: 16, vertical: 8);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(compact ? 26 : 32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          MenuIcon(
            tooltip: "Home",
            icon: Icons.home_outlined,
            onPressed: () => Navigator.pushNamed(context, '/home'),
            size: btnSize,
            iconSize: iconSize,
            borderW: borderW,
          ),
          SizedBox(width: gap),

          MenuIcon(
            tooltip: "Perfil",
            icon: Icons.person_outline,
            onPressed: () => Navigator.pushNamed(context, '/perfil'),
            size: btnSize,
            iconSize: iconSize,
            borderW: borderW,
          ),
          SizedBox(width: gap),

          MenuIcon(
            tooltip: "Ajuda",
            icon: Icons.help_outline,
            onPressed: () => Navigator.pushNamed(context, '/ajuda'),
            size: btnSize,
            iconSize: iconSize,
            borderW: borderW,
          ),
          SizedBox(width: gap),

          MenuIcon(
            tooltip: "Modo escuro",
            icon: Icons.dark_mode_outlined,
            onPressed: () {},
            size: btnSize,
            iconSize: iconSize,
            borderW: borderW,
          ),
        ],
      ),
    );
  }
}
