import "./Par.dart";
import "./Servidor.dart";
import "../Comando.dart";
import "../Identidad.dart";
import "../Mensaje.dart";
import "dart:async";
import 'dart:html';

/// Clase que el usuario final deberá instanciar para usar la librería cómoda
///y modularmente
class WebRTCnetmesh {
  Identidad identity;
  Servidor server;
  List<Par> pairs;

  WebRTCNetwork([String server_uri]) {
    server = new Servidor(server_uri);
    server.onMensaje.listen(_manejadorMensajes);
    server.onConexion.listen((e){
      _manejadorConexionServidor(e);
      _pedirInfoRed();
    });
  }

  send(Identidad to, Mensaje message) {}

  sendAll(Mensaje msj) {}

  int get totalPairs => pairs.length;

  int get amountDirectlyConnected =>
      pairs.where((Par p) => p.conectadoDirectamente).length;

  Stream<Mensaje> onMessage;
  Stream<Comando> onCommand;
  Stream<Identidad> onNewConnection;

  void _manejadorConexionServidor(Event e) {
  }

  void _pedirInfoRed() {
  }

  void _manejadorMensajes(Mensaje msj) {
  }
}
