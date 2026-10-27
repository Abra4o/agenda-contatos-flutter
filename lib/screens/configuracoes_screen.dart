import 'package:flutter/material.dart';

import '../models/contact.dart';
import '../store/agenda_store.dart';

/// Tela de Configurações: tema, backup automático e preferências.
class ConfiguracoesScreen extends StatelessWidget {
  const ConfiguracoesScreen({super.key});

  static const _coresTema = {
    'Vermelho': Colors.red,
    'Azul': Colors.blue,
    'Verde': Colors.green,
    'Roxo': Colors.deepPurple,
    'Laranja': Colors.orange,
  };

  Future<void> _restaurar(BuildContext context) async {
    final store = AgendaStore.instance;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restaurar backup'),
        content: Text(
          'Os contatos atuais serão substituídos pelos do backup de '
          '${formatDateTime(store.ultimoBackupEm!)}. Continuar?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Restaurar')),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      final n = store.restaurarBackup();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$n contato(s) restaurado(s).')),
      );
    }
  }

  Widget _titulo(BuildContext context, String t) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
        child: Text(
          t,
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final store = AgendaStore.instance;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('Configurações'), centerTitle: true),
          body: ListView(
            children: [
              _titulo(context, 'Aparência'),
              SwitchListTile(
                secondary: Icon(store.darkMode ? Icons.dark_mode : Icons.light_mode),
                title: const Text('Tema escuro'),
                subtitle: Text(store.darkMode ? 'Escuro' : 'Claro'),
                value: store.darkMode,
                onChanged: store.setDarkMode,
              ),
              ListTile(
                leading: const Icon(Icons.palette),
                title: const Text('Cor do tema'),
                subtitle: Wrap(
                  spacing: 8,
                  children: [
                    for (final e in _coresTema.entries)
                      Tooltip(
                        message: e.key,
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () => store.setCorTema(e.value),
                          child: Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: CircleAvatar(
                              radius: 14,
                              backgroundColor: e.value,
                              child: store.corTema == e.value
                                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                                  : null,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              _titulo(context, 'Backup'),
              SwitchListTile(
                secondary: const Icon(Icons.backup),
                title: const Text('Backup automático'),
                subtitle: Text(store.backupAuto
                    ? 'A cada ${store.intervaloBackupMin} min'
                    : 'Desativado'),
                value: store.backupAuto,
                onChanged: store.setBackupAuto,
              ),
              ListTile(
                enabled: store.backupAuto,
                leading: const Icon(Icons.timer),
                title: const Text('Intervalo'),
                trailing: DropdownButton<int>(
                  value: store.intervaloBackupMin,
                  onChanged: store.backupAuto ? (v) => store.setIntervaloBackup(v!) : null,
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
                subtitle: Text(store.ultimoBackupEm == null
                    ? 'Nenhum backup feito'
                    : formatDateTime(store.ultimoBackupEm!)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {
                        store.fazerBackup();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Backup feito.')),
                        );
                      },
                      icon: const Icon(Icons.save_alt),
                      label: const Text('Fazer backup agora'),
                    ),
                    OutlinedButton.icon(
                      onPressed: store.ultimoBackupCsv == null ? null : () => _restaurar(context),
                      icon: const Icon(Icons.restore),
                      label: const Text('Restaurar último backup'),
                    ),
                  ],
                ),
              ),
              _titulo(context, 'Preferências'),
              SwitchListTile(
                secondary: const Icon(Icons.sort_by_alpha),
                title: const Text('Ordem alfabética crescente'),
                subtitle: Text(store.ordemCrescente ? 'A → Z' : 'Z → A'),
                value: store.ordemCrescente,
                onChanged: store.setOrdemCrescente,
              ),
              SwitchListTile(
                secondary: const Icon(Icons.phone),
                title: const Text('Mostrar telefone na lista'),
                value: store.mostrarTelefoneNaLista,
                onChanged: store.setMostrarTelefone,
              ),
              ListTile(
                leading: const Icon(Icons.notifications),
                title: const Text('Antecedência dos lembretes de aniversário'),
                trailing: DropdownButton<int>(
                  value: store.diasLembrete,
                  onChanged: (v) => store.setDiasLembrete(v!),
                  items: [
                    for (final d in [3, 7, 15, 30])
                      DropdownMenuItem(value: d, child: Text('$d dias')),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Os dados ficam em memória enquanto o app estiver aberto (o exercício '
                  'usa apenas widgets, sem pacotes de banco de dados). Use Exportar para '
                  'guardar uma cópia em CSV.',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
