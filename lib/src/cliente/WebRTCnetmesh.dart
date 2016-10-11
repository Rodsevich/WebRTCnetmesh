import "./Par.dart";
import "./Servidor.dart";
import "../Comando.dart";
import "../Identidad.dart";
import "../Mensaje.dart";
import "./Mensaje.dart";
import "dart:async";
// import 'dart:html';
import 'package:WebRTCnetmesh/src/Informacion.dart';
import 'package:WebRTCnetmesh/src/Falta.dart';
import 'package:WebRTCnetmesh/src/cliente/Mensaje.dart';
import 'dart:developer';

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
          new MensajeInformacion(identity, DestinatariosMensaje.TODOS, info));
      _identity = identity;
    }
  }

  Servidor server;
  List<Par> pairs;
  Stream<Mensaje> get onMessage => _onMessageController.stream;
  StreamController _onMessageController;
  Stream<Comando> get onCommand => _onCommandController.stream;
  StreamController _onCommandController;
  Stream<Identidad> get onNewConnection => _onNewConnectionController.stream;
  StreamController _onNewConnectionController;

  WebRTCnetmesh(Identidad local_identity, [String server_uri]) {
    pairs = [];
    server = new Servidor(server_uri);
    server.onMensaje.listen(_manejadorMensajes);
    server.onConexion.listen((e) {
      local_identity.id_sesion = null; //prevenir eventuales hackeos
      identity = local_identity;
      //El setter de identity hará automáticamente...
      //server.enviarMensaje(new MensajeSuscripcion(local_identity));
    });
    _onMessageController = new StreamController();
    _onCommandController = new StreamController();
    _onNewConnectionController = new StreamController();
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
    pairs.where(conectadoDirectamente).forEach(enviarMensaje(message));
  }

  int get totalPairs => pairs.length;

  int get amountPairsDirectlyConnected =>
      pairs.where((Par p) => p.conectadoDirectamente).length;

  Future _manejadorMensajes(Mensaje msj) async {
    //if (identity.id_sesion != null)
    //  if(msj.id_destinatario == identity.id_Sesion)
    //  else forward(msj)
    switch (msj.tipo) {
      case MensajesAPI.INFORMACION:
        Informacion informacion = (msj as MensajeInformacion).informacion;
        switch (informacion.tipo) {
          case InformacionAPI.USUARIOS:
            List<Identidad> ids = (informacion as InfoUsuarios).usuarios;
            try {
              identity = ids.singleWhere((id) => id == identity);
            } catch (e) {
              debugger();
            } finally {
              ids.forEach((id) {
                if (id != identity) _crearPar(id);
              });
            }
            break;
          case InformacionAPI.NUEVO_USUARIO:
            Identidad id = (informacion as InfoUsuario).usuario;
            if (identity != id) {
              Par par = _crearPar(id);
              pairs.add(par);
              _onNewConnectionController.add(id);
              MensajeOfertaWebRTC oferta = await par.mensaje_inicio_conexion();
              send(DestinatariosMensaje.SERVIDOR, oferta);
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
      case MensajesAPI.OFERTA_WEBRTC:
      case MensajesAPI.RESPUESTA_WEBRTC:
      case MensajesAPI.CANDIDATOICE_WEBRTC:
        Par par = _buscarPar(msj.id_emisor);
        switch (msj.tipo) {
          case MensajesAPI.OFERTA_WEBRTC:
            MensajeRespuestaWebRTC resp =
                await par.mensaje_respuesta_inicio_conexion(
                    (msj as MensajeOfertaWebRTC).oferta);
            send(msj.id_emisor, resp);
            break;
          case MensajesAPI.RESPUESTA_WEBRTC:
            par.setear_respuesta((msj as MensajeRespuestaWebRTC).respuesta);
            break;
          case MensajesAPI.CANDIDATOICE_WEBRTC:
            par.setear_ice_candidate_remoto(
                (msj as MensajeCandidatoICEWebRTC).candidato);
            break;
          default: //Para evitar warnings...
            throw new Error(); //Imposible que pase
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

  Par _buscarPar(id) {
    Par ret;
    try {
      if (id is int)
        ret = pairs.singleWhere((par) => par.identidad_remota.id_sesion == id);
      else if (id is Identidad)
        ret = pairs.singleWhere((par) => par.identidad_remota == id);
      else
        throw new Exception("Usa un int o una Identidad, pls");
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
