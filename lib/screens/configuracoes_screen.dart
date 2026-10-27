import 'package:flutter/material.dart';

import '../models/contact.dart';
import '../services/plataforma.dart';
import '../store/agenda_store.dart';
import '../widgets/dialogos.dart';

/// Tela de Configurações: tema, backup automático e preferências.
class ConfiguracoesScreen extends StatelessWidget {
  const ConfiguracoesScreen({super.key});

  /// Cores que podem ser usadas no tema do app.
  static const coresTema = [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.deepPurple,
    Colors.orange,
  ];

  Future<void> restaurar(BuildContext context) async {
    final ok = await confirmar(
      context,
      'Restaurar backup',
      'Os contatos atuais serão trocados pelos do backup de '
          '${formatarDataHora(agenda.ultimoBackupEm!)}. Continuar?',
      'Restaurar',
    );
    if (!ok || !context.mounted) return;

    final quantidade = agenda.restaurarBackup();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$quantidade contato(s) restaurado(s).')),
    );
  }

  Future<void> apagarTudo(BuildContext context) async {
    final ok = await confirmar(
      context,
      'Apagar todos os dados',
      'Todos os contatos, grupos e o backup serão apagados. Essa ação não pode ser desfeita.',
      'Apagar',
    );
    if (ok) agenda.apagarTudo();
  }

  /// Título de cada seção da tela.
  Widget titulo(String texto) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Text(texto, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
    );
  }

  /// Bolinhas para escolher a cor do tema.
  Widget escolhaDeCor() {
    return Wrap(
      spacing: 8,
      children: [
        for (final cor in coresTema)
          GestureDetector(
            onTap: () {
              agenda.setCorTema(cor);
            },
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: CircleAvatar(
                radius: 14,
                backgroundColor: cor,
                child: agenda.corTema.toARGB32() == cor.toARGB32()
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : null,
              ),
            ),
          ),
      ],
    );
  }

  /// Texto no fim da tela explicando onde os dados ficam salvos.
  String textoSobreOsDados() {
    if (!suportaArquivos) {
      return 'Os dados ficam em memória enquanto o app estiver aberto.';
    }
    if (!agenda.salvoNoNavegador) {
      return 'Não foi possível salvar no navegador (espaço cheio). '
          'Remova fotos grandes ou exporte um backup em CSV.';
    }
    return 'Os dados são salvos automaticamente neste navegador. '
        'Use Importar / Exportar para guardar uma cópia em arquivo CSV.';
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: agenda,
      builder: (context, child) {
        String textoUltimoBackup = 'Nenhum backup feito';
        if (agenda.ultimoBackupEm != null) {
          textoUltimoBackup = formatarDataHora(agenda.ultimoBackupEm!);
        }

        return Scaffold(
          appBar: AppBar(title: const Text('Configurações'), centerTitle: true),
          body: ListView(
            children: [
              titulo('Aparência'),
              SwitchListTile(
                secondary: Icon(agenda.darkMode ? Icons.dark_mode : Icons.light_mode),
                title: const Text('Tema escuro'),
                subtitle: Text(agenda.darkMode ? 'Escuro' : 'Claro'),
                value: agenda.darkMode,
                onChanged: agenda.setDarkMode,
              ),
              ListTile(
                leading: const Icon(Icons.palette),
                title: const Text('Cor do tema'),
                subtitle: escolhaDeCor(),
              ),

              titulo('Backup'),
              SwitchListTile(
                secondary: const Icon(Icons.backup),
                title: const Text('Backup automático'),
                subtitle: Text(agenda.backupAuto ? 'A cada ${agenda.intervaloBackupMin} min' : 'Desativado'),
                value: agenda.backupAuto,
                onChanged: agenda.setBackupAuto,
              ),
              ListTile(
                leading: const Icon(Icons.timer),
                title: const Text('Intervalo'),
                trailing: DropdownButton<int>(
                  value: agenda.intervaloBackupMin,
                  onChanged: (minutos) {
                    if (minutos != null) agenda.setIntervaloBackup(minutos);
                  },
                  items: const [
                    DropdownMenuItem(value: 1, child: Text('1 min')),
                    DropdownMenuItem(value: 5, child: Text('5 min')),
                    DropdownMenuItem(value: 15, child: Text('15 min')),
                    DropdownMenuItem(value: 60, child: Text('1 hora')),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.history),
                title: const Text('Último backup'),
                subtitle: Text(textoUltimoBackup),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {
                        agenda.fazerBackup();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Backup feito.')),
                        );
                      },
                      icon: const Icon(Icons.save_alt),
                      label: const Text('Fazer backup agora'),
                    ),
                    OutlinedButton.icon(
                      onPressed: agenda.ultimoBackup == null ? null : () => restaurar(context),
                      icon: const Icon(Icons.restore),
                      label: const Text('Restaurar último backup'),
                    ),
                  ],
                ),
              ),

              titulo('Preferências'),
              SwitchListTile(
                secondary: const Icon(Icons.sort_by_alpha),
                title: const Text('Ordem alfabética crescente'),
                subtitle: Text(agenda.ordemCrescente ? 'A → Z' : 'Z → A'),
                value: agenda.ordemCrescente,
                onChanged: agenda.setOrdemCrescente,
              ),
              SwitchListTile(
                secondary: const Icon(Icons.phone),
                title: const Text('Mostrar telefone na lista'),
                value: agenda.mostrarTelefoneNaLista,
                onChanged: agenda.setMostrarTelefone,
              ),
              ListTile(
                leading: const Icon(Icons.notifications),
                title: const Text('Antecedência dos lembretes de aniversário'),
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
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: const Text('Apagar todos os dados'),
                subtitle: const Text('Remove contatos, grupos e backup'),
                onTap: () => apagarTudo(context),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(textoSobreOsDados(), style: const TextStyle(fontSize: 12)),
              ),
            ],
          ),
        );
      },
    );
  }
}
