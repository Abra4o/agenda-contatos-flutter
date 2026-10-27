import 'package:flutter/material.dart';

import '../models/contact.dart';
import '../store/agenda_store.dart';
import '../widgets/contact_tile.dart';
import 'selecionar_contatos_screen.dart';

/// Tela de Favoritos: lista os favoritos e permite adicionar/remover.
class FavoritosScreen extends StatelessWidget {
  const FavoritosScreen({super.key});

  Future<void> adicionar(BuildContext context) async {
    // Só mostra quem ainda não é favorito.
    final naoFavoritos = <Contact>[];
    for (final c in agenda.contatos) {
      if (!c.favorito) naoFavoritos.add(c);
    }

    if (naoFavoritos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Todos os contatos já são favoritos.')),
      );
      return;
    }

    final escolhidos = await selecionarContatos(context, 'Adicionar aos favoritos', naoFavoritos);
    if (escolhidos == null) return;
    for (final c in escolhidos) {
      agenda.setFavorito(c, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: agenda,
      builder: (context, child) {
        final favoritos = agenda.favoritos;

        Widget conteudo;
        if (favoritos.isEmpty) {
          conteudo = const EmptyState(icon: Icons.star_border, texto: 'Nenhum favorito ainda.');
        } else {
          conteudo = ListView.builder(
            padding: const EdgeInsets.only(bottom: 88),
            itemCount: favoritos.length,
            itemBuilder: (context, index) {
              final contato = favoritos[index];
              return ContactTile(
                contato: contato,
                botao: IconButton(
                  tooltip: 'Remover dos favoritos',
                  icon: const Icon(Icons.star, color: Colors.amber),
                  onPressed: () {
                    agenda.setFavorito(contato, false);
                  },
                ),
              );
            },
          );
        }

        return Scaffold(
          appBar: AppBar(title: const Text('Favoritos'), centerTitle: true),
          body: conteudo,
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => adicionar(context),
            icon: const Icon(Icons.star),
            label: const Text('Adicionar'),
          ),
        );
      },
    );
  }
}
