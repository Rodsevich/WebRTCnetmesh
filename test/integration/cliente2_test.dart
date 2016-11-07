@TestOn("browser")
import "dart:html";
// import "dart:async";
import 'package:WebRTCnetmesh/src/WebRTCnetmesh_base.dart';
import "package:test/test.dart";
import "package:WebRTCnetmesh/WebRTCnetmesh_client.dart";

class Imprimir extends CommandImplementation {
  @override
  askForPermission() {
    return true;
  }

  @override
  Impresor executor;

  Imprimir(Impresor imp) {
    this.executor = imp;
  }

  @override
  execute() {
    this.executor.agregarMsj(this.arguments["valor"]);
  }
}

class Impresor {
  Impresor(this.actual);
  List<String> buffer = [];
  String actual;
  agregarMsj(String msj) {
    buffer.add(actual);
    actual = msj;
  }
}

void main() {
  print("test cliente 2");

  Impresor imp = new Impresor("actual");

  Imprimir cmdImp = new Imprimir(imp);

  Identity id = new Identity("cliDos");

  group("Inicios de sesion", () {
    test("Conexion cliente 1", () async {
      WebRTCnetmesh cliente1 = new WebRTCnetmesh(id, [cmdImp]);
      cliente1.onNewConnection.listen(expectAsync((Identity id) {
        expect(id.name, equals("cliUno"));
      }));
    });
  });
}
