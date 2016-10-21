import 'package:WebRTCnetmesh/src/WebRTCnetmesh_base.dart';
///Contenedor implementación de Comandos
// class ContenedorComandos{
//   final List<Comando> comandos;
//
//   ContenedorComandos
// }

///Wrapper y ejecutor de [CommandImplementation] para:
/// -Serializar para envío
/// -Ejecutar la implementación con
class Comando extends Codificable{
  int indice;
  Map arguments = {};
  CommandImplementation implementacion;

  String get nombre => implementacion.name;

  Comando(this.implementacion, this.indice);
  Comando.desdeCodificacion(codificacion){
    this.indice = codificacion[0];
    this.arguments = codificacion[1];
  }

  cargarDesde(Comando otro){
    this.indice ??= otro.indice;
    this.implementacion ??= otro.implementacion;
    this.arguments = otro.arguments;
  }

  ejecutar(){
    if(implementacion == null)
      throw "Tenés que ponerme la implementación, o mejor: En un nuevo comando ya creado cargar mis datos";
    implementacion.arguments = arguments;
    implementacion.execute();
  }

  @override
  serializacionPropia() => [indice,arguments];
}

/// Used to execute a [CommandImplementation] from another [WebRTCnetmesh]
///paired client
class Command{
  String name;
  Map arguments = {};
  // Associate transmitter;

  Command(this.name, this.arguments);
}

/// Abstract parent class used to program the execution flow of a [Command]
///that another [Pair] requests
abstract class CommandImplementation{
  bool requiresPermission = true;
  bool permissionGranted = false;
  List<Associate> allowedUsers = [];
  List<Associate> deniedUsers = [];
  List<Roles> allowedRoles = [Roles.ADMIN];
  List<Roles> grantedRoles = [];
  List<Roles> deniedRoles = [];
  Map arguments = {};
  Object executor;
  String name;
  String description;

  askForPermission();
  execute();

  Command generateCommand(Map arguments) => new Command(this.name, arguments);
}
