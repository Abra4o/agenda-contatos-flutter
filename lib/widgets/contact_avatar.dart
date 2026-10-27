import 'package:flutter/material.dart';

import '../models/contact.dart';

// Fotos já convertidas de texto para imagem. Assim a foto não pisca
// toda vez que a tela é redesenhada.
final Map<String, MemoryImage> fotosConvertidas = {};

/// Foto do contato. Se não tiver foto, mostra as iniciais sobre a cor do avatar.
class ContactAvatar extends StatelessWidget {
  final Contact contact;
  final double radius;

  const ContactAvatar({super.key, required this.contact, this.radius = 22});

  @override
  Widget build(BuildContext context) {
    // Sem foto: círculo colorido com as iniciais.
    if (contact.fotoUrl.isEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: contact.corAvatar,
        child: Text(
          contact.iniciais,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: radius * 0.8,
          ),
        ),
      );
    }

    // Com foto: a foto pode ser um link (https://...) ou uma imagem escolhida
    // do computador, guardada como texto "data:image/...".
    ImageProvider imagem;
    if (contact.fotoUrl.startsWith('data:')) {
      if (!fotosConvertidas.containsKey(contact.fotoUrl)) {
        final bytes = UriData.parse(contact.fotoUrl).contentAsBytes();
        fotosConvertidas[contact.fotoUrl] = MemoryImage(bytes);
      }
      imagem = fotosConvertidas[contact.fotoUrl]!;
    } else {
      imagem = NetworkImage(contact.fotoUrl);
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: contact.corAvatar,
      backgroundImage: imagem,
      // Se a imagem não carregar, fica só a cor de fundo.
      onBackgroundImageError: (erro, pilha) {},
    );
  }
}
