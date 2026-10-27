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
  // Mês que está sendo mostrado (1 = janeiro).
  int mes = DateTime.now().month;

  void mesAnterior() {
    setState(() {
      mes--;
      if (mes < 1) mes = 12;
    });
  }

  void proximoMes() {
    setState(() {
      mes++;
      if (mes > 12) mes = 1;
    });
  }

  /// Linha de um aniversariante: data, quantos dias faltam e idade.
  Widget linhaAniversario(Contact c) {
    final dias = AgendaStore.diasAteAniversario(c.aniversario!);

    String quando = 'Faltam $dias dias';
    if (dias == 0) quando = 'Hoje! 🎉';
    if (dias == 1) quando = 'Amanhã';

    // Idade que a pessoa vai completar no próximo aniversário.
    final anoDoProximo = DateTime.now().add(Duration(days: dias)).year;
    final idade = anoDoProximo - c.aniversario!.year;

    final diaEMes = '${doisDigitos(c.aniversario!.day)}/${doisDigitos(c.aniversario!.month)}';
    String texto = '$diaEMes  •  $quando';
    if (idade > 0) texto += '  •  completa $idade anos';

    return ListTile(
      leading: ContactAvatar(contact: c),
      title: Text(c.nome),
      subtitle: Text(texto),
      trailing: dias == 0 ? const Icon(Icons.cake, color: Colors.pink) : null,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => DetalhesScreen(contato: c)),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: agenda,
      builder: (context, child) {
        final lembretes = agenda.lembretes;
        final doMes = agenda.aniversariantesDoMes(mes);

        return Scaffold(
          appBar: AppBar(title: const Text('Aniversários'), centerTitle: true),
          body: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              // Card de lembretes: aniversários dos próximos dias.
              Card(
                margin: const EdgeInsets.all(12),
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.notifications_active),
                      title: const Text('Lembretes'),
                      subtitle: Text('Próximos ${agenda.diasLembrete} dias'),
                      trailing: DropdownButton<int>(
                        value: agenda.diasLembrete,
                        onChanged: (dias) {
                          if (dias != null) agenda.setDiasLembrete(dias);
                        },
                        items: const [
                          DropdownMenuItem(value: 3, child: Text('3 dias')),
                          DropdownMenuItem(value: 7, child: Text('7 dias')),
                          DropdownMenuItem(value: 15, child: Text('15 dias')),
                          DropdownMenuItem(value: 30, child: Text('30 dias')),
                        ],
                      ),
                    ),
                    if (lembretes.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 16),
                        child: Text('Nenhum aniversário próximo.'),
                      ),
                    for (final c in lembretes) linhaAniversario(c),
                  ],
                ),
              ),
              // Escolha do mês.
              Row(
                children: [
                  IconButton(
                    tooltip: 'Mês anterior',
                    icon: const Icon(Icons.chevron_left),
                    onPressed: mesAnterior,
                  ),
                  Expanded(
                    child: Text(
                      'Aniversariantes de ${nomesMeses[mes - 1]}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Próximo mês',
                    icon: const Icon(Icons.chevron_right),
                    onPressed: proximoMes,
                  ),
                ],
              ),
              if (doMes.isEmpty)
                const SizedBox(
                  height: 200,
                  child: EmptyState(icon: Icons.cake_outlined, texto: 'Ninguém faz aniversário neste mês.'),
                ),
              for (final c in doMes) linhaAniversario(c),
            ],
          ),
        );
      },
    );
  }
}
