import 'package:WebRTCnetmesh/src/Identidad.dart';
import 'package:WebRTCnetmesh/src/WebRTCnetmesh_base.dart';
import 'dart:developer';
// import 'dart:convert';

enum InformacionAPI {
  USUARIOS,
  NUEVO_USUARIO,
  CAMBIO_USUARIO,
  SALIDA_USUARIO,
  NUEVA_TRANSMISION,
  FIN_TRANSMISION,
  INDEFINIDO,
}

abstract class Informacion extends Codificable<InformacionAPI> {
  Informacion() {
    tipo = InformacionAPI.INDEFINIDO;
  }

  factory Informacion.desdeCodificacion(List codificacion) {
    InformacionAPI tipo = InformacionAPI.values[codificacion[0]];
    List listaSerializaciones = codificacion.sublist(1);
    switch (tipo) {
      case InformacionAPI.USUARIOS:
        return new InfoUsuarios.desdeCodificacionPropia(listaSerializaciones);
        break;
      case InformacionAPI.NUEVO_USUARIO:
      case InformacionAPI.SALIDA_USUARIO:
        return new InfoUsuario.desdeCodificacionPropia(
            tipo, listaSerializaciones);
        break;
      case InformacionAPI.CAMBIO_USUARIO:
        return new InfoCambioUsuario.desdeCodificacionPropia(
            listaSerializaciones);
        break;
      case InformacionAPI.NUEVA_TRANSMISION:
      case InformacionAPI.FIN_TRANSMISION:
        return new InfoTransmision.desdeCodificacionPropia(
            tipo, listaSerializaciones);
      case InformacionAPI.INDEFINIDO:
      default:
        throw new Exception("Indefinido, no se qué hacer");
    }
  }
}

class InfoCambioUsuario extends Informacion {
  Identidad identidad_vieja;
  Identidad identidad_nueva;

  InfoCambioUsuario([this.identidad_vieja, this.identidad_nueva]) {
    this.tipo = InformacionAPI.CAMBIO_USUARIO;
  }

  InfoCambioUsuario.desdeCodificacionPropia(List listaSerializaciones) {
    this.tipo = InformacionAPI.CAMBIO_USUARIO;
    //Esta hecho con exepcion a la politica, listaSerializaciones viene
    identidad_vieja = new Identidad.desdeCodificacion(listaSerializaciones[0]);
    identidad_nueva = new Identidad.desdeCodificacion(listaSerializaciones[1]);
  }

  @override
  serializacionPropia() => [identidad_vieja, identidad_nueva];
}

/// Usuarios actualmente registrados en el sistema. Mensaje también utilizado
/// como mensaje que informa del éxito en la suscripción
/// @todo: Hay que meterle:
///   - info de transmisiones vigentes
///   - info de interconexiones vigentes
class InfoUsuarios extends Informacion {
  List<Identidad> usuarios = new List();

  InfoUsuarios() {
    this.tipo = InformacionAPI.USUARIOS;
  }

  InfoUsuarios.desdeCodificacionPropia(List listaSerializaciones) {
    this.tipo = InformacionAPI.USUARIOS;
    listaSerializaciones.forEach(
        (usuario) => usuarios.add(new Identidad.desdeCodificacion(usuario)));
  }

  @override
  serializacionPropia() => usuarios;
}

/// Usado para informar de nuevos usuarios o salidas de los mismos
class InfoUsuario extends Informacion {
  Identidad usuario;

  InfoUsuario(InformacionAPI tipo) {
    this.tipo = tipo;
  }

  InfoUsuario.desdeCodificacionPropia(
      InformacionAPI tipo, List listaSerializaciones) {
    this.tipo = tipo;
    usuario = new Identidad.desdeCodificacion(listaSerializaciones[0]);
  }

  @override
  serializacionPropia() => usuario;
}

class InfoTransmision extends Informacion {
  // TODO: meter la informacion pertinente a las trasmisiones
  InfoTransmision(InformacionAPI tipo) {
    this.tipo = tipo;
  }

  InfoTransmision.desdeCodificacionPropia(
      InformacionAPI tipo, List listaSerializaciones) {
    this.tipo = tipo;
  }

  @override
  String serializacionPropia() {
    // TODO: implement serializar
  }
}
