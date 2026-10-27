import 'package:flutter/material.dart';

import '../models/contact.dart';
import '../store/agenda_store.dart';
import 'contact_avatar.dart';

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

/// Formulário usado no Cadastro (contato == null) e na Edição.
class ContactForm extends StatefulWidget {
  final Contact? contato;

  const ContactForm({super.key, this.contato});

  @override
  State<ContactForm> createState() => _ContactFormState();
}

class _ContactFormState extends State<ContactForm> {
  final _formKey = GlobalKey<FormState>();
  final store = AgendaStore.instance;

  late final _nome = TextEditingController(text: widget.contato?.nome);
  late final _email = TextEditingController(text: widget.contato?.email);
  late final _telefone = TextEditingController(text: widget.contato?.telefone);
  late final _cidade = TextEditingController(text: widget.contato?.cidade);
  late final _empresa = TextEditingController(text: widget.contato?.empresa);
  late final _obs = TextEditingController(text: widget.contato?.observacoes);

  late String _fotoUrl = widget.contato?.fotoUrl ?? '';
  late Color _cor = widget.contato?.corAvatar ?? Colors.red;
  late DateTime? _aniversario = widget.contato?.aniversario;
  late final Set<String> _categorias = {...?widget.contato?.categorias};
  late bool _favorito = widget.contato?.favorito ?? false;

  bool _alterado = false;

  bool get _editando => widget.contato != null;

  @override
  void dispose() {
    for (final c in [_nome, _email, _telefone, _cidade, _empresa, _obs]) {
      c.dispose();
    }
    super.dispose();
  }

  void _marcar() {
    if (!_alterado) setState(() => _alterado = true);
  }

  Contact _montar() {
    final base = widget.contato ?? Contact(id: '', nome: '');
    return base.copyWith(
      nome: _nome.text.trim(),
      email: _email.text.trim(),
      telefone: _telefone.text.trim(),
      cidade: _cidade.text.trim(),
      empresa: _empresa.text.trim(),
      observacoes: _obs.text.trim(),
      fotoUrl: _fotoUrl,
      corAvatar: _cor,
      categorias: {..._categorias},
      favorito: _favorito,
      aniversario: _aniversario,
      limparAniversario: _aniversario == null,
    );
  }

  void _salvar() {
    if (!_formKey.currentState!.validate()) return;
    final c = _montar();
    if (_editando) {
      store.atualizar(c);
    } else {
      store.adicionar(c);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_editando ? 'Contato atualizado' : 'Contato salvo')),
    );
    _alterado = false;
    Navigator.pop(context, true);
  }

  Future<bool> _confirmarDescarte() async {
    if (!_alterado) return true;
    final r = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Descartar alterações?'),
        content: const Text('As mudanças feitas não serão salvas.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Continuar editando')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Descartar')),
        ],
      ),
    );
    return r ?? false;
  }

  Future<void> _cancelar() async {
    if (await _confirmarDescarte() && mounted) {
      _alterado = false;
      Navigator.pop(context, false);
    }
  }

  Future<void> _escolherFoto() async {
    final url = TextEditingController(text: _fotoUrl);
    var cor = _cor;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: const Text('Foto do contato'),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: url,
                  decoration: const InputDecoration(
                    labelText: 'URL da imagem',
                    hintText: 'https://...',
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Ou escolha a cor do avatar:'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final c in coresAvatar)
                      GestureDetector(
                        onTap: () => setD(() => cor = c),
                        child: CircleAvatar(
                          radius: 16,
                          backgroundColor: c,
                          child: cor == c
                              ? const Icon(Icons.check, color: Colors.white, size: 18)
                              : null,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                url.clear();
                Navigator.pop(ctx, true);
              },
              child: const Text('Remover foto'),
            ),
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Aplicar')),
          ],
        ),
      ),
    );
    if (ok == true) {
      setState(() {
        _fotoUrl = url.text.trim();
        _cor = cor;
        _alterado = true;
      });
    }
    url.dispose();
  }

  Future<void> _escolherAniversario() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _aniversario ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      helpText: 'Data de aniversário',
    );
    if (d != null) {
      setState(() {
        _aniversario = d;
        _alterado = true;
      });
    }
  }

  Widget _foto() {
    final semFoto = _fotoUrl.isEmpty && _nome.text.trim().isEmpty;
    return Center(
      child: Tooltip(
        message: 'Alterar foto',
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: _escolherFoto,
          child: Stack(
            children: [
              semFoto
                  ? const Icon(Icons.account_circle, size: 100)
                  : Padding(
                      padding: const EdgeInsets.all(4),
                      child: ContactAvatar(contact: _montar(), radius: 46),
                    ),
              const Positioned(
                right: 0,
                bottom: 0,
                child: CircleAvatar(radius: 14, child: Icon(Icons.camera_alt, size: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_alterado,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _cancelar();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_editando ? 'Editar Contato' : 'Novo Contato'),
          centerTitle: true,
          actions: [
            IconButton(
              tooltip: _favorito ? 'Remover dos favoritos' : 'Favoritar',
              icon: Icon(_favorito ? Icons.star : Icons.star_border),
              onPressed: () => setState(() {
                _favorito = !_favorito;
                _alterado = true;
              }),
            ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(8, 16, 8, 96),
            children: [
              _foto(),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nome,
                decoration: const InputDecoration(labelText: 'Nome'),
                textCapitalization: TextCapitalization.words,
                onChanged: (_) => setState(() => _alterado = true),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe o nome' : null,
              ),
              TextFormField(
                controller: _email,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                onChanged: (_) => _marcar(),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim())
                      ? null
                      : 'E-mail inválido';
                },
              ),
              TextFormField(
                controller: _telefone,
                decoration: const InputDecoration(labelText: 'Phone'),
                keyboardType: TextInputType.phone,
                onChanged: (_) => _marcar(),
              ),
              TextFormField(
                controller: _cidade,
                decoration: const InputDecoration(labelText: 'Cidade'),
                onChanged: (_) => _marcar(),
              ),
              TextFormField(
                controller: _empresa,
                decoration: const InputDecoration(labelText: 'Empresa'),
                onChanged: (_) => _marcar(),
              ),
              TextFormField(
                controller: _obs,
                decoration: const InputDecoration(labelText: 'Observações'),
                maxLines: 3,
                minLines: 1,
                onChanged: (_) => _marcar(),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.cake_outlined),
                title: Text(_aniversario == null
                    ? 'Aniversário (opcional)'
                    : 'Aniversário: ${formatDate(_aniversario!)}'),
                onTap: _escolherAniversario,
                trailing: _aniversario == null
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() {
                          _aniversario = null;
                          _alterado = true;
                        }),
                      ),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 8, bottom: 4),
                child: Text('Categorias'),
              ),
              Wrap(
                spacing: 8,
                children: [
                  for (final cat in store.categorias)
                    FilterChip(
                      label: Text(cat),
                      selected: _categorias.contains(cat),
                      onSelected: (s) => setState(() {
                        s ? _categorias.add(cat) : _categorias.remove(cat);
                        _alterado = true;
                      }),
                    ),
                ],
              ),
              if (_editando) ...[
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _cancelar,
                      icon: const Icon(Icons.close),
                      label: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed: _salvar,
                      icon: const Icon(Icons.save),
                      label: const Text('Salvar'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          tooltip: 'Salvar',
          onPressed: _salvar,
          child: const Icon(Icons.save),
        ),
      ),
    );
  }
}
