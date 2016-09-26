@TestOn("vm")
import "package:test/test.dart";
import "dart:io";
import "dart:async";
import "package:WebRTCnetmesh/WebRTCnetmesh_server.dart";
import 'package:WebRTCnetmesh/src/Identidad.dart';

void main() {
  WebRTCnetmesh servidor = new WebRTCnetmesh();
  StreamController idsCtrl = new StreamController();
  Stream<String> ids = idsCtrl.stream;

  servidor.onNewConnection.listen((Identidad id) {
    idsCtrl.add(id.id_sesion);
  });

  group("Inicios de sesion", () {
    test("alguna conexion", () {
      ids.listen(expectAsync((id) {
        expect(id, greaterThan(0));
      }, reason: "razon", id: "id", count: 1));
    });
    // test("2 conexiones", () async {
    //   servidor.onNewConnection.listen(expectAsync((Identidad id) {
    //     expect(id.nombre, isNotEmpty);
    //   }, count: 2));
    // });
  });
}
