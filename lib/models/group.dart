/// Grupo de contatos.
class Group {
  final String id;
  String nome;
  final Set<String> memberIds;

  Group({required this.id, required this.nome, Set<String>? memberIds})
      : memberIds = memberIds ?? <String>{};
}
