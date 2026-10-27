# Agenda de Contatos (Flutter)

Exercício de Programação para Dispositivos Móveis: agenda de contatos feita somente com widgets do Flutter (sem pacotes externos).

## Telas

- Cadastro de Contato
- Listagem (busca por nome, e-mail ou telefone, ordem alfabética)
- Detalhes (editar e excluir)
- Edição (alterar dados e foto, salvar ou cancelar)
- Favoritos
- Categorias (Família, Amigos, Trabalho, Clientes e novas)
- Grupos (membros)
- Aniversários (do mês e lembretes)
- Pesquisa Avançada (categoria, cidade, empresa, data de cadastro)
- Importação e Exportação (CSV / Excel)
- Configurações (tema claro/escuro, backup automático, preferências)

## Como rodar

```
flutter pub get
flutter run -d chrome
```

No navegador, os dados (contatos, categorias, grupos, preferências e último backup) são salvos automaticamente no `localStorage`, usando apenas o SDK do Dart (`dart:js_interop`), sem pacotes. Em outras plataformas eles ficam em memória.

Importação/exportação: escolher ou baixar arquivo `.csv` (o Excel abre e salva nesse formato), ou copiar e colar direto de uma planilha. A foto do contato pode ser uma URL ou uma imagem escolhida do computador (até 500 KB).
