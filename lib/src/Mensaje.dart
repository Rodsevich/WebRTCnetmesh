import 'dart:convert';
import 'dart:html';
import 'Identidad.dart';

enum MensajesAPI {
  INDEFINIDO,
  SUSCRIPCION,
  OFERTA_WEBRTC,
  RESPUESTA_WEBRTC,
  CANDIDATOICE_WEBRTC,
  COMANDO,
  INFORMACION,
  INTERACCION,
  PING,
  PONG,
}

/// Para especificar si el mensaje es de Broadcast o al servidor, null si es a un usuario específico
enum DestinatariosMensaje { SERVIDOR, TODOS }

class Mensaje {
  MensajesAPI tipo;
  String id_emisor;

  /// Si es String será el id, si es DestinatariosMensaje, SERVIDOR o TODOS
  var id_receptor;
  List<String> ids_intermediarios;

  Mensaje(this.id_emisor, this.id_receptor) {
    tipo = MensajesAPI.INDEFINIDO;
  }

  /// Decodifica un mensaje recibido desde un Cliente en su clase correspondiente
  factory Mensaje.desdeCodificacion(String json) {
    List msjDecodificado = JSON.decode(json);
    List info_direccionamiento = msjDecodificado[0];
    List msjEspecifico = msjDecodificado.sublist(1);
    switch (MensajesAPI.values[msjEspecifico[0]]) {
      case MensajesAPI.COMANDO:
        return new MensajeComando.desdeDecodificacion(
            info_direccionamiento, msjEspecifico);
      case MensajesAPI.OFERTA_WEBRTC:
        return new MensajeOfertaWebRTC.desdeDecodificacion(
            info_direccionamiento, msjEspecifico);
      case MensajesAPI.RESPUESTA_WEBRTC:
        return new MensajeRespuestaWebRTC.desdeDecodificacion(
            info_direccionamiento, msjEspecifico);
      case MensajesAPI.CANDIDATOICE_WEBRTC:
        return new MensajeCandidatoICEWebRTC.desdeDecodificacion(
            info_direccionamiento, msjEspecifico);
      case MensajesAPI.SUSCRIPCION:
        return new MensajeSuscripcion.desdeDecodificacion(
            info_direccionamiento, msjEspecifico);
      case MensajesAPI.INFORMACION:
        return new MensajeInformacion.desdeDecodificacion(
            info_direccionamiento, msjEspecifico);
      case MensajesAPI.INTERACCION:
        return new MensajeInteraccion.desdeDecodificacion(
            info_direccionamiento, msjEspecifico);
      case MensajesAPI.PING:
        return new MensajePing.desdeDecodificacion(
            info_direccionamiento, msjEspecifico);
      case MensajesAPI.PONG:
        return new MensajePong.desdeDecodificacion(
            info_direccionamiento, msjEspecifico);
      default:
        throw new Exception(
            "Tipo de mensaje no reconocido... (No se qué hacer)");
    }
  }

  Mensaje.desdeDecodificacion(List info_direccionamiento) {
    informacion_direccionamiento = info_direccionamiento;
  }

  int codificacionMensajeAPI(MensajesAPI msj) {
    List<MensajesAPI> vals = MensajesAPI.values;
    for (var i in vals) if (msj == vals[i]) return i;
    return MensajesAPI.INDEFINIDO.index;
  }

  MensajesAPI decodificacionMensajeAPI(int index) => MensajesAPI.values[index];

  List get informacion_direccionamiento =>
      [this.id_emisor, this.id_receptor, this.ids_intermediarios];

  void set informacion_direccionamiento(List info) {
    this.id_emisor = info[0];
    this.id_receptor = info[1];
    this.ids_intermediarios = info[2];
  }
}

/// Mensaje enviado por el cliente para que el Servidor tenga su información
/// WebAPP --> Cliente --> Servidor X-termino ahi-X
class MensajeSuscripcion extends Mensaje {
  Identidad identidad;

  MensajeSuscripcion(this.identidad)
      : super(null, DestinatariosMensaje.SERVIDOR) {
    this.tipo = MensajesAPI.SUSCRIPCION;
    this.id_receptor = DestinatariosMensaje.SERVIDOR;
  }
  MensajeSuscripcion.desdeDecodificacion(
      List info_direccionamiento, List msjEspecifico)
      : super.desdeDecodificacion(info_direccionamiento) {
    this.tipo = decodificacionMensajeAPI(msjEspecifico[0]);
    this.identidad = msjEspecifico[1];
  }

  String toString() => JSON.encode([
        informacion_direccionamiento,
        MensajesAPI.SUSCRIPCION.index,
        [identidad.id]
      ]);
}

/// Mensaje que porta la negociacion SDP para establecer conexiones WebRTC
/// WebAPP --> Cliente --> Servidor
/// Servidor --> Cliente --> WebApp
class MensajeOfertaWebRTC extends Mensaje {
  RtcSessionDescription oferta;

  MensajeOfertaWebRTC(String id_emisor, String id_receptor, this.oferta)
      : super(id_emisor, id_receptor) {
    this.tipo = MensajesAPI.OFERTA_WEBRTC;
  }
  MensajeOfertaWebRTC.desdeDecodificacion(
      List info_direccionamiento, List msjEspecifico)
      : super.desdeDecodificacion(info_direccionamiento) {
    this.tipo = decodificacionMensajeAPI(msjEspecifico[0]);
    List<String> datosOferta = msjEspecifico[1];
    this.oferta = new RtcSessionDescription();
    oferta.sdp = datosOferta[0];
  }

  String toString() => JSON.encode([
        informacion_direccionamiento,
        MensajesAPI.OFERTA_WEBRTC.index,
        [oferta.sdp]
      ]);
}

/// Mensaje que porta la negociacion SDP para establecer conexiones WebRTC
/// WebAPP --> Cliente --> Servidor
/// Servidor --> Cliente --> WebApp
class MensajeRespuestaWebRTC extends Mensaje {
  RtcSessionDescription respuesta;

  MensajeRespuestaWebRTC(String id_emisor, String id_receptor, this.respuesta)
      : super(id_emisor, id_receptor) {
    this.tipo = MensajesAPI.RESPUESTA_WEBRTC;
  }
  MensajeRespuestaWebRTC.desdeDecodificacion(
      List info_direccionamiento, List msjEspecifico)
      : super.desdeDecodificacion(info_direccionamiento) {
    this.tipo = decodificacionMensajeAPI(msjEspecifico[0]);
    List<String> datosRespuesta = msjEspecifico[1];
    this.respuesta = new RtcSessionDescription();
    respuesta.sdp = datosRespuesta[0];
  }

  String toString() => JSON.encode([
        informacion_direccionamiento,
        MensajesAPI.RESPUESTA_WEBRTC.index,
        [respuesta.sdp]
      ]);
}

/// Mensaje que porta la negociacion SDP para establecer conexiones WebRTC
/// WebAPP --> Cliente --> Servidor
/// Servidor --> Cliente --> WebApp
class MensajeCandidatoICEWebRTC extends Mensaje {
  RtcIceCandidate candidato;

  MensajeCandidatoICEWebRTC(
      String id_emisor, String id_receptor, this.candidato)
      : super(id_emisor, id_receptor) {
    this.tipo = MensajesAPI.RESPUESTA_WEBRTC;
  }
  MensajeCandidatoICEWebRTC.desdeDecodificacion(
      List info_direccionamiento, List msjEspecifico)
      : super.desdeDecodificacion(info_direccionamiento) {
    this.tipo = decodificacionMensajeAPI(msjEspecifico[0]);
    List<String> datosCandidato = msjEspecifico[1];
    this.candidato = new RtcIceCandidate({
      "candidate": datosCandidato[0],
      "sdpMid": datosCandidato[1],
      "sdpMLineIndex": datosCandidato[2]
    });
  }

  String toString() => JSON.encode([
        informacion_direccionamiento,
        MensajesAPI.RESPUESTA_WEBRTC.index,
        [candidato.candidate, candidato.sdpMid, candidato.sdpMLineIndex]
      ]);
}

/// Comando para que se ejecute funcionalidad remotamente
/// WebAPP --> Cliente --> Servidor
/// Servidor --> Cliente { --> WebAPP } --> WebApp
class MensajeComando extends Mensaje {
  String comando;
  List<String> argumentos;

  MensajeComando(
      String id_emisor, String id_receptor, this.comando, this.argumentos)
      : super(id_emisor, id_receptor) {
    this.tipo = MensajesAPI.COMANDO;
  }
  MensajeComando.desdeDecodificacion(
      List info_direccionamiento, List msjEspecifico)
      : super.desdeDecodificacion(info_direccionamiento) {
    this.tipo = decodificacionMensajeAPI(msjEspecifico[0]);
    this.comando = msjEspecifico[1];
    this.argumentos = msjEspecifico[2];
  }

  String toString() => JSON.encode([
        informacion_direccionamiento,
        MensajesAPI.COMANDO.index,
        comando,
        argumentos
      ]);
}

/// Resultado de alguna interacción por parte del usuario: _votacion_, _encuesta_, _etc..._
/// WebAPP \[ --> WebAPP \] --> Cliente --> Servidor
class MensajeInformacion extends Mensaje {
  String id_informacion;
  Map valores;

  MensajeInformacion(
      String id_emisor, String id_receptor, this.id_informacion, this.valores)
      : super(id_emisor, id_receptor) {
    this.tipo = MensajesAPI.INFORMACION;
  }
  MensajeInformacion.desdeDecodificacion(
      List info_direccionamiento, List msjEspecifico)
      : super.desdeDecodificacion(info_direccionamiento) {
    this.tipo = decodificacionMensajeAPI(msjEspecifico[0]);
    this.id_informacion = msjEspecifico[1];
    this.valores = msjEspecifico[2];
  }

  String toString() => JSON.encode([
        informacion_direccionamiento,
        MensajesAPI.INFORMACION.index,
        id_informacion,
        valores
      ]);
}

/// Mensaje enviado con iniciativa para medir el tiempo de respuesta futuro
/// WebAPP --> \[ WebAPP | Servidor \]
class MensajePing extends Mensaje {
  String carga;

  MensajePing(String id_emisor, String id_receptor)
      : super(id_emisor, id_receptor) {
    this.tipo = MensajesAPI.PING;
  }
  MensajePing.desdeDecodificacion(
      List info_direccionamiento, List msjEspecifico)
      : super.desdeDecodificacion(info_direccionamiento) {
    this.tipo = decodificacionMensajeAPI(msjEspecifico[0]);
    this.carga = msjEspecifico[1];
  }

  String toString() => JSON
      .encode([informacion_direccionamiento, MensajesAPI.PING.index, carga]);
}

/// Mensaje enviado responsivamente para medir el tiempo de respuesta definitivamente
/// WebAPP --> \[ WebAPP | Servidor \]
class MensajePong extends Mensaje {
  String carga;

  MensajePong(String id_emisor, String id_receptor)
      : super(id_emisor, id_receptor) {
    this.tipo = MensajesAPI.PONG;
  }
  MensajePong.desdeDecodificacion(
      List info_direccionamiento, List msjEspecifico)
      : super.desdeDecodificacion(info_direccionamiento) {
    this.tipo = decodificacionMensajeAPI(msjEspecifico[0]);
    this.carga = msjEspecifico[1];
  }

  String toString() => JSON
      .encode([informacion_direccionamiento, MensajesAPI.PONG.index, carga]);
}
