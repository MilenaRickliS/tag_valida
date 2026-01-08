import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/menu.dart';
import '../widgets/home_menu_card_v2.dart';
import '../widgets/camera_fab_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Widget produtosValidosLink(BuildContext context,
      {double titleSize = 28, double subtitleSize = 13}) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, '/etiquetas-ativas'),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          children: [
            Text(
              "Todos os produtos\ndentro da validade",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: titleSize,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF2E8B73),
                height: 1.12,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Clique aqui para visualizar seus produtos",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: subtitleSize,
                decoration: TextDecoration.underline,
                color: Colors.black.withOpacity(0.55),
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _gridColumns(double w) {
    if (w < 600) return 1; 
    if (w < 1024) return 2;
    return 4; 
  }

  double _gridAspect(double w) {
    if (w < 600) return 2.25;
    if (w < 1024) return 1.15;
    return 0.95;
  }

  double _contentMaxWidth(double w) {
    if (w < 600) return 520;
    if (w < 1024) return 860;
    return 1180;
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    if (user == null) {
      Future.microtask(() {
        Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
      });
      return const SizedBox();
    }
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
                  Image.asset('assets/logo1.png', height: 78),
                  const SizedBox(height: 10),
                  const TopMenu(),
                ],
              )
            : Row(
                children: [
                  Image.asset('assets/logo1.png', height: 92),
                  const Spacer(),
                  const TopMenu(),
                ],
              ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final cols = _gridColumns(w);
            final maxW = _contentMaxWidth(w);

            final isMobile = w < 600;
            final titleSize = isMobile ? 26.0 : (w < 1024 ? 30.0 : 34.0);
            final subtitleSize = isMobile ? 13.0 : 14.0;

            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16 : 24,
                vertical: isMobile ? 16 : 24,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxW),
                  child: Container(
                    padding: EdgeInsets.all(isMobile ? 16 : 22),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFFB7E4C7),
                          Color(0xFF74C69D),
                          Color(0xFF40916C),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.16),
                          blurRadius: 26,
                          offset: const Offset(0, 14),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        produtosValidosLink(
                          context,
                          titleSize: titleSize,
                          subtitleSize: subtitleSize,
                        ),
                        const SizedBox(height: 18),

                      
                        Align(
                          alignment: Alignment.center,
                          child: CameraFabCard(
                            width: isMobile ? double.infinity : 420,
                            height: 98,
                            onTap: () =>
                                Navigator.pushNamed(context, '/prever-validade'),
                          ),
                        ),

                        const SizedBox(height: 22),

                        GridView.count(
                          crossAxisCount: cols,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          childAspectRatio: _gridAspect(w),
                          children: [
                            HomeMenuCardV2(
                              icon: Icons.add_circle_outline,
                              title: "Criar etiqueta",
                              subtitle:
                                  "Crie uma nova etiqueta para seus produtos",
                              onTap: () => Navigator.pushNamed(
                                  context, '/criar-etiqueta'),
                            ),
                            HomeMenuCardV2(
                              icon: Icons.check_circle_outline,
                              title: "Etiquetas ativas",
                              subtitle: "Veja as etiquetas ativas no estoque",
                              onTap: () => Navigator.pushNamed(
                                  context, '/etiquetas-ativas'),
                            ),
                            HomeMenuCardV2(
                              icon: Icons.event_note_outlined,
                              title: "Etiquetas diárias",
                              subtitle: "Produtos feitos diariamente",
                              onTap: () => Navigator.pushNamed(
                                  context, '/etiquetas-diarias'),
                            ),
                            HomeMenuCardV2(
                              icon: Icons.settings_outlined,
                              title: "Configurações",
                              subtitle: "Ajustes do aplicativo",
                              onTap: () => Navigator.pushNamed(
                                  context, '/configuracoes'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
