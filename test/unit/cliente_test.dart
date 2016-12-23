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

class Imprimir extends Command {
  @override
  askForPermission() {
    return true;
  }

  Impresor impresor;

  Imprimir(Impresor imp) {
    this.impresor = imp;
    this.name = "imprimir";
  }

  @override
  void execution(Identity user, Map args) {
    this.impresor.agregarMsj(args["mensaje"]);
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
  WebSocketDebugger debugger = new WebSocketDebugger(4040);
  Identity identity = new Identity("sorpi");
  Identidad identidad = new Identidad("sorpi");
  WebRTCnetmesh cliente;
  Impresor impresor = new Impresor("inicial");
  List<Command> comandos = [];
  Imprimir comandoImprimir = new Imprimir(impresor);
  comandos.add(comandoImprimir);

  // test("Identidad genera Identity", () {
  //   expect(identidad.aExportable(), completion(new isInstanceOf<Identity>()));
  // });
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
    test("Mensaje de suscripcion actualiza a ID enviada por el server", () {
      String cambioNombre = "longa";
      String cambioEmail = "p@q.com";
      var iden = identidad
        ..id_sesion = 1
        ..nombre = cambioNombre
        ..email = cambioEmail;
      var msj = new MensajeSuscripcion(iden);
      debugger.enviarMensaje(msj.toCodificacion());
      schedule(() => new Future.delayed(new Duration(milliseconds: 300)));
      schedule(() {
        expect(identity.name, equals(cambioNombre));
        expect(identity.email, equals(cambioEmail));
        //"Cuando mejore el debugger para borrar un cliente y empezar otro nuevo,
        //crearlo con un Identity.desdeEncubierto y sacar este comment"
        // Identidad identidad = new Identidad("pepe");
        // Identity identity = new Identity.desdeEncubierto(identidad);
        // expect(identidad.id_sesion, equals(1));
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
      schedule(() => new Future.delayed(new Duration(milliseconds: 200)));
      var identidadComparadora = new Identity.desdeEncubierto(identidad);
      schedule(() {
        expect(cliente.associates, isList);
        expect(cliente.associates.length, equals(2));
        expect(cliente.identity.name, equals(identidadComparadora.name));
        expect(cliente.associates[0].identity.name, equals("pp"));
        expect(cliente.associates[1].identity.name, equals("qq"));
      });
    });
    test("Cambios en la identity son informados ", () {
      Future msj = schedule(() => debugger.proximoMensajeARecibir);
      String cambioNombre = "cliente";
      CambioIdentidad cambio =
          new CambioIdentidad("n", identidad.nombre, cambioNombre);
      InfoCambioUsuario info = new InfoCambioUsuario(cambio);
      var m = new Mensaje.desdeDatos(
          identidad.id_sesion, DestinatariosMensaje.TODOS, info);
      String codificacion = m.toCodificacion();
      identity.name = cambioNombre;
      schedule(() {
        expect(msj, completion(equals(codificacion)));
      });
    });
    test("Creación nuevo usuario", () async {
      cliente.onNewConnection.listen(expectAsync((id) {
        expect(id.identity.name, equals("carlos"));
      }));
      InfoUsuario info = new InfoUsuario(InformacionAPI.NUEVO_USUARIO);
      info.usuario = new Identidad("carlos")..id_sesion = 4;
      MensajeInformacion msj = new Mensaje.desdeDatos(0, 1, info);
      // Future msj = schedule(() => debugger.proximoMensajeARecibir);
      debugger.enviarMensaje(msj.toCodificacion());
      // schedule(() => expect(msj, completes));
    }, testOn: "browser");
  });
  group("Usabilidad con el cliente:", () {
    test("Puede conseguir pairs", () {
      expect(cliente.associates[0], new isInstanceOf<Pair>());
    });
  });
  group("Comandos:", () {
    String codificacionComando;
    CommandOrder imprimirCmd =
        comandoImprimir.generateCommand({"mensaje": "imprimi"});
    test("Obtener CodificacionComando...", () {
      cliente.send(cliente.associates[0], imprimirCmd);
      schedule(() async {
        codificacionComando = await debugger.proximoMensajeARecibir;
        print("MENSAJE: $codificacionComando");
      });
      // schedule(() => new Future.delayed(new Duration(milliseconds: 500)));
      schedule(() => expect(codificacionComando, new isInstanceOf<String>()));
      schedule(() => expect(codificacionComando, contains("0,{}")););
    });

    test("Manda bien los comandos", () {
      Future msj = schedule(() => debugger.proximoMensajeARecibir);
      cliente.send(cliente.associates[0], imprimirCmd);
      Comando comando = new Comando(null, 0)..arguments = imprimirCmd.arguments;
      schedule(() => expect(msj, completion(equals(codificacionComando))));
      schedule(() => print(msj.runtimeType));
    });

    test("Ejecuta bien los comandos", () {
      Mensaje msj = new Mensaje.desdeCodificacion(codificacionComando);
      var aux = msj.id_emisor;
      msj.id_emisor = msj.id_receptor;
      msj.id_receptor = aux;
      debugger.enviarMensaje(msj.toCodificacion());
      schedule(() => new Future.delayed(new Duration(milliseconds: 300)));
      schedule(() =>
          expect(impresor.actual, equals(imprimirCmd.arguments["mensaje"])));
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
