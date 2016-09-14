import 'package:WebRTCnetmesh/src/Identidad.dart';
import 'dart:convert';

enum FaltasAPI { INDEFINIDO, NOMBRE_NO_DISPONIBLE, NODO_CAIDO, NO_AUTORIZADO }

/// Indica errores en las conexiones de la libreria
abstract class Falta {
  FaltasAPI tipo;

  Falta() {
    tipo = FaltasAPI.INDEFINIDO;
  }

  /// Decodifica desde un mensaje
  factory Falta.desdeCodificacion(List codificacion_json) {
    switch (FaltasAPI.values[codificacion_json[0]]) {
      case FaltasAPI.INDEFINIDO:
      default:
        throw new Exception("Tipo de falta no reconocido... (No se qué hacer)");
    }
  }

  int codificacionFaltasAPI(FaltasAPI msj) {
    List<FaltasAPI> vals = FaltasAPI.values;
    for (var i in vals) if (msj == vals[i]) return i;
    return FaltasAPI.INDEFINIDO.index;
  }

  FaltasAPI decodificacionFaltasAPI(int index) => FaltasAPI.values[index];

  String serializar();

  String toString() => serializar();
}

/// Cuando se pretende suscribir o cambiar el nombre por uno ya existente
class FaltaNombreNoDisponible extends Falta {
  Identidad identidad_no_disponible;

  FaltaNombreNoDisponible(this.identidad_no_disponible) {
    this.tipo = FaltasAPI.NOMBRE_NO_DISPONIBLE;
  }

  @override
  String serializar() => JSON.encode([
        FaltasAPI.NOMBRE_NO_DISPONIBLE.index,
        identidad_no_disponible.toString()
      ]);
}

/// Cuando se pretende enviar un Mensaje a un nodo a través de otro(s) estando
/// el primero caído
class FaltaNodoCaido extends Falta {
  Identidad identidad_nodo_caido;

  FaltaNodoCaido(this.identidad_nodo_caido) {
    this.tipo = FaltasAPI.NODO_CAIDO;
  }

  @override
  String serializar() => JSON
      .encode([FaltasAPI.NODO_CAIDO.index, identidad_nodo_caido.toString()]);
}

///Cuando se pretende hacer algo para lo que no se tiene autorización
/// (por ej. [Comando])
class FaltaNoAutorizado extends Falta {
  FaltaNoAutorizado() {
    this.tipo = FaltasAPI.NO_AUTORIZADO;
  }

  @override
  String serializar() => JSON.encode([FaltasAPI.NO_AUTORIZADO.index]);
}
