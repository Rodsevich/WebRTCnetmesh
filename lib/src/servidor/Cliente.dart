import 'dart:io';
import 'dart:async';
import '../Mensaje.dart';
import '../Identidad.dart';

class Cliente {
  final Identidad identidad_local;
  Identidad identidad_remota;
  String id, pseudonimo;
  WebSocket _canal;
  StreamController _notificadorMensajes;
  Stream<Mensaje> onMensaje;

  DateTime _ultimaComunicacion;

  Duration get tiempoSinComunicacion =>
      new DateTime.now().difference(_ultimaComunicacion);

  bool get conectadoDirectamente => _canal.readyState == WebSocket.OPEN;

  Cliente(this._canal, Identidad identidad_local)
      : this.identidad_local = identidad_local {
    _notificadorMensajes = new StreamController();
    onMensaje = _notificadorMensajes.stream;
    _canal.listen(_manejarMensajes);
  }

  void _manejarMensajes(String input) {
    Mensaje mensaje = new Mensaje.desdeCodificacion(input);
    //Evitar loops
    if (mensaje.ids_intermediarios.contains(identidad_local.id_sesion)) return;
    if (mensaje.id_receptor == this.identidad_local.id_sesion) {
      switch (mensaje.tipo) {
        case MensajesAPI.PING:
          enviarMensaje(new MensajePong.desdeMensajePing(mensaje));
          return;
          break;
        case MensajesAPI.PONG:
          throw new Exception("No debería medir el ping yo");
          break;
        default:
          //Delegar manejo del mensaje al controlador general que contiene a este Par
          _notificadorMensajes.add(mensaje);
          _ultimaComunicacion = new DateTime.now();
      }
    } else {
      //Agregar este par como repetidor del envío del mensaje
      mensaje.ids_intermediarios.add(identidad_local.id_sesion);
      _notificadorMensajes.add(mensaje);
      _ultimaComunicacion = new DateTime.now();
    }
  }

  void enviarMensaje(Mensaje msj) {
    _canal.add(msj.toString());
  }
}
