import 'package:flutter/material.dart';

import '../models/group.dart';
import '../store/agenda_store.dart';
import '../widgets/contact_picker_dialog.dart';
import '../widgets/contact_tile.dart';

/// Tela de Grupos: cria, renomeia e exclui grupos.
class GruposScreen extends StatelessWidget {
  const GruposScreen({super.key});

  Future<void> _criar(BuildContext context) async {
    final nome = await showTextDialog(context, titulo: 'Novo grupo', confirmar: 'Criar');
    if (nome != null) AgendaStore.instance.criarGrupo(nome);
  }

  @override
  Widget build(BuildContext context) {
    final store = AgendaStore.instance;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('Grupos'), centerTitle: true),
          body: store.grupos.isEmpty
              ? const EmptyState(icon: Icons.group_outlined, texto: 'Nenhum grupo criado.')
              : ListView.separated(
                  padding: const EdgeInsets.only(bottom: 88),
                  itemCount: store.grupos.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final g = store.grupos[i];
                    return ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.group)),
                      title: Text(g.nome),
                      subtitle: Text('${store.membros(g).length} membro(s)'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => GrupoDetalheScreen(grupo: g)),
                      ),
                    );
                  },
                ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _criar(context),
            icon: const Icon(Icons.group_add),
            label: const Text('Novo grupo'),
          ),
        );
      },
    );
  }
}

/// Membros de um grupo: adicionar e remover.
class GrupoDetalheScreen extends StatelessWidget {
  final Group grupo;

  const GrupoDetalheScreen({super.key, required this.grupo});

  Future<void> _adicionar(BuildContext context) async {
    final store = AgendaStore.instance;
    final fora = store.contatos.where((c) => !grupo.memberIds.contains(c.id)).toList();
    if (fora.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Todos os contatos já estão no grupo.')),
      );
      return;
    }
    final escolhidos = await showContactPicker(
      context,
      titulo: 'Adicionar membros',
      contatos: fora,
      confirmar: 'Adicionar',
    );
    for (final id in escolhidos ?? const <String>{}) {
      store.setMembro(grupo, id, true);
    }
  }

  Future<void> _renomear(BuildContext context) async {
    final nome = await showTextDialog(context, titulo: 'Renomear grupo', inicial: grupo.nome);
    if (nome != null) AgendaStore.instance.renomearGrupo(grupo, nome);
  }

  Future<void> _excluir(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir grupo'),
        content: Text('Excluir "${grupo.nome}"? Os contatos não serão apagados.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Excluir')),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      Navigator.pop(context);
      AgendaStore.instance.excluirGrupo(grupo);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = AgendaStore.instance;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final membros = store.membros(grupo);
        return Scaffold(
          appBar: AppBar(
            title: Text(grupo.nome),
            centerTitle: true,
            actions: [
              IconButton(
                tooltip: 'Renomear',
                icon: const Icon(Icons.edit),
                onPressed: () => _renomear(context),
              ),
              IconButton(
                tooltip: 'Excluir grupo',
                icon: const Icon(Icons.delete),
                onPressed: () => _excluir(context),
              ),
            ],
          ),
          body: membros.isEmpty
              ? const EmptyState(icon: Icons.person_add_alt, texto: 'Grupo sem membros.')
              : ListView.separated(
                  padding: const EdgeInsets.only(bottom: 88),
                  itemCount: membros.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, i) => ContactTile(
                    contato: membros[i],
                    trailing: IconButton(
                      tooltip: 'Remover do grupo',
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: () => store.setMembro(grupo, membros[i].id, false),
                    ),
                  ),
                ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _adicionar(context),
            icon: const Icon(Icons.person_add),
            label: const Text('Adicionar membros'),
          ),
        );
      },
    );
  }
}
