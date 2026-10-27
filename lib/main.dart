import 'package:flutter/material.dart';

import 'screens/listagem_screen.dart';
import 'store/agenda_store.dart';

void main() {
  runApp(const AgendaApp());
}

class AgendaApp extends StatelessWidget {
  const AgendaApp({super.key});

  ThemeData _tema(Color cor, Brightness brilho) {
    final esquema = ColorScheme.fromSeed(seedColor: cor, brightness: brilho).copyWith(
      primary: brilho == Brightness.light ? cor : null,
      onPrimary: brilho == Brightness.light ? Colors.white : null,
    );
    return ThemeData(
      colorScheme: esquema,
      appBarTheme: AppBarTheme(
        backgroundColor: brilho == Brightness.light ? cor : null,
        foregroundColor: brilho == Brightness.light ? Colors.white : null,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: cor,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = AgendaStore.instance;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) => MaterialApp(
        title: 'Agenda de Contatos',
        debugShowCheckedModeBanner: false,
        theme: _tema(store.corTema, Brightness.light),
        darkTheme: _tema(store.corTema, Brightness.dark),
        themeMode: store.darkMode ? ThemeMode.dark : ThemeMode.light,
        home: const ListagemScreen(),
      ),
    );
  }
}
