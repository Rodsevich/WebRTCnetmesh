@TestOn("browser")
import 'dart:async';
import 'package:WebRTCnetmesh/src/cliente/WebSocketDebugger.dart';
import "package:scheduled_test/scheduled_test.dart";
import "dart:html";

main() {
  WebSocketDebugger debugger = new WebSocketDebugger(4040);
  WebSocket ws;
  StreamController respuestasWS;
  StreamSubscription suscripcion;

  setUpAll(() async {
    ws = new WebSocket("ws://localhost:4040");
    respuestasWS = new StreamController.broadcast();
    ws.onMessage.listen((MessageEvent evt) {
      var datos = evt.data;
      respuestasWS.add(datos);
    });
  });

  test("Recibida", () {
    ws.send("pp");
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
    ws.send("data");
  });
  test("ultimo mensaje bien guardado", () {
    expect(debugger.ultimoMensajeRecibido, equals("data"));
  });
}
