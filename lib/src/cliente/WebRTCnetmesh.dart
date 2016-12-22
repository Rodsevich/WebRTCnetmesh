library WebRTCNetmesh.client;

import "dart:async";
import 'dart:convert';
import 'dart:html';

import "../WebRTCnetmesh_base.dart";
import "./Par.dart";
import "./Servidor.dart";
import "./Mensaje.dart";

import 'package:WebRTCnetmesh/src/Identidad.dart';
import 'package:meta/meta.dart';

part "Identity.dart";

// enum WebRTCnetmeshStates {
//   NOT_CONNECTED,
//   CONNECTING,
//   CONNECTED
// }

/// Clase que el usuario final deberá instanciar para usar la librería cómoda
///y modularmente
class ClienteWebRTCnetmesh extends InterfazEnvioMensaje<Par> {
  Identity identity;

  Stream<CommandOrder> get onCommand => onCommandController.stream;
  Stream<Mensaje> get onInteraction => onInteractionController.stream;
  Stream<Pair> get onNewConnection => onNewConnectionController.stream;

  final List<Comando> comandos;

  Identidad identidad;
  Servidor servidor;
  StreamController onCommandController = new StreamController.broadcast();
  StreamController onInteractionController = new StreamController.broadcast();
  StreamController onNewConnectionController = new StreamController.broadcast();

  String version;

  ClienteWebRTCnetmesh(this.identity, List<Comando> comandos,
      [String server_uri])
      : this.comandos = comandos {
    identidad = identity._id;
    //TODO: Meter la version del package como definición base de [version]
    servidor = new Servidor(server_uri);
    servidor.onMensaje.listen(manejadorMensajes);
    servidor.onConexion.listen((e) {
      informarIdentidad();
    });
    identidad.onCambios.listen((cambio) {
      print(cambio);
      informarIdentidad(cambio);
    });
  }

  void informarIdentidad([CambioIdentidad cambio = null]) {
    print(identidad.id_sesion);
    if (identidad.id_sesion == null) {
      send(DestinatariosMensaje.SERVIDOR, new MensajeSuscripcion(identidad));
    } else {
      print("Cambio: ${cambio.toString()}");
      InfoCambioUsuario info = new InfoCambioUsuario(cambio);
      sendAll(info);
    }
  }

  Future manejadorMensajes(Mensaje msj) async {
    //if (_identidad.id_sesion != null)
    //  if(msj.id_destinatario == _identidad.id_Sesion)
    //  else forward(msj)
    switch (msj.tipo) {
      case MensajesAPI.SUSCRIPCION:
        print("antes: $identidad");
        identidad.actualizarCon((msj as MensajeSuscripcion).identidad);
        print("depues: $identidad");
        break;
      case MensajesAPI.INFORMACION:
        Informacion informacion = (msj as MensajeInformacion).informacion;
        switch (informacion.tipo) {
          case InformacionAPI.USUARIOS:
            List<Identidad> ids = (informacion as InfoUsuarios).usuarios;
            ids.forEach((Identidad id) {
              if (id != identidad) crearPar(id);
            });
            break;
          case InformacionAPI.NUEVO_USUARIO:
            Identidad id = (informacion as InfoUsuario).usuario;
            if (identidad != id) {
              Par par = crearPar(id);
              onNewConnectionController.add(par.aExportable());
              MensajeOfertaWebRTC oferta = await par.mensaje_inicio_conexion();
              send(par, oferta);
            }
            break;
          case InformacionAPI.CAMBIO_USUARIO:
            (informacion as InfoCambioUsuario)
                .cambio
                .implementarEn(search(msj.id_emisor).identidad);
            break;
          case InformacionAPI.SALIDA_USUARIO:
            associates.removeWhere(
                (p) => p.identidad == (informacion as InfoUsuario).usuario);
            break;
          default:
            throw new Exception("No se qué hacer con $informacion");
        }
        break;
      case MensajesAPI.OFERTA_WEBRTC:
      case MensajesAPI.RESPUESTA_WEBRTC:
      case MensajesAPI.CANDIDATOICE_WEBRTC:
        Par par = search(msj.id_emisor);
        if (par != null) {
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
        }
        break;
      case MensajesAPI.FALTA:
        Falta falta = (msj as MensajeFalta).falta;
        switch (falta.tipo) {
          case FaltasAPI.NOMBRE_NO_DISPONIBLE:
            identidad = null;
            throw new Exception(
                "Identity name is already taken, set another name.");
            break;
          default:
            throw new Exception("Tipo de falta no reconocido");
        }
        break;
      case MensajesAPI.COMANDO:
        try {
          Comando comandoLocal =
              conseguirComandoLocal((msj as MensajeComando).orden);
          try {
            comandoLocal.ejecutar(search(msj.id_emisor).identidad);
          } catch (error) {
            if (error is Falta)
              send(msj.id_emisor, error);
            else
              throw error;
          }
        } on StateError {
          FaltaComandoAusente noHayComando = new FaltaComandoAusente();
          send(msj.id_emisor, noHayComando);
        }
        break;
      default:
        throw new Exception(
            "Recibido un mensaje con tipo anomalo: ${msj.tipo}");
    }
  }

  Comando conseguirComandoLocal(CommandOrder orden) =>
      comandos.singleWhere((c) => c.indentificador == orden.id);

  @override
  Par search(id) {
    Par ret;
    try {
      if (id is int)
        ret = associates.singleWhere((par) => par.identidad.id_sesion == id);
      else if (id is Identidad)
        ret = associates.singleWhere((par) => par.identidad == id);
      else
        throw new Exception("Usa un int o una Identidad, pls");
    } catch (e) {
      //no aparece o hay más de una identidad igual
      ret = null;
    } finally {
      return ret;
    }
  }

  Par crearPar(Identidad id) {
    Par par = new Par(identidad, id);
    associates.add(par);
    // print("par $id agregado: ${JSON.encode(associates)}");
    par.onMensaje.listen(manejadorMensajes);
    return par;
  }

  pedirPermisos(bool video, bool audio) {}

  AudioElement audioLocalElem;
  VideoElement videoLocalElem;

  AudioElement get audioLocal {
    if (audioLocalElem == null) {
      audioLocalElem = new AudioElement();
    }
    return audioLocalElem;
  }

  AudioElement get videoLocal {
    if (videoLocalElem == null) {
      videoLocalElem = new VideoElement();
    }
    return audioLocalElem;
  }
}

///Public use class to encapsulate internal logic
class WebRTCnetmesh {
  ClienteWebRTCnetmesh _cliente;

  WebRTCnetmesh(Identity identity, List<Command> commandImplementations,
      [String server_uri = null]) {
    List<Comando> comandos = [];
    for (var i = 0; i < commandImplementations.length; i++) {
      if (commandImplementations[i] is! Command ||
          commandImplementations[i].runtimeType.toString() == "Command")
        throw new Exception("Must be a subclass of Command");
      commandImplementations[i]
          .comandos
          .insert(i, new Comando(commandImplementations[i], i));
    }
    _cliente = new ClienteWebRTCnetmesh(identity, comandos, server_uri);
  }

  Identity get identity => _cliente.identity;

  List<Pair> get associates => _cliente.associates
      .map((Par p) => p.aExportable())
      .toList(growable: false);

  send(to, data) => _cliente.send(to, data);
  sendAll(data) => _cliente.sendAll(data);

  requestMediaPermissions({bool video: true, bool audio: true}) =>
      _cliente.pedirPermisos(video, audio);

  Stream get onCommand => _cliente.onCommand;
  Stream get onInteraction => _cliente.onInteraction;
  Stream get onNewConnection => _cliente.onNewConnection;
}
