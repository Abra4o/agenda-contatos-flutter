import 'package:flutter/material.dart';

import '../screens/aniversarios_screen.dart';
import '../screens/categorias_screen.dart';
import '../screens/configuracoes_screen.dart';
import '../screens/favoritos_screen.dart';
import '../screens/grupos_screen.dart';
import '../screens/importar_exportar_screen.dart';
import '../screens/pesquisa_avancada_screen.dart';

/// Menu lateral com as telas da agenda.
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    void abrir(Widget tela) {
      Navigator.pop(context);
      Navigator.push(context, MaterialPageRoute(builder: (_) => tela));
    }

    final cor = Theme.of(context).colorScheme;
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: cor.primary),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Text(
                'Agenda de Contatos',
                style: TextStyle(color: cor.onPrimary, fontSize: 22),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.contacts),
            title: const Text('Contatos'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.star),
            title: const Text('Favoritos'),
            onTap: () => abrir(const FavoritosScreen()),
          ),
          ListTile(
            leading: const Icon(Icons.label),
            title: const Text('Categorias'),
            onTap: () => abrir(const CategoriasScreen()),
          ),
          ListTile(
            leading: const Icon(Icons.group),
            title: const Text('Grupos'),
            onTap: () => abrir(const GruposScreen()),
          ),
          ListTile(
            leading: const Icon(Icons.cake),
            title: const Text('Aniversários'),
            onTap: () => abrir(const AniversariosScreen()),
          ),
          ListTile(
            leading: const Icon(Icons.manage_search),
            title: const Text('Pesquisa Avançada'),
            onTap: () => abrir(const PesquisaAvancadaScreen()),
          ),
          ListTile(
            leading: const Icon(Icons.import_export),
            title: const Text('Importar / Exportar'),
            onTap: () => abrir(const ImportarExportarScreen()),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Configurações'),
            onTap: () => abrir(const ConfiguracoesScreen()),
          ),
        ],
      ),
    );
  }
}
