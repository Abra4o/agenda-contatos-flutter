import 'package:flutter/material.dart';

import '../store/agenda_store.dart';
import '../widgets/app_drawer.dart';
import '../widgets/contact_tile.dart';
import 'aniversarios_screen.dart';
import 'cadastro_screen.dart';

/// Tela de Listagem: todos os contatos, em ordem alfabética, com busca.
class ListagemScreen extends StatefulWidget {
  const ListagemScreen({super.key});

  @override
  State<ListagemScreen> createState() => _ListagemScreenState();
}

class _ListagemScreenState extends State<ListagemScreen> {
  final buscaController = TextEditingController();
  bool avisoFechado = false;

  @override
  void dispose() {
    buscaController.dispose();
    super.dispose();
  }

  /// Aviso no topo quando tem aniversário chegando.
  Widget avisoDeAniversario() {
    final lembretes = agenda.lembretes;
    if (lembretes.isEmpty || avisoFechado) return const SizedBox();

    String texto;
    if (lembretes.length == 1) {
      final dias = AgendaStore.diasAteAniversario(lembretes[0].aniversario!);
      String quando = 'em $dias dias';
      if (dias == 0) quando = 'hoje';
      if (dias == 1) quando = 'amanhã';
      texto = '${lembretes[0].nome} faz aniversário $quando!';
    } else {
      texto = '${lembretes.length} aniversários nos próximos ${agenda.diasLembrete} dias.';
    }

    return MaterialBanner(
      leading: const Icon(Icons.cake),
      content: Text(texto),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AniversariosScreen()),
            );
          },
          child: const Text('VER'),
        ),
        TextButton(
          onPressed: () {
            setState(() {
              avisoFechado = true;
            });
          },
          child: const Text('FECHAR'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: agenda,
      builder: (context, child) {
        final lista = agenda.buscar(buscaController.text);

        Widget conteudo;
        if (lista.isEmpty && buscaController.text.isEmpty) {
          conteudo = const EmptyState(
            icon: Icons.person_search,
            texto: 'Nenhum contato cadastrado.\nToque em + para adicionar.',
          );
        } else if (lista.isEmpty) {
          conteudo = const EmptyState(icon: Icons.person_search, texto: 'Nenhum contato encontrado.');
        } else {
          conteudo = ListView.builder(
            padding: const EdgeInsets.only(bottom: 88),
            itemCount: lista.length,
            itemBuilder: (context, index) {
              return ContactTile(contato: lista[index]);
            },
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Agenda de Contatos'),
            centerTitle: true,
          ),
          drawer: const AppDrawer(),
          body: Column(
            children: [
              avisoDeAniversario(),
              Padding(
                padding: const EdgeInsets.all(8),
                child: TextField(
                  controller: buscaController,
                  onChanged: (texto) {
                    setState(() {});
                  },
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Buscar por nome, e-mail ou telefone',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Text('${lista.length} contato(s)'),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () {
                        agenda.setOrdemCrescente(!agenda.ordemCrescente);
                      },
                      icon: const Icon(Icons.sort_by_alpha),
                      label: Text(agenda.ordemCrescente ? 'A-Z' : 'Z-A'),
                    ),
                  ],
                ),
              ),
              Expanded(child: conteudo),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            tooltip: 'Novo contato',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CadastroScreen()),
              );
            },
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}
