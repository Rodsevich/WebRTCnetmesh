import 'dart:io';
import 'dart:async';

///Clase propia de Servidor que abstrae el servicio de la página y el establecimiento
/// de los WebSockets. Su tarea principal es la de proveer [Cliente]s
class Servidor {
  HttpServer _server;
  // Directory _carpetaBuild;
  StreamController _notificadorPedidosHTML = new StreamController();
  StreamController _notificadorNuevoWebSocket = new StreamController();
  Stream<HttpRequest> get onPedidoHTML => _notificadorPedidosHTML.stream;
  Stream<WebSocket> get onNuevoWebSocket => _notificadorNuevoWebSocket.stream;

  Servidor([String path_build = "../build", int puerto = 4040]) {
        HttpServer.bind(InternetAddress.LOOPBACK_IP_V4, 4040).then((HttpServer srv) {
      print("HttpServer: escuchando en el 4040");
      _server = srv;
      _server.serverHeader = "Servidor hecho con Dart por Nico";
      _manejarPedidos();
    });
    // _carpetaBuild = new Directory(path_build);
  }

  _manejarPedidos() async {
    await for (HttpRequest pedido in _server) {
      if (WebSocketTransformer.isUpgradeRequest(pedido)) {
        WebSocketTransformer
            .upgrade(pedido)
            .then((ws) => _notificadorNuevoWebSocket.add(ws));
      } else {
        _devolverPedidoInvalido(pedido);
      }
    }
  }

  _devolverPedidoInvalido(HttpRequest pedido) {
    HttpResponse respuesta = pedido.response;
    respuesta.statusCode = HttpStatus.FORBIDDEN;
    respuesta.reasonPhrase =
        '''Este servidor está programado solo para WebSockets, ¡POR AHORA!:
        Posterioremente se le adicionará la funcionalidad de proveer el sitio completo
        ''';
    _notificadorPedidosHTML.add(pedido);
    respuesta.close();
  }
}
