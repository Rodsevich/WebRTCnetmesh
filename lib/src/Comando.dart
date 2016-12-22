import 'package:WebRTCnetmesh/src/WebRTCnetmesh_base.dart';
import 'package:WebRTCnetmesh/src/cliente/WebRTCnetmesh.dart';

///Contenedor implementación de Comandos
// class ContenedorComandos{
//   final List<Comando> comandos;
//
//   ContenedorComandos
// }

///Wrapper y ejecutor de [Command] para:
/// -Ejecutar la implementación
class Comando {
  int indice;
  String get identificador => implementacion._identifier;

  void set identificador(String identificador) {
    implementacion._identifier = identificador;
  }

  Map arguments = {};
  Command implementacion;

  String get nombre => implementacion.name;

  Comando(this.implementacion, this.indice);

  cargarDesde(Comando otro) {
    this.indice ??= otro.indice;
    this.implementacion ??= otro.implementacion;
    this.arguments = otro.arguments;
  }

  ejecutar(Identidad usuario) {
    if (implementacion == null)
      throw "Tenés que ponerme la implementación... como coño me hiciste? O.o";
    implementacion._ejecutarOrden(usuario, arguments);
  }

}

/// Used to execute a [Command] from another [WebRTCnetmesh] paired client
/// and to Serialize for sending
class CommandOrder extends Codificable {
  String id;
  Map arguments = {};
  // Identity transmitter;

  CommandOrder(this.id, this.arguments);
  CommandOrder._desdeCodificacion(codificacion) {
    this.indice = codificacion[0];
    this.arguments = codificacion[1];
  };

  @override
  serializacionPropia() => [id, arguments];
}

/// Abstract class used to program the execution flow of a [CommandOrder]
///that another [Pair] requests
abstract class Command {
  bool requiresPermission = true;
  bool _permisoConcedido = false;
  List<Identity> allowedUsers = [];
  List<Identity> deniedUsers = [];
  List<Roles> allowedRoles = [Roles.ADMIN];

  /// When adding Commands after creation of [WebRTCnetmesh] client, they must be
  /// provided with an unique name in all [WebRTCnetmesh] instances in order to
  /// distinguish them besides the index provided
  /// TO BE IMPLEMENTED
  String name;

  String _identifier;

  bool askForPermission();
  void execution(Identity user, Map args);
  _ejecutarOrden(Identidad usuario, Map args) {
    Identity identity = new Identity.desdeEncubierto(usuario);
    if (false == allowedUsers.contains(identity)) {
      if (deniedUsers.contains(identity))
        throw new Exception("Usuario denegado");
      if (allowedRoles.any((rol) => usuario.roles.contains(rol)))
        throw new Exception("No se tiene rol requerido");
    }
    if (requiresPermission) {
      if (false == _permisoConcedido) _permisoConcedido = askForPermission();
      if (_permisoConcedido) execution(identity, args);
    } else
      execution(identity, args);
  }

  CommandOrder generateCommand(Map arguments) =>
      new CommandOrder(_identifier, arguments);
}
