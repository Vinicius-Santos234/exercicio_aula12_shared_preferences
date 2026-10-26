import 'package:flutter/material.dart';

import 'screens/configuracoes_screen.dart';
import 'services/preferences_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final service = PreferencesService();
  final modoEscuroInicial = await service.obterModoEscuro();

  runApp(MeuApp(modoEscuroInicial: modoEscuroInicial));
}

class MeuApp extends StatefulWidget {
  final bool modoEscuroInicial;

  const MeuApp({super.key, required this.modoEscuroInicial});

  @override
  State<MeuApp> createState() => _MeuAppState();
}

class _MeuAppState extends State<MeuApp> {
  late bool _modoEscuro;

  @override
  void initState() {
    super.initState();
    _modoEscuro = widget.modoEscuroInicial;
  }

  void _alternarTema(bool valor) {
    setState(() => _modoEscuro = valor);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Aula 12 - SharedPreferences',
      themeMode: _modoEscuro ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
      darkTheme: ThemeData.dark(useMaterial3: true),
      home: ConfiguracoesScreen(onTemaAlterado: _alternarTema),
    );
  }
}
