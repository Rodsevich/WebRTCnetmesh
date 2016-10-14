library WebRTCNetmesh.client;
import "dart:async";
import 'dart:convert';
import 'dart:developer';
import 'dart:html' show RtcIceCandidate, RtcSessionDescription;

import "../WebRTCnetmesh_base.dart";
part "./Par.dart";
part "./Servidor.dart";
part "./Mensaje.dart";
part "./Identity.dart";

// enum WebRTCnetmeshStates {
//   NOT_CONNECTED,
//   CONNECTING,
//   CONNECTED
// }


/// Clase que el usuario final deberá instanciar para usar la librería cómoda
///y modularmente
class WebRTCnetmesh {
  Identity identity;
  Identidad _identidad;

  Servidor server;
  List<Par> pairs = [];
  Stream<Mensaje> get onMessage => _onMessageController.stream;
  StreamController _onMessageController;
  Stream<Comando> get onCommand => _onCommandController.stream;
  StreamController _onCommandController;
  Stream<Identidad> get onNewConnection => _onNewConnectionController.stream;
  StreamController _onNewConnectionController;

  WebRTCnetmesh(this.identity, [String server_uri]){
     _identidad = identity._id;
    server = new Servidor(server_uri);
    server.onMensaje.listen(_manejadorMensajes);
    server.onConexion.listen((e) {
      _informarIdentidad();
    });
    _identidad.onCambios.listen(_informarIdentidad);
    _onMessageController = new StreamController();
    _onCommandController = new StreamController();
    _onNewConnectionController = new StreamController();
  }

  void _informarIdentidad([Map cambios = null]) {
    if (_identidad.id_sesion == null) {
      send(DestinatariosMensaje.SERVIDOR, new MensajeSuscripcion(_identidad));
    } else {
      InfoCambioUsuario info = new InfoCambioUsuario(_identidad, identity);
      //TODO: Seguir desde acá, corrigiendo InfoCambioUsuario primero
      send(DestinatariosMensaje.SERVIDOR, info);
    }
    }
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
        .where((Par par) => par.conectadoDirectamente)
        .forEach((Par p) => p.enviarMensaje(message));
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
            print(JSON.encode(_identidad));
            if (_identidad.id_sesion == null) {
              print("entro");
              List<Identidad> ids = (informacion as InfoUsuarios).usuarios;
              try {
                _identidad =
                    ids.singleWhere((Identidad id) => id == this.identity);
              } catch (e) {
                print("error de tipo: ${e.runtimeType}");
                // debugger();
              } finally {
                print("Agregado de pares");
                print(JSON.encode(ids));
                ids.forEach((Identidad id) {
                  if (id != identity) _crearPar(id);
                });
              }
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
            _identidad = null;
            throw new Exception("Identity name is already taken, set another name.");
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
    Par par = new Par(_identidad, id);
    pairs.add(par);
    print("par $id agregado: ${JSON.encode(pairs)}");
    par.onMensaje.listen(_manejadorMensajes);
    return par;
  }
}
