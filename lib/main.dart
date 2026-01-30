import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:tag_valida/screens/ajuda.dart';
import 'package:tag_valida/screens/categorias.dart';
import 'package:tag_valida/screens/configuracoes.dart';
import 'package:tag_valida/screens/criar_etiqueta.dart';
import 'package:tag_valida/screens/criar_etiqueta_diaria.dart';
import 'package:tag_valida/screens/editar_etiqueta.dart';
import 'package:tag_valida/screens/etiqueta_ativa_detalhes.dart';
import 'package:tag_valida/screens/etiqueta_diaria_detalhes.dart';
import 'package:tag_valida/screens/etiquetas_ativas.dart';
import 'package:tag_valida/screens/etiquetas_diarias.dart';
import 'package:tag_valida/screens/historico.dart';
import 'package:tag_valida/screens/perfil.dart';
import 'package:tag_valida/screens/prever.dart';
import 'package:tag_valida/screens/relatorios.dart';
import 'package:tag_valida/screens/setores.dart';
import 'package:tag_valida/screens/tipo_etiqueta.dart';
import 'firebase_options.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'services/firestore_paths.dart';
import 'providers/categorias_provider.dart';
import 'providers/setores_provider.dart';
import 'providers/tipo_etiqueta_provider.dart';
import 'providers/gerar_etiqueta_provider.dart';
import 'screens/welcome.dart';
import 'screens/login.dart';
import 'screens/cadastro.dart';
import 'screens/home.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
      MultiProvider(
      providers: [     
         Provider<FirestorePaths>(
          create: (_) => FirestorePaths(FirebaseFirestore.instance),
        ),   
        ChangeNotifierProvider(create: (context) => AuthProvider()),
        ChangeNotifierProvider(create: (_) {
          final paths = FirestorePaths(FirebaseFirestore.instance);
          return CategoriasProvider(paths: paths);
        }),
        ChangeNotifierProvider(create: (_) {
          final paths = FirestorePaths(FirebaseFirestore.instance);
          return SetoresProvider(paths: paths);
        }),
        ChangeNotifierProvider(create: (_) {
          final paths = FirestorePaths(FirebaseFirestore.instance);
          return TiposEtiquetaProvider(paths: paths);
        }),
        ChangeNotifierProvider(create: (_) {
          final paths = FirestorePaths(FirebaseFirestore.instance);
          return GerarEtiquetaProvider(paths: paths);
        }), 
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TagVálida',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFFFDF7ED),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const WelcomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/cadastro': (context) => const CadastroScreen(),
        '/home': (context) => const HomeScreen(),
        '/perfil': (context) => const PerfilScreen(),
        '/ajuda': (context) => const AjudaScreen(),
        '/tipos-etiqueta': (_) => const TiposEtiquetaScreen(),
        '/criar-etiqueta': (context) => const CriarEtiquetaScreen(),
        '/etiquetas-ativas': (context) => const EtiquetasAtivasScreen(),
        '/etiqueta-ativa-detalhes': (context) => const EtiquetaAtivaDetalhes(),
        '/editar-etiqueta': (context) => const EditarEtiquetaScreen(),
        '/etiquetas-diarias': (context) => const EtiquetasDiariasScreen(),
        '/etiqueta-diaria-detalhes': (context) => const EtiquetaDiariaDetalhesScreen(),
        '/criar-etiqueta-diaria': (context) => const CriarEtiquetaDiariaScreen(),
        '/configuracoes': (context) => const ConfiguracoesScreen(),
        '/categorias': (context) => const CategoriasScreen(),
        '/setores': (context) => const SetoresScreen(),
        '/relatorios': (context) => const RelatoriosScreen(),
        '/historico': (context) => const HistoricoScreen(),
        '/prever-validade': (context) => const PreverValidadeScreen(),
      },
    );
  }
}


