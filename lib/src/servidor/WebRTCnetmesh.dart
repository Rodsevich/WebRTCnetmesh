import "./Cliente.dart";
import "./Servidor.dart";
import "../Comando.dart";
import "../Identidad.dart";
import "../Mensaje.dart";
import "dart:async";

/// Clase que el usuario final deberá instanciar para usar la librería cómoda
///y modularmente
class WebRTCnetmesh {
  Identidad identity;
  Servidor server;
  List<Cliente> clients;

  WebRTCNetwork([String path, int port]) {
    server = new Servidor(path, port);
    server.onNuevoCliente.listen(_manejadorNuevosClientes);
  }

  send(Identidad to, Mensaje message) {}

  sendAll(Mensaje msj) {}

  int get totalClients => clients.length;

  int get amountClientsDirectlyConnected =>
      clients.where((Cliente p) => p.conectadoDirectamente).length;

  Stream<Mensaje> onMessage;
  Stream<Comando> onCommand;
  Stream<Identidad> onNewConnection;

  void _manejadorMensajes(Mensaje msj) {
    switch (msj.tipo) {
      case MensajesAPI.COMANDO:
        break;
      case MensajesAPI.SUSCRIPCION:
        break;
      case MensajesAPI.INFORMACION:
      case MensajesAPI.INDEFINIDO:
      default:
        throw new Exception(
            "El cliente envió un mensaje desconocido (no se qué hacer)");
    }
  }

  void _manejadorNuevosClientes(Cliente cliente) {
    cliente.onMensaje.listen(_manejadorMensajes);
    clients.add(cliente);
  }
}
