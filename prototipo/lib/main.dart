import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'screens/home_shell.dart';
import 'screens/login.dart';
import 'store.dart';

void main() => runApp(const GincanaApp());

class GincanaApp extends StatefulWidget {
  const GincanaApp({super.key});

  @override
  State<GincanaApp> createState() => _GincanaAppState();
}

class _GincanaAppState extends State<GincanaApp> {
  final store = AppStore();

  @override
  Widget build(BuildContext context) {
    return AppScope(
      store: store,
      child: MaterialApp(
        title: 'Gincanas do Recanto',
        debugShowCheckedModeBanner: false,
        locale: const Locale('pt', 'BR'),
        supportedLocales: const [Locale('pt', 'BR')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        theme: ThemeData(
          colorSchemeSeed: const Color(0xFF0B3D6B),
          useMaterial3: true,
          visualDensity: VisualDensity.standard,
          cardTheme: const CardThemeData(margin: EdgeInsets.zero),
        ),
        home: const _Raiz(),
      ),
    );
  }
}

class _Raiz extends StatelessWidget {
  const _Raiz();

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    return store.usuarioAtual == null ? const LoginScreen() : const HomeShell();
  }
}
