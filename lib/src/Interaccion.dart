import 'package:WebRTCnetmesh/src/WebRTCnetmesh_base.dart';

/// Wrapper interno de [Interaction]s provistos por el developer para el envío
/// del mensajes a los usuarios
class Interaccion {
  String nombre;
  Map arguments = {};

  Interaccion(this.nombre, this.arguments);
}

/// Parent class used to inform of the interactions of this user to the rest
class Interaction {}
