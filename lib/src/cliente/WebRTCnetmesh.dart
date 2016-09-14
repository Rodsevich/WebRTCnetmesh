import "./Par.dart";
import "./Servidor.dart";
import "../Comando.dart";
import "../Identidad.dart";
import "../Mensaje.dart";
import "dart:async";
import 'dart:html';
import 'package:WebRTCnetmesh/src/Informacion.dart';
import 'package:WebRTCnetmesh/src/Falta.dart';

// enum WebRTCnetmeshStates {
//   NOT_CONNECTED,
//   CONNECTING,
//   CONNECTED
// }

/// Clase que el usuario final deberá instanciar para usar la librería cómoda
///y modularmente
class WebRTCnetmesh {
  Identidad _identity;

  Identidad get identity => _identity;

  void set identity(Identidad identity) {
    if (_identity == null)
      send(DestinatariosMensaje.SERVIDOR, new MensajeSuscripcion(identity));
    else {
      InfoCambioUsuario info = new InfoCambioUsuario(_identity, identity);
      sendAll(
          new MensajeInformacion(_identity, DestinatariosMensaje.TODOS, info));
      _identity = identity;
    }
  }

  Servidor server;
  List<Par> pairs;

  WebRTCnetmesh(Identidad local_identity, [String server_uri])
      : this._identity = local_identity {
    server = new Servidor(server_uri);
    server.onMensaje.listen(_manejadorMensajes);
    server.onConexion.listen((e) {
      server.enviarMensaje(new MensajeSuscripcion(identity));
    });
  }

  send(to, Mensaje message) {
    if (to is DestinatariosMensaje) {
      if (to == DestinatariosMensaje.SERVIDOR)
        server.enviarMensaje(message);
      else if (to == DestinatariosMensaje.TODOS) sendAll(message);
      return;
    }
    if (to is Identidad) {
      Par entidad = _buscarPar(to);
      entidad.enviarMensaje(message);
    } else
      throw new Exception(
          "Must be delivered to Identidad or DestinatariosMensaje");
  }

  sendAll(Mensaje message) {
    message.id_receptor = DestinatariosMensaje.TODOS;
    server.enviarMensaje(message);
    pairs
        .where((p) => p.conectadoDirectamente)
        .forEach((p) => p.enviarMensaje(message));
  }

  int get totalPairs => pairs.length;

  int get amountPairsDirectlyConnected =>
      pairs.where((Par p) => p.conectadoDirectamente).length;

  Stream<Mensaje> onMessage;
  Stream<Comando> onCommand;
  Stream<Identidad> onNewConnection;

  void _manejadorMensajes(Mensaje msj) {
    switch (msj.tipo) {
      case MensajesAPI.INFORMACION:
        Informacion informacion = (msj as MensajeInformacion).informacion;
        switch (informacion.tipo) {
          case InformacionAPI.USUARIOS:
            List<Identidad> ids = (informacion as InfoUsuarios).usuarios;
            identity = ids.singleWhere((id) => id == identity);
            ids.forEach((id) {
              if (id != identity) _crearPar(id);
            });
            break;
          case InformacionAPI.NUEVO_USUARIO:
            Identidad id = (informacion as InfoUsuario).usuario;
            if (identity != id) {
              Par par = _crearPar(id);
              par.mensaje_inicio_conexion();
            }
            break;
          case InformacionAPI.CAMBIO_USUARIO:
            Par par =
                _buscarPar((informacion as InfoCambioUsuario).identidad_vieja);
            par.identidad_remota =
                (informacion as InfoCambioUsuario).identidad_nueva;
            break;
          case InformacionAPI.SALIDA_USUARIO:
            pairs.removeWhere((p) =>
                p.identidad_remota == (informacion as InfoUsuario).usuario);
            break;
          default:
            throw new Exception("No se qué hacer con $informacion");
        }
        break;
      case MensajesAPI.FALTA:
        Falta falta = (msj as MensajeFalta).falta;
        switch (falta.tipo) {
          case FaltasAPI.NOMBRE_NO_DISPONIBLE:
            _identity = null;
            throw new Exception("Identity is already taken, set another name.");
            break;
          default:
            throw new Exception("Tipo de falta no reconocido");
        }
        break;
      default:
        throw new Exception(
            "Recibido un mensaje con tipo anomalo: ${msj.tipo}");
    }
  }

  Par _buscarPar(Identidad id) {
    Par ret;
    try {
      ret = pairs.singleWhere((par) => par.identidad_remota == id);
    } catch (e) {
      //no aparece o hay más de una identidad igual
      ret = null;
    } finally {
      return ret;
    }
  }

  Par _crearPar(Identidad id) {
    Par par = new Par(_identity, id);
    pairs.add(par);
    par.onMensaje.listen(_manejadorMensajes);
    return par;
  }
}
