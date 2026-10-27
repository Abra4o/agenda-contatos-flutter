import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:agenda_contatos/main.dart';
import 'package:agenda_contatos/models/contact.dart';
import 'package:agenda_contatos/store/agenda_store.dart';

void main() {
  testWidgets('lista em ordem alfabética e busca filtra', (tester) async {
    await tester.pumpWidget(const AgendaApp());
    expect(find.text('Agenda de Contatos'), findsOneWidget);

    final nomes = <String>[];
    for (final tile in tester.widgetList<ListTile>(find.byType(ListTile))) {
      final titulo = tile.title;
      if (titulo is Text && titulo.data != null) nomes.add(titulo.data!);
    }
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
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    bool achou = false;
    for (final c in agenda.contatos) {
      if (c.nome == 'Zeca Teste') achou = true;
    }
    expect(achou, isTrue);
  });

  test('CSV exporta e reimporta', () {
    final lidos = agenda.lerCsv(agenda.exportarCsv());
    expect(lidos.length, agenda.contatos.length);
    expect(lidos.first.nome, agenda.contatos.first.nome);

    final doExcel = agenda.lerCsv('Fulano\tf@x.com\t123');
    expect(doExcel.single.email, 'f@x.com');

    // CSV salvo pelo Excel vem com BOM no começo; favorito é lido.
    final comBom = agenda.lerCsv('﻿${colunasCsv.join(';')}\nBeltrano;;;;;;;;sim');
    expect(comBom.single.nome, 'Beltrano');
    expect(comBom.single.favorito, isTrue);
  });

  test('JSON guarda todos os campos do contato', () {
    final c = Contact(
      id: 'x1',
      nome: 'Maria',
      favorito: true,
      corAvatar: Colors.teal,
      categorias: ['Amigos'],
      aniversario: DateTime(1990, 5, 10),
      fotoUrl: 'data:image/png;base64,AAAA',
    );
    final copia = Contact.fromJson(c.toJson());
    expect(copia.id, 'x1');
    expect(copia.favorito, isTrue);
    expect(copia.corAvatar.toARGB32(), Colors.teal.toARGB32());
    expect(copia.categorias, ['Amigos']);
    expect(copia.aniversario, DateTime(1990, 5, 10));
    expect(copia.fotoUrl, c.fotoUrl);
  });

  test('restaurar backup mantém favoritos e grupos', () {
    agenda.fazerBackup();
    final qtdFavoritos = agenda.favoritos.length;
    final qtdMembros = agenda.membros(agenda.grupos.first).length;

    agenda.excluir(agenda.favoritos.first);
    expect(agenda.favoritos.length, qtdFavoritos - 1);

    agenda.restaurarBackup();
    expect(agenda.favoritos.length, qtdFavoritos);
    expect(agenda.membros(agenda.grupos.first).length, qtdMembros);
  });
}
