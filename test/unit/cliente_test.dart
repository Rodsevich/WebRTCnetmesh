@TestOn("browser")
import 'dart:async';

import 'dart:convert';
import 'package:WebRTCnetmesh/WebRTCnetmesh_client.dart';
import 'package:WebRTCnetmesh/src/Informacion.dart';
import 'package:WebRTCnetmesh/src/Mensaje.dart';
import 'package:WebRTCnetmesh/src/cliente/WebSocketDebugger.dart';
import "package:scheduled_test/scheduled_test.dart";

void main() {
  WebSocketDebugger debugger = new WebSocketDebugger(4040);
  Identidad identidad = new Identidad("cliente");
  WebRTCnetmesh cliente;

  test("Suscripcion", () {
    String codificacion = new MensajeSuscripcion(identidad).toCodificacion();
    Future msj = schedule(() => debugger.proximoMensajeARecibir);

    cliente = new WebRTCnetmesh(identidad); //Dispara Suscripcion namas crearse
    schedule(() => expect(msj, completion(equals(codificacion))));
  });
  test("Checkeo creación de Usuarios",(){
    InfoUsuarios infoUsuarios = new InfoUsuarios();
    infoUsuarios.usuarios
      ..add(identidad..id_sesion = 1)
      ..add(new Identidad("pp")..id_sesion = 2)
      ..add(new Identidad("qq")..id_sesion = 3);
    String codificacion = new Mensaje.desdeDatos(0, 1, infoUsuarios).toCodificacion();
    print(codificacion);
    debugger.enviarMensaje(codificacion);
    print("mensaje enviado");
    expect(cliente.pairs, isList);
    print(JSON.encode(cliente.pairs));
    expect(cliente.identity, equals(new Identidad("cliente")..id_sesion = 1));
    expect(cliente.pairs[1].identidad_remota, equals(new Identidad("pp")..id_sesion = 2));
    expect(cliente.pairs[2].identidad_remota, equals(new Identidad("qq")..id_sesion = 3));
  });
}
