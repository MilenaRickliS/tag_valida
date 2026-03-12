// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../widgets/menu.dart';

class ConfiguracoesScreen extends StatelessWidget {
  const ConfiguracoesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final compact = w < 835;
    return Scaffold(
      backgroundColor: const Color(0xFFFDF7ED),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDF7ED),
        elevation: 0,
        toolbarHeight: compact ? 160 : 100, 
        centerTitle: true,
        title: compact
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset('assets/logo6.png', height: 78),
                  const SizedBox(height: 10),
                  const TopMenu(),
                ],
              )
            : Row(
                children: [
                  Image.asset('assets/logo6.png', height: 92),
                  const Spacer(),
                  const TopMenu(),
                ],
              ),
      ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 980),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.black.withOpacity(0.07)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Configurações",
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Gerencie cadastros e preferências do sistema. Aqui você organiza categorias, setores, relatórios e ferramentas de backup.",
                      style: TextStyle(color: Colors.black.withOpacity(0.60)),
                    ),
                    const SizedBox(height: 18),

                    LayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.maxWidth;
                        final cols = width >= 900 ? 3 : (width >= 600 ? 2 : 1);

                        return GridView.count(
                          crossAxisCount: cols,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                          childAspectRatio: cols == 1 ? 3.2 : 2.6,
                          children: [
                            _ConfigTile(
                              icon: Icons.category_outlined,
                              title: "Categorias de produtos",
                              subtitle: "Cadastre e edite categorias",
                              onTap: () => Navigator.pushNamed(context, "/categorias"),
                            ),
                            _ConfigTile(
                              icon: Icons.badge_outlined,
                              title: "Setores / Responsáveis",
                              subtitle: "Cadastre setores e responsáveis",
                              onTap: () => Navigator.pushNamed(context, "/setores"),
                            ),
                            _ConfigTile(
                              icon: Icons.inventory_2_outlined,
                              title: "Etiquetas finalizadas",
                              subtitle: "Vendidas e canceladas",
                              onTap: () => Navigator.pushNamed(context, "/etiquetas-finalizadas"),
                            ),
                            _ConfigTile(
                              icon: Icons.print_outlined,
                              title: "Configurações - Impressora",
                              subtitle: "Modelo, tamanho e ajustes",
                              onTap: () =>  Navigator.pushNamed(context, "/configuracoes-impressora"),
                            ),
                            _ConfigTile(
                              icon: Icons.cloud_upload_outlined,
                              title: "Backup de dados",
                              subtitle: "Salve e restaure informações",
                              onTap: () => _soon(context),
                            ),
                            _ConfigTile(
                              icon: Icons.bar_chart_outlined,
                              title: "Relatórios",
                              subtitle: "Resumo e exportações",
                              onTap: () => Navigator.pushNamed(context, "/relatorios"),
                            ),
                            _ConfigTile(
                              icon: Icons.history_outlined,
                              title: "Histórico",
                              subtitle: "Ações e movimentações",
                              onTap: () => Navigator.pushNamed(context, "/historico"),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

    );
  }
}

void _soon(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text("Em breve 👀")),
  );
}

class _ConfigTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ConfigTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFFDF7ED),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black.withOpacity(0.10)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xffed7227),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: Colors.black, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Colors.black.withOpacity(0.60),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.black54),
          ],
        ),
      ),
    );
  }
}
