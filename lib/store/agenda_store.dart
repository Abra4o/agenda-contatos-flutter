import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import '../models/contact.dart';
import '../models/group.dart';
import '../services/plataforma.dart';

/// A agenda usada pelo app inteiro. Todas as telas leem e alteram este objeto.
final agenda = AgendaStore();

/// Guarda contatos, categorias, grupos e preferências.
/// Quando algo muda, chama [avisarMudanca], que salva os dados no navegador
/// e avisa as telas (ChangeNotifier) para se redesenharem.
class AgendaStore extends ChangeNotifier {
  AgendaStore() {
    final carregou = carregarDoNavegador();
    if (!carregou) {
      carregarExemplos();
    }
    iniciarBackupAutomatico();
  }

  List<Contact> todosContatos = [];
  List<String> categorias = ['Família', 'Amigos', 'Trabalho', 'Clientes'];
  List<Group> grupos = [];

  // ---------- Preferências ----------

  bool darkMode = false;
  bool ordemCrescente = true;
  bool mostrarTelefoneNaLista = true;
  Color corTema = Colors.red;
  int diasLembrete = 7;

  // ---------- Backup ----------

  bool backupAuto = false;
  int intervaloBackupMin = 1;
  String? ultimoBackup;
  DateTime? ultimoBackupEm;
  Timer? timerBackup;

  /// false quando não deu para salvar no navegador.
  bool salvoNoNavegador = true;

  int contadorId = 0;

  /// Gera um id diferente para cada contato ou grupo.
  String novoId() {
    contadorId++;
    return '${DateTime.now().millisecondsSinceEpoch}-$contadorId';
  }

  /// Salva tudo e avisa as telas que os dados mudaram.
  void avisarMudanca() {
    salvar();
    notifyListeners();
  }

  // ---------- Preferências ----------

  void setDarkMode(bool valor) {
    darkMode = valor;
    avisarMudanca();
  }

  void setOrdemCrescente(bool valor) {
    ordemCrescente = valor;
    avisarMudanca();
  }

  void setMostrarTelefone(bool valor) {
    mostrarTelefoneNaLista = valor;
    avisarMudanca();
  }

  void setCorTema(Color cor) {
    corTema = cor;
    avisarMudanca();
  }

  void setDiasLembrete(int dias) {
    diasLembrete = dias;
    avisarMudanca();
  }

  // ---------- Contatos ----------

  /// Todos os contatos em ordem alfabética (A-Z ou Z-A).
  List<Contact> get contatos {
    final lista = List<Contact>.from(todosContatos);
    lista.sort((a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()));
    if (ordemCrescente) {
      return lista;
    } else {
      return lista.reversed.toList();
    }
  }

  List<Contact> get favoritos {
    final lista = <Contact>[];
    for (final c in contatos) {
      if (c.favorito) lista.add(c);
    }
    return lista;
  }

  /// Procura um contato pelo id. Retorna null se não achar.
  Contact? buscarPorId(String id) {
    for (final c in todosContatos) {
      if (c.id == id) return c;
    }
    return null;
  }

  void adicionar(Contact contato) {
    contato.id = novoId();
    contato.dataCadastro = DateTime.now();
    todosContatos.add(contato);
    avisarMudanca();
  }

  /// Chamado depois de alterar os dados de um contato.
  void atualizar(Contact contato) {
    avisarMudanca();
  }

  void excluir(Contact contato) {
    todosContatos.remove(contato);
    // Tira o contato dos grupos também.
    for (final g in grupos) {
      g.membros.remove(contato.id);
    }
    avisarMudanca();
  }

  void setFavorito(Contact contato, bool favorito) {
    contato.favorito = favorito;
    avisarMudanca();
  }

  /// Busca por nome, e-mail ou telefone.
  List<Contact> buscar(String termo) {
    final texto = termo.trim().toLowerCase();
    if (texto.isEmpty) return contatos;

    // Para o telefone, compara só os números: "11 9876" acha "(11) 98765-4321".
    final numerosBusca = somenteNumeros(texto);

    final resultado = <Contact>[];
    for (final c in contatos) {
      bool achou = false;
      if (c.nome.toLowerCase().contains(texto)) achou = true;
      if (c.email.toLowerCase().contains(texto)) achou = true;
      if (c.telefone.contains(texto)) achou = true;
      if (numerosBusca.isNotEmpty && somenteNumeros(c.telefone).contains(numerosBusca)) {
        achou = true;
      }
      if (achou) resultado.add(c);
    }
    return resultado;
  }

  /// Tira tudo que não é número. Ex.: "(11) 9999-0000" -> "1199990000".
  String somenteNumeros(String texto) {
    String numeros = '';
    for (final letra in texto.split('')) {
      if ('0123456789'.contains(letra)) numeros += letra;
    }
    return numeros;
  }

  // ---------- Categorias ----------

  /// Cria uma categoria. Retorna false se o nome estiver vazio ou já existir.
  bool criarCategoria(String nome) {
    nome = nome.trim();
    if (nome.isEmpty) return false;
    for (final c in categorias) {
      if (c.toLowerCase() == nome.toLowerCase()) return false;
    }
    categorias.add(nome);
    avisarMudanca();
    return true;
  }

  void excluirCategoria(String nome) {
    categorias.remove(nome);
    for (final c in todosContatos) {
      c.categorias.remove(nome);
    }
    avisarMudanca();
  }

  List<Contact> contatosDaCategoria(String categoria) {
    final lista = <Contact>[];
    for (final c in contatos) {
      if (c.categorias.contains(categoria)) lista.add(c);
    }
    return lista;
  }

  void colocarNaCategoria(Contact contato, String categoria) {
    if (!contato.categorias.contains(categoria)) {
      contato.categorias.add(categoria);
    }
    avisarMudanca();
  }

  void tirarDaCategoria(Contact contato, String categoria) {
    contato.categorias.remove(categoria);
    avisarMudanca();
  }

  // ---------- Grupos ----------

  void criarGrupo(String nome) {
    grupos.add(Group(id: novoId(), nome: nome.trim()));
    avisarMudanca();
  }

  void renomearGrupo(Group grupo, String nome) {
    grupo.nome = nome.trim();
    avisarMudanca();
  }

  void excluirGrupo(Group grupo) {
    grupos.remove(grupo);
    avisarMudanca();
  }

  void adicionarMembro(Group grupo, Contact contato) {
    if (!grupo.membros.contains(contato.id)) {
      grupo.membros.add(contato.id);
    }
    avisarMudanca();
  }

  void removerMembro(Group grupo, Contact contato) {
    grupo.membros.remove(contato.id);
    avisarMudanca();
  }

  List<Contact> membros(Group grupo) {
    final lista = <Contact>[];
    for (final c in contatos) {
      if (grupo.membros.contains(c.id)) lista.add(c);
    }
    return lista;
  }

  // ---------- Aniversários ----------

  List<Contact> aniversariantesDoMes(int mes) {
    final lista = <Contact>[];
    for (final c in todosContatos) {
      if (c.aniversario != null && c.aniversario!.month == mes) {
        lista.add(c);
      }
    }
    lista.sort((a, b) => a.aniversario!.day.compareTo(b.aniversario!.day));
    return lista;
  }

  /// Quantos dias faltam para o próximo aniversário (0 = hoje).
  static int diasAteAniversario(DateTime aniversario) {
    final agora = DateTime.now();
    final hoje = DateTime(agora.year, agora.month, agora.day);

    var proximo = DateTime(hoje.year, aniversario.month, aniversario.day);
    if (proximo.isBefore(hoje)) {
      // Já passou este ano, então é no ano que vem.
      proximo = DateTime(hoje.year + 1, aniversario.month, aniversario.day);
    }
    return proximo.difference(hoje).inDays;
  }

  /// Contatos que fazem aniversário nos próximos [diasLembrete] dias.
  List<Contact> get lembretes {
    final lista = <Contact>[];
    for (final c in todosContatos) {
      if (c.aniversario != null && diasAteAniversario(c.aniversario!) <= diasLembrete) {
        lista.add(c);
      }
    }
    lista.sort((a, b) =>
        diasAteAniversario(a.aniversario!).compareTo(diasAteAniversario(b.aniversario!)));
    return lista;
  }

  // ---------- Importação / Exportação (CSV) ----------

  /// Gera o texto CSV com todos os contatos.
  String exportarCsv({String separador = ';'}) {
    final linhas = <String>[];
    linhas.add(colunasCsv.join(separador));

    for (final c in contatos) {
      final valores = <String>[];
      for (var valor in contatoParaCsv(c)) {
        // Se o valor tiver o separador ou aspas, coloca entre aspas.
        if (valor.contains(separador) || valor.contains('"')) {
          valor = '"${valor.replaceAll('"', '""')}"';
        }
        valores.add(valor);
      }
      linhas.add(valores.join(separador));
    }
    return linhas.join('\n');
  }

  /// Lê um texto CSV (separado por ; ou ,) ou copiado do Excel (separado por tab).
  List<Contact> lerCsv(String texto) {
    // O Excel às vezes coloca um caractere invisível (BOM) no começo.
    texto = texto.replaceAll('﻿', '');
    texto = texto.replaceAll('\r\n', '\n');

    final linhas = <String>[];
    for (final linha in texto.split('\n')) {
      if (linha.trim().isNotEmpty) linhas.add(linha);
    }
    if (linhas.isEmpty) return [];

    // Descobre o separador olhando a primeira linha.
    String separador = ',';
    if (linhas[0].contains('\t')) {
      separador = '\t';
    } else if (linhas[0].contains(';')) {
      separador = ';';
    }

    final resultado = <Contact>[];
    for (var i = 0; i < linhas.length; i++) {
      final campos = separarCampos(linhas[i], separador);
      // Pula a linha de cabeçalho.
      if (i == 0 && campos[0].trim().toLowerCase() == 'nome') continue;

      final contato = contatoDoCsv(novoId(), campos);
      if (contato != null) resultado.add(contato);
    }
    return resultado;
  }

  /// Separa uma linha do CSV em campos, respeitando valores entre aspas.
  List<String> separarCampos(String linha, String separador) {
    final campos = <String>[];
    String atual = '';
    bool dentroDeAspas = false;

    for (var i = 0; i < linha.length; i++) {
      final letra = linha[i];
      if (letra == '"') {
        // Duas aspas seguidas dentro de aspas = uma aspa de verdade.
        if (dentroDeAspas && i + 1 < linha.length && linha[i + 1] == '"') {
          atual += '"';
          i++;
        } else {
          dentroDeAspas = !dentroDeAspas;
        }
      } else if (letra == separador && !dentroDeAspas) {
        campos.add(atual);
        atual = '';
      } else {
        atual += letra;
      }
    }
    campos.add(atual);
    return campos;
  }

  void importar(List<Contact> novos) {
    for (final c in novos) {
      // Cria as categorias que ainda não existem.
      for (final cat in c.categorias) {
        if (!categorias.contains(cat)) categorias.add(cat);
      }
      todosContatos.add(c);
    }
    avisarMudanca();
  }

  // ---------- Salvar no navegador ----------

  static const chaveNavegador = 'agenda_contatos_v1';

  /// Contatos, categorias e grupos em formato de Map (para virar JSON).
  Map<String, dynamic> dadosParaJson() {
    final listaContatos = [];
    for (final c in todosContatos) {
      listaContatos.add(c.toJson());
    }
    final listaGrupos = [];
    for (final g in grupos) {
      listaGrupos.add(g.toJson());
    }
    return {
      'contatos': listaContatos,
      'categorias': categorias,
      'grupos': listaGrupos,
    };
  }

  /// Troca os dados atuais pelos que vieram do JSON.
  void carregarDadosDoJson(Map<String, dynamic> dados) {
    final novosContatos = <Contact>[];
    for (final json in dados['contatos']) {
      novosContatos.add(Contact.fromJson(json));
    }
    final novosGrupos = <Group>[];
    for (final json in dados['grupos']) {
      novosGrupos.add(Group.fromJson(json));
    }
    todosContatos = novosContatos;
    grupos = novosGrupos;
    categorias = List<String>.from(dados['categorias']);
  }

  void salvar() {
    if (!suportaArquivos) return;

    final dados = dadosParaJson();
    dados['preferencias'] = {
      'darkMode': darkMode,
      'ordemCrescente': ordemCrescente,
      'mostrarTelefone': mostrarTelefoneNaLista,
      'corTema': corTema.toARGB32(),
      'diasLembrete': diasLembrete,
      'backupAuto': backupAuto,
      'intervaloBackupMin': intervaloBackupMin,
    };
    dados['backup'] = ultimoBackup;
    dados['backupEm'] = ultimoBackupEm?.toIso8601String();

    salvoNoNavegador = salvarNoNavegador(chaveNavegador, jsonEncode(dados));
  }

  /// Carrega os dados salvos. Retorna false se não tinha nada salvo.
  bool carregarDoNavegador() {
    final texto = lerDoNavegador(chaveNavegador);
    if (texto == null) return false;

    try {
      final dados = jsonDecode(texto);
      carregarDadosDoJson(dados);

      final prefs = dados['preferencias'];
      if (prefs != null) {
        darkMode = prefs['darkMode'] ?? false;
        ordemCrescente = prefs['ordemCrescente'] ?? true;
        mostrarTelefoneNaLista = prefs['mostrarTelefone'] ?? true;
        corTema = Color(prefs['corTema'] ?? Colors.red.toARGB32());
        diasLembrete = prefs['diasLembrete'] ?? 7;
        backupAuto = prefs['backupAuto'] ?? false;
        intervaloBackupMin = prefs['intervaloBackupMin'] ?? 1;
      }

      ultimoBackup = dados['backup'];
      if (dados['backupEm'] != null) {
        ultimoBackupEm = DateTime.parse(dados['backupEm']);
      }
      return true;
    } catch (e) {
      // Dados salvos com problema: começa do zero.
      todosContatos = [];
      grupos = [];
      return false;
    }
  }

  /// Apaga contatos, grupos e backup.
  void apagarTudo() {
    todosContatos = [];
    grupos = [];
    categorias = ['Família', 'Amigos', 'Trabalho', 'Clientes'];
    ultimoBackup = null;
    ultimoBackupEm = null;
    avisarMudanca();
  }

  // ---------- Backup ----------

  /// Guarda uma cópia de tudo (contatos, categorias e grupos).
  void fazerBackup() {
    ultimoBackup = jsonEncode(dadosParaJson());
    ultimoBackupEm = DateTime.now();
    avisarMudanca();
  }

  /// Volta os dados para o último backup. Retorna quantos contatos voltaram.
  int restaurarBackup() {
    if (ultimoBackup == null) return 0;
    carregarDadosDoJson(jsonDecode(ultimoBackup!));
    avisarMudanca();
    return todosContatos.length;
  }

  void setBackupAuto(bool valor) {
    backupAuto = valor;
    iniciarBackupAutomatico();
    if (valor) {
      fazerBackup();
    } else {
      avisarMudanca();
    }
  }

  void setIntervaloBackup(int minutos) {
    intervaloBackupMin = minutos;
    iniciarBackupAutomatico();
    avisarMudanca();
  }

  /// Liga (ou desliga) o timer que faz backup de tempos em tempos.
  void iniciarBackupAutomatico() {
    if (timerBackup != null) {
      timerBackup!.cancel();
      timerBackup = null;
    }
    if (backupAuto) {
      timerBackup = Timer.periodic(Duration(minutes: intervaloBackupMin), (timer) {
        fazerBackup();
      });
    }
  }

  // ---------- Dados de exemplo ----------

  /// Contatos de exemplo para o app não começar vazio.
  void carregarExemplos() {
    final hoje = DateTime.now();
    final daqui3Dias = hoje.add(const Duration(days: 3));
    final daqui15Dias = hoje.add(const Duration(days: 15));
    final daqui60Dias = hoje.add(const Duration(days: 60));

    final ana = Contact(
      id: novoId(),
      nome: 'Ana Souza',
      email: 'ana.souza@email.com',
      telefone: '(11) 98765-4321',
      cidade: 'São Paulo',
      empresa: 'Tech SA',
      categorias: ['Trabalho'],
      favorito: true,
      corAvatar: Colors.purple,
      aniversario: DateTime(1995, hoje.month, hoje.day),
      observacoes: 'Colega do time de produto.',
      dataCadastro: hoje.subtract(const Duration(days: 40)),
    );
    final bruno = Contact(
      id: novoId(),
      nome: 'Bruno Lima',
      email: 'bruno@email.com',
      telefone: '(21) 99888-7766',
      cidade: 'Rio de Janeiro',
      empresa: 'Loja Lima',
      categorias: ['Clientes'],
      corAvatar: Colors.blue,
      aniversario: DateTime(1988, daqui3Dias.month, daqui3Dias.day),
      dataCadastro: hoje.subtract(const Duration(days: 20)),
    );
    final carla = Contact(
      id: novoId(),
      nome: 'Carla Mendes',
      email: 'carla.m@email.com',
      telefone: '(31) 97777-1234',
      cidade: 'Belo Horizonte',
      categorias: ['Família'],
      favorito: true,
      corAvatar: Colors.teal,
      aniversario: DateTime(1990, daqui15Dias.month, daqui15Dias.day),
      observacoes: 'Prima.',
      dataCadastro: hoje.subtract(const Duration(days: 5)),
    );
    final diego = Contact(
      id: novoId(),
      nome: 'Diego Rocha',
      email: 'diego.rocha@email.com',
      telefone: '(11) 96666-5555',
      cidade: 'São Paulo',
      empresa: 'Tech SA',
      categorias: ['Amigos', 'Trabalho'],
      corAvatar: Colors.orange,
      aniversario: DateTime(1992, daqui60Dias.month, daqui60Dias.day),
      dataCadastro: hoje,
    );

    todosContatos.addAll([ana, bruno, carla, diego]);
    grupos.add(Group(id: novoId(), nome: 'Futebol de quinta', membros: [bruno.id, diego.id]));
  }
}
