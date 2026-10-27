import 'package:flutter/material.dart';

import '../models/contact.dart';
import '../services/plataforma.dart';
import '../store/agenda_store.dart';
import 'contact_avatar.dart';
import 'dialogos.dart';

/// Cores que o usuário pode escolher para o avatar.
const coresAvatar = [
  Colors.red,
  Colors.pink,
  Colors.purple,
  Colors.indigo,
  Colors.blue,
  Colors.teal,
  Colors.green,
  Colors.orange,
  Colors.brown,
  Colors.blueGrey,
];

/// Formulário usado no Cadastro (contato == null) e na Edição (contato != null).
class ContactForm extends StatefulWidget {
  final Contact? contato;

  const ContactForm({super.key, this.contato});

  @override
  State<ContactForm> createState() => _ContactFormState();
}

class _ContactFormState extends State<ContactForm> {
  final formKey = GlobalKey<FormState>();

  final nomeController = TextEditingController();
  final emailController = TextEditingController();
  final telefoneController = TextEditingController();
  final cidadeController = TextEditingController();
  final empresaController = TextEditingController();
  final observacoesController = TextEditingController();

  String fotoUrl = '';
  Color corAvatar = Colors.red;
  DateTime? aniversario;
  List<String> categorias = [];
  bool favorito = false;

  bool get editando => widget.contato != null;

  @override
  void initState() {
    super.initState();
    // Na edição, preenche os campos com os dados do contato.
    final c = widget.contato;
    if (c != null) {
      nomeController.text = c.nome;
      emailController.text = c.email;
      telefoneController.text = c.telefone;
      cidadeController.text = c.cidade;
      empresaController.text = c.empresa;
      observacoesController.text = c.observacoes;
      fotoUrl = c.fotoUrl;
      corAvatar = c.corAvatar;
      aniversario = c.aniversario;
      categorias = List<String>.from(c.categorias);
      favorito = c.favorito;
    }
  }

  @override
  void dispose() {
    nomeController.dispose();
    emailController.dispose();
    telefoneController.dispose();
    cidadeController.dispose();
    empresaController.dispose();
    observacoesController.dispose();
    super.dispose();
  }

  /// Contato com o que está digitado agora (usado para mostrar a prévia da foto).
  Contact contatoDaTela() {
    return Contact(
      id: '',
      nome: nomeController.text,
      fotoUrl: fotoUrl,
      corAvatar: corAvatar,
    );
  }

  void salvar() {
    // Valida os campos (nome obrigatório, e-mail válido).
    if (!formKey.currentState!.validate()) return;

    Contact contato;
    if (editando) {
      contato = widget.contato!;
    } else {
      contato = Contact(id: '', nome: '');
    }

    contato.nome = nomeController.text.trim();
    contato.email = emailController.text.trim();
    contato.telefone = telefoneController.text.trim();
    contato.cidade = cidadeController.text.trim();
    contato.empresa = empresaController.text.trim();
    contato.observacoes = observacoesController.text.trim();
    contato.fotoUrl = fotoUrl;
    contato.corAvatar = corAvatar;
    contato.aniversario = aniversario;
    contato.categorias = categorias;
    contato.favorito = favorito;

    if (editando) {
      agenda.atualizar(contato);
    } else {
      agenda.adicionar(contato);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(editando ? 'Contato atualizado' : 'Contato salvo')),
    );
    Navigator.pop(context);
  }

  void cancelar() {
    // Nada é alterado: os dados só mudam quando clica em Salvar.
    Navigator.pop(context);
  }

  Future<void> escolherImagemDoComputador() async {
    final imagem = await escolherImagem();
    if (imagem == null) return;

    // A imagem vira texto; imagens muito grandes enchem o armazenamento do navegador.
    if (imagem.length > 700000) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Imagem muito grande (máximo 500 KB).')),
      );
      return;
    }
    setState(() {
      fotoUrl = imagem;
    });
  }

  Future<void> informarUrlDaFoto() async {
    String textoInicial = '';
    if (!fotoUrl.startsWith('data:')) textoInicial = fotoUrl;

    final url = await pedirTexto(
      context,
      'Foto do contato',
      rotulo: 'URL da imagem (https://...)',
      textoInicial: textoInicial,
    );
    if (url != null) {
      setState(() {
        fotoUrl = url;
      });
    }
  }

  Future<void> escolherAniversario() async {
    final data = await showDatePicker(
      context: context,
      initialDate: aniversario ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      helpText: 'Data de aniversário',
    );
    if (data != null) {
      setState(() {
        aniversario = data;
      });
    }
  }

  /// Foto, botões para trocar a foto e escolha da cor.
  Widget areaDaFoto() {
    return Column(
      children: [
        ContactAvatar(contact: contatoDaTela(), radius: 50),
        const SizedBox(height: 8),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          children: [
            if (suportaArquivos)
              TextButton.icon(
                onPressed: escolherImagemDoComputador,
                icon: const Icon(Icons.upload_file),
                label: const Text('Escolher imagem'),
              ),
            TextButton.icon(
              onPressed: informarUrlDaFoto,
              icon: const Icon(Icons.link),
              label: const Text('URL da foto'),
            ),
            if (fotoUrl.isNotEmpty)
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    fotoUrl = '';
                  });
                },
                icon: const Icon(Icons.delete_outline),
                label: const Text('Remover foto'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final cor in coresAvatar)
              GestureDetector(
                onTap: () {
                  setState(() {
                    corAvatar = cor;
                  });
                },
                child: CircleAvatar(
                  radius: 14,
                  backgroundColor: cor,
                  child: corAvatar.toARGB32() == cor.toARGB32()
                      ? const Icon(Icons.check, color: Colors.white, size: 16)
                      : null,
                ),
              ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    String textoAniversario = 'Aniversário (opcional)';
    if (aniversario != null) {
      textoAniversario = 'Aniversário: ${formatarData(aniversario!)}';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(editando ? 'Editar Contato' : 'Novo Contato'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: favorito ? 'Remover dos favoritos' : 'Favoritar',
            icon: Icon(favorito ? Icons.star : Icons.star_border),
            onPressed: () {
              setState(() {
                favorito = !favorito;
              });
            },
          ),
        ],
      ),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            areaDaFoto(),
            const SizedBox(height: 16),
            TextFormField(
              controller: nomeController,
              decoration: const InputDecoration(labelText: 'Nome'),
              // Atualiza as iniciais da foto enquanto digita.
              onChanged: (texto) {
                setState(() {});
              },
              validator: (texto) {
                if (texto == null || texto.trim().isEmpty) return 'Informe o nome';
                return null;
              },
            ),
            TextFormField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
              validator: (texto) {
                if (texto == null || texto.trim().isEmpty) return null;
                if (!texto.contains('@') || !texto.contains('.')) return 'E-mail inválido';
                return null;
              },
            ),
            TextFormField(
              controller: telefoneController,
              decoration: const InputDecoration(labelText: 'Telefone'),
              keyboardType: TextInputType.phone,
            ),
            TextFormField(
              controller: cidadeController,
              decoration: const InputDecoration(labelText: 'Cidade'),
            ),
            TextFormField(
              controller: empresaController,
              decoration: const InputDecoration(labelText: 'Empresa'),
            ),
            TextFormField(
              controller: observacoesController,
              decoration: const InputDecoration(labelText: 'Observações'),
              maxLines: 3,
              minLines: 1,
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.cake_outlined),
              title: Text(textoAniversario),
              onTap: escolherAniversario,
              trailing: aniversario == null
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          aniversario = null;
                        });
                      },
                    ),
            ),
            const SizedBox(height: 8),
            const Text('Categorias'),
            Wrap(
              spacing: 8,
              children: [
                for (final cat in agenda.categorias)
                  FilterChip(
                    label: Text(cat),
                    selected: categorias.contains(cat),
                    onSelected: (marcou) {
                      setState(() {
                        if (marcou) {
                          categorias.add(cat);
                        } else {
                          categorias.remove(cat);
                        }
                      });
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
      // Botões fixos no rodapé da tela.
      persistentFooterButtons: [
        OutlinedButton.icon(
          onPressed: cancelar,
          icon: const Icon(Icons.close),
          label: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: salvar,
          icon: const Icon(Icons.save),
          label: const Text('Salvar'),
        ),
      ],
    );
  }
}
