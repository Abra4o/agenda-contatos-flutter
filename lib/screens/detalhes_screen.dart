import 'package:flutter/material.dart';

import '../models/contact.dart';
import '../store/agenda_store.dart';
import '../widgets/contact_avatar.dart';
import '../widgets/dialogos.dart';
import 'edicao_screen.dart';

/// Tela de Detalhes: mostra tudo do contato e tem os botões de editar e excluir.
class DetalhesScreen extends StatelessWidget {
  final Contact contato;

  const DetalhesScreen({super.key, required this.contato});

  void editar(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EdicaoScreen(contato: contato)),
    );
  }

  Future<void> excluir(BuildContext context) async {
    final ok = await confirmar(
      context,
      'Excluir contato',
      'Deseja excluir "${contato.nome}"? Essa ação não pode ser desfeita.',
      'Excluir',
    );
    if (!ok || !context.mounted) return;

    agenda.excluir(contato);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${contato.nome} excluído')),
    );
    Navigator.pop(context);
  }

  /// Uma linha de informação. Se o valor estiver vazio, não mostra nada.
  Widget linhaInfo(IconData icone, String rotulo, String valor) {
    if (valor.isEmpty) return const SizedBox();
    return ListTile(
      leading: Icon(icone),
      title: SelectableText(valor),
      subtitle: Text(rotulo),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: agenda,
      builder: (context, child) {
        // Nomes dos grupos de que o contato participa.
        final nomesGrupos = <String>[];
        for (final g in agenda.grupos) {
          if (g.membros.contains(contato.id)) nomesGrupos.add(g.nome);
        }

        String aniversario = '';
        if (contato.aniversario != null) {
          aniversario = formatarData(contato.aniversario!);
        }

        String observacoes = contato.observacoes;
        if (observacoes.isEmpty) observacoes = 'Sem observações';

        return Scaffold(
          appBar: AppBar(
            title: const Text('Detalhes do Contato'),
            centerTitle: true,
            actions: [
              IconButton(
                tooltip: contato.favorito ? 'Remover dos favoritos' : 'Favoritar',
                icon: Icon(contato.favorito ? Icons.star : Icons.star_border),
                onPressed: () {
                  agenda.setFavorito(contato, !contato.favorito);
                },
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(vertical: 24),
            children: [
              Center(child: ContactAvatar(contact: contato, radius: 60)),
              const SizedBox(height: 12),
              Center(
                child: Text(contato.nome, style: const TextStyle(fontSize: 24)),
              ),
              const SizedBox(height: 8),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 6,
                children: [
                  for (final cat in contato.categorias) Chip(label: Text(cat)),
                ],
              ),
              const Divider(),
              linhaInfo(Icons.phone, 'Telefone', contato.telefone),
              linhaInfo(Icons.email, 'E-mail', contato.email),
              linhaInfo(Icons.location_city, 'Cidade', contato.cidade),
              linhaInfo(Icons.business, 'Empresa', contato.empresa),
              linhaInfo(Icons.cake, 'Aniversário', aniversario),
              linhaInfo(Icons.group, 'Grupos', nomesGrupos.join(', ')),
              linhaInfo(Icons.notes, 'Observações', observacoes),
              linhaInfo(Icons.event, 'Cadastrado em', formatarData(contato.dataCadastro)),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => excluir(context),
                        icon: const Icon(Icons.delete, color: Colors.red),
                        label: const Text('Excluir'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => editar(context),
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
