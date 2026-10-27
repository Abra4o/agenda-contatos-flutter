import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/contact.dart';
import '../services/plataforma.dart';
import '../store/agenda_store.dart';
import '../widgets/contact_avatar.dart';

/// Tela de Importação e Exportação (arquivo CSV ou texto copiado do Excel).
class ImportarExportarScreen extends StatelessWidget {
  const ImportarExportarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // DefaultTabController controla as duas abas: Importar e Exportar.
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Importar / Exportar'),
          centerTitle: true,
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(icon: Icon(Icons.file_download), text: 'Importar'),
              Tab(icon: Icon(Icons.file_upload), text: 'Exportar'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [ImportarAba(), ExportarAba()],
        ),
      ),
    );
  }
}

/// Aba de importar: escolhe um arquivo ou cola o texto, mostra a prévia e importa.
class ImportarAba extends StatefulWidget {
  const ImportarAba({super.key});

  @override
  State<ImportarAba> createState() => _ImportarAbaState();
}

class _ImportarAbaState extends State<ImportarAba> {
  final textoController = TextEditingController();

  // Contatos lidos do texto, antes de importar.
  List<Contact> previa = [];

  @override
  void dispose() {
    textoController.dispose();
    super.dispose();
  }

  /// Lê o texto da caixa e atualiza a prévia.
  void lerTexto() {
    setState(() {
      previa = agenda.lerCsv(textoController.text);
    });
  }

  Future<void> abrirArquivo() async {
    final texto = await escolherArquivoCsv();
    if (texto == null) return;
    textoController.text = texto;
    lerTexto();
  }

  Future<void> colar() async {
    final dados = await Clipboard.getData(Clipboard.kTextPlain);
    if (dados != null && dados.text != null) {
      textoController.text = dados.text!;
      lerTexto();
    }
  }

  void importar() {
    final quantidade = previa.length;
    agenda.importar(previa);
    setState(() {
      previa = [];
      textoController.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$quantidade contato(s) importado(s).')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Escolha um arquivo CSV ou cole abaixo o conteúdo do arquivo (ou as células '
          'copiadas do Excel). A primeira coluna deve ser o nome. Para planilhas do '
          'Excel (.xlsx), use "Salvar como > CSV" no Excel antes.',
        ),
        const SizedBox(height: 4),
        Text(
          'Colunas: ${colunasCsv.join(' ; ')}',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: textoController,
          minLines: 6,
          maxLines: 12,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'nome;email;telefone;cidade;empresa;aniversario;categorias;observacoes;favorito\n'
                'João Silva;joao@email.com;(11) 91234-5678;Campinas;ACME;10/05/1990;Amigos;;sim',
          ),
          onChanged: (texto) {
            lerTexto();
          },
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (suportaArquivos)
              OutlinedButton.icon(
                onPressed: abrirArquivo,
                icon: const Icon(Icons.folder_open),
                label: const Text('Escolher arquivo CSV'),
              ),
            OutlinedButton.icon(
              onPressed: colar,
              icon: const Icon(Icons.content_paste),
              label: const Text('Colar'),
            ),
            FilledButton.icon(
              onPressed: previa.isEmpty ? null : importar,
              icon: const Icon(Icons.download_done),
              label: Text('Importar ${previa.length} contato(s)'),
            ),
          ],
        ),
        if (previa.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text('Prévia', style: TextStyle(fontWeight: FontWeight.bold)),
          for (final c in previa)
            ListTile(
              dense: true,
              leading: ContactAvatar(contact: c, radius: 16),
              title: Text(c.nome),
              subtitle: Text('${c.email}  ${c.telefone}'),
            ),
        ],
      ],
    );
  }
}

/// Aba de exportar: baixa o arquivo CSV ou copia o texto.
class ExportarAba extends StatelessWidget {
  const ExportarAba({super.key});

  void mostrarMensagem(BuildContext context, String texto) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  Future<void> copiar(BuildContext context, String texto, String mensagem) async {
    await Clipboard.setData(ClipboardData(text: texto));
    if (context.mounted) mostrarMensagem(context, mensagem);
  }

  void baixar() {
    final hoje = DateTime.now();
    final nome = 'contatos_${hoje.year}-${doisDigitos(hoje.month)}-${doisDigitos(hoje.day)}.csv';
    // O caractere ﻿ no começo faz o Excel entender os acentos.
    baixarArquivo(nome, '﻿${agenda.exportarCsv()}');
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: agenda,
      builder: (context, child) {
        final csv = agenda.exportarCsv();
        // Separado por tab, para colar direto nas células do Excel.
        final paraExcel = agenda.exportarCsv(separador: '\t');

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('${agenda.contatos.length} contato(s) para exportar.'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (suportaArquivos)
                  FilledButton.icon(
                    onPressed: baixar,
                    icon: const Icon(Icons.download),
                    label: const Text('Baixar arquivo CSV'),
                  ),
                OutlinedButton.icon(
                  onPressed: () => copiar(context, csv, 'CSV copiado.'),
                  icon: const Icon(Icons.copy),
                  label: const Text('Copiar CSV'),
                ),
                OutlinedButton.icon(
                  onPressed: () => copiar(context, paraExcel, 'Copiado. Cole direto numa planilha do Excel.'),
                  icon: const Icon(Icons.table_chart),
                  label: const Text('Copiar para Excel'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(4),
              ),
              child: SelectableText(csv),
            ),
          ],
        );
      },
    );
  }
}
