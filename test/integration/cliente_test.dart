@TestOn("browser")
import "dart:html";
// import "dart:async";
import "package:test/test.dart";
import "package:WebRTCnetmesh/WebRTCnetmesh_client.dart";
import 'package:WebRTCnetmesh/src/Identidad.dart';

void main() {
  print("test cliente");
  Identidad id1 = new Identidad("cliUno");
  Identidad id2 = new Identidad("cliDos");

  group("Inicios de sesion", () {
    test("Conexion cliente 1", () async {
      WebRTCnetmesh cliente1 = new WebRTCnetmesh(id1);
      cliente1.onNewConnection.listen(expectAsync((Identidad id) {
        expect(id.nombre, equals("cliUno"));
      }));
    });
    test("2 conexiones", () async {
      WebRTCnetmesh cliente2 = new WebRTCnetmesh(id2);
      cliente2.onNewConnection.listen(expectAsync((Identidad id) {
        expect(id.nombre, equals("cliDos"));
      }));
    });
  });
}
