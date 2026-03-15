// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../widgets/menu.dart';

class PreverValidadeScreen extends StatelessWidget {
  const PreverValidadeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bg = theme.scaffoldBackgroundColor;
    final brand = isDark ? const Color(0xFFD4AF37) : const Color(0xFF428E2E);
    final text = isDark ? Colors.white : const Color(0xFF2B2B2B);
    final muted = isDark ? const Color(0xFFD6D6D6) : Colors.black.withOpacity(0.60);
    final fabBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final fabFg = isDark ? const Color(0xFFD4AF37) : const Color(0xFF428E2E);
    final fabBorder = isDark
        ? const Color(0xFFD4AF37).withOpacity(0.18)
        : Colors.black.withOpacity(0.08);

    final w = MediaQuery.of(context).size.width;
    final compact = w < 835;
    final mobile = w < 640;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
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
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.28 : 0.10),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          backgroundColor: fabBg,
          foregroundColor: fabFg,
          elevation: 0,
          onPressed: () {
            // TODO: abrir câmera / selecionar imagem
          },
          icon: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: brand,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.camera_alt,
              color: isDark ? Colors.black : Colors.white,
              size: 20,
            ),
          ),
          label: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Text(
              "Tirar foto",
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: fabFg,
              ),
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: fabBorder),
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1080),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 110),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HeroCard(compact: compact),

                const SizedBox(height: 18),

                if (mobile)
                  Column(
                    children: const [
                      _InfoStatCard(
                        icon: Icons.photo_camera_outlined,
                        title: "1. Tire a foto",
                        subtitle: "Capture uma imagem nítida do produto.",
                      ),
                      SizedBox(height: 12),
                      _InfoStatCard(
                        icon: Icons.psychology_alt_outlined,
                        title: "2. IA analisa",
                        subtitle: "O sistema avalia o estado visual do alimento.",
                      ),
                      SizedBox(height: 12),
                      _InfoStatCard(
                        icon: Icons.fact_check_outlined,
                        title: "3. Veja o resultado",
                        subtitle: "Receba o status: bom, alerta ou vencido.",
                      ),
                    ],
                  )
                else
                  Row(
                    children: const [
                      Expanded(
                        child: _InfoStatCard(
                          icon: Icons.photo_camera_outlined,
                          title: "1. Tire a foto",
                          subtitle: "Capture uma imagem nítida do produto.",
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _InfoStatCard(
                          icon: Icons.psychology_alt_outlined,
                          title: "2. IA analisa",
                          subtitle: "O sistema avalia o estado visual do alimento.",
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _InfoStatCard(
                          icon: Icons.fact_check_outlined,
                          title: "3. Veja o resultado",
                          subtitle: "Receba o status: bom, alerta ou vencido.",
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 24),

                Text(
                  "Orientações para tirar a foto",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: text,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Siga estas recomendações para melhorar a precisão da análise da validade.",
                  style: TextStyle(
                    color: muted,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 16),

                LayoutBuilder(
                  builder: (context, constraints) {
                    final isSmall = constraints.maxWidth < 850;

                    if (isSmall) {
                      return Column(
                        children: const [
                          _TipCard(
                            icon: Icons.wb_sunny_outlined,
                            title: "Boa iluminação",
                            description:
                                "Tire a foto em um local bem iluminado para destacar textura, cor e possíveis sinais de deterioração.",
                          ),
                          SizedBox(height: 12),
                          _TipCard(
                            icon: Icons.center_focus_strong_outlined,
                            title: "Enquadre o produto",
                            description:
                                "Centralize o alimento na imagem e evite cortar partes importantes.",
                          ),
                          SizedBox(height: 12),
                          _TipCard(
                            icon: Icons.cleaning_services_outlined,
                            title: "Fundo limpo",
                            description:
                                "Prefira um fundo neutro e sem objetos excessivos para evitar confusão na análise.",
                          ),
                          SizedBox(height: 12),
                          _TipCard(
                            icon: Icons.no_photography_outlined,
                            title: "Evite borrões",
                            description:
                                "Mantenha a câmera firme e não use fotos tremidas, escuras ou muito distantes.",
                          ),
                        ],
                      );
                    }

                    return GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 2.2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: const [
                        _TipCard(
                          icon: Icons.wb_sunny_outlined,
                          title: "Boa iluminação",
                          description:
                              "Tire a foto em um local bem iluminado para destacar textura, cor e possíveis sinais de deterioração.",
                        ),
                        _TipCard(
                          icon: Icons.center_focus_strong_outlined,
                          title: "Enquadre o produto",
                          description:
                              "Centralize o alimento na imagem e evite cortar partes importantes.",
                        ),
                        _TipCard(
                          icon: Icons.cleaning_services_outlined,
                          title: "Fundo limpo",
                          description:
                              "Prefira um fundo neutro e sem objetos excessivos para evitar confusão na análise.",
                        ),
                        _TipCard(
                          icon: Icons.no_photography_outlined,
                          title: "Evite borrões",
                          description:
                              "Mantenha a câmera firme e não use fotos tremidas, escuras ou muito distantes.",
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 28),

                Text(
                  "Exemplos de fotos",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: text,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Abaixo estão exemplos visuais de como a foto deve ser tirada.",
                  style: TextStyle(
                    color: muted,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 16),

                LayoutBuilder(
                  builder: (context, constraints) {
                    int crossAxisCount = 3;
                    if (constraints.maxWidth < 900) crossAxisCount = 2;
                    if (constraints.maxWidth < 560) crossAxisCount = 1;

                    return GridView.count(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: 0.95,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: const [
                        _ExampleImageCard(
                          title: "Exemplo correto",
                          subtitle: "Produto centralizado e bem iluminado",
                          assetPath: 'assets/exemplo_bom_1.jpg',
                          isGood: true,
                        ),
                        _ExampleImageCard(
                          title: "Exemplo correto",
                          subtitle: "Boa nitidez e fundo limpo",
                          assetPath: 'assets/exemplo_bom_2.jpg',
                          isGood: true,
                        ),
                        _ExampleImageCard(
                          title: "Evite este tipo",
                          subtitle: "Imagem escura ou desfocada",
                          assetPath: 'assets/exemplo_ruim_1.png',
                          isGood: false,
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 28),

                _InfoBox(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final bool compact;

  const _HeroCard({required this.compact});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cardGradient = isDark
        ? const [
            Color(0xFF1E1E1E),
            Color(0xFF151515),
          ]
        : const [
            Color(0xFFFFFFFF),
            Color(0xFFF7F3EA),
          ];

    final borderColor = isDark
        ? const Color(0xFFD4AF37).withOpacity(0.16)
        : Colors.black.withOpacity(0.05);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 18 : 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: cardGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.24 : 0.05),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                _HeroText(),
                SizedBox(height: 18),
                _HeroIcon(),
              ],
            )
          : Row(
              children: const [
                Expanded(child: _HeroText()),
                SizedBox(width: 20),
                _HeroIcon(),
              ],
            ),
    );
  }
}

class _HeroText extends StatelessWidget {
  const _HeroText();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final brand = isDark ? const Color(0xFFD4AF37) : const Color(0xFF428E2E);
    final text = isDark ? Colors.white : const Color(0xFF2B2B2B);
    final muted = isDark ? const Color(0xFFD6D6D6) : Colors.black.withOpacity(0.68);
    final pillBg = isDark
        ? const Color(0xFFD4AF37).withOpacity(0.12)
        : const Color(0xFF428E2E).withOpacity(0.10);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: pillBg,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            "Visão computacional",
            style: TextStyle(
              color: brand,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          "Prever validade por imagem",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: text,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          "Tire uma foto do alimento para que a inteligência artificial analise sinais visuais e ajude a identificar se o produto está bom, em alerta ou vencido.",
          style: TextStyle(
            fontSize: 15,
            height: 1.5,
            color: muted,
          ),
        ),
      ],
    );
  }
}

class _HeroIcon extends StatelessWidget {
  const _HeroIcon();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final brand = isDark ? const Color(0xFFD4AF37) : const Color(0xFF428E2E);
    final bg = isDark
        ? const Color(0xFFD4AF37).withOpacity(0.12)
        : const Color(0xFF428E2E).withOpacity(0.10);

    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Icon(
        Icons.document_scanner_outlined,
        size: 52,
        color: brand,
      ),
    );
  }
}

class _InfoStatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _InfoStatCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final card = isDark
        ? const Color(0xFF1E1E1E).withOpacity(0.96)
        : Colors.white.withOpacity(0.92);
    final borderColor = isDark
        ? const Color(0xFFD4AF37).withOpacity(0.16)
        : Colors.black.withOpacity(0.05);
    final brand = isDark ? const Color(0xFFD4AF37) : const Color(0xFF428E2E);
    final iconBg = isDark
        ? const Color(0xFFD4AF37).withOpacity(0.12)
        : const Color(0xFF428E2E).withOpacity(0.12);
    final text = isDark ? Colors.white : const Color(0xFF2B2B2B);
    final muted = isDark ? const Color(0xFFD6D6D6) : Colors.black.withOpacity(0.62);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.24 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: brand),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: muted,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _TipCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final card = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final borderColor = isDark
        ? const Color(0xFFD4AF37).withOpacity(0.16)
        : Colors.black.withOpacity(0.05);
    final brand = isDark ? const Color(0xFFD4AF37) : const Color(0xFF428E2E);
    final iconBg = isDark
        ? const Color(0xFFD4AF37).withOpacity(0.12)
        : const Color(0xFF428E2E).withOpacity(0.12);
    final text = isDark ? Colors.white : const Color(0xFF2B2B2B);
    final muted = isDark ? const Color(0xFFD6D6D6) : Colors.black.withOpacity(0.65);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.24 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: brand),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: text,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: muted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExampleImageCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String assetPath;
  final bool isGood;

  const _ExampleImageCard({
    required this.title,
    required this.subtitle,
    required this.assetPath,
    required this.isGood,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final goodColor = isDark ? const Color(0xFFD4AF37) : const Color(0xFF428E2E);
    final badColor = const Color(0xFFC94B41);
    final statusColor = isGood ? goodColor : badColor;
    final statusText = isGood ? "Recomendado" : "Não recomendado";

    final card = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final borderColor = isDark
        ? const Color(0xFFD4AF37).withOpacity(0.16)
        : Colors.black.withOpacity(0.05);
    final imageBg = isDark ? const Color(0xFF141414) : const Color(0xFFF4EFE5);
    final text = isDark ? Colors.white : const Color(0xFF2B2B2B);
    final muted = isDark ? const Color(0xFFD6D6D6) : Colors.black.withOpacity(0.62);

    return Container(
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.24 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                color: imageBg,
                child: Image.asset(
                  assetPath,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) {
                    return Center(
                      child: Icon(
                        Icons.image_outlined,
                        size: 52,
                        color: isDark
                            ? Colors.white.withOpacity(0.22)
                            : Colors.black.withOpacity(0.25),
                      ),
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: muted,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final card = isDark
        ? const Color(0xFF1E1E1E).withOpacity(0.96)
        : Colors.white.withOpacity(0.92);
    final borderColor = isDark
        ? const Color(0xFFD4AF37).withOpacity(0.16)
        : Colors.black.withOpacity(0.05);
    final brand = isDark ? const Color(0xFFD4AF37) : const Color(0xFF428E2E);
    final iconBg = isDark
        ? const Color(0xFFD4AF37).withOpacity(0.12)
        : const Color(0xFF428E2E).withOpacity(0.12);
    final text = isDark ? const Color(0xFFD6D6D6) : Colors.black.withOpacity(0.75);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.24 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.info_outline,
              color: brand,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              "Após tirar a foto, a inteligência artificial poderá classificar o alimento como bom, em alerta ou vencido, conforme os padrões visuais aprendidos durante o treinamento.",
              style: TextStyle(
                height: 1.5,
                fontSize: 14.5,
                color: text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}