import 'package:flutter/material.dart';
import 'menu_icon.dart';

class TopMenu extends StatelessWidget {
  const TopMenu({super.key});

  void _go(BuildContext context, String route) {
    final current = ModalRoute.of(context)?.settings.name;
    if (current == route) return;
    Navigator.pushNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final compact = w < 835;


    final gap = 18.0;
    final btnSize = 56.0;
    final iconSize = 28.0;
    final borderW = 2.0;


    final mBtnSize = 46.0;
    final mIconSize = 24.0;
    final mBorderW = 1.6;

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
      child: compact
          ? PopupMenuButton<_MenuItem>(
              tooltip: "Menu",
              offset: const Offset(0, 52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
           
              child: IgnorePointer(
                child: MenuIcon(
                  tooltip: "Menu",
                  icon: Icons.menu_rounded,
                  onPressed: () {}, 
                  size: mBtnSize,
                  iconSize: mIconSize,
                  borderW: mBorderW,
                ),
              ),
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: _MenuItem.home,
                  child: _MenuRow(Icons.home_outlined, "Home"),
                ),
                PopupMenuItem(
                  value: _MenuItem.perfil,
                  child: _MenuRow(Icons.person_outline, "Perfil"),
                ),
                PopupMenuItem(
                  value: _MenuItem.ajuda,
                  child: _MenuRow(Icons.help_outline, "Ajuda"),
                ),
                PopupMenuItem(
                  value: _MenuItem.tema,
                  child: _MenuRow(Icons.dark_mode_outlined, "Modo escuro"),
                ),
              ],
              onSelected: (item) {
                switch (item) {
                  case _MenuItem.home:
                    _go(context, '/home');
                    break;
                  case _MenuItem.perfil:
                    _go(context, '/perfil');
                    break;
                  case _MenuItem.ajuda:
                    _go(context, '/ajuda');
                    break;
                  case _MenuItem.tema:
                   
                    break;
                }
              },
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                MenuIcon(
                  tooltip: "Home",
                  icon: Icons.home_outlined,
                  onPressed: () => _go(context, '/home'),
                  size: btnSize,
                  iconSize: iconSize,
                  borderW: borderW,
                ),
                SizedBox(width: gap),
                MenuIcon(
                  tooltip: "Perfil",
                  icon: Icons.person_outline,
                  onPressed: () => _go(context, '/perfil'),
                  size: btnSize,
                  iconSize: iconSize,
                  borderW: borderW,
                ),
                SizedBox(width: gap),
                MenuIcon(
                  tooltip: "Ajuda",
                  icon: Icons.help_outline,
                  onPressed: () => _go(context, '/ajuda'),
                  size: btnSize,
                  iconSize: iconSize,
                  borderW: borderW,
                ),
                SizedBox(width: gap),
                MenuIcon(
                  tooltip: "Modo escuro",
                  icon: Icons.dark_mode_outlined,
                  onPressed: () {
                   
                  },
                  size: btnSize,
                  iconSize: iconSize,
                  borderW: borderW,
                ),
              ],
            ),
    );
  }
}

enum _MenuItem { home, perfil, ajuda, tema }

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _MenuRow(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.black87),
        const SizedBox(width: 10),
        Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}
