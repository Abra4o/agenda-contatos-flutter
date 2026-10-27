import 'package:flutter/material.dart';

import '../models/contact.dart';
import '../store/agenda_store.dart';
import '../widgets/contact_avatar.dart';
import '../widgets/contact_tile.dart';
import 'detalhes_screen.dart';

/// Tela de Aniversários: aniversariantes do mês e lembretes de datas próximas.
class AniversariosScreen extends StatefulWidget {
  const AniversariosScreen({super.key});

  @override
  State<AniversariosScreen> createState() => _AniversariosScreenState();
}

class _AniversariosScreenState extends State<AniversariosScreen> {
  int _mes = DateTime.now().month;

  String _quando(int dias) {
    if (dias == 0) return 'Hoje! 🎉';
    if (dias == 1) return 'Amanhã';
    return 'Faltam $dias dias';
  }

  Widget _tile(Contact c) {
    final dias = AgendaStore.diasAteAniversario(c.aniversario!);
    // Idade que a pessoa completa no próximo aniversário.
    final idade = DateTime.now().add(Duration(days: dias)).year - c.aniversario!.year;
    return ListTile(
      leading: ContactAvatar(contact: c),
      title: Text(c.nome),
      subtitle: Text(
        '${formatDate(c.aniversario!).substring(0, 5)}  •  ${_quando(dias)}  •  completa $idade anos',
      ),
      trailing: dias == 0 ? const Icon(Icons.cake, color: Colors.pink) : null,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DetalhesScreen(contatoId: c.id)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = AgendaStore.instance;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final lembretes = store.lembretes;
        final doMes = store.aniversariantesDoMes(_mes);
        final tema = Theme.of(context);
        return Scaffold(
          appBar: AppBar(title: const Text('Aniversários'), centerTitle: true),
          body: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              Card(
                margin: const EdgeInsets.all(12),
                color: tema.colorScheme.primaryContainer,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.notifications_active),
                      title: const Text('Lembretes'),
                      subtitle: Text('Próximos ${store.diasLembrete} dias'),
                      trailing: PopupMenuButton<int>(
                        tooltip: 'Antecedência',
                        icon: const Icon(Icons.tune),
                        onSelected: store.setDiasLembrete,
                        itemBuilder: (_) => [
                          for (final d in [3, 7, 15, 30])
                            CheckedPopupMenuItem(
                              value: d,
                              checked: store.diasLembrete == d,
                              child: Text('$d dias'),
                            ),
                        ],
                      ),
                    ),
                    if (lembretes.isEmpty)
                      const Padding(
                        padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Text('Nenhum aniversário próximo.'),
                      ),
                    for (final c in lembretes) _tile(c),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'Mês anterior',
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () => setState(() => _mes = _mes == 1 ? 12 : _mes - 1),
                    ),
                    Expanded(
                      child: Text(
                        'Aniversariantes de ${nomesMeses[_mes - 1]}',
                        textAlign: TextAlign.center,
                        style: tema.textTheme.titleMedium,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Próximo mês',
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () => setState(() => _mes = _mes == 12 ? 1 : _mes + 1),
                    ),
                  ],
                ),
              ),
              if (doMes.isEmpty)
                const SizedBox(
                  height: 200,
                  child: EmptyState(icon: Icons.cake_outlined, texto: 'Ninguém faz aniversário neste mês.'),
                ),
              for (final c in doMes) _tile(c),
            ],
          ),
        );
      },
    );
  }
}
