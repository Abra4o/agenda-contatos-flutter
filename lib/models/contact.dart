import 'package:flutter/material.dart';

/// Contato da agenda.
class Contact {
  final String id;
  final String nome;
  final String email;
  final String telefone;
  final String observacoes;
  final String fotoUrl;
  final Color corAvatar;
  final bool favorito;
  final Set<String> categorias;
  final String cidade;
  final String empresa;
  final DateTime? aniversario;
  final DateTime dataCadastro;

  Contact({
    required this.id,
    required this.nome,
    this.email = '',
    this.telefone = '',
    this.observacoes = '',
    this.fotoUrl = '',
    this.corAvatar = Colors.red,
    this.favorito = false,
    Set<String>? categorias,
    this.cidade = '',
    this.empresa = '',
    this.aniversario,
    DateTime? dataCadastro,
  })  : categorias = categorias ?? <String>{},
        dataCadastro = dataCadastro ?? DateTime.now();

  Contact copyWith({
    String? nome,
    String? email,
    String? telefone,
    String? observacoes,
    String? fotoUrl,
    Color? corAvatar,
    bool? favorito,
    Set<String>? categorias,
    String? cidade,
    String? empresa,
    DateTime? aniversario,
    bool limparAniversario = false,
  }) {
    return Contact(
      id: id,
      nome: nome ?? this.nome,
      email: email ?? this.email,
      telefone: telefone ?? this.telefone,
      observacoes: observacoes ?? this.observacoes,
      fotoUrl: fotoUrl ?? this.fotoUrl,
      corAvatar: corAvatar ?? this.corAvatar,
      favorito: favorito ?? this.favorito,
      categorias: categorias ?? {...this.categorias},
      cidade: cidade ?? this.cidade,
      empresa: empresa ?? this.empresa,
      aniversario: limparAniversario ? null : (aniversario ?? this.aniversario),
      dataCadastro: dataCadastro,
    );
  }

  String get iniciais {
    final partes = nome.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (partes.isEmpty) return '?';
    if (partes.length == 1) return partes.first[0].toUpperCase();
    return (partes.first[0] + partes.last[0]).toUpperCase();
  }

  // ---------- CSV ----------

  static const csvHeader = [
    'nome',
    'email',
    'telefone',
    'cidade',
    'empresa',
    'aniversario',
    'categorias',
    'observacoes',
  ];

  List<String> toCsvFields() => [
        nome,
        email,
        telefone,
        cidade,
        empresa,
        aniversario == null ? '' : formatDate(aniversario!),
        categorias.join('|'),
        observacoes.replaceAll('\n', ' '),
      ];

  /// Cria um contato a partir de uma linha do CSV já separada em campos.
  static Contact? fromCsvFields(String id, List<String> f) {
    String at(int i) => i < f.length ? f[i].trim() : '';
    final nome = at(0);
    if (nome.isEmpty) return null;
    return Contact(
      id: id,
      nome: nome,
      email: at(1),
      telefone: at(2),
      cidade: at(3),
      empresa: at(4),
      aniversario: parseDate(at(5)),
      categorias: at(6).split('|').map((c) => c.trim()).where((c) => c.isNotEmpty).toSet(),
      observacoes: at(7),
    );
  }
}

String _dois(int n) => n.toString().padLeft(2, '0');

/// dd/MM/yyyy
String formatDate(DateTime d) => '${_dois(d.day)}/${_dois(d.month)}/${d.year}';

String formatDateTime(DateTime d) =>
    '${formatDate(d)} ${_dois(d.hour)}:${_dois(d.minute)}:${_dois(d.second)}';

/// Aceita dd/MM/yyyy ou yyyy-MM-dd.
DateTime? parseDate(String s) {
  s = s.trim();
  if (s.isEmpty) return null;
  final br = RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{4})$').firstMatch(s);
  if (br != null) {
    return DateTime(int.parse(br[3]!), int.parse(br[2]!), int.parse(br[1]!));
  }
  return DateTime.tryParse(s);
}

const nomesMeses = [
  'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
  'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro',
];
