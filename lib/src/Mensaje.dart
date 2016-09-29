import 'dart:convert';
import 'dart:developer';
import 'Identidad.dart';
import 'Informacion.dart';
import 'Falta.dart';
import 'package:WebRTCnetmesh/src/Comando.dart';
import 'package:WebRTCnetmesh/src/WebRTCnetmesh_base.dart';
// import "cliente/Mensaje.dart"
//     show MensajeOfertaWebRTC, MensajeRespuestaWebRTC, MensajeCandidatoICEWebRTC;

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

abstract class Mensaje extends Codificable<MensajesAPI> {
  int _id_emisor;

  int get id_emisor => _id_emisor;

  void set id_emisor(id) {
    if (id is int || id == null)
      _id_emisor = id;
    else if (id is Identidad)
      _id_emisor = id.id_sesion;
    else
      throw new Exception("Usá un int o una Identidad, pls.");
  }

  /// Si es String será el id, si es DestinatariosMensaje, SERVIDOR o TODOS
  var _id_receptor;

  get id_receptor {
    if (_id_receptor >= 0)
      return _id_receptor;
    else
      return DestinatariosMensaje.values[_id_receptor * -1];
  }

  void set id_receptor(id) {
    if (id is DestinatariosMensaje)
      _id_receptor = id.index * -1;
    else if (id is String)
      _id_receptor = int.parse(id);
    else if (id is int)
      _id_receptor = id;
    else if (id is Identidad)
      _id_receptor = id.id_sesion;
    else
      throw new Exception(
          "Usá un String, int, Identidad o DestinatariosMensaje, pls.");
  }

  List<int> ids_intermediarios = new List();

  Mensaje(emisor, receptor) {
    this.id_emisor = emisor;
    this.id_receptor = receptor;
    tipo = MensajesAPI.INDEFINIDO;
  }

  /// Decodifica un mensaje recibido desde un remoto en su clase correspondiente
  factory Mensaje.desdeDatos(desde, para, dato) {
    if (dato is Mensaje) {
      dato.id_emisor = desde;
      dato._id_receptor = para;
      return dato;
    } else if (dato is Falta)
      return new MensajeFalta(desde, para, dato);
    else if (dato is Informacion)
      return new MensajeInformacion(desde, para, dato);
    else if (dato is Comando)
      return new MensajeComando(desde, para, dato);
    else
      throw new Exception("Tipo de dato (${dato.runtimeType}) no manejado");
  }

  /// Decodifica un mensaje recibido desde un remoto en su clase correspondiente
  factory Mensaje.desdeCodificacion(String json) {
    //agregando los [] removidos al momento de codificarlos
    List msjDecodificado = JSON.decode("[$json]");
    List info_direccionamiento = msjDecodificado.sublist(0, 3); // end exclusive
    MensajesAPI tipo = MensajesAPI.values[msjDecodificado[3]];
    List msjEspecifico = msjDecodificado.sublist(4);
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

  // int codificacionMensajeAPI(MensajesAPI msj) {
  //   List<MensajesAPI> vals = MensajesAPI.values;
  //   for (var i in vals) if (msj == vals[i]) return i;
  //   return MensajesAPI.INDEFINIDO.index;
  // }
  //
  // MensajesAPI decodificacionMensajeAPI(int index) => MensajesAPI.values[index];

  List get informacion_direccionamiento =>
      [this._id_emisor, this._id_receptor, this.ids_intermediarios];

  void set informacion_direccionamiento(List info) {
    this._id_emisor = info[0];
    this._id_receptor = info[1];
    if (info[2] != null) this.ids_intermediarios = info[2];
  }

  /// Codificación eficiente para ser enviada por los canales de comunicación
  String toCodificacion() {
    // debugger(when: this is MensajeInformacion &&
    //     (this as MensajeInformacion).informacion is InfoCambioUsuario);
    String sGral = JSON.encode(informacion_direccionamiento);
    String sEsp = JSON.encode(paraSerializar());
    //Le volamos los [] extremos que es al pedo mandarlos por redundantes
    sGral = sGral.substring(1, sGral.length - 1);
    sEsp = sEsp.substring(1, sEsp.length - 1);
    String sorp = "$sGral,${this.tipo.index},$sEsp";
    // debugger(when: this is MensajeInformacion &&
    //     (this as MensajeInformacion).informacion is InfoCambioUsuario);
    return sorp;
  }

  toJson() =>
      throw new Exception("No uses Json con Mensajes, usa toCodificacion()");
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
    this.identidad = new Identidad.desdeCodificacion(msjEspecifico[0]);
  }

  @override
  serializacionPropia() => identidad;
}

/// Comando para que se ejecute funcionalidad remotamente
/// WebAPP --> Cliente --> Servidor
/// Servidor --> Cliente { --> WebAPP } --> WebApp
class MensajeComando extends Mensaje {
  Comando comando;

  MensajeComando(emisor, receptor, this.comando) : super(emisor, receptor) {
    this.tipo = MensajesAPI.COMANDO;
  }
  MensajeComando.desdeDecodificacion(
      List info_direccionamiento, List msjEspecifico)
      : super.desdeDecodificacion(info_direccionamiento) {
    this.tipo = MensajesAPI.COMANDO;
    this.comando = new Comando.desdeCodificacion(msjEspecifico[0]);
  }

  @override
  serializacionPropia() => comando;
}

/// Los _metadatos_ que mantienen vivo al sistema con, justamente, actualizaciones de Informaciones
/// WebAPP \[ --> WebAPP | Servidor\] --> \[ --> WebAPP | Servidor\]
class MensajeInformacion extends Mensaje {
  Informacion informacion;

  MensajeInformacion(emisor, receptor, this.informacion)
      : super(emisor, receptor) {
    this.tipo = MensajesAPI.INFORMACION;
  }
  MensajeInformacion.desdeDecodificacion(
      List info_direccionamiento, List msjEspecifico)
      : super.desdeDecodificacion(info_direccionamiento) {
    this.tipo = MensajesAPI.INFORMACION;
    this.informacion = new Informacion.desdeCodificacion(msjEspecifico);
  }

  @override //Ya devuelve una lista asi q no hace falta encapsular en otros []
  serializacionPropia() => informacion;
}

/// Informe de un fallo: COsas que se pretendía que fueran unas, pero son otras
/// WebAPP \[ --> WebAPP | Servidor\] --> \[ --> WebAPP | Servidor\]
class MensajeFalta extends Mensaje {
  Falta falta;

  MensajeFalta(emisor, receptor, Falta this.falta) : super(emisor, receptor) {
    this.tipo = MensajesAPI.FALTA;
  }
  MensajeFalta.desdeDecodificacion(
      List info_direccionamiento, List msjEspecifico)
      : super.desdeDecodificacion(info_direccionamiento) {
    this.tipo = MensajesAPI.FALTA;
    this.falta = msjEspecifico[0];
  }

  @override
  serializacionPropia() => falta;
}

/// Resultado de alguna interacción por parte del usuario: _votacion_, _encuesta_, _etc..._
/// WebAPP \[ --> WebAPP \] --> Cliente --> Servidor
class MensajeInteraccion extends Mensaje {
  String id_interaccion;
  Map valores;

  MensajeInteraccion(emisor, receptor, this.id_interaccion, this.valores)
      : super(emisor, receptor) {
    this.tipo = MensajesAPI.INFORMACION;
  }
  MensajeInteraccion.desdeDecodificacion(
      List info_direccionamiento, List msjEspecifico)
      : super.desdeDecodificacion(info_direccionamiento) {
    this.tipo = MensajesAPI.INFORMACION;
    this.id_interaccion = msjEspecifico[0];
    this.valores = msjEspecifico[2];
  }

  @override
  serializacionPropia() => [id_interaccion, valores];
}

/// Mensaje enviado con iniciativa para medir el tiempo de respuesta futuro
/// WebAPP --> \[ WebAPP | Servidor \]
class MensajePing extends Mensaje {
  int indice;

  MensajePing(emisor, receptor, this.indice) : super(emisor, receptor) {
    this.tipo = MensajesAPI.PING;
  }
  MensajePing.desdeDecodificacion(
      List info_direccionamiento, List msjEspecifico)
      : super.desdeDecodificacion(info_direccionamiento) {
    this.tipo = MensajesAPI.PING;
    this.indice = msjEspecifico[0];
  }

  @override
  serializacionPropia() => indice;
}

/// Mensaje enviado responsivamente para medir el tiempo de respuesta definitivamente
/// WebAPP --> \[ WebAPP | Servidor \]
class MensajePong extends Mensaje {
  int indice;

  MensajePong(emisor, receptor, this.indice) : super(emisor, receptor) {
    this.tipo = MensajesAPI.PONG;
  }
  MensajePong.desdeDecodificacion(
      List info_direccionamiento, List msjEspecifico)
      : super.desdeDecodificacion(info_direccionamiento) {
    this.tipo = MensajesAPI.PONG;
    this.indice = msjEspecifico[0];
  }
  MensajePong.desdeMensajePing(MensajePing msj)
      : this(msj.id_receptor, msj.id_emisor.toString(), msj.indice);

  @override
  serializacionPropia() => indice;
}
