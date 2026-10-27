import 'package:flutter/material.dart';

import '../store/agenda_store.dart';
import '../widgets/contact_picker_dialog.dart';
import '../widgets/contact_tile.dart';

/// Tela de Favoritos: lista e permite adicionar/remover.
class FavoritosScreen extends StatelessWidget {
  const FavoritosScreen({super.key});

  Future<void> _adicionar(BuildContext context) async {
    final store = AgendaStore.instance;
    final candidatos = store.contatos.where((c) => !c.favorito).toList();
    if (candidatos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Todos os contatos já são favoritos.')),
      );
      return;
    }
    final escolhidos = await showContactPicker(
      context,
      titulo: 'Adicionar aos favoritos',
      contatos: candidatos,
    );
    for (final id in escolhidos ?? const <String>{}) {
      store.setFavorito(id, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = AgendaStore.instance;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final favs = store.favoritos;
        return Scaffold(
          appBar: AppBar(title: const Text('Favoritos'), centerTitle: true),
          body: favs.isEmpty
              ? const EmptyState(icon: Icons.star_border, texto: 'Nenhum favorito ainda.')
              : ListView.separated(
                  padding: const EdgeInsets.only(bottom: 88),
                  itemCount: favs.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, i) => ContactTile(
                    contato: favs[i],
                    trailing: IconButton(
                      tooltip: 'Remover dos favoritos',
                      icon: const Icon(Icons.star, color: Colors.amber),
                      onPressed: () => store.setFavorito(favs[i].id, false),
                    ),
                  ),
                ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _adicionar(context),
            icon: const Icon(Icons.star),
            label: const Text('Adicionar'),
          ),
        );
      },
    );
  }
}
