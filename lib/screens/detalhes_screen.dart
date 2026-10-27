import 'package:flutter/material.dart';

import '../models/contact.dart';
import '../store/agenda_store.dart';
import '../widgets/contact_avatar.dart';
import 'edicao_screen.dart';

/// Tela de Detalhes: informações completas, editar e excluir.
class DetalhesScreen extends StatelessWidget {
  final String contatoId;

  const DetalhesScreen({super.key, required this.contatoId});

  void _editar(BuildContext context, Contact c) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EdicaoScreen(contato: c)),
    );
  }

  Future<void> _excluir(BuildContext context, Contact c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir contato'),
        content: Text('Deseja excluir "${c.nome}"? Essa ação não pode ser desfeita.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      AgendaStore.instance.excluir(c.id);
      messenger.showSnackBar(SnackBar(content: Text('${c.nome} excluído')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = AgendaStore.instance;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final c = store.byId(contatoId);
        if (c == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Contato não encontrado')),
          );
        }
        final grupos = store.grupos
            .where((g) => g.memberIds.contains(c.id))
            .map((g) => g.nome)
            .join(', ');

        Widget info(IconData icon, String label, String valor) {
          if (valor.isEmpty) return const SizedBox.shrink();
          return ListTile(
            leading: Icon(icon),
            title: SelectableText(valor),
            subtitle: Text(label),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Detalhes do Contato'),
            centerTitle: true,
            actions: [
              IconButton(
                tooltip: c.favorito ? 'Remover dos favoritos' : 'Favoritar',
                icon: Icon(c.favorito ? Icons.star : Icons.star_border),
                onPressed: () => store.setFavorito(c.id, !c.favorito),
              ),
              IconButton(
                tooltip: 'Editar',
                icon: const Icon(Icons.edit),
                onPressed: () => _editar(context, c),
              ),
              IconButton(
                tooltip: 'Excluir',
                icon: const Icon(Icons.delete),
                onPressed: () => _excluir(context, c),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(vertical: 24),
            children: [
              Center(
                child: Hero(
                  tag: 'avatar-${c.id}',
                  child: ContactAvatar(contact: c, radius: 60),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(c.nome, style: Theme.of(context).textTheme.headlineSmall),
              ),
              if (c.categorias.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 6,
                    children: [for (final cat in c.categorias) Chip(label: Text(cat))],
                  ),
                ),
              const SizedBox(height: 12),
              const Divider(),
              info(Icons.phone, 'Telefone', c.telefone),
              info(Icons.email, 'E-mail', c.email),
              info(Icons.location_city, 'Cidade', c.cidade),
              info(Icons.business, 'Empresa', c.empresa),
              info(Icons.cake, 'Aniversário',
                  c.aniversario == null ? '' : formatDate(c.aniversario!)),
              info(Icons.group, 'Grupos', grupos),
              info(Icons.notes, 'Observações',
                  c.observacoes.isEmpty ? 'Sem observações' : c.observacoes),
              info(Icons.event, 'Cadastrado em', formatDate(c.dataCadastro)),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _excluir(context, c),
                        icon: const Icon(Icons.delete, color: Colors.red),
                        label: const Text('Excluir'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => _editar(context, c),
                        icon: const Icon(Icons.edit),
                        label: const Text('Editar'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
