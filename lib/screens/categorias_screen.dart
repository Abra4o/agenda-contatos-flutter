import 'package:flutter/material.dart';

import '../store/agenda_store.dart';
import '../widgets/contact_avatar.dart';
import '../widgets/contact_picker_dialog.dart';
import '../widgets/contact_tile.dart';

/// Tela de Categorias: cria categorias e associa contatos (um contato pode ter várias).
class CategoriasScreen extends StatelessWidget {
  const CategoriasScreen({super.key});

  static const _icones = {
    'Família': Icons.family_restroom,
    'Amigos': Icons.people,
    'Trabalho': Icons.work,
    'Clientes': Icons.storefront,
  };

  Future<void> _criar(BuildContext context) async {
    final nome = await showTextDialog(context, titulo: 'Nova categoria', confirmar: 'Criar');
    if (nome == null || !context.mounted) return;
    if (!AgendaStore.instance.criarCategoria(nome)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('A categoria "$nome" já existe.')),
      );
    }
  }

  Future<void> _associar(BuildContext context, String cat) async {
    final store = AgendaStore.instance;
    final atuais = store.contatosDaCategoria(cat).map((c) => c.id).toSet();
    final escolhidos = await showContactPicker(
      context,
      titulo: 'Contatos em "$cat"',
      contatos: store.contatos,
      selecionados: atuais,
      confirmar: 'Salvar',
    );
    if (escolhidos == null) return;
    for (final c in store.contatos) {
      final dentro = escolhidos.contains(c.id);
      if (dentro != atuais.contains(c.id)) store.setCategoria(c.id, cat, dentro);
    }
  }

  Future<void> _excluir(BuildContext context, String cat) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir categoria'),
        content: Text('Excluir "$cat"? Os contatos não serão apagados.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Excluir')),
        ],
      ),
    );
    if (ok == true) AgendaStore.instance.excluirCategoria(cat);
  }

  @override
  Widget build(BuildContext context) {
    final store = AgendaStore.instance;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('Categorias'), centerTitle: true),
          body: store.categorias.isEmpty
              ? const EmptyState(icon: Icons.label_outline, texto: 'Nenhuma categoria.')
              : ListView(
                  padding: const EdgeInsets.only(bottom: 88),
                  children: [
                    for (final cat in store.categorias)
                      _CategoriaCard(
                        categoria: cat,
                        icone: _icones[cat] ?? Icons.label,
                        onAssociar: () => _associar(context, cat),
                        onExcluir: () => _excluir(context, cat),
                      ),
                  ],
                ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _criar(context),
            icon: const Icon(Icons.add),
            label: const Text('Nova categoria'),
          ),
        );
      },
    );
  }
}

class _CategoriaCard extends StatelessWidget {
  final String categoria;
  final IconData icone;
  final VoidCallback onAssociar;
  final VoidCallback onExcluir;

  const _CategoriaCard({
    required this.categoria,
    required this.icone,
    required this.onAssociar,
    required this.onExcluir,
  });

  @override
  Widget build(BuildContext context) {
    final contatos = AgendaStore.instance.contatosDaCategoria(categoria);
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: ExpansionTile(
        leading: Icon(icone),
        title: Text(categoria),
        subtitle: Text('${contatos.length} contato(s)'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Associar contatos',
              icon: const Icon(Icons.person_add),
              onPressed: onAssociar,
            ),
            IconButton(
              tooltip: 'Excluir categoria',
              icon: const Icon(Icons.delete_outline),
              onPressed: onExcluir,
            ),
          ],
        ),
        children: [
          if (contatos.isEmpty)
            const ListTile(title: Text('Nenhum contato nesta categoria.')),
          for (final c in contatos)
            ListTile(
              leading: ContactAvatar(contact: c, radius: 16),
              title: Text(c.nome),
              trailing: IconButton(
                tooltip: 'Remover da categoria',
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: () => AgendaStore.instance.setCategoria(c.id, categoria, false),
              ),
            ),
        ],
      ),
    );
  }
}
