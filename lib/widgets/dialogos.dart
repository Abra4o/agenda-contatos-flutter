import 'package:flutter/material.dart';

/// Mostra uma pergunta de Sim/Não. Retorna true se o usuário confirmar.
Future<bool> confirmar(BuildContext context, String titulo, String mensagem, String botaoSim) async {
  final resposta = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(titulo),
        content: Text(mensagem),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(botaoSim),
          ),
        ],
      );
    },
  );
  return resposta == true;
}

/// Pede um texto ao usuário (ex.: nome de grupo). Retorna null se cancelar.
Future<String?> pedirTexto(
  BuildContext context,
  String titulo, {
  String rotulo = 'Nome',
  String textoInicial = '',
}) async {
  final controller = TextEditingController(text: textoInicial);

  final resposta = await showDialog<String>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(titulo),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(labelText: rotulo),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Salvar'),
          ),
        ],
      );
    },
  );

  if (resposta == null || resposta.trim().isEmpty) return null;
  return resposta.trim();
}
