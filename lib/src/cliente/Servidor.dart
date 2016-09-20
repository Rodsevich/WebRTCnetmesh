import "dart:html";
import "dart:async";
import "../Mensaje.dart";

/// Objeto que tendrá el cliente para facilitar las comunicaciones con el
/// servidor a través de websockets (utilizados también para establecer WebRTC)
class Servidor {
  /// Canal de comunicación con el servidor
  WebSocket _canal;

  Stream<Event> onConexion;
  Stream<Mensaje> onMensaje;

  StreamController<Event> _onConexionController;
  StreamController<Mensaje> _onMensajeController;

  /// se puede proporcionar una URL particular para conectarse con el servidor
  /// por defecto la url que se usará será "ws://${window.location.host}"
  Servidor([String url]) {
    url ??= "ws://localhost:4040";
    log("Creando websocket a: '$url'");
    _canal = new WebSocket(url);
    _canal.onOpen.listen(_manejadorEstablecimientoDeCanal);

    _onConexionController = new StreamController();
    onConexion = _onConexionController.stream;
    _onConexionController.addStream(_canal.onOpen);

    _onMensajeController = new StreamController();
    onMensaje = _onMensajeController.stream;

    log("Esperando establecimiento del canal...");
    _canal.onMessage.listen(_manejadorDatosDesdeCanal);
    _canal.onError.listen(_manejadorErroresDeCanal);
    _canal.onClose.listen(_manejadorCierreDeCanal);
  }

  void enviarMensaje(Mensaje msj) {
    _canal.send(msj.toCodificacion());
  }

  void _manejadorEstablecimientoDeCanal(Event evt) {
    log("Websocket con servidor abierto.");
    // _onConexionController.add(evt);
  }

  void _manejadorErroresDeCanal(ErrorEvent errorMessage) {
    log("¡Error! (en el establecimiento del websocket con el server)");
  }

  void _manejadorCierreDeCanal(CloseEvent closeEvent) {
    log("Websocket con servidor cerrado.");
  }

  void _manejadorDatosDesdeCanal(MessageEvent messageEvent) {
    log("Se recibió el texto: ${messageEvent.data}");
    Mensaje msj = new Mensaje.desdeCodificacion(messageEvent.data);

    _onMensajeController.add(msj);
  }

  void log(message) {
    window.console.log(message);
  }
}
