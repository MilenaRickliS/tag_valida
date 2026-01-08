import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/menu.dart';
import '../widgets/home_background_arc.dart';
import '../widgets/home_menu_card_v2.dart';
import '../widgets/camera_fab_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    if (user == null) {
      Future.microtask(() {
        Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
      });
      return const SizedBox();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFDF7ED),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final compact = w < 835;


          final quickActions = <Widget>[
            CameraFabCard(
              onTap: () => Navigator.pushNamed(context, '/prever-validade'),
            ),

          ];

          return Scaffold(
            backgroundColor: const Color(0xFFFDF7ED),
            appBar: AppBar(
              backgroundColor: const Color(0xFFFDF7ED),
              elevation: 0,
              toolbarHeight: compact ? 150 : 100, 
              title: compact
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Image.asset('assets/logo1.png', height: 86),
                        const SizedBox(height: 12),
                        const TopMenu(), 
                      ],
                    )
                  : Row(
                      children: [
                        Image.asset('assets/logo1.png', height: 100),
                        const Spacer(),
                        const TopMenu(),
                      ],
                    ),
              centerTitle: compact, 
            ),
            body: Stack(
              children: [
                
                Positioned.fill(child: HomeBackgroundArc(compact: compact)),

              
                if (compact)
                 
                  Align(
                    alignment: Alignment.topCenter,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(18, 24, 18, 28),
                      child: Column(
                        children: [
                          const SizedBox(height: 14),
                          const Text(
                            "Todos os produtos\ndentro da validade",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF2E8B73),
                              height: 1.15,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "Clique aqui para visualizar seus produtos",
                            style: TextStyle(
                              fontSize: 13,
                              decoration: TextDecoration.underline,
                              color: Colors.black.withOpacity(0.55),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),

                       
                          Column(
                            children: [
                              for (int i = 0; i < quickActions.length; i++) ...[
                                quickActions[i],
                                if (i != quickActions.length - 1) const SizedBox(height: 14),
                              ]
                            ],
                          ),

                          const SizedBox(height: 22),

                          GridView.count(
                            crossAxisCount: 1,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            childAspectRatio: 3.0, 
                            children: [
                              HomeMenuCardV2(
                                icon: Icons.add_circle_outline,
                                title: "Criar etiqueta",
                                subtitle: "Clique aqui para criar uma nova etiqueta para seus produtos",
                                onTap: () => Navigator.pushNamed(context, '/criar-etiqueta'),
                              ),
                              HomeMenuCardV2(
                                icon: Icons.check_circle_outline,
                                title: "Etiquetas ativas",
                                subtitle: "Clique aqui para ver todas as suas etiquetas ativas no estoque",
                                onTap: () => Navigator.pushNamed(context, '/etiquetas-ativas'),
                              ),
                              HomeMenuCardV2(
                                icon: Icons.event_note_outlined,
                                title: "Etiquetas diárias",
                                subtitle:
                                    "Clique aqui para ver todas as suas etiquetas diárias (produtos que são sempre feitos)",
                                onTap: () => Navigator.pushNamed(context, '/etiquetas-diarias'),
                              ),
                              HomeMenuCardV2(
                                icon: Icons.settings_outlined,
                                title: "Configurações",
                                subtitle: "Clique aqui para ir até as configurações do app",
                                onTap: () => Navigator.pushNamed(context, '/configuracoes'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  
                  Stack(
                    children: [
                     
                      Positioned(
                        right: 26,
                        top: 40,
                        child: Column(
                          children: [
                            for (int i = 0; i < quickActions.length; i++) ...[
                              quickActions[i],
                              if (i != quickActions.length - 1) const SizedBox(height: 14),
                            ],
                          ],
                        ),
                      ),
                      Align(
                        alignment: Alignment.topCenter,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.only(top: 80, left: 40, right: 40, bottom: 40),
                          child: Column(
                            children: [
                              const Text(
                                "Todos os produtos\ndentro da validade",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 34,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF2E8B73),
                                  height: 1.15,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                "Clique aqui para visualizar seus produtos",
                                style: TextStyle(
                                  fontSize: 14,
                                  decoration: TextDecoration.underline,
                                  color: Colors.black.withOpacity(0.55),
                                ),
                              ),
                              const SizedBox(height: 34),
                              SizedBox(
                                width: w >= 900 ? 980 : double.infinity,
                                child: GridView.count(
                                  crossAxisCount: w >= 900 ? 4 : 2,
                                  crossAxisSpacing: 22,
                                  mainAxisSpacing: 22,
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  childAspectRatio: w >= 900 ? 0.78 : 0.9,
                                  children: [
                                    HomeMenuCardV2(
                                      icon: Icons.add_circle_outline,
                                      title: "Criar etiqueta",
                                      subtitle:
                                          "Clique aqui para criar uma nova etiqueta para seus produtos",
                                      onTap: () => Navigator.pushNamed(context, '/criar-etiqueta'),
                                    ),
                                    HomeMenuCardV2(
                                      icon: Icons.check_circle_outline,
                                      title: "Etiquetas ativas",
                                      subtitle:
                                          "Clique aqui para ver todas as suas etiquetas ativas no estoque",
                                      onTap: () => Navigator.pushNamed(context, '/etiquetas-ativas'),
                                    ),
                                    HomeMenuCardV2(
                                      icon: Icons.event_note_outlined,
                                      title: "Etiquetas diárias",
                                      subtitle:
                                          "Clique aqui para ver todas as suas etiquetas diárias (produtos que são sempre feitos)",
                                      onTap: () => Navigator.pushNamed(context, '/etiquetas-diarias'),
                                    ),
                                    HomeMenuCardV2(
                                      icon: Icons.settings_outlined,
                                      title: "Configurações",
                                      subtitle:
                                          "Clique aqui para ir até as configurações do app",
                                      onTap: () => Navigator.pushNamed(context, '/configuracoes'),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
