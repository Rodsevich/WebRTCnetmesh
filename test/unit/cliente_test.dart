@TestOn("browser")
import 'dart:async';
import 'dart:convert';

import 'package:WebRTCnetmesh/WebRTCnetmesh_client.dart';
import 'package:WebRTCnetmesh/src/Identidad.dart';
import 'package:WebRTCnetmesh/src/Mensaje.dart';
import 'package:WebRTCnetmesh/src/WebRTCnetmesh_base.dart';
import 'package:WebRTCnetmesh/src/cliente/WebSocketDebugger.dart';
import "package:scheduled_test/scheduled_test.dart";

void main() {
  WebSocketDebugger debugger = new WebSocketDebugger(4040);
  Identidad identidad = new Identidad("cliente");
  Identity identity = new Identity("cliente");
  WebRTCnetmesh cliente;

  test("Tira exception si no hay conexión con el servidor",(){
    //Debería intemntar crear el cliente acá y que falle normalmente
    //después de eso, recién ahi crear el debugger
  }, skip: "Todavía no implementado");
  test("El cliente se reconecta... ¿con client.reconnect()?",(){
    //client.reconnect() ???
  },skip: "no implementar todavía...");
  test("Envío de Msj de Suscripcion", () {
    String codificacion = new MensajeSuscripcion(identidad).toCodificacion();
    Future msj = schedule(() => debugger.proximoMensajeARecibir);

    cliente = new WebRTCnetmesh(identity); //Dispara Suscripcion namas crearse
    schedule(() => expect(msj, completion(equals(codificacion))));
  });
  test("Suscripcion errónea (nombre ya ocupado)",(){
    // El debugger Debe mandar una suscripcion de donde saca el id_sesion
    //y después un FaltaNombreNoDisponible que hace throwear
  },skip: "implementar pronto");
  test("Checkeo creación de Usuarios", () {
    InfoUsuarios infoUsuarios = new InfoUsuarios();
    infoUsuarios.usuarios
      ..add(identidad..id_sesion = 1)
      ..add(new Identidad("pp")..id_sesion = 2)
      ..add(new Identidad("qq")..id_sesion = 3);
    String codificacion =
        new Mensaje.desdeDatos(0, 1, infoUsuarios).toCodificacion();
    print(codificacion);
    debugger.enviarMensaje(codificacion);
    print("mensaje enviado");
    // schedule(() => new Future.delayed(new Duration(seconds: 2)));
    schedule(() {
      expect(cliente.pairs, isList);
      print(JSON.encode([cliente.identity, cliente.pairs]));
      expect(cliente.identity, equals(new Identidad("cliente")..id_sesion = 1));
      expect(cliente.pairs[0].identidad_remota,
          equals(new Identidad("pp")..id_sesion = 2));
      expect(cliente.pairs[1].identidad_remota,
          equals(new Identidad("qq")..id_sesion = 3));
    });
  });
  test("Cambios en la identity son informados ",(){
    Future msj = schedule(() => debugger.proximoMensajeARecibir);
    Identidad id_vieja = cliente.identity;
    cliente.identity.nombre = "pepe";
    InfoCambioUsuario i = new InfoCambioUsuario(id_vieja, cliente.identity);
    var m = new Mensaje.desdeDatos(cliente.identity.id_sesion, DestinatariosMensaje.TODOS, i);
    String codificacion = m.toCodificacion();
    schedule((){
      expect(msj, completion(equals(codificacion)));
    });
  });
}
