import 'package:flutter/material.dart';

import '../models/contact.dart';
import '../models/group.dart';
import '../store/agenda_store.dart';
import '../widgets/contact_tile.dart';
import '../widgets/dialogos.dart';
import 'selecionar_contatos_screen.dart';

/// Tela de Grupos: lista os grupos e permite criar novos.
class GruposScreen extends StatelessWidget {
  const GruposScreen({super.key});

  Future<void> criar(BuildContext context) async {
    final nome = await pedirTexto(context, 'Novo grupo');
    if (nome != null) agenda.criarGrupo(nome);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: agenda,
      builder: (context, child) {
        Widget conteudo;
        if (agenda.grupos.isEmpty) {
          conteudo = const EmptyState(icon: Icons.group_outlined, texto: 'Nenhum grupo criado.');
        } else {
          conteudo = ListView.builder(
            padding: const EdgeInsets.only(bottom: 88),
            itemCount: agenda.grupos.length,
            itemBuilder: (context, index) {
              final grupo = agenda.grupos[index];
              return ListTile(
                leading: const CircleAvatar(child: Icon(Icons.group)),
                title: Text(grupo.nome),
                subtitle: Text('${agenda.membros(grupo).length} membro(s)'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => GrupoDetalheScreen(grupo: grupo)),
                  );
                },
              );
            },
          );
        }

        return Scaffold(
          appBar: AppBar(title: const Text('Grupos'), centerTitle: true),
          body: conteudo,
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => criar(context),
            icon: const Icon(Icons.group_add),
            label: const Text('Novo grupo'),
          ),
        );
      },
    );
  }
}

/// Membros de um grupo: adicionar e remover. Também renomeia e exclui o grupo.
class GrupoDetalheScreen extends StatelessWidget {
  final Group grupo;

  const GrupoDetalheScreen({super.key, required this.grupo});

  Future<void> adicionarMembros(BuildContext context) async {
    // Só mostra quem ainda não está no grupo.
    final foraDoGrupo = <Contact>[];
    for (final c in agenda.contatos) {
      if (!grupo.membros.contains(c.id)) foraDoGrupo.add(c);
    }

    if (foraDoGrupo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Todos os contatos já estão no grupo.')),
      );
      return;
    }

    final escolhidos = await selecionarContatos(context, 'Adicionar membros', foraDoGrupo);
    if (escolhidos == null) return;
    for (final c in escolhidos) {
      agenda.adicionarMembro(grupo, c);
    }
  }

  Future<void> renomear(BuildContext context) async {
    final nome = await pedirTexto(context, 'Renomear grupo', textoInicial: grupo.nome);
    if (nome != null) agenda.renomearGrupo(grupo, nome);
  }

  Future<void> excluir(BuildContext context) async {
    final ok = await confirmar(
      context,
      'Excluir grupo',
      'Excluir "${grupo.nome}"? Os contatos não serão apagados.',
      'Excluir',
    );
    if (ok && context.mounted) {
      agenda.excluirGrupo(grupo);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: agenda,
      builder: (context, child) {
        final membros = agenda.membros(grupo);

        Widget conteudo;
        if (membros.isEmpty) {
          conteudo = const EmptyState(icon: Icons.person_add_alt, texto: 'Grupo sem membros.');
        } else {
          conteudo = ListView.builder(
            padding: const EdgeInsets.only(bottom: 88),
            itemCount: membros.length,
            itemBuilder: (context, index) {
              final contato = membros[index];
              return ContactTile(
                contato: contato,
                botao: IconButton(
                  tooltip: 'Remover do grupo',
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: () {
                    agenda.removerMembro(grupo, contato);
                  },
                ),
              );
            },
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(grupo.nome),
            centerTitle: true,
            actions: [
              IconButton(
                tooltip: 'Renomear',
                icon: const Icon(Icons.edit),
                onPressed: () => renomear(context),
              ),
              IconButton(
                tooltip: 'Excluir grupo',
                icon: const Icon(Icons.delete),
                onPressed: () => excluir(context),
              ),
            ],
          ),
          body: conteudo,
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => adicionarMembros(context),
            icon: const Icon(Icons.person_add),
            label: const Text('Adicionar membros'),
          ),
        );
      },
    );
  }
}
