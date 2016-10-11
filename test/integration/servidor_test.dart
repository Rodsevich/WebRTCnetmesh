@TestOn("vm")
import "dart:io";
import "dart:async";
import 'dart:convert';
import 'dart:developer';
import "package:test/test.dart";
import 'package:WebRTCnetmesh/src/Identidad.dart';
import "package:WebRTCnetmesh/WebRTCnetmesh_server.dart";

void main() {
  WebRTCnetmesh servidor = new WebRTCnetmesh();
  StreamController idsCtrl = new StreamController();
  Stream<Identidad> ids = idsCtrl.stream;

  servidor.onNewConnection.listen((id) {
    print("listener del servidor: ${id.runtimeType}");
    print(JSON.encode(id));
    // pp(id);
    // print(StackTrace.current);
    idsCtrl.add(id);
  });

  group("Inicios de sesion", () {
    test("alguna conexion", () {
      ids.listen(expectAsync((Identidad id) {
        print("Dentro de expectAsync: ${id.runtimeType}");
        print(JSON.encode(id));
        expect(id.id_sesion, greaterThan(0));
      }, count: 2));
      // ids.listen(expectAsync((id) {
      //   print("dentro: " + id.runtimeType.toString());
      //   print(JSON.encode(id));
      //   debugger();
      //   expect(id, greaterThan(0));
      // }, reason: "razon", id: "id", count: 1));
    });
    // test("2 conexiones", () async {
    //   servidor.onNewConnection.listen(expectAsync((Identidad id) {
    //     expect(id.nombre, isNotEmpty);
    //   }, count: 2));
    // });
  });

  // group("Usuarios", () {
  //   test("Nombres", (){
  //
  //   });
  // });
}
