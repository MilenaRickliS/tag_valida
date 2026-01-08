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
import 'package:tag_valida/screens/perfil.dart';
import 'package:tag_valida/screens/prever.dart';
import 'package:tag_valida/screens/setores.dart';
import 'firebase_options.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
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
        ChangeNotifierProvider(create: (context) => AuthProvider()), 
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
        '/prever-validade': (context) => const PreverValidadeScreen(),
      },
    );
  }
}


