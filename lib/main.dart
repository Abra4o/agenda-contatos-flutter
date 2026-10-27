import 'package:flutter/material.dart';

import 'screens/listagem_screen.dart';
import 'store/agenda_store.dart';

void main() {
  runApp(const AgendaApp());
}

class AgendaApp extends StatelessWidget {
  const AgendaApp({super.key});

  /// Monta o tema claro ou escuro usando a cor escolhida nas Configurações.
  ThemeData criarTema(Brightness brilho) {
    return ThemeData(
      colorSchemeSeed: agenda.corTema,
      brightness: brilho,
      appBarTheme: AppBarTheme(
        backgroundColor: agenda.corTema,
        foregroundColor: Colors.white,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ListenableBuilder redesenha o app quando a agenda muda (ex.: trocar o tema).
    return ListenableBuilder(
      listenable: agenda,
      builder: (context, child) {
        ThemeMode modo = ThemeMode.light;
        if (agenda.darkMode) {
          modo = ThemeMode.dark;
        }

        return MaterialApp(
          title: 'Agenda de Contatos',
          debugShowCheckedModeBanner: false,
          theme: criarTema(Brightness.light),
          darkTheme: criarTema(Brightness.dark),
          themeMode: modo,
          home: const ListagemScreen(),
        );
      },
    );
  }
}
