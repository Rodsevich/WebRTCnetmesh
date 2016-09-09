import 'dart:io';
import 'dart:async';

import 'Cliente.dart';

///Clase propia de Servidor que abstrae el servicio de la página y el establecimiento
/// de los WebSockets. Su tarea principal es la de proveer [Cliente]s
class Servidor {
  HttpServer _server;
  // Directory _carpetaBuild;
  StreamController _notificadorPedidosHTML;
  StreamController _notificadorNuevoCliente;
  Stream<HttpRequest> get onPedidoHTML => _notificadorPedidosHTML.stream;
  Stream<Cliente> get onNuevoCliente => _notificadorNuevoCliente.stream;

  Servidor([String path_build = "../build", int puerto = 4040]) {
    HttpServer
        .bind(InternetAddress.LOOPBACK_IP_V4, puerto)
        .then((HttpServer srv) {
      _server = srv;
      _server.serverHeader = "Servidor hecho con Dart por Nico";
      _notificadorPedidosHTML = new StreamController();
      _notificadorNuevoCliente = new StreamController();
      _manejarPedidos();
    });
    // _carpetaBuild = new Directory(path_build);
  }

  _manejarPedidos() async {
    await for (HttpRequest pedido in _server) {
      if (WebSocketTransformer.isUpgradeRequest(pedido)) {
        WebSocketTransformer.upgrade(pedido).then(_nuevaConexionWebSocket);
      } else {
        _devolverPedidoInvalido(pedido);
      }
    }
  }

  _nuevaConexionWebSocket(WebSocket ws) {
    Cliente cliente = new Cliente(ws);
    _notificadorNuevoCliente.add(cliente);
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
