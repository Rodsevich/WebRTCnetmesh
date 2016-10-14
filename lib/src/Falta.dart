import 'package:WebRTCnetmesh/src/WebRTCnetmesh_base.dart';

enum FaltasAPI {
  INDEFINIDO,
  NOMBRE_NO_DISPONIBLE,
  NOMBRE_MAL_FORMADO,
  NODO_CAIDO,
  NO_AUTORIZADO
}

/// Indica errores en las conexiones de la libreria
abstract class Falta extends Codificable<FaltasAPI> {
  Falta() {
    tipo = FaltasAPI.INDEFINIDO;
  }

  /// Decodifica desde el contenido de un mensaje
  factory Falta.desdeCodificacion(List codificacion) {
    switch (FaltasAPI.values[codificacion[0]]) {
      case FaltasAPI.NOMBRE_NO_DISPONIBLE:
        Identidad id = new Identidad.desdeCodificacion(codificacion[1]);
        return new FaltaNombreNoDisponible(id);
        break;
      case FaltasAPI.NOMBRE_MAL_FORMADO:
        return new FaltaNombreMalFormado(codificacion[1], codificacion[2]);
        break;
      case FaltasAPI.NO_AUTORIZADO:
        return new FaltaNoAutorizado();
        break;
      case FaltasAPI.NODO_CAIDO:
        return new FaltaNodoCaido(codificacion[1]);
        break;
      case FaltasAPI.INDEFINIDO:
      default:
        throw new Exception("Tipo de falta no reconocido... (No se qué hacer)");
    }
  }
}

/// Cuando se pretende suscribir o cambiar el nombre por uno ya existente
class FaltaNombreNoDisponible extends Falta {
  Identidad identidad_no_disponible;

  String get nombre => identidad_no_disponible.nombre;

  FaltaNombreNoDisponible(this.identidad_no_disponible) {
    this.tipo = FaltasAPI.NOMBRE_NO_DISPONIBLE;
  }

  @override
  serializacionPropia() => identidad_no_disponible;
}

/// Cuando se pretende suscribir o cambiar el nombre por uno inválido
class FaltaNombreMalFormado extends Falta {
  String nombre;
  String causa;

  FaltaNombreMalFormado(this.nombre, this.causa) {
    this.tipo = FaltasAPI.NOMBRE_MAL_FORMADO;
  }

  @override
  serializacionPropia() => [nombre, causa];
}

/// Cuando se pretende enviar un Mensaje a un nodo a través de otro(s) estando
/// el primero caído
class FaltaNodoCaido extends Falta {
  Identidad identidad_nodo_caido;

  FaltaNodoCaido(this.identidad_nodo_caido) {
    this.tipo = FaltasAPI.NODO_CAIDO;
  }

  @override
  serializacionPropia() => identidad_nodo_caido;
}

///Cuando se pretende hacer algo para lo que no se tiene autorización
/// (por ej. [Comando])
class FaltaNoAutorizado extends Falta {
  FaltaNoAutorizado() {
    this.tipo = FaltasAPI.NO_AUTORIZADO;
  }

  @override
  serializacionPropia() => null;
}
