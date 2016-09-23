@TestOn("vm")
import "package:test/test.dart";
import "dart:io";
import "dart:async";
import "package:WebRTCnetmesh/WebRTCnetmesh_server.dart";
import 'package:WebRTCnetmesh/src/Identidad.dart';

void main() {
  WebRTCnetmesh servidor = new WebRTCnetmesh();

  group("Inicios de sesion", () {
    test("alguna conexion", () async {
      servidor.onNewConnection.listen(expectAsync((Identidad id) {
        expect(id.nombre, isNotEmpty);
      }));
    });
    test("2 conexiones", () async {
      servidor.onNewConnection.listen(expectAsync((Identidad id) {
        expect(id.nombre, isNotEmpty);
      }, count: 2));
    });
  });
}
