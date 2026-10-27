// Versão usada no navegador. Conversa com o JavaScript da página usando
// dart:js_interop, que já vem no SDK do Dart (não é um pacote externo).
import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

const suportaArquivos = true;

/// O objeto `document` da página.
JSObject pegarDocumento() {
  return globalContext.getProperty<JSObject>('document'.toJS);
}

/// O objeto `localStorage` do navegador, onde guardamos os dados.
JSObject pegarLocalStorage() {
  return globalContext.getProperty<JSObject>('localStorage'.toJS);
}

/// Lê um texto salvo no navegador. Retorna null se não existir.
String? lerDoNavegador(String chave) {
  try {
    final valor = pegarLocalStorage().callMethod<JSString?>('getItem'.toJS, chave.toJS);
    if (valor == null) return null;
    return valor.toDart;
  } catch (e) {
    return null;
  }
}

/// Salva um texto no navegador. Retorna false se der erro (ex.: espaço cheio).
bool salvarNoNavegador(String chave, String valor) {
  try {
    pegarLocalStorage().callMethod<JSAny?>('setItem'.toJS, chave.toJS, valor.toJS);
    return true;
  } catch (e) {
    return false;
  }
}

/// Faz o navegador baixar um arquivo de texto.
/// Funciona criando um link <a download> e clicando nele.
void baixarArquivo(String nomeArquivo, String conteudo) {
  // "data:" permite colocar o conteúdo do arquivo dentro do próprio link.
  final link = 'data:text/csv;charset=utf-8,${Uri.encodeComponent(conteudo)}';

  final a = pegarDocumento().callMethod<JSObject>('createElement'.toJS, 'a'.toJS);
  a.setProperty('href'.toJS, link.toJS);
  a.setProperty('download'.toJS, nomeArquivo.toJS);
  a.callMethod<JSAny?>('click'.toJS);
}

/// Abre a janela de escolher arquivo e lê o arquivo como texto (CSV)
/// ou como "data URL" (imagem). Retorna null se o usuário cancelar.
Future<String?> escolherArquivo(String tiposAceitos, bool comoImagem) {
  final completer = Completer<String?>();

  final input = pegarDocumento().callMethod<JSObject>('createElement'.toJS, 'input'.toJS);
  input.setProperty('type'.toJS, 'file'.toJS);
  input.setProperty('accept'.toJS, tiposAceitos.toJS);

  // Chamado quando o usuário escolhe um arquivo.
  void quandoEscolher(JSAny? evento) {
    final arquivos = input.getProperty<JSObject>('files'.toJS);
    final quantidade = arquivos.getProperty<JSNumber>('length'.toJS).toDartInt;
    if (quantidade == 0) {
      completer.complete(null);
      return;
    }
    final arquivo = arquivos.callMethod<JSObject>('item'.toJS, 0.toJS);

    // FileReader é a classe do navegador que lê o conteúdo do arquivo.
    final classeFileReader = globalContext.getProperty<JSFunction>('FileReader'.toJS);
    final leitor = classeFileReader.callAsConstructor<JSObject>();

    void quandoTerminarDeLer(JSAny? evento) {
      final resultado = leitor.getProperty<JSString>('result'.toJS);
      completer.complete(resultado.toDart);
    }

    leitor.setProperty('onload'.toJS, quandoTerminarDeLer.toJS);
    if (comoImagem) {
      leitor.callMethod<JSAny?>('readAsDataURL'.toJS, arquivo);
    } else {
      leitor.callMethod<JSAny?>('readAsText'.toJS, arquivo);
    }
  }

  // Chamado quando o usuário fecha a janela sem escolher nada.
  void quandoCancelar(JSAny? evento) {
    completer.complete(null);
  }

  input.setProperty('onchange'.toJS, quandoEscolher.toJS);
  input.setProperty('oncancel'.toJS, quandoCancelar.toJS);
  input.callMethod<JSAny?>('click'.toJS);

  return completer.future;
}

Future<String?> escolherArquivoCsv() {
  return escolherArquivo('.csv,.txt', false);
}

/// Retorna a imagem como texto "data:image/...;base64,...".
Future<String?> escolherImagem() {
  return escolherArquivo('image/*', true);
}
