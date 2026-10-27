// Versão usada fora do navegador (Android, Windows, testes...).
// Nada é salvo e não há escolha de arquivos.

const suportaArquivos = false;

String? lerDoNavegador(String chave) {
  return null;
}

bool salvarNoNavegador(String chave, String valor) {
  return false;
}

void baixarArquivo(String nomeArquivo, String conteudo) {}

Future<String?> escolherArquivoCsv() async {
  return null;
}

Future<String?> escolherImagem() async {
  return null;
}
