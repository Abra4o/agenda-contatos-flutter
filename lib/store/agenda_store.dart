import 'dart:async';

import 'package:flutter/material.dart';

import '../models/contact.dart';
import '../models/group.dart';

/// Estado global do app, em memória (sem pacotes externos).
class AgendaStore extends ChangeNotifier {
  AgendaStore._() {
    _carregarExemplos();
  }

  static final AgendaStore instance = AgendaStore._();

  final List<Contact> _contatos = [];
  final List<String> categorias = ['Família', 'Amigos', 'Trabalho', 'Clientes'];
  final List<Group> grupos = [];

  int _seq = 0;
  String _novoId() => '${DateTime.now().microsecondsSinceEpoch}-${_seq++}';

  // ---------- Preferências ----------

  bool darkMode = false;
  bool ordemCrescente = true;
  bool mostrarTelefoneNaLista = true;
  Color corTema = Colors.red;
  int diasLembrete = 7;

  void setDarkMode(bool v) {
    darkMode = v;
    notifyListeners();
  }

  void setOrdemCrescente(bool v) {
    ordemCrescente = v;
    notifyListeners();
  }

  void setMostrarTelefone(bool v) {
    mostrarTelefoneNaLista = v;
    notifyListeners();
  }

  void setCorTema(Color c) {
    corTema = c;
    notifyListeners();
  }

  void setDiasLembrete(int d) {
    diasLembrete = d;
    notifyListeners();
  }

  // ---------- Contatos ----------

  /// Todos os contatos, em ordem alfabética (respeitando a preferência).
  List<Contact> get contatos {
    final lista = [..._contatos]
      ..sort((a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()));
    return ordemCrescente ? lista : lista.reversed.toList();
  }

  List<Contact> get favoritos => contatos.where((c) => c.favorito).toList();

  Contact? byId(String id) {
    for (final c in _contatos) {
      if (c.id == id) return c;
    }
    return null;
  }

  Contact adicionar(Contact c) {
    final novo = Contact(
      id: _novoId(),
      nome: c.nome,
      email: c.email,
      telefone: c.telefone,
      observacoes: c.observacoes,
      fotoUrl: c.fotoUrl,
      corAvatar: c.corAvatar,
      favorito: c.favorito,
      categorias: c.categorias,
      cidade: c.cidade,
      empresa: c.empresa,
      aniversario: c.aniversario,
    );
    _contatos.add(novo);
    notifyListeners();
    return novo;
  }

  void atualizar(Contact c) {
    final i = _contatos.indexWhere((e) => e.id == c.id);
    if (i >= 0) {
      _contatos[i] = c;
      notifyListeners();
    }
  }

  void excluir(String id) {
    _contatos.removeWhere((c) => c.id == id);
    for (final g in grupos) {
      g.memberIds.remove(id);
    }
    notifyListeners();
  }

  void setFavorito(String id, bool fav) {
    final c = byId(id);
    if (c != null) atualizar(c.copyWith(favorito: fav));
  }

  /// Busca por nome, e-mail ou telefone.
  List<Contact> buscar(String termo) {
    final t = termo.trim().toLowerCase();
    if (t.isEmpty) return contatos;
    final soDigitos = t.replaceAll(RegExp(r'\D'), '');
    return contatos.where((c) {
      final tel = c.telefone.replaceAll(RegExp(r'\D'), '');
      return c.nome.toLowerCase().contains(t) ||
          c.email.toLowerCase().contains(t) ||
          c.telefone.toLowerCase().contains(t) ||
          (soDigitos.isNotEmpty && tel.contains(soDigitos));
    }).toList();
  }

  // ---------- Categorias ----------

  bool criarCategoria(String nome) {
    nome = nome.trim();
    if (nome.isEmpty || categorias.any((c) => c.toLowerCase() == nome.toLowerCase())) {
      return false;
    }
    categorias.add(nome);
    notifyListeners();
    return true;
  }

  void excluirCategoria(String nome) {
    categorias.remove(nome);
    for (var i = 0; i < _contatos.length; i++) {
      if (_contatos[i].categorias.contains(nome)) {
        _contatos[i] = _contatos[i].copyWith(
          categorias: {..._contatos[i].categorias}..remove(nome),
        );
      }
    }
    notifyListeners();
  }

  List<Contact> contatosDaCategoria(String cat) =>
      contatos.where((c) => c.categorias.contains(cat)).toList();

  void setCategoria(String contatoId, String cat, bool incluir) {
    final c = byId(contatoId);
    if (c == null) return;
    final cats = {...c.categorias};
    incluir ? cats.add(cat) : cats.remove(cat);
    atualizar(c.copyWith(categorias: cats));
  }

  // ---------- Grupos ----------

  Group criarGrupo(String nome) {
    final g = Group(id: _novoId(), nome: nome.trim());
    grupos.add(g);
    notifyListeners();
    return g;
  }

  void renomearGrupo(Group g, String nome) {
    g.nome = nome.trim();
    notifyListeners();
  }

  void excluirGrupo(Group g) {
    grupos.remove(g);
    notifyListeners();
  }

  void setMembro(Group g, String contatoId, bool incluir) {
    incluir ? g.memberIds.add(contatoId) : g.memberIds.remove(contatoId);
    notifyListeners();
  }

  List<Contact> membros(Group g) =>
      contatos.where((c) => g.memberIds.contains(c.id)).toList();

  // ---------- Aniversários ----------

  List<Contact> aniversariantesDoMes(int mes) {
    final lista = _contatos.where((c) => c.aniversario?.month == mes).toList()
      ..sort((a, b) => a.aniversario!.day.compareTo(b.aniversario!.day));
    return lista;
  }

  /// Dias até o próximo aniversário (0 = hoje).
  static int diasAteAniversario(DateTime aniversario, [DateTime? agora]) {
    final hoje = DateUtils.dateOnly(agora ?? DateTime.now());
    var proximo = DateTime(hoje.year, aniversario.month, aniversario.day);
    if (proximo.isBefore(hoje)) {
      proximo = DateTime(hoje.year + 1, aniversario.month, aniversario.day);
    }
    return proximo.difference(hoje).inDays;
  }

  /// Contatos com aniversário nos próximos [diasLembrete] dias.
  List<Contact> get lembretes {
    final lista = _contatos
        .where((c) =>
            c.aniversario != null &&
            diasAteAniversario(c.aniversario!) <= diasLembrete)
        .toList()
      ..sort((a, b) => diasAteAniversario(a.aniversario!)
          .compareTo(diasAteAniversario(b.aniversario!)));
    return lista;
  }

  // ---------- Importação / Exportação ----------

  String exportarCsv({String separador = ';'}) {
    String escapar(String v) {
      if (v.contains(separador) || v.contains('"') || v.contains('\n')) {
        return '"${v.replaceAll('"', '""')}"';
      }
      return v;
    }

    final linhas = <String>[Contact.csvHeader.join(separador)];
    for (final c in contatos) {
      linhas.add(c.toCsvFields().map(escapar).join(separador));
    }
    return linhas.join('\n');
  }

  /// Lê CSV (`;` ou `,`) ou texto colado do Excel (tab). Ignora o cabeçalho.
  List<Contact> lerCsv(String texto) {
    final linhas = texto
        .replaceAll('\r\n', '\n')
        .split('\n')
        .where((l) => l.trim().isNotEmpty)
        .toList();
    if (linhas.isEmpty) return [];

    final primeira = linhas.first;
    final sep = primeira.contains('\t')
        ? '\t'
        : primeira.contains(';')
            ? ';'
            : ',';

    final resultado = <Contact>[];
    for (var i = 0; i < linhas.length; i++) {
      final campos = _separar(linhas[i], sep);
      if (i == 0 && campos.isNotEmpty && campos.first.trim().toLowerCase() == 'nome') {
        continue;
      }
      final c = Contact.fromCsvFields(_novoId(), campos);
      if (c != null) resultado.add(c);
    }
    return resultado;
  }

  List<String> _separar(String linha, String sep) {
    final campos = <String>[];
    final atual = StringBuffer();
    var aspas = false;
    for (var i = 0; i < linha.length; i++) {
      final ch = linha[i];
      if (ch == '"') {
        if (aspas && i + 1 < linha.length && linha[i + 1] == '"') {
          atual.write('"');
          i++;
        } else {
          aspas = !aspas;
        }
      } else if (ch == sep && !aspas) {
        campos.add(atual.toString());
        atual.clear();
      } else {
        atual.write(ch);
      }
    }
    campos.add(atual.toString());
    return campos;
  }

  void importar(List<Contact> novos) {
    for (final c in novos) {
      for (final cat in c.categorias) {
        if (!categorias.contains(cat)) categorias.add(cat);
      }
      _contatos.add(c);
    }
    notifyListeners();
  }

  // ---------- Backup automático ----------

  bool backupAuto = false;
  int intervaloBackupMin = 1;
  String? ultimoBackupCsv;
  DateTime? ultimoBackupEm;
  Timer? _timerBackup;

  void fazerBackup() {
    ultimoBackupCsv = exportarCsv();
    ultimoBackupEm = DateTime.now();
    notifyListeners();
  }

  void setBackupAuto(bool v) {
    backupAuto = v;
    _reiniciarTimer();
    if (v) {
      fazerBackup();
    } else {
      notifyListeners();
    }
  }

  void setIntervaloBackup(int minutos) {
    intervaloBackupMin = minutos;
    _reiniciarTimer();
    notifyListeners();
  }

  void _reiniciarTimer() {
    _timerBackup?.cancel();
    _timerBackup = null;
    if (backupAuto) {
      _timerBackup = Timer.periodic(
        Duration(minutes: intervaloBackupMin),
        (_) => fazerBackup(),
      );
    }
  }

  /// Substitui os contatos atuais pelos do último backup.
  int restaurarBackup() {
    final csv = ultimoBackupCsv;
    if (csv == null) return 0;
    final lidos = lerCsv(csv);
    _contatos.clear();
    for (final g in grupos) {
      g.memberIds.clear();
    }
    importar(lidos);
    return lidos.length;
  }

  // ---------- Dados de exemplo ----------

  void _carregarExemplos() {
    final hoje = DateTime.now();
    DateTime niver(int diasAFrente, int ano) {
      final d = hoje.add(Duration(days: diasAFrente));
      return DateTime(ano, d.month, d.day);
    }

    final exemplos = [
      Contact(
        id: _novoId(),
        nome: 'Ana Souza',
        email: 'ana.souza@email.com',
        telefone: '(11) 98765-4321',
        cidade: 'São Paulo',
        empresa: 'Tech SA',
        categorias: {'Trabalho'},
        favorito: true,
        corAvatar: Colors.purple,
        aniversario: niver(0, 1995),
        observacoes: 'Colega do time de produto.',
        dataCadastro: hoje.subtract(const Duration(days: 40)),
      ),
      Contact(
        id: _novoId(),
        nome: 'Bruno Lima',
        email: 'bruno@email.com',
        telefone: '(21) 99888-7766',
        cidade: 'Rio de Janeiro',
        empresa: 'Loja Lima',
        categorias: {'Clientes'},
        corAvatar: Colors.blue,
        aniversario: niver(3, 1988),
        dataCadastro: hoje.subtract(const Duration(days: 20)),
      ),
      Contact(
        id: _novoId(),
        nome: 'Carla Mendes',
        email: 'carla.m@email.com',
        telefone: '(31) 97777-1234',
        cidade: 'Belo Horizonte',
        categorias: {'Família'},
        favorito: true,
        corAvatar: Colors.teal,
        aniversario: niver(15, 1990),
        observacoes: 'Prima.',
        dataCadastro: hoje.subtract(const Duration(days: 5)),
      ),
      Contact(
        id: _novoId(),
        nome: 'Diego Rocha',
        email: 'diego.rocha@email.com',
        telefone: '(11) 96666-5555',
        cidade: 'São Paulo',
        empresa: 'Tech SA',
        categorias: {'Amigos', 'Trabalho'},
        corAvatar: Colors.orange,
        aniversario: niver(60, 1992),
        dataCadastro: hoje,
      ),
    ];
    _contatos.addAll(exemplos);
    grupos.add(Group(
      id: _novoId(),
      nome: 'Futebol de quinta',
      memberIds: {exemplos[1].id, exemplos[3].id},
    ));
  }
}
