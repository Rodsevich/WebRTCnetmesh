@TestOn("browser")
import 'dart:async';
import 'dart:convert';

import 'package:WebRTCnetmesh/WebRTCnetmesh_client.dart';
import 'package:WebRTCnetmesh/src/Identidad.dart';
import 'package:WebRTCnetmesh/src/Mensaje.dart';
import 'package:WebRTCnetmesh/src/WebRTCnetmesh_base.dart';
import 'package:WebRTCnetmesh/src/cliente/Par.dart';
import 'package:WebRTCnetmesh/src/cliente/WebSocketDebugger.dart';
import "package:scheduled_test/scheduled_test.dart";

class Imprimir extends CommandImplementation{

  @override
  askForPermission() {
    return true;
  }

  @override
  Impresor executor;

  Imprimir(Impresor imp){
    this.executor = imp;
  }

  @override
  execute() {
    this.executor.agregarMsj(this.arguments["valor"]);
  }
}

class Impresor{
  Impresor(this.actual);
  List<String> buffer = [];
  String actual;
  agregarMsj(String msj){
    buffer.add(actual);
    actual = msj;
  }
}

void main() {
  WebSocketDebugger debugger = new WebSocketDebugger(4040);
  Identidad identidad = new Identidad("pepe");
  Identity identity = new Identity.desdeEncubierto(identidad);
  WebRTCnetmesh cliente;
  Impresor impresor = new Impresor("inicial");
  List<CommandImplementation> comandos = [];
  Imprimir comandoImprimir = new Imprimir(impresor);
  comandos.add(comandoImprimir);

  test("Identidad genera Identity",(){
    expect(identidad.aExportable(), new isInstanceOf<Identity>());
  });
  group("Funcionalidad en red:", () {
    test("Tira exception si no hay conexión con el servidor", () {
      //Debería intemntar crear el cliente acá y que falle normalmente
      //después de eso, recién ahi crear el debugger
    }, skip: "Todavía no implementado");
    test("El cliente se reconecta... ¿con client.reconnect()?", () {
      //client.reconnect() ???
    }, skip: "no implementar todavía...");
    test("Envío de Msj de Suscripcion", () {
      String codificacion = new MensajeSuscripcion(identidad).toCodificacion();
      Future msj = schedule(() => debugger.proximoMensajeARecibir);
      //Dispara Suscripcion namas crearse
      cliente = new WebRTCnetmesh(identity, comandos);
      schedule(() => expect(msj, completion(equals(codificacion))));
    });
    test("Mensajde de suscripcion actualiza ID enviada por el server sin +",
        () {
      var iden = new Identidad("cliente")..id_sesion = 1;
      var msj = new MensajeSuscripcion(iden);
      debugger.enviarMensaje(msj.toCodificacion());
      schedule(() => new Future.delayed(new Duration(milliseconds: 300)));
      schedule((){
        expect(identity.name, equals("cliente"));
        expect(identidad.id_sesion, equals(1));
        expect(cliente.associates, isEmpty);
      });
    });
    test("Suscripcion errónea (nombre ya ocupado)", () {
      // El debugger Debe mandar una suscripcion de donde saca el id_sesion
      //y después un FaltaNombreNoDisponible que hace throwear
    }, skip: "implementar pronto");
    test("Creación inicial de Usuarios", () {
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
        expect(cliente.associates, isList);
        expect(cliente.associates.length, equals(2));
        var comparador = new Identidad("cliente")
          ..id_sesion = 1
          ..aExportable();
        expect(cliente.identity, equals(comparador));
        expect(cliente.associates[0].identity,
            equals(new Identidad("pp")..id_sesion = 2..aExportable()));
        expect(cliente.associates[1].identity,
            equals(new Identidad("qq")..id_sesion = 3..aExportable()));
      });
    });
    test("Cambios en la identity son informados ", () {
      Future msj = schedule(() => debugger.proximoMensajeARecibir);
      CambioIdentidad cambio = new CambioIdentidad("n", "cliente", "pepe");
      InfoCambioUsuario info = new InfoCambioUsuario(cambio);
      var m = new Mensaje.desdeDatos(
          identidad.id_sesion, DestinatariosMensaje.TODOS, info);
      String codificacion = m.toCodificacion();
      identity.name = "pepe";
      schedule(() {
        expect(msj, completion(equals(codificacion)));
      });
    });
    test("Creación nuevo usuario", () async {
      cliente.onNewConnection.listen(expectAsync((id) {
        expect(id.name, equals("carlos"));
      }));
      InfoUsuario info = new InfoUsuario(InformacionAPI.NUEVO_USUARIO);
      info.usuario = new Identidad("carlos")..id_sesion = 4;
      MensajeInformacion msj = new Mensaje.desdeDatos(0, 1, info);
      debugger.enviarMensaje(msj.toCodificacion());
    }, testOn: "browser");
  });
  group("Usabilidad con el cliente:", () {
    test("Puede conseguir pairs", () {
      expect(cliente.associates[0], new isInstanceOf<Pair>());
    });
    test("Manda bien los comandos", () {
      var msj = debugger.proximoMensajeARecibir;
      Command imprimirCmd = comandoImprimir.generateCommand({"valor":"pepe"});
      cliente.send(cliente.associates[0], imprimirCmd);
      expect(msj, completion(equals('1,2,3,1,{"valor":"pepe"}')));
    });
    test("Ejecuta bien los comandos",(){
      debugger.enviarMensaje('2,1,3,1,{"valor":"pepe"}');
      schedule(() => new Future.delayed(new Duration(milliseconds: 100)));
      schedule(() => expect(impresor.actual, equals("pepe")));
    }, testOn: "browser");
    test("Recibe bien las interacciones", () async {
      cliente.onInteraction.listen(expectAsync((msj) {
        expect(msj, new isInstanceOf<Interaccion>());
      }));
      InfoUsuario inf = new InfoUsuario(InformacionAPI.NUEVO_USUARIO);
      inf.usuario = identidad;
      debugger
          .enviarMensaje(new MensajeInformacion(4, 1, inf).toCodificacion());
    }, skip: "implementame");
  });
}
