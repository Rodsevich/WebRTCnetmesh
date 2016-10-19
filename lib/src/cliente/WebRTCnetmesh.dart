library WebRTCNetmesh.client;

import "dart:async";
import 'dart:convert';

import "../WebRTCnetmesh_base.dart";
import "./Par.dart";
import "./Servidor.dart";
import "./Mensaje.dart";

import 'package:meta/meta.dart' show visibleForTesting;

// enum WebRTCnetmeshStates {
//   NOT_CONNECTED,
//   CONNECTING,
//   CONNECTED
// }

/// Clase que el usuario final deberá instanciar para usar la librería cómoda
///y modularmente
class ClienteWebRTCnetmesh extends InterfazEnvioMensaje<Par> {
  Identity identity;

  Stream<Command> get onCommand => onCommandController.stream;
  Stream<Mensaje> get onInteraction => onInteractionController.stream;
  Stream<Pair> get onNewConnection => onNewConnectionController.stream;

  final List<Comando> comandos;

  Identidad identidad;
  Servidor servidor;
  StreamController onCommandController = new StreamController.broadcast();
  StreamController onInteractionController = new StreamController.broadcast();
  StreamController onNewConnectionController = new StreamController.broadcast();

  ClienteWebRTCnetmesh(this.identity, List<Comando> comandos,
      [String server_uri])
      : this.comandos = comandos {
    identidad = identity._id;
    servidor = new Servidor(server_uri);
    servidor.onMensaje.listen(manejadorMensajes);
    servidor.onConexion.listen((e) {
      informarIdentidad();
    });
    identidad.onCambios.listen(informarIdentidad);
  }

  void informarIdentidad([CambioIdentidad cambio = null]) {
    if (identidad.id_sesion == null) {
      send(DestinatariosMensaje.SERVIDOR, new MensajeSuscripcion(identidad));
    } else {
      InfoCambioUsuario info = new InfoCambioUsuario(cambio);
      send(DestinatariosMensaje.TODOS, info);
    }
  }

  Future manejadorMensajes(Mensaje msj) async {
    //if (_identidad.id_sesion != null)
    //  if(msj.id_destinatario == _identidad.id_Sesion)
    //  else forward(msj)
    switch (msj.tipo) {
      case MensajesAPI.SUSCRIPCION:
        identidad = (msj as MensajeSuscripcion).identidad;
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
            identidad = null;
            throw new Exception(
                "Identity name is already taken, set another name.");
            break;
          default:
            throw new Exception("Tipo de falta no reconocido");
        }
        break;
      case MensajesAPI.COMANDO:
        Comando comando = comandos[(msj as MensajeComando).comando.indice];
        //Todo: Seguir aca
      break;
      default:
        throw new Exception(
            "Recibido un mensaje con tipo anomalo: ${msj.tipo}");
    }
  }

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
    print("par $id agregado: ${JSON.encode(associates)}");
    par.onMensaje.listen(manejadorMensajes);
    return par;
  }
}

///Class that the client would use in order to have everybody informed
class Identity {
  Identidad _id;

  bool _modificable;

  Identity(String name) {
    this._id = new Identidad(name);
    _modificable = true;
  }

  @visibleForTesting
  Identity.desdeEncubierto(this._id) {
    _modificable = false; //De un Pair o algo asi q no admite modificaciones
  }

  String get name => _id.nombre;

  void set name(String name) {
    if (_modificable) {
      CambioIdentidad cambio;
      new CambioIdentidad('n', _id.nombre, name);
      _id.nombre = name;
      _id.cambiosController.add(cambio);
    } else
      throw "Not possible to change Identities other than yours own";
  }

  String get email => _id.email;

  void set email(String email) {
    if (_modificable) {
      CambioIdentidad cambio;
      new CambioIdentidad('E', _id.email, email);
      _id.email = email;
      _id.cambiosController.add(cambio);
    } else
      throw "Not possible to change Identities other than yours own";
  }

  String get facebook_id => _id.id_feis;

  void set facebook_id(String facebook_id) {
    if (_modificable) {
      CambioIdentidad cambio;
      new CambioIdentidad('F', _id.id_feis, facebook_id);
      _id.id_feis = facebook_id;
      _id.cambiosController.add(cambio);
    } else
      throw "Not possible to change Identities other than yours own";
  }

  String get google_id => _id.id_goog;

  void set google_id(String google_id) {
    if (_modificable) {
      CambioIdentidad cambio;
      new CambioIdentidad('G', _id.id_goog, google_id);
      _id.id_goog = google_id;
      _id.cambiosController.add(cambio);
    } else
      throw "Not possible to change Identities other than yours own";
  }

  String get github_id => _id.id_github;

  void set github_id(String github_id) {
    if (_modificable) {
      CambioIdentidad cambio;
      new CambioIdentidad('g', _id.id_github, github_id);
      _id.id_github = github_id;
      _id.cambiosController.add(cambio);
    } else
      throw "Not possible to change Identities other than yours own";
  }
}

///Public use class to encapsulate internal logic
class WebRTCnetmesh {
  ClienteWebRTCnetmesh _cliente;

  WebRTCnetmesh(
      Identity identity, List<CommandImplementation> commandImplementations,
      [String server_uri = null]) {
    List<Comando> comandos = [];
    for (var i = 0; i < commandImplementations.length; i++) {
      if (commandImplementations[i] is! CommandImplementation ||
          commandImplementations[i].runtimeType.toString() ==
              "CommandImplementation")
        throw new Exception("Must be a subclass of CommandImplementation");
      comandos[i] = new Comando(commandImplementations[i], i);
    }
    _cliente = new ClienteWebRTCnetmesh(identity, comandos, server_uri);
  }

  Identity get identity => _cliente.identity;

  List<Pair> get associates => _cliente.associates
      .map((Par p) => p.aExportable())
      .toList(growable: false);

  send(to, data) => _cliente.send(to, data);
  sendAll(data) => _cliente.sendAll(data);

  Stream get onCommand => _cliente.onCommand;
  Stream get onInteraction => _cliente.onInteraction;
  Stream get onNewConnection => _cliente.onNewConnection;
}
