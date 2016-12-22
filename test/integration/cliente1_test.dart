@TestOn("browser")
import "dart:html";
// import "dart:async";
import 'package:WebRTCnetmesh/src/WebRTCnetmesh_base.dart';
import "package:test/test.dart";
import "package:WebRTCnetmesh/WebRTCnetmesh_client.dart";

class Imprimir extends Command {
  @override
  askForPermission() {
    return true;
  }

  @override
  Impresor impresor;

  Imprimir(Impresor imp) {
    this.impresor = imp;
  }

  @override
  execute() {
    this.impresor.agregarMsj(this.arguments["valor"]);
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
  print("test cliente 1");

  Impresor imp = new Impresor("actual");

  Imprimir cmdImp = new Imprimir(imp);

  Identity id = new Identity("cliUno");

  group("Inicios de sesion", () {
    test("Conexion cliente 2", () async {
      WebRTCnetmesh cliente1 = new WebRTCnetmesh(id, [cmdImp]);
      cliente1.onNewConnection.listen(expectAsync((Identity id) {
        expect(id.name, equals("cliDos"));
      }));
    });
  });
}
