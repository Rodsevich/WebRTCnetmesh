import "dart:async";
import "dart:io";

import "./Cliente.dart";
import "./Servidor.dart";

import 'package:WebRTCnetmesh/src/WebRTCnetmesh_base.dart';

/// Clase que el usuario final deberá instanciar para usar la librería cómoda
///y modularmente
class WebRTCnetmesh extends InterfazEnvioMensaje<Cliente> {
  Identidad identity;
  Servidor server;

  List<Cliente> clients;

  int get totalClients => clients.length;

  int get amountClientsDirectlyConnected =>
      clients.where((Cliente p) => p.tieneConexion).length;

  Stream<Mensaje> get onMessage => _controladorMensajes.stream;
  Stream<Comando> get onCommand => _controladorComandos.stream;
  Stream<Identidad> get onNewConnection => _controladorNuevasConexiones.stream;

  StreamController _controladorMensajes = new StreamController();
  StreamController _controladorComandos = new StreamController();
  StreamController _controladorNuevasConexiones = new StreamController();

  WebRTCnetmesh([String path, int port]) {
    server = new Servidor(path, port);
    server.onNuevoWebSocket.listen(_manejadorNuevosClientes);
    identity = new Identidad("servidor");
    identity.es_servidor = true;
    identity.id_sesion = 0;
  }

  _reenviar(Mensaje msj) {
    if (msj.ids_intermediarios.last != identity.id_sesion)
      msj.ids_intermediarios.add(identity.id_sesion);
    search(msj.id_receptor).enviarMensaje(msj);
  }

  void _manejadorMensajes(Mensaje msj, Cliente emisor) {
    switch (msj.tipo) {
      case MensajesAPI.SUSCRIPCION:
        try {
          _suscribirNuevoCliente(msj, emisor); //puede tirar faltas
          emisor.enviarMensaje(_estadoActualUsuarios(emisor));
          _propagarNuevaSuscripcion((msj as MensajeSuscripcion).identidad);
        } on FaltaNombreMalFormado catch (falta) {
          send(emisor, falta);
        } on FaltaNombreNoDisponible catch (falta) {
          send(emisor, falta);
        }
        break;
      case MensajesAPI.COMANDO:
      case MensajesAPI.INFORMACION:
      case MensajesAPI.INDEFINIDO:
      default:
        throw new Exception(
            "El cliente envió un mensaje '${msj.runtimeType}' desconocido (no se qué hacer)");
    }
  }

  @override
  Cliente search(id) {
    try {
      if (id is int)
        return clients.singleWhere((c) => c.identidad.id_sesion == id);
      else if (id is Identidad)
        return clients.singleWhere((c) => c.identidad == id);
      else
        throw new Exception("Usa un int o una Identidad, pls");
    } on StateError {
      return null;
    }
  }

  int _contador_sesiones = 1;
  void _manejadorNuevosClientes(WebSocket ws) {
    Cliente cliente = new Cliente(ws, identity);
    cliente.identidad.id_sesion = _contador_sesiones++;
    cliente.onMensaje.listen((msj) {
      _manejadorMensajes(msj, cliente);
    });
    clients.add(cliente);
    _controladorNuevasConexiones.add(cliente.identidad);
  }

  _suscribirNuevoCliente(MensajeSuscripcion msj, Cliente emisor) {
    Identidad id_pretendida = msj.identidad;

    if (search(id_pretendida) != null) {
      //La Identidad pretendida ya está registrada
      Cliente cliente = search(msj.identidad);
      throw new FaltaNombreNoDisponible(cliente.identidad);
    } else {
      try {
        emisor.identidad.nombre = msj.identidad.nombre;
      } catch (e) {
        throw new FaltaNombreMalFormado(id_pretendida.nombre, e.toString());
      }
      emisor.identidad = id_pretendida;
    }
  }

  MensajeInformacion _estadoActualUsuarios(Cliente emisor) {
    InfoUsuarios info_usuarios = new InfoUsuarios();
    for (Cliente c in clients) info_usuarios.usuarios.add(c.identidad);
    return new MensajeInformacion(identity, emisor.identidad, info_usuarios);
  }

  _propagarNuevaSuscripcion(Identidad nuevoId) {
    InfoUsuario info = new InfoUsuario(InformacionAPI.NUEVO_USUARIO);
    info.usuario = nuevoId;
    sendAll(new MensajeInformacion(identity, DestinatariosMensaje.TODOS, info));
  }
}
