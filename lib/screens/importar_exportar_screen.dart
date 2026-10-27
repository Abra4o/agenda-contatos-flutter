import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/contact.dart';
import '../store/agenda_store.dart';
import '../widgets/contact_avatar.dart';

/// Tela de Importação e Exportação (CSV ou texto colado do Excel).
class ImportarExportarScreen extends StatelessWidget {
  const ImportarExportarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Importar / Exportar'),
          centerTitle: true,
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.file_download), text: 'Importar'),
              Tab(icon: Icon(Icons.file_upload), text: 'Exportar'),
            ],
          ),
        ),
        body: const TabBarView(children: [_ImportarTab(), _ExportarTab()]),
      ),
    );
  }
}

class _ImportarTab extends StatefulWidget {
  const _ImportarTab();

  @override
  State<_ImportarTab> createState() => _ImportarTabState();
}

class _ImportarTabState extends State<_ImportarTab> {
  final _texto = TextEditingController();
  List<Contact> _previa = [];

  @override
  void dispose() {
    _texto.dispose();
    super.dispose();
  }

  Future<void> _colar() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) {
      _texto.text = data!.text!;
      _analisar();
    }
  }

  void _analisar() => setState(() => _previa = AgendaStore.instance.lerCsv(_texto.text));

  void _importar() {
    final n = _previa.length;
    AgendaStore.instance.importar(_previa);
    setState(() {
      _previa = [];
      _texto.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$n contato(s) importado(s).')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Cole abaixo o conteúdo de um arquivo CSV (separado por ; ou ,) ou as células '
          'copiadas de uma planilha do Excel. A primeira coluna deve ser o nome.',
        ),
        const SizedBox(height: 4),
        Text(
          'Colunas: ${Contact.csvHeader.join(' ; ')}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _texto,
          minLines: 6,
          maxLines: 12,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'nome;email;telefone;cidade;empresa;aniversario;categorias;observacoes\n'
                'João Silva;joao@email.com;(11) 91234-5678;Campinas;ACME;10/05/1990;Amigos;',
          ),
          onChanged: (_) => _analisar(),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: _colar,
              icon: const Icon(Icons.content_paste),
              label: const Text('Colar da área de transferência'),
            ),
            FilledButton.icon(
              onPressed: _previa.isEmpty ? null : _importar,
              icon: const Icon(Icons.download_done),
              label: Text('Importar ${_previa.length} contato(s)'),
            ),
          ],
        ),
        if (_previa.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('Prévia', style: Theme.of(context).textTheme.titleSmall),
          for (final c in _previa)
            ListTile(
              dense: true,
              leading: ContactAvatar(contact: c, radius: 16),
              title: Text(c.nome),
              subtitle: Text([c.email, c.telefone].where((s) => s.isNotEmpty).join('  •  ')),
            ),
        ],
      ],
    );
  }
}

class _ExportarTab extends StatelessWidget {
  const _ExportarTab();

  @override
  Widget build(BuildContext context) {
    final store = AgendaStore.instance;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final csv = store.exportarCsv();
        final excel = store.exportarCsv(separador: '\t');
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('${store.contatos.length} contato(s) para exportar.'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: csv));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('CSV copiado. Cole num arquivo .csv para guardar o backup.')),
                      );
                    }
                  },
                  icon: const Icon(Icons.copy),
                  label: const Text('Copiar CSV'),
                ),
                OutlinedButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: excel));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Copiado. Cole direto numa planilha do Excel.')),
                      );
                    }
                  },
                  icon: const Icon(Icons.table_chart),
                  label: const Text('Copiar para Excel'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).dividerColor),
                borderRadius: BorderRadius.circular(4),
              ),
              child: SelectableText(
                csv,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
              ),
            ),
          ],
        );
      },
    );
  }
}
