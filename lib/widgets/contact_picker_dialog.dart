import 'package:flutter/material.dart';

import '../models/contact.dart';
import 'contact_avatar.dart';

/// Diálogo para marcar vários contatos. Retorna os ids marcados ou null se cancelar.
Future<Set<String>?> showContactPicker(
  BuildContext context, {
  required String titulo,
  required List<Contact> contatos,
  Set<String> selecionados = const {},
  String confirmar = 'Confirmar',
}) {
  final marcados = {...selecionados};
  var filtro = '';
  return showDialog<Set<String>>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setD) {
        final visiveis = contatos
            .where((c) => c.nome.toLowerCase().contains(filtro.toLowerCase()))
            .toList();
        return AlertDialog(
          title: Text(titulo),
          content: SizedBox(
            width: 380,
            height: 420,
            child: Column(
              children: [
                TextField(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Filtrar',
                    isDense: true,
                  ),
                  onChanged: (v) => setD(() => filtro = v),
                ),
                Expanded(
                  child: visiveis.isEmpty
                      ? const Center(child: Text('Nenhum contato.'))
                      : ListView(
                          children: [
                            for (final c in visiveis)
                              CheckboxListTile(
                                secondary: ContactAvatar(contact: c, radius: 16),
                                title: Text(c.nome),
                                value: marcados.contains(c.id),
                                onChanged: (v) => setD(() {
                                  v! ? marcados.add(c.id) : marcados.remove(c.id);
                                }),
                              ),
                          ],
                        ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, marcados),
              child: Text(confirmar),
            ),
          ],
        );
      },
    ),
  );
}

/// Diálogo simples de texto (criar/renomear). Retorna o texto ou null.
Future<String?> showTextDialog(
  BuildContext context, {
  required String titulo,
  String label = 'Nome',
  String inicial = '',
  String confirmar = 'Salvar',
}) async {
  final ctrl = TextEditingController(text: inicial);
  final r = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(titulo),
      content: TextField(
        controller: ctrl,
        autofocus: true,
        decoration: InputDecoration(labelText: label),
        onSubmitted: (v) => Navigator.pop(ctx, v),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
        FilledButton(onPressed: () => Navigator.pop(ctx, ctrl.text), child: Text(confirmar)),
      ],
    ),
  );
  ctrl.dispose();
  final t = r?.trim();
  return (t == null || t.isEmpty) ? null : t;
}
