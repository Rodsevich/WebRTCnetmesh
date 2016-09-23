@TestOn("content-shell")
import "package:test/test.dart";
import "dart:html";
import "dart:async";
import "package:WebRTCnetmesh/WebRTCnetmesh_client.dart";
import 'package:WebRTCnetmesh/src/Identidad.dart';

void main() {
  Identidad id1 = new Identidad("prb1");
  Identidad id2 = new Identidad("prb2");

  group("Inicios de sesion", () {
    test("Conexion cliente 1", () async {
      WebRTCnetmesh cliente1 = new WebRTCnetmesh(id1);
    });
    test("2 conexiones", () async {
      WebRTCnetmesh cliente2 = new WebRTCnetmesh(id2);
    });
  });
}
