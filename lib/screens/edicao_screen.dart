import 'package:flutter/material.dart';

import '../models/contact.dart';
import '../widgets/contact_form.dart';

/// Tela de Edição: altera dados, foto, e salva ou cancela.
class EdicaoScreen extends StatelessWidget {
  final Contact contato;

  const EdicaoScreen({super.key, required this.contato});

  @override
  Widget build(BuildContext context) => ContactForm(contato: contato);
}
