import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:agenda_contatos/main.dart';
import 'package:agenda_contatos/store/agenda_store.dart';

void main() {
  testWidgets('lista em ordem alfabética e busca filtra', (tester) async {
    await tester.pumpWidget(const AgendaApp());
    expect(find.text('Agenda de Contatos'), findsOneWidget);

    final nomes = tester
        .widgetList<ListTile>(find.byType(ListTile))
        .map((t) => (t.title as Text?)?.data)
        .whereType<String>()
        .toList();
    expect(nomes, ['Ana Souza', 'Bruno Lima', 'Carla Mendes', 'Diego Rocha']);

    await tester.enterText(find.byType(TextField), 'bruno@');
    await tester.pump();
    expect(find.text('Bruno Lima'), findsOneWidget);
    expect(find.text('Ana Souza'), findsNothing);
  });

  testWidgets('cadastro salva novo contato', (tester) async {
    await tester.pumpWidget(const AgendaApp());
    await tester.tap(find.byTooltip('Novo contato'));
    await tester.pumpAndSettle();
    expect(find.text('Novo Contato'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextFormField, 'Nome'), 'Zeca Teste');
    await tester.tap(find.byTooltip('Salvar'));
    await tester.pumpAndSettle();

    expect(AgendaStore.instance.contatos.any((c) => c.nome == 'Zeca Teste'), isTrue);
  });

  test('CSV exporta e reimporta', () {
    final store = AgendaStore.instance;
    final lidos = store.lerCsv(store.exportarCsv());
    expect(lidos.length, store.contatos.length);
    expect(lidos.first.nome, store.contatos.first.nome);

    final excel = store.lerCsv('Fulano\tf@x.com\t123');
    expect(excel.single.email, 'f@x.com');
  });
}
