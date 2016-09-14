import 'package:WebRTCnetmesh/src/Identidad.dart';
import 'dart:convert';

enum InformacionAPI {
  USUARIOS,
  NUEVO_USUARIO,
  CAMBIO_USUARIO,
  SALIDA_USUARIO,
  NUEVA_TRANSMISION,
  FIN_TRANSMISION,
  INDEFINIDO,
}

abstract class Informacion {
  InformacionAPI tipo;

  Informacion() {
    tipo = InformacionAPI.INDEFINIDO;
  }

  factory Informacion.desdeCodificacion(String codificacion) {
    List partes = JSON.decode(codificacion);
    InformacionAPI tipo = InformacionAPI.values[partes[0]];
    List listaSerializaciones = partes[1];
    switch (tipo) {
      case InformacionAPI.USUARIOS:
        return new InfoUsuarios.desdeListaCodificada(listaSerializaciones);
        break;
      case InformacionAPI.NUEVO_USUARIO:
      case InformacionAPI.SALIDA_USUARIO:
        return new InfoUsuario.desdeListaCodificada(tipo, listaSerializaciones);
        break;
      case InformacionAPI.CAMBIO_USUARIO:
        return new InfoCambioUsuario.desdeListaCodificada(listaSerializaciones);
        break;
      case InformacionAPI.NUEVA_TRANSMISION:
      case InformacionAPI.FIN_TRANSMISION:
        return new InfoTransmision.desdeListaCodificada(
            tipo, listaSerializaciones);
      case InformacionAPI.INDEFINIDO:
      default:
        throw new Exception("Indefinido, no se qué hacer");
    }
  }

  String serializar();

  String toString() => JSON.encode([tipo.index, serializar()]);
}

class InfoCambioUsuario extends Informacion {
  Identidad identidad_vieja;
  Identidad identidad_nueva;

  InfoCambioUsuario([this.identidad_vieja, this.identidad_nueva]) {
    this.tipo = InformacionAPI.CAMBIO_USUARIO;
  }

  InfoCambioUsuario.desdeListaCodificada(List listaSerializaciones) {
    identidad_vieja = new Identidad.desdeString(listaSerializaciones[0]);
    identidad_nueva = new Identidad.desdeString(listaSerializaciones[1]);
  }

  @override
  String serializar() =>
      JSON.encode([identidad_vieja.toString(), identidad_nueva.toString()]);
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

  InfoUsuarios.desdeListaCodificada(List listaSerializaciones) {
    listaSerializaciones
        .forEach((usuario) => usuarios.add(new Identidad.desdeString(usuario)));
  }

  @override
  String serializar() => JSON.encode(usuarios);
}

/// Usado para informar de nuevos usuarios o salidas de los mismos
class InfoUsuario extends Informacion {
  Identidad usuario;

  InfoUsuario(InformacionAPI tipo) {
    this.tipo = tipo;
  }

  InfoUsuario.desdeListaCodificada(
      InformacionAPI tipo, List listaSerializaciones) {
    this.tipo = tipo;
    usuario = new Identidad.desdeString(listaSerializaciones[0]);
  }

  @override
  String serializar() => JSON.encode([usuario.toString()]);
}

class InfoTransmision extends Informacion {
  // TODO: meter la informacion pertinente a las trasmisiones
  InfoTransmision(InformacionAPI tipo) {
    this.tipo = tipo;
  }

  InfoTransmision.desdeListaCodificada(
      InformacionAPI tipo, List listaSerializaciones) {}

  @override
  String serializar() {
    // TODO: implement serializar
  }
}
