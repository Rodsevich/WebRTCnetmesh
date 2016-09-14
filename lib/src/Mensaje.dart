import 'dart:convert';
import 'dart:html' show RtcIceCandidate, RtcSessionDescription;
import 'Identidad.dart';
import 'Informacion.dart';
import 'Falta.dart';
import 'package:WebRTCnetmesh/src/Comando.dart';

enum MensajesAPI {
  SUSCRIPCION,
  INFORMACION,
  FALTA,
  COMANDO,
  INTERACCION,
  PING,
  PONG,
  CANDIDATOICE_WEBRTC,
  RESPUESTA_WEBRTC,
  OFERTA_WEBRTC,
  INDEFINIDO,
}

/// Para especificar si el mensaje es de Broadcast o al servidor, null si es a
/// un usuario específico
enum DestinatariosMensaje { SERVIDOR, TODOS }

abstract class Mensaje {
  MensajesAPI tipo;
  int _id_emisor;

  int get id_emisor => _id_emisor;

  void set id_emisor(id_emisor) {
    if (id_emisor is int)
      _id_emisor = id_emisor;
    else if (id_emisor is Identidad)
      _id_emisor = id_emisor.id_sesion;
    else
      throw new Exception("Usá un int o una Identidad, pls.");
  }

  /// Si es String será el id, si es DestinatariosMensaje, SERVIDOR o TODOS
  var _id_receptor;

  get id_receptor {
    if (id_receptor >= 0)
      return _id_receptor;
    else
      return DestinatariosMensaje.values[_id_receptor * -1];
  }

  void set id_receptor(id_receptor) {
    if (id_receptor is DestinatariosMensaje)
      _id_receptor = id_receptor.index * -1;
    else if (id_receptor is String)
      _id_receptor = int.parse(id_receptor);
    else if (id_receptor is int)
      _id_receptor = id_receptor;
    else if (id_receptor is Identidad)
      _id_receptor = id_receptor.id_sesion;
    else
      throw new Exception(
          "Usá un String, int, Identidad o DestinatariosMensaje, pls.");
  }

  List<int> ids_intermediarios;

  Mensaje(emisor, receptor) {
    this.id_emisor = emisor;
    this.id_receptor = receptor;
    tipo = MensajesAPI.INDEFINIDO;
  }

  /// Decodifica un mensaje recibido desde un Cliente en su clase correspondiente
  factory Mensaje.desdeCodificacion(String json) {
    //agregando los [] removidos al momento de codificarlos
    List msjDecodificado = JSON.decode("[$json]");
    List info_direccionamiento = msjDecodificado[0];
    MensajesAPI tipo = MensajesAPI.values[msjDecodificado[1]];
    List msjEspecifico = msjDecodificado.sublist(2);
    switch (tipo) {
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
      case MensajesAPI.FALTA:
        return new MensajeFalta.desdeDecodificacion(
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

  /// Metodo implementado por cada Mensaje para devolver una lista de parametros
  /// propios de cada uno
  String _serializacionPropia();

  /// Codificación eficiente para ser enviada por los canales de comunicación
  String toString() {
    //Le volamos los [] extremos que es al pedo mandarlos por redundantes
    String datos_propios = _serializacionPropia();
    String serializacion = JSON.encode([
      informacion_direccionamiento,
      this.tipo.index,
      datos_propios.substring(1, datos_propios.length - 1)
    ]);
    return serializacion.substring(1, serializacion.length - 1);
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
    this.tipo = MensajesAPI.SUSCRIPCION;
    this.identidad = new Identidad.desdeString(msjEspecifico[1]);
  }

  @override
  String _serializacionPropia() => JSON.encode(identidad);
}

/// Mensaje que porta la negociacion SDP para establecer conexiones WebRTC
/// WebAPP --> Cliente --> Servidor
/// Servidor --> Cliente --> WebApp
class MensajeOfertaWebRTC extends Mensaje {
  RtcSessionDescription oferta;

  MensajeOfertaWebRTC(id_emisor, id_receptor, this.oferta)
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

  @override
  String _serializacionPropia() => JSON.encode([oferta.sdp]);
}

/// Mensaje que porta la negociacion SDP para establecer conexiones WebRTC
/// WebAPP --> Cliente --> Servidor
/// Servidor --> Cliente --> WebApp
class MensajeRespuestaWebRTC extends Mensaje {
  RtcSessionDescription respuesta;

  MensajeRespuestaWebRTC(id_emisor, id_receptor, this.respuesta)
      : super(id_emisor, id_receptor) {
    this.tipo = MensajesAPI.RESPUESTA_WEBRTC;
  }
  MensajeRespuestaWebRTC.desdeDecodificacion(
      List info_direccionamiento, List msjEspecifico)
      : super.desdeDecodificacion(info_direccionamiento) {
    this.tipo = MensajesAPI.RESPUESTA_WEBRTC;
    this.respuesta = new RtcSessionDescription();
    respuesta.sdp = msjEspecifico[0];
  }

  @override
  String _serializacionPropia() => JSON.encode([respuesta.sdp]);
}

/// Mensaje que porta la negociacion SDP para establecer conexiones WebRTC
/// WebAPP --> Cliente --> Servidor
/// Servidor --> Cliente --> WebApp
class MensajeCandidatoICEWebRTC extends Mensaje {
  RtcIceCandidate candidato;

  MensajeCandidatoICEWebRTC(id_emisor, id_receptor, this.candidato)
      : super(id_emisor, id_receptor) {
    this.tipo = MensajesAPI.RESPUESTA_WEBRTC;
  }
  MensajeCandidatoICEWebRTC.desdeDecodificacion(
      List info_direccionamiento, List datosCandidato)
      : super.desdeDecodificacion(info_direccionamiento) {
    this.tipo = MensajesAPI.RESPUESTA_WEBRTC;
    this.candidato = new RtcIceCandidate({
      "candidate": datosCandidato[0],
      "sdpMid": datosCandidato[1],
      "sdpMLineIndex": datosCandidato[2]
    });
  }

  @override
  String _serializacionPropia() => JSON
      .encode([candidato.candidate, candidato.sdpMid, candidato.sdpMLineIndex]);
}

/// Comando para que se ejecute funcionalidad remotamente
/// WebAPP --> Cliente --> Servidor
/// Servidor --> Cliente { --> WebAPP } --> WebApp
class MensajeComando extends Mensaje {
  Comando comando;

  MensajeComando(id_emisor, id_receptor, this.comando)
      : super(id_emisor, id_receptor) {
    this.tipo = MensajesAPI.COMANDO;
  }
  MensajeComando.desdeDecodificacion(
      List info_direccionamiento, List msjEspecifico)
      : super.desdeDecodificacion(info_direccionamiento) {
    this.tipo = MensajesAPI.COMANDO;
    this.comando = new Comando.desdeCodificacion(msjEspecifico[1]);
  }

  @override
  String _serializacionPropia() => JSON.encode(comando);
}

/// Los _metadatos_ que mantienen vivo al sistema con, justamente, actualizaciones de Informaciones
/// WebAPP \[ --> WebAPP | Servidor\] --> \[ --> WebAPP | Servidor\]
class MensajeInformacion extends Mensaje {
  Informacion informacion;

  MensajeInformacion(id_emisor, id_receptor, this.informacion)
      : super(id_emisor, id_receptor) {
    this.tipo = MensajesAPI.INFORMACION;
  }
  MensajeInformacion.desdeDecodificacion(
      List info_direccionamiento, List msjEspecifico)
      : super.desdeDecodificacion(info_direccionamiento) {
    this.tipo = MensajesAPI.INFORMACION;
    this.informacion = new Informacion.desdeCodificacion(msjEspecifico[1]);
  }

  @override
  String _serializacionPropia() => JSON.encode(informacion);
}

/// Informe de un fallo: COsas que se pretendía que fueran unas, pero son otras
/// WebAPP \[ --> WebAPP | Servidor\] --> \[ --> WebAPP | Servidor\]
class MensajeFalta extends Mensaje {
  Falta falta;

  MensajeFalta(id_emisor, id_receptor, Falta this.falta)
      : super(id_emisor, id_receptor) {
    this.tipo = MensajesAPI.FALTA;
  }
  MensajeFalta.desdeDecodificacion(
      List info_direccionamiento, List msjEspecifico)
      : super.desdeDecodificacion(info_direccionamiento) {
    this.tipo = decodificacionMensajeAPI(msjEspecifico[0]);
    this.falta = msjEspecifico[1];
  }

  @override
  String _serializacionPropia() => JSON.encode(falta);
}

/// Resultado de alguna interacción por parte del usuario: _votacion_, _encuesta_, _etc..._
/// WebAPP \[ --> WebAPP \] --> Cliente --> Servidor
class MensajeInteraccion extends Mensaje {
  String id_interaccion;
  Map valores;

  MensajeInteraccion(id_emisor, id_receptor, this.id_interaccion, this.valores)
      : super(id_emisor, id_receptor) {
    this.tipo = MensajesAPI.INFORMACION;
  }
  MensajeInteraccion.desdeDecodificacion(
      List info_direccionamiento, List msjEspecifico)
      : super.desdeDecodificacion(info_direccionamiento) {
    this.tipo = decodificacionMensajeAPI(msjEspecifico[0]);
    this.id_interaccion = msjEspecifico[1];
    this.valores = msjEspecifico[2];
  }

  @override
  String _serializacionPropia() => JSON.encode([id_interaccion, valores]);
}

/// Mensaje enviado con iniciativa para medir el tiempo de respuesta futuro
/// WebAPP --> \[ WebAPP | Servidor \]
class MensajePing extends Mensaje {
  int indice;

  MensajePing(id_emisor, id_receptor, this.indice)
      : super(id_emisor, id_receptor) {
    this.tipo = MensajesAPI.PING;
  }
  MensajePing.desdeDecodificacion(
      List info_direccionamiento, List msjEspecifico)
      : super.desdeDecodificacion(info_direccionamiento) {
    this.tipo = decodificacionMensajeAPI(msjEspecifico[0]);
    this.indice = msjEspecifico[1];
  }

  @override
  String _serializacionPropia() => JSON.encode(indice);
}

/// Mensaje enviado responsivamente para medir el tiempo de respuesta definitivamente
/// WebAPP --> \[ WebAPP | Servidor \]
class MensajePong extends Mensaje {
  int indice;

  MensajePong(id_emisor, id_receptor, this.indice)
      : super(id_emisor, id_receptor) {
    this.tipo = MensajesAPI.PONG;
  }
  MensajePong.desdeDecodificacion(
      List info_direccionamiento, List msjEspecifico)
      : super.desdeDecodificacion(info_direccionamiento) {
    this.tipo = decodificacionMensajeAPI(msjEspecifico[0]);
    this.indice = msjEspecifico[1];
  }
  MensajePong.desdeMensajePing(MensajePing msj)
      : this(msj.id_receptor, msj.id_emisor.toString(), msj.indice);

  @override
  String _serializacionPropia() => JSON.encode(indice);
}
