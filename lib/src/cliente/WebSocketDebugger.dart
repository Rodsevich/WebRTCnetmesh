import 'dart:async';
import 'dart:html';

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
    controlador.send(msj);
  }

  WebSocketDebugger([int puerto = 1234]) {
    controlador = new WebSocket("ws://localhost:$puerto");
    controlador.onMessage.listen(_manejarMensajes);
  }

  void _manejarMensajes(MessageEvent evt) {
    var datos = evt.data;
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
      controlador.send(mensajeADevolver);
      if (!mantenerMensajeADevolver) mensajeADevolver = null;
    }
    _mensajesController.add(datos);
  }
}
