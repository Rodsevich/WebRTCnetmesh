@TestOn("browser")
import 'package:WebRTCnetmesh/WebRTCnetmesh_client.dart';
import 'package:WebRTCnetmesh/src/cliente/WebSocketDebugger.dart';
import 'package:WebRTCnetmesh/src/Mensaje.dart';
import "package:scheduled_test/scheduled_test.dart";

void main() {
  WebSocketDebugger debugger = new WebSocketDebugger(4040);
  Identidad identidad = new Identidad("cliente");
  WebRTCnetmesh cliente;

  test("Suscripcion", () {
    MensajeSuscripcion suscripcion = new MensajeSuscripcion(identidad);
    String codificacion = suscripcion.toCodificacion();
    var msj = schedule(() => debugger.proximoMensajeARecibir);
    cliente = new WebRTCnetmesh(identidad); //Dispara Suscripcion namas crearse
    schedule(() => expect(msj, completion(equals(codificacion))));
  });
}
