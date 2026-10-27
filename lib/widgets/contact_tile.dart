import 'package:flutter/material.dart';

import '../models/contact.dart';
import '../screens/detalhes_screen.dart';
import '../store/agenda_store.dart';
import 'contact_avatar.dart';

/// Item de lista de contato. Ao tocar, abre a tela de Detalhes.
class ContactTile extends StatelessWidget {
  final Contact contato;

  /// Botão da direita. Se não for informado, mostra a estrela de favorito.
  final Widget? botao;

  const ContactTile({super.key, required this.contato, this.botao});

  @override
  Widget build(BuildContext context) {
    // Texto de baixo: e-mail e telefone.
    String subtitulo = contato.email;
    if (agenda.mostrarTelefoneNaLista && contato.telefone.isNotEmpty) {
      if (subtitulo.isNotEmpty) subtitulo += '  •  ';
      subtitulo += contato.telefone;
    }

    Widget botaoDireita;
    if (botao != null) {
      botaoDireita = botao!;
    } else {
      botaoDireita = IconButton(
        tooltip: contato.favorito ? 'Remover dos favoritos' : 'Favoritar',
        icon: Icon(
          contato.favorito ? Icons.star : Icons.star_border,
          color: contato.favorito ? Colors.amber : null,
        ),
        onPressed: () {
          agenda.setFavorito(contato, !contato.favorito);
        },
      );
    }

    return ListTile(
      leading: ContactAvatar(contact: contato),
      title: Text(contato.nome),
      subtitle: subtitulo.isEmpty ? null : Text(subtitulo),
      trailing: botaoDireita,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => DetalhesScreen(contato: contato)),
        );
      },
    );
  }
}

/// Mensagem mostrada quando uma lista está vazia.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String texto;

  const EmptyState({super.key, required this.icon, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: Colors.grey),
            const SizedBox(height: 12),
            Text(texto, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
