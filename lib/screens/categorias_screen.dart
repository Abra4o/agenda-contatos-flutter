import 'package:flutter/material.dart';

import '../store/agenda_store.dart';
import '../widgets/contact_avatar.dart';
import '../widgets/contact_tile.dart';
import '../widgets/dialogos.dart';
import 'selecionar_contatos_screen.dart';

/// Tela de Categorias: cria categorias e associa contatos (um contato pode ter várias).
class CategoriasScreen extends StatelessWidget {
  const CategoriasScreen({super.key});

  /// Ícone de cada categoria padrão. As novas usam um ícone de etiqueta.
  IconData iconeDaCategoria(String categoria) {
    if (categoria == 'Família') return Icons.family_restroom;
    if (categoria == 'Amigos') return Icons.people;
    if (categoria == 'Trabalho') return Icons.work;
    if (categoria == 'Clientes') return Icons.storefront;
    return Icons.label;
  }

  Future<void> criar(BuildContext context) async {
    final nome = await pedirTexto(context, 'Nova categoria');
    if (nome == null || !context.mounted) return;

    final criou = agenda.criarCategoria(nome);
    if (!criou) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('A categoria "$nome" já existe.')),
      );
    }
  }

  /// Abre a lista de contatos para marcar quem faz parte da categoria.
  Future<void> associar(BuildContext context, String categoria) async {
    final escolhidos = await selecionarContatos(
      context,
      'Contatos em "$categoria"',
      agenda.contatos,
      jaMarcados: agenda.contatosDaCategoria(categoria),
    );
    if (escolhidos == null) return;

    for (final c in agenda.contatos) {
      if (escolhidos.contains(c)) {
        agenda.colocarNaCategoria(c, categoria);
      } else {
        agenda.tirarDaCategoria(c, categoria);
      }
    }
  }

  Future<void> excluir(BuildContext context, String categoria) async {
    final ok = await confirmar(
      context,
      'Excluir categoria',
      'Excluir "$categoria"? Os contatos não serão apagados.',
      'Excluir',
    );
    if (ok) agenda.excluirCategoria(categoria);
  }

  /// Card de uma categoria, que abre para mostrar os contatos dela.
  Widget cardDaCategoria(BuildContext context, String categoria) {
    final contatos = agenda.contatosDaCategoria(categoria);

    final linhas = <Widget>[];
    if (contatos.isEmpty) {
      linhas.add(const ListTile(title: Text('Nenhum contato nesta categoria.')));
    }
    for (final c in contatos) {
      linhas.add(ListTile(
        leading: ContactAvatar(contact: c, radius: 16),
        title: Text(c.nome),
        trailing: IconButton(
          tooltip: 'Remover da categoria',
          icon: const Icon(Icons.remove_circle_outline),
          onPressed: () {
            agenda.tirarDaCategoria(c, categoria);
          },
        ),
      ));
    }

    return Card(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: ExpansionTile(
        leading: Icon(iconeDaCategoria(categoria)),
        title: Text(categoria),
        subtitle: Text('${contatos.length} contato(s)'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Associar contatos',
              icon: const Icon(Icons.person_add),
              onPressed: () => associar(context, categoria),
            ),
            IconButton(
              tooltip: 'Excluir categoria',
              icon: const Icon(Icons.delete_outline),
              onPressed: () => excluir(context, categoria),
            ),
          ],
        ),
        children: linhas,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: agenda,
      builder: (context, child) {
        Widget conteudo;
        if (agenda.categorias.isEmpty) {
          conteudo = const EmptyState(icon: Icons.label_outline, texto: 'Nenhuma categoria.');
        } else {
          conteudo = ListView.builder(
            padding: const EdgeInsets.only(bottom: 88),
            itemCount: agenda.categorias.length,
            itemBuilder: (context, index) {
              return cardDaCategoria(context, agenda.categorias[index]);
            },
          );
        }

        return Scaffold(
          appBar: AppBar(title: const Text('Categorias'), centerTitle: true),
          body: conteudo,
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => criar(context),
            icon: const Icon(Icons.add),
            label: const Text('Nova categoria'),
          ),
        );
      },
    );
  }
}
