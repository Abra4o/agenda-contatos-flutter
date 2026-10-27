import 'package:flutter/material.dart';

import '../models/contact.dart';
import '../store/agenda_store.dart';
import '../widgets/contact_tile.dart';

/// Tela de Pesquisa Avançada: filtra por categoria, cidade, empresa e data de cadastro.
class PesquisaAvancadaScreen extends StatefulWidget {
  const PesquisaAvancadaScreen({super.key});

  @override
  State<PesquisaAvancadaScreen> createState() => _PesquisaAvancadaScreenState();
}

class _PesquisaAvancadaScreenState extends State<PesquisaAvancadaScreen> {
  // Filtros escolhidos. Vazio ou null = sem filtro.
  List<String> categoriasEscolhidas = [];
  String? cidade;
  String? empresa;
  DateTime? cadastroDe;
  DateTime? cadastroAte;

  /// Retorna true se o contato passa em todos os filtros.
  bool passaNosFiltros(Contact c) {
    if (categoriasEscolhidas.isNotEmpty) {
      bool temCategoria = false;
      for (final cat in c.categorias) {
        if (categoriasEscolhidas.contains(cat)) temCategoria = true;
      }
      if (!temCategoria) return false;
    }

    if (cidade != null && c.cidade != cidade) return false;
    if (empresa != null && c.empresa != empresa) return false;

    if (cadastroDe != null && cadastroAte != null) {
      // Compara só a data, sem a hora.
      final data = DateTime(c.dataCadastro.year, c.dataCadastro.month, c.dataCadastro.day);
      if (data.isBefore(cadastroDe!) || data.isAfter(cadastroAte!)) return false;
    }
    return true;
  }

  Future<void> escolherPeriodo() async {
    final periodo = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      helpText: 'Data de cadastro',
    );
    if (periodo != null) {
      setState(() {
        cadastroDe = periodo.start;
        cadastroAte = periodo.end;
      });
    }
  }

  void limparFiltros() {
    setState(() {
      categoriasEscolhidas = [];
      cidade = null;
      empresa = null;
      cadastroDe = null;
      cadastroAte = null;
    });
  }

  /// Lista sem repetição e em ordem. Ex.: cidades de todos os contatos.
  List<String> semRepetir(List<String> valores) {
    final lista = <String>[];
    for (final v in valores) {
      if (v.isNotEmpty && !lista.contains(v)) lista.add(v);
    }
    lista.sort();
    return lista;
  }

  /// Caixa de seleção com a opção "Todas" (null) no começo.
  Widget caixaDeSelecao(String rotulo, List<String> opcoes, String? valor, ValueChanged<String?> aoMudar) {
    final itens = <DropdownMenuItem<String>>[];
    itens.add(const DropdownMenuItem(value: null, child: Text('Todas')));
    for (final opcao in opcoes) {
      itens.add(DropdownMenuItem(value: opcao, child: Text(opcao)));
    }

    return Row(
      children: [
        SizedBox(width: 80, child: Text(rotulo)),
        Expanded(
          child: DropdownButton<String>(
            value: valor,
            isExpanded: true,
            items: itens,
            onChanged: aoMudar,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: agenda,
      builder: (context, child) {
        final todos = agenda.contatos;

        final listaCidades = <String>[];
        final listaEmpresas = <String>[];
        for (final c in todos) {
          listaCidades.add(c.cidade);
          listaEmpresas.add(c.empresa);
        }
        final cidades = semRepetir(listaCidades);
        final empresas = semRepetir(listaEmpresas);

        // Se a cidade/empresa escolhida não existe mais (contato editado), limpa o filtro.
        if (!cidades.contains(cidade)) cidade = null;
        if (!empresas.contains(empresa)) empresa = null;

        final resultado = <Contact>[];
        for (final c in todos) {
          if (passaNosFiltros(c)) resultado.add(c);
        }

        String textoPeriodo = 'Data de cadastro: qualquer';
        if (cadastroDe != null && cadastroAte != null) {
          textoPeriodo = 'Cadastro: ${formatarData(cadastroDe!)} a ${formatarData(cadastroAte!)}';
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Pesquisa Avançada'),
            centerTitle: true,
            actions: [
              IconButton(
                tooltip: 'Limpar filtros',
                icon: const Icon(Icons.filter_alt_off),
                onPressed: limparFiltros,
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              const Text('Categorias'),
              Wrap(
                spacing: 8,
                children: [
                  for (final cat in agenda.categorias)
                    FilterChip(
                      label: Text(cat),
                      selected: categoriasEscolhidas.contains(cat),
                      onSelected: (marcou) {
                        setState(() {
                          if (marcou) {
                            categoriasEscolhidas.add(cat);
                          } else {
                            categoriasEscolhidas.remove(cat);
                          }
                        });
                      },
                    ),
                ],
              ),
              const SizedBox(height: 12),
              caixaDeSelecao('Cidade', cidades, cidade, (valor) {
                setState(() {
                  cidade = valor;
                });
              }),
              caixaDeSelecao('Empresa', empresas, empresa, (valor) {
                setState(() {
                  empresa = valor;
                });
              }),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: escolherPeriodo,
                icon: const Icon(Icons.date_range),
                label: Text(textoPeriodo),
              ),
              const Divider(height: 32),
              Text('${resultado.length} resultado(s)', style: const TextStyle(fontWeight: FontWeight.bold)),
              if (resultado.isEmpty)
                const SizedBox(
                  height: 200,
                  child: EmptyState(icon: Icons.filter_alt_off, texto: 'Nenhum contato com esses filtros.'),
                ),
              for (final c in resultado) ContactTile(contato: c),
            ],
          ),
        );
      },
    );
  }
}
