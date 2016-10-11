import 'dart:async';
import 'dart:io';

class WebSocketDebugger {
  WebSocket controlador;
  Completer _proximo;
  StreamController _mensajesController = new StreamController();

  bool todoBien = false;

  Stream get mensajes => _mensajesController.stream;

  Future get proximoMensajeARecibir {
    _proximo ??= new Completer();
    return _proximo.future;
  }

  var ultimoMensajeRecibido;

  var mensajeADevolver;

  bool mantenerMensajeADevolver = false;

  enviarMensaje(msj) {
    controlador.add(msj);
  }

  WebSocketDebugger([int puerto = 1234]) {
    WebSocket.connect("ws://localhost:$puerto").then((ws) {
      controlador = ws;
      controlador.listen(_manejarMensajes);
    });
  }

  void _manejarMensajes(datos) {
    if (datos == "hay conexion") {
      todoBien = true;
      return;
    }
    ultimoMensajeRecibido = datos;
    if (_proximo != null) {
      _proximo.complete(datos);
      _proximo = null;
    }
    if (mensajeADevolver != null) {
      controlador.add(mensajeADevolver);
      if (!mantenerMensajeADevolver) mensajeADevolver = null;
    }
    _mensajesController.add(datos);
  }
}
