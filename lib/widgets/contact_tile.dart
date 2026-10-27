import 'package:flutter/material.dart';

import '../models/contact.dart';
import '../screens/detalhes_screen.dart';
import '../store/agenda_store.dart';
import 'contact_avatar.dart';

/// Item de lista de contato; abre os Detalhes ao tocar.
class ContactTile extends StatelessWidget {
  final Contact contato;
  final Widget? trailing;

  const ContactTile({super.key, required this.contato, this.trailing});

  @override
  Widget build(BuildContext context) {
    final store = AgendaStore.instance;
    final sub = [
      contato.email,
      if (store.mostrarTelefoneNaLista) contato.telefone,
    ].where((s) => s.isNotEmpty).join('  •  ');

    return ListTile(
      leading: Hero(
        tag: 'avatar-${contato.id}',
        child: ContactAvatar(contact: contato),
      ),
      title: Text(contato.nome),
      subtitle: sub.isEmpty ? null : Text(sub),
      trailing: trailing ??
          IconButton(
            tooltip: contato.favorito ? 'Remover dos favoritos' : 'Favoritar',
            icon: Icon(
              contato.favorito ? Icons.star : Icons.star_border,
              color: contato.favorito ? Colors.amber : null,
            ),
            onPressed: () => store.setFavorito(contato.id, !contato.favorito),
          ),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DetalhesScreen(contatoId: contato.id)),
      ),
    );
  }
}

/// Mensagem para listas vazias.
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
            Icon(icon, size: 64, color: Theme.of(context).disabledColor),
            const SizedBox(height: 12),
            Text(texto, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
