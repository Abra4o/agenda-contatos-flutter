import 'package:flutter/material.dart';

/// Contato da agenda.
class Contact {
  String id;
  String nome;
  String email;
  String telefone;
  String observacoes;
  String fotoUrl;
  Color corAvatar;
  bool favorito;
  List<String> categorias;
  String cidade;
  String empresa;
  DateTime? aniversario;
  DateTime dataCadastro;

  Contact({
    required this.id,
    required this.nome,
    this.email = '',
    this.telefone = '',
    this.observacoes = '',
    this.fotoUrl = '',
    this.corAvatar = Colors.red,
    this.favorito = false,
    List<String>? categorias,
    this.cidade = '',
    this.empresa = '',
    this.aniversario,
    DateTime? dataCadastro,
  })  : categorias = categorias ?? [],
        dataCadastro = dataCadastro ?? DateTime.now();

  /// Primeira letra do primeiro e do último nome. Ex.: "Ana Souza" -> "AS".
  String get iniciais {
    final partes = nome.trim().split(' ');
    final palavras = <String>[];
    for (final p in partes) {
      if (p.isNotEmpty) palavras.add(p);
    }
    if (palavras.isEmpty) return '?';
    if (palavras.length == 1) return palavras[0][0].toUpperCase();
    return (palavras.first[0] + palavras.last[0]).toUpperCase();
  }

  // ---------- JSON (para salvar no navegador e fazer backup) ----------

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'email': email,
      'telefone': telefone,
      'observacoes': observacoes,
      'fotoUrl': fotoUrl,
      'cor': corAvatar.toARGB32(),
      'favorito': favorito,
      'categorias': categorias,
      'cidade': cidade,
      'empresa': empresa,
      'aniversario': aniversario?.toIso8601String(),
      'dataCadastro': dataCadastro.toIso8601String(),
    };
  }

  factory Contact.fromJson(Map<String, dynamic> json) {
    DateTime? aniversario;
    if (json['aniversario'] != null) {
      aniversario = DateTime.parse(json['aniversario']);
    }

    return Contact(
      id: json['id'],
      nome: json['nome'],
      email: json['email'] ?? '',
      telefone: json['telefone'] ?? '',
      observacoes: json['observacoes'] ?? '',
      fotoUrl: json['fotoUrl'] ?? '',
      corAvatar: Color(json['cor'] ?? Colors.red.toARGB32()),
      favorito: json['favorito'] ?? false,
      categorias: List<String>.from(json['categorias'] ?? []),
      cidade: json['cidade'] ?? '',
      empresa: json['empresa'] ?? '',
      aniversario: aniversario,
      dataCadastro: DateTime.parse(json['dataCadastro']),
    );
  }
}

// ---------- CSV (importação e exportação) ----------

/// Ordem das colunas no arquivo CSV.
const colunasCsv = [
  'nome',
  'email',
  'telefone',
  'cidade',
  'empresa',
  'aniversario',
  'categorias',
  'observacoes',
  'favorito',
];

/// Transforma o contato numa lista de valores, na ordem de [colunasCsv].
List<String> contatoParaCsv(Contact c) {
  String aniversario = '';
  if (c.aniversario != null) {
    aniversario = formatarData(c.aniversario!);
  }

  String favorito = '';
  if (c.favorito) {
    favorito = 'sim';
  }

  return [
    c.nome,
    c.email,
    c.telefone,
    c.cidade,
    c.empresa,
    aniversario,
    c.categorias.join('|'),
    c.observacoes.replaceAll('\n', ' '),
    favorito,
  ];
}

/// Cria um contato a partir dos valores de uma linha do CSV.
/// Retorna null se a linha não tiver nome.
Contact? contatoDoCsv(String id, List<String> campos) {
  // Pega o campo da posição i, ou '' se a linha for mais curta.
  String campo(int i) {
    if (i < campos.length) return campos[i].trim();
    return '';
  }

  final nome = campo(0);
  if (nome.isEmpty) return null;

  final categorias = <String>[];
  for (final cat in campo(6).split('|')) {
    if (cat.trim().isNotEmpty) categorias.add(cat.trim());
  }

  final fav = campo(8).toLowerCase();

  return Contact(
    id: id,
    nome: nome,
    email: campo(1),
    telefone: campo(2),
    cidade: campo(3),
    empresa: campo(4),
    aniversario: lerData(campo(5)),
    categorias: categorias,
    observacoes: campo(7),
    favorito: fav == 'sim' || fav == 's' || fav == 'true' || fav == '1',
  );
}

// ---------- Datas ----------

/// Coloca zero à esquerda. Ex.: 5 -> "05".
String doisDigitos(int n) {
  return n.toString().padLeft(2, '0');
}

/// Formato dd/MM/yyyy.
String formatarData(DateTime d) {
  return '${doisDigitos(d.day)}/${doisDigitos(d.month)}/${d.year}';
}

/// Formato dd/MM/yyyy HH:mm.
String formatarDataHora(DateTime d) {
  return '${formatarData(d)} ${doisDigitos(d.hour)}:${doisDigitos(d.minute)}';
}

/// Lê datas no formato dd/MM/yyyy ou yyyy-MM-dd. Retorna null se não conseguir.
DateTime? lerData(String texto) {
  texto = texto.trim();
  if (texto.isEmpty) return null;

  final partes = texto.split('/');
  if (partes.length == 3) {
    final dia = int.tryParse(partes[0]);
    final mes = int.tryParse(partes[1]);
    final ano = int.tryParse(partes[2]);
    if (dia == null || mes == null || ano == null) return null;
    return DateTime(ano, mes, dia);
  }

  return DateTime.tryParse(texto);
}

const nomesMeses = [
  'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
  'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro',
];
