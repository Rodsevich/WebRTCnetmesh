import 'dart:io';
import 'dart:async';

import 'Cliente.dart';
import 'package:pruebas_dart/src/Mensaje.dart';

/// Clase propia de servidor (en donde se puede meter Shelf y demás tranquilamente)
/// cuya función es la de abstraer las conexiones inter-pares de los clientes que
/// son manejadas en background mientras que emite como eventos todo lo demás
class Servidor {
  List<Cliente> clientes = [];
  HttpServer _server;
  StreamController _notificadorPedidosHTML;
  StreamController _notificadorPedidosWebSocket;
  Stream<HttpRequest> get onPedidoHTML => _notificadorPedidosHTML.stream;
  Stream<MensajeCliente> get onPedidoWebSocket =>
      _notificadorPedidosWebSocket.stream;

  Servidor([int puerto = 4040]) {
    HttpServer
        .bind(InternetAddress.LOOPBACK_IP_V4, puerto)
        .then((HttpServer srv) {
      _server = srv;
      _server.serverHeader = "Servidor hecho con Dart por Nico";
      _notificadorPedidosHTML = new StreamController();
      _notificadorPedidosWebSocket = new StreamController();
      _manejarPedidos();
    });
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
    cliente.onMensaje.listen(_manejarMensajesDeCliente);
    clientes.add(cliente);
  }

  _devolverPedidoInvalido(HttpRequest pedido) {
    HttpResponse respuesta = pedido.response;
    respuesta.statusCode = HttpStatus.FORBIDDEN;
    respuesta.reasonPhrase =
        "Este servidor está programado solo para WebSockets por ahora";
    _notificadorPedidosHTML.add(pedido);
    respuesta.close();
  }

  // @TODO: hacer algo menos negro que un MensajeCliente, tal vez estudiando
  // el sistemas de eventos para encontrar algo mejor como un
  // event.emitterObject y un event.data
  _manejarMensajesDeCliente(MensajeCliente mensajeCliente) {
    Cliente cliente = mensajeCliente.cliente;
    Mensaje msj = mensajeCliente.mensaje;
    switch (msj.tipo) {
      case MensajesAPI.NEGOCIACION_WEBRTC:
        break;
      case MensajesAPI.COMANDO:
        break;
      case MensajesAPI.SUSCRIPCION:
      case MensajesAPI.INFORMACION:
      case MensajesAPI.INDEFINIDO:
      default:
        throw new Exception(
            "El cliente envió un mensaje desconocido (no se qué hacer)");
    }
  }
}
