// Salvar dados e escolher/baixar arquivos sem usar pacotes externos.
// No navegador usa o arquivo plataforma_web.dart; nas outras plataformas
// usa plataforma_stub.dart, que não faz nada.
export 'plataforma_stub.dart' if (dart.library.js_interop) 'plataforma_web.dart';
