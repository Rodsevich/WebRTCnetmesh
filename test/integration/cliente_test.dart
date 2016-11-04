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
  print("test cliente");

  Impresor imp1 = new Impresor("actual");
  Impresor imp2 = new Impresor("actual");

  Imprimir cmdImp = new Imprimir(imp1);
  Imprimir cmdImp = new Imprimir(imp1);

  Identity id1 = new Identity("cliUno");
  Identity id2 = new Identity("cliDos");

  group("Inicios de sesion", () {
    test("Conexion cliente 1", () async {
      WebRTCnetmesh cliente1 = new WebRTCnetmesh(id1);
      cliente1.onNewConnection.listen(expectAsync((Identity id) {
        expect(id.name, equals("cliUno"));
      }));
    });
    test("2 conexiones", () async {
      WebRTCnetmesh cliente2 = new WebRTCnetmesh(identity, commandImplementations)sh(id2);
      cliente2.onNewConnection.listen(expectAsync((Identity id) {
        expect(id.name, equals("cliDos"));
      }));
    });
  });
}
