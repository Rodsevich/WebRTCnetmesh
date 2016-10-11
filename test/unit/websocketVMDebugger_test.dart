@TestOn("vm")
import 'dart:async';
import 'package:WebRTCnetmesh/src/servidor/WebSocketDebugger.dart';
import "package:scheduled_test/scheduled_test.dart";
import "dart:io";

main() {
  WebSocketDebugger debugger = new WebSocketDebugger(4040);
  WebSocket ws;
  StreamController respuestasWS;
  StreamSubscription suscripcion;

  setUpAll(() async {
    ws = await WebSocket.connect("ws://localhost:4040");
    respuestasWS = new StreamController.broadcast();
    ws.listen((datos) {
      respuestasWS.add(datos);
    });
  });

  test("Recibida", () {
    ws.add("pp");
    var msj = schedule(() => debugger.proximoMensajeARecibir);
    schedule(() => expect(msj, completion(equals("pp"))));
  });
  test("Respuesta", () {
    suscripcion = respuestasWS.stream.listen(expectAsync((String msj) {
      expect(msj, equals("msj"));
      suscripcion.cancel();
    }));
    debugger.enviarMensaje("msj");
  });
  test("respuesta automática", () {
    debugger.mensajeADevolver = "devuelta";
    suscripcion = respuestasWS.stream.listen(expectAsync((String msj) {
      expect(msj, equals("devuelta"));
      suscripcion.cancel();
    }));
    ws.add("data");
  });
  test("ultimo mensaje bien guardado", () {
    expect(debugger.ultimoMensajeRecibido, equals("data"));
  });
}
