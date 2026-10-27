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
  final Set<String> _categorias = {};
  String? _cidade;
  String? _empresa;
  DateTimeRange? _periodo;

  bool get _temFiltro =>
      _categorias.isNotEmpty || _cidade != null || _empresa != null || _periodo != null;

  List<Contact> _filtrar(List<Contact> todos) {
    return todos.where((c) {
      if (_categorias.isNotEmpty && !c.categorias.any(_categorias.contains)) return false;
      if (_cidade != null && c.cidade != _cidade) return false;
      if (_empresa != null && c.empresa != _empresa) return false;
      if (_periodo != null) {
        final d = DateUtils.dateOnly(c.dataCadastro);
        if (d.isBefore(_periodo!.start) || d.isAfter(_periodo!.end)) return false;
      }
      return true;
    }).toList();
  }

  Future<void> _escolherPeriodo() async {
    final r = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      initialDateRange: _periodo,
      helpText: 'Data de cadastro',
    );
    if (r != null) setState(() => _periodo = r);
  }

  void _limpar() => setState(() {
        _categorias.clear();
        _cidade = null;
        _empresa = null;
        _periodo = null;
      });

  Widget _dropdown(String label, IconData icon, List<String> opcoes, String? valor,
      ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String?>(
      key: ValueKey('$label-$valor'),
      initialValue: valor,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      items: [
        const DropdownMenuItem(value: null, child: Text('Todas')),
        for (final o in opcoes) DropdownMenuItem(value: o, child: Text(o)),
      ],
      onChanged: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = AgendaStore.instance;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final todos = store.contatos;
        final cidades = todos.map((c) => c.cidade).where((s) => s.isNotEmpty).toSet().toList()..sort();
        final empresas = todos.map((c) => c.empresa).where((s) => s.isNotEmpty).toSet().toList()..sort();
        final resultado = _filtrar(todos);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Pesquisa Avançada'),
            centerTitle: true,
            actions: [
              if (_temFiltro)
                TextButton(
                  onPressed: _limpar,
                  style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.onPrimary),
                  child: const Text('Limpar'),
                ),
            ],
          ),
          body: ListView(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Categorias'),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        for (final cat in store.categorias)
                          FilterChip(
                            label: Text(cat),
                            selected: _categorias.contains(cat),
                            onSelected: (s) =>
                                setState(() => s ? _categorias.add(cat) : _categorias.remove(cat)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _dropdown('Cidade', Icons.location_city, cidades, _cidade,
                        (v) => setState(() => _cidade = v)),
                    const SizedBox(height: 12),
                    _dropdown('Empresa', Icons.business, empresas, _empresa,
                        (v) => setState(() => _empresa = v)),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _escolherPeriodo,
                      icon: const Icon(Icons.date_range),
                      label: Text(_periodo == null
                          ? 'Data de cadastro: qualquer'
                          : 'Cadastro: ${formatDate(_periodo!.start)} a ${formatDate(_periodo!.end)}'),
                    ),
                    if (_periodo != null)
                      TextButton(
                        onPressed: () => setState(() => _periodo = null),
                        child: const Text('Remover filtro de data'),
                      ),
                  ],
                ),
              ),
              const Divider(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Text('${resultado.length} resultado(s)',
                    style: Theme.of(context).textTheme.titleSmall),
              ),
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
