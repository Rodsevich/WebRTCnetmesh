import 'package:WebRTCnetmesh/src/WebRTCnetmesh_base.dart';

class Comando{
  int indice;
  CommandImplementation commandBody;

  Comando(this.commandBody, this.indice);
  Comando.desdeCodificacion(List codificacion){
    this.indice = codificacion[0];
    this.commandBody.arguments = codificacion[1];
  }

  toJson() => [indice,commandBody.arguments];
}

class Command{
  String name;
  Map arguments = {};
  // Associate transmitter;

  Command(this.name, this.arguments);
}

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
