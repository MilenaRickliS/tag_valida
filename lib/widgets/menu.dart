// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';
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
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;
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

    final menuBgColor = isDark
        ? const Color(0xFF161616)
        : Colors.white;

    final menuBorderColor = isDark
        ? const Color(0xFFD4AF37).withOpacity(0.18)
        : Colors.black.withOpacity(0.08);

    final menuShadowColor = isDark
        ? Colors.black.withOpacity(0.30)
        : Colors.black.withOpacity(0.08);

    final popupColor = isDark
        ? const Color(0xFF1E1E1E)
        : Colors.white;

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: menuBgColor,
        borderRadius: BorderRadius.circular(compact ? 26 : 32),
        border: Border.all(
          color: menuBorderColor,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: menuShadowColor,
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: compact
          ? PopupMenuButton<_MenuItem>(
              tooltip: "Menu",
              offset: const Offset(0, 52),
              color: popupColor,
              elevation: 10,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: isDark
                    ? BorderSide(
                        color: const Color(0xFFD4AF37).withOpacity(0.18),
                      )
                    : BorderSide.none,
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
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: _MenuItem.home,
                  child: _MenuRow(Icons.home_outlined, "Home"),
                ),
                const PopupMenuItem(
                  value: _MenuItem.perfil,
                  child: _MenuRow(Icons.person_outline, "Perfil"),
                ),
                const PopupMenuItem(
                  value: _MenuItem.ajuda,
                  child: _MenuRow(Icons.help_outline, "Ajuda"),
                ),
                const PopupMenuItem(
                  value: _MenuItem.scanner,
                  child: _MenuRow(Icons.qr_code_scanner, "Ler etiqueta"),
                ),
                PopupMenuItem(
                  value: _MenuItem.tema,
                  child: _MenuRow(
                    isDark
                        ? Icons.light_mode_outlined
                        : Icons.dark_mode_outlined,
                    isDark ? "Modo claro" : "Modo escuro",
                  ),
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
                  case _MenuItem.scanner:
                    _go(context, '/scanner');
                    break;
                  case _MenuItem.tema:
                    context.read<ThemeProvider>().toggleTheme();
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
                  tooltip: "Ler etiqueta",
                  icon: Icons.qr_code_scanner,
                  onPressed: () => _go(context, '/scanner'),
                  size: btnSize,
                  iconSize: iconSize,
                  borderW: borderW,
                ),
                SizedBox(width: gap),
                MenuIcon(
                  tooltip: isDark ? "Modo claro" : "Modo escuro",
                  icon: isDark
                      ? Icons.light_mode_outlined
                      : Icons.dark_mode_outlined,
                  onPressed: () {
                    context.read<ThemeProvider>().toggleTheme();
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

enum _MenuItem { home, perfil, ajuda, scanner, tema }

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MenuRow(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final color = isDark
        ? const Color(0xFFF2E1BB)
        : Colors.black87;

    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 10),
        Text(
          text,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}