/// Grupo de contatos.
class Group {
  String id;
  String nome;

  /// Ids dos contatos que fazem parte do grupo.
  List<String> membros;

  Group({required this.id, required this.nome, List<String>? membros})
      : membros = membros ?? [];

  Map<String, dynamic> toJson() {
    return {'id': id, 'nome': nome, 'membros': membros};
  }

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      id: json['id'],
      nome: json['nome'],
      membros: List<String>.from(json['membros'] ?? []),
    );
  }
}
