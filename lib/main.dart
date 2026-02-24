import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'services/firestore_paths.dart';

import 'providers/auth_provider.dart';

import 'data/local/repos/categorias_local_repo.dart';
import 'data/local/repos/setores_local_repo.dart';
import 'data/local/repos/tipos_etiqueta_local_repo.dart';
import 'data/local/repos/etiquetas_local_repo.dart';
import 'data/local/repos/estoque_mov_local_repo.dart';
import 'data/local/repos/etiqueta_template_local_repo.dart';

import 'providers/categorias_local_provider.dart';
import 'providers/setores_local_provider.dart';
import 'providers/tipos_etiqueta_local_provider.dart';
import 'providers/estoque_mov_local_provider.dart';
import 'providers/gerar_etiqueta_local_provider.dart';
import 'providers/templates_provider.dart';

import 'data/sync/sync_service.dart';

import 'screens/welcome.dart';
import 'screens/login.dart';
import 'screens/cadastro.dart';
import 'screens/home.dart';
import 'screens/perfil.dart';
import 'screens/ajuda.dart';
import 'screens/scanner_etiqueta.dart';
import 'screens/tipo_etiqueta.dart';
import 'screens/criar_etiqueta.dart';
import 'screens/etiquetas_ativas.dart';
import 'screens/etiquetas_diarias.dart';
import 'screens/etiquetas_finalizadas.dart';
import 'screens/configuracoes.dart';
import 'screens/categorias.dart';
import 'screens/setores.dart';
import 'screens/relatorios.dart';
import 'screens/historico.dart';
import 'screens/prever.dart';

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
        ChangeNotifierProvider(create: (_) => AuthProvider()),

        Provider<CategoriasLocalRepo>(create: (_) => CategoriasLocalRepo()),
        Provider<SetoresLocalRepo>(create: (_) => SetoresLocalRepo()),
        Provider<TiposEtiquetaLocalRepo>(create: (_) => TiposEtiquetaLocalRepo()),
        Provider<EtiquetasLocalRepo>(create: (_) => EtiquetasLocalRepo()),
        Provider<EstoqueMovLocalRepo>(create: (_) => EstoqueMovLocalRepo()),
        Provider<EtiquetasTemplatesLocalRepo>(create: (_) => EtiquetasTemplatesLocalRepo()),
        ChangeNotifierProvider(
          create: (ctx) => CategoriasLocalProvider(repo: ctx.read<CategoriasLocalRepo>()),
        ),
        ChangeNotifierProvider(
          create: (ctx) => SetoresLocalProvider(repo: ctx.read<SetoresLocalRepo>()),
        ),
        ChangeNotifierProvider(
          create: (ctx) => TiposEtiquetaLocalProvider(repo: ctx.read<TiposEtiquetaLocalRepo>()),
        ),

        ChangeNotifierProvider<EstoqueMovLocalProvider>(
          create: (ctx) => EstoqueMovLocalProvider(
            repo: ctx.read<EstoqueMovLocalRepo>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (ctx) => TemplatesProvider(
            repo: ctx.read<EtiquetasTemplatesLocalRepo>(),
          ),
        ),

        ChangeNotifierProvider<GerarEtiquetaLocalProvider>(
          create: (ctx) => GerarEtiquetaLocalProvider(
            repo: ctx.read<EtiquetasLocalRepo>(),
            mov: ctx.read<EstoqueMovLocalProvider>(),
            templateRepo: ctx.read<EtiquetasTemplatesLocalRepo>(),
          ),
        ),


        Provider(
          create: (_) => SyncService(FirebaseFirestore.instance),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

final RouteObserver<PageRoute<dynamic>> routeObserver =
    RouteObserver<PageRoute<dynamic>>();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorObservers: [routeObserver],
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
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
        '/scanner': (_) => const ScannerEtiquetaScreen(),
        '/tipos-etiqueta': (_) => const TiposEtiquetaScreen(),
        '/etiquetas-ativas': (context) => const EtiquetasAtivasScreen(),
        '/etiquetas-diarias': (context) => const EtiquetasDiariasScreen(),
        '/etiquetas-finalizadas': (context) => const EtiquetasFinalizadasScreen(),
        '/configuracoes': (context) => const ConfiguracoesScreen(),
        '/categorias': (context) => const CategoriasScreen(),
        '/setores': (context) => const SetoresScreen(),
        '/relatorios': (context) => const RelatoriosScreen(),
        '/historico': (context) => const HistoricoScreen(),
        '/prever-validade': (context) => const PreverValidadeScreen(),
      },

      
      onGenerateRoute: (settings) {
        if (settings.name == '/criar-etiqueta') {
          final args = (settings.arguments as Map?) ?? {};

          return MaterialPageRoute(
            settings: settings,
            builder: (_) => CriarEtiquetaScreen(
              templateId: args['templateId'] as String?,
              editarEtiquetaId: args['editarEtiquetaId'] as String?,
            ),
          );
        }

        return null;
      },
    );
  }
}