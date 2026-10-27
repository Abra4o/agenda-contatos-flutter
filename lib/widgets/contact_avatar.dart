import 'package:flutter/material.dart';

import '../models/contact.dart';

/// Foto do contato: imagem por URL ou iniciais sobre a cor do avatar.
class ContactAvatar extends StatelessWidget {
  final Contact contact;
  final double radius;

  const ContactAvatar({super.key, required this.contact, this.radius = 22});

  @override
  Widget build(BuildContext context) {
    final iniciais = Text(
      contact.iniciais,
      style: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: radius * 0.8,
      ),
    );

    if (contact.fotoUrl.isEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: contact.corAvatar,
        child: iniciais,
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: contact.corAvatar,
      child: ClipOval(
        child: Image.network(
          contact.fotoUrl,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => Center(child: iniciais),
        ),
      ),
    );
  }
}
