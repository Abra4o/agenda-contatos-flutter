import 'package:flutter/material.dart';

import '../models/contact.dart';
import '../widgets/contact_avatar.dart';

/// Tela para marcar vários contatos de uma vez.
/// Ao confirmar, volta para a tela anterior com a lista dos marcados.
class SelecionarContatosScreen extends StatefulWidget {
  final String titulo;
  final List<Contact> contatos;
  final List<Contact> jaMarcados;

  const SelecionarContatosScreen({
    super.key,
    required this.titulo,
    required this.contatos,
    this.jaMarcados = const [],
  });

  @override
  State<SelecionarContatosScreen> createState() => _SelecionarContatosScreenState();
}

class _SelecionarContatosScreenState extends State<SelecionarContatosScreen> {
  List<Contact> marcados = [];

  @override
  void initState() {
    super.initState();
    marcados = List<Contact>.from(widget.jaMarcados);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.titulo)),
      body: ListView.builder(
        itemCount: widget.contatos.length,
        itemBuilder: (context, index) {
          final contato = widget.contatos[index];
          return CheckboxListTile(
            secondary: ContactAvatar(contact: contato, radius: 18),
            title: Text(contato.nome),
            value: marcados.contains(contato),
            onChanged: (marcou) {
              setState(() {
                if (marcou == true) {
                  marcados.add(contato);
                } else {
                  marcados.remove(contato);
                }
              });
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pop(context, marcados);
        },
        icon: const Icon(Icons.check),
        label: const Text('Confirmar'),
      ),
    );
  }
}

/// Abre a tela de seleção e retorna os contatos marcados (ou null se voltar).
Future<List<Contact>?> selecionarContatos(
  BuildContext context,
  String titulo,
  List<Contact> contatos, {
  List<Contact> jaMarcados = const [],
}) {
  return Navigator.push<List<Contact>>(
    context,
    MaterialPageRoute(
      builder: (context) => SelecionarContatosScreen(
        titulo: titulo,
        contatos: contatos,
        jaMarcados: jaMarcados,
      ),
    ),
  );
}
