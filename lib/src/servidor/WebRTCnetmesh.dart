import "./Cliente.dart";
import "./Servidor.dart";
import "../Comando.dart";
import "../Identidad.dart";
import "../Mensaje.dart";
import "dart:async";
import "dart:io";
import 'package:WebRTCnetmesh/src/Informacion.dart';
import 'package:WebRTCnetmesh/src/Falta.dart';

/// Clase que el usuario final deberá instanciar para usar la librería cómoda
///y modularmente
class WebRTCnetmesh {
  Identidad identity;
  Servidor server;
  List<Cliente> clients;

  WebRTCNetwork([String path, int port]) {
    server = new Servidor(path, port);
    server.onNuevoWebSocket.listen(_manejadorNuevosClientes);
    identity.es_servidor = true;
    identity.nombre = "servidor";
    identity.id_sesion = 0;
  }

  /// Handles the sending of both the information and the destinatary supplied
  send(to, data) {
    int desde = identity.id_sesion;
    Identidad para;
    Cliente medio;
    Mensaje msj;
    switch (to.runtimeType) {
      case Cliente:
        para = to.identidad_remota;
        medio = to;
        break;

      case Identidad:
        para = to;
        medio = searchClient(to);
        break;

      case int:
        //must be the session_id
        Identidad id_busqueda = new Identidad("");
        id_busqueda.id_sesion = to;
        medio = searchClient(id_busqueda);
        para = medio.identidad_remota;
        break;

      default:
        throw new Exception("Tipo de to (${to.runtimeType}) no manejado");
    }

    switch (data.runtimeType) {
      case Mensaje:
        medio = searchClient((data as Mensaje).id_emisor);
        msj = data;
        break;

      case Falta:
        msj = new MensajeFalta(desde, para, data);
        break;

      case Informacion:
        msj = new MensajeInformacion(desde, para, data);
        break;

      case Comando:
        msj = new MensajeComando(desde, para, data);
        break;

      default:
        throw new Exception("Tipo de data (${data.runtimeType}) no manejado");
    }

    if (medio == null)
      throw new Exception("Hubo un lindo error por acá :/");
    else
      medio.enviarMensaje(msj);
  }

  sendAll(Mensaje msj) {
    clients.forEach((c) {
      send(c, msj);
    });
  }

  int get totalClients => clients.length;

  int get amountClientsDirectlyConnected =>
      clients.where((Cliente p) => p.conectadoDirectamente).length;

  Stream<Mensaje> onMessage;
  Stream<Comando> onCommand;
  Stream<Identidad> onNewConnection;

  void _manejadorMensajes(Mensaje msj, Cliente emisor) {
    switch (msj.tipo) {
      case MensajesAPI.SUSCRIPCION:
        if (searchClient((msj as MensajeSuscripcion).identidad) == null) {
          InfoUsuarios usuarios = new InfoUsuarios();
          emisor.identidad_remota.nombre =
              (msj as MensajeSuscripcion).identidad.nombre;
          clients.forEach((c) {
            usuarios.usuarios.add(c.identidad_remota);
          });
          emisor.enviarMensaje(new MensajeInformacion(
              identity, emisor.identidad_remota, usuarios));
          InfoUsuario info = new InfoUsuario(InformacionAPI.NUEVO_USUARIO);
          info.usuario = (msj as MensajeSuscripcion).identidad;
          sendAll(new MensajeInformacion(
              identity, DestinatariosMensaje.TODOS, info));
        } else {
          FaltaNombreNoDisponible falta;
          Cliente cliente = searchClient((msj as MensajeSuscripcion).identidad);
          falta = new FaltaNombreNoDisponible(cliente.identidad_remota);
          send(emisor.identidad_remota, falta);
        }
        break;
      case MensajesAPI.COMANDO:
      case MensajesAPI.INFORMACION:
      case MensajesAPI.INDEFINIDO:
      default:
        throw new Exception(
            "El cliente envió un mensaje desconocido (no se qué hacer)");
    }
  }

  Cliente searchClient(id) {
    try {
      if (id is int)
        return clients.singleWhere((c) => c.identidad_remota.id_sesion == id);
      else if (id is Identidad)
        return clients.singleWhere((c) => c.identidad_remota == id);
      else
        throw new Exception("Usa un int o una Identidad, pls");
    } on StateError {
      return null;
    }
  }

  int _contador_sesiones = 1;
  void _manejadorNuevosClientes(WebSocket ws) {
    Cliente cliente = new Cliente(ws, identity);
    cliente.identidad_remota.id_sesion = _contador_sesiones++;
    cliente.onMensaje.listen((msj) {
      _manejadorMensajes(msj, cliente);
    });
    clients.add(cliente);
  }
}
