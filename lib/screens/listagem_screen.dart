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
  final _busca = TextEditingController();
  bool _bannerFechado = false;

  @override
  void dispose() {
    _busca.dispose();
    super.dispose();
  }

  String _quando(DateTime aniversario) {
    final d = AgendaStore.diasAteAniversario(aniversario);
    if (d == 0) return 'hoje';
    if (d == 1) return 'amanhã';
    return 'em $d dias';
  }

  @override
  Widget build(BuildContext context) {
    final store = AgendaStore.instance;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final lista = store.buscar(_busca.text);
        final lembretes = store.lembretes;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Agenda de Contatos'),
            centerTitle: true,
          ),
          drawer: const AppDrawer(),
          body: Column(
            children: [
              if (lembretes.isNotEmpty && !_bannerFechado)
                MaterialBanner(
                  leading: const Icon(Icons.cake),
                  content: Text(
                    lembretes.length == 1
                        ? '${lembretes.first.nome} faz aniversário ${_quando(lembretes.first.aniversario!)}!'
                        : '${lembretes.length} aniversários nos próximos ${store.diasLembrete} dias.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AniversariosScreen()),
                      ),
                      child: const Text('VER'),
                    ),
                    TextButton(
                      onPressed: () => setState(() => _bannerFechado = true),
                      child: const Text('FECHAR'),
                    ),
                  ],
                ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: TextField(
                  controller: _busca,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: 'Buscar por nome, e-mail ou telefone',
                    border: const OutlineInputBorder(),
                    isDense: true,
                    suffixIcon: _busca.text.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => setState(_busca.clear),
                          ),
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
                      onPressed: () => store.setOrdemCrescente(!store.ordemCrescente),
                      icon: const Icon(Icons.sort_by_alpha),
                      label: Text(store.ordemCrescente ? 'A-Z' : 'Z-A'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: lista.isEmpty
                    ? EmptyState(
                        icon: Icons.person_search,
                        texto: _busca.text.isEmpty
                            ? 'Nenhum contato cadastrado.\nToque em + para adicionar.'
                            : 'Nenhum contato encontrado.',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.only(bottom: 88),
                        itemCount: lista.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (_, i) => ContactTile(contato: lista[i]),
                      ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            tooltip: 'Novo contato',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CadastroScreen()),
            ),
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}
