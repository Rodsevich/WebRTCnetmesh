// Copyright (c) 2016, Nico Rodsevich. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.
library WebRTCNetmesh.base;

import 'dart:async';
import 'package:WebRTCnetmesh/src/Comando.dart';
import 'package:meta/meta.dart' show protected;
import 'Identidad.dart';
import 'Mensaje.dart';

export 'Comando.dart';
export 'Falta.dart';
export 'Identidad.dart';
export 'Informacion.dart';
export 'Mensaje.dart';

/// Usada para estandarizar el proceso de codificacion del objeto para su envio
/// eficiente por la red
abstract class Codificable<API> {
  API tipo;

  serializacionPropia();

  @protected
  List paraSerializar() {
    List ret = (this.tipo != null) ? [this.tipo.index] : [];
    var sPropia = serializacionPropia();
    if (sPropia == null) return ret;
    if (sPropia is! List) {
      sPropia = [sPropia];
    }
    for (var item in sPropia) {
      if (item is Codificable)
        ret.addAll(item.paraSerializar());
      else
        ret.add(item);
    }
    ;
    return ret;
  }

  toJson() => paraSerializar();
}

abstract class Asociado {
  var canal;
  DateTime establecimientoConexion;
  DateTime ultimaComunicacion;
  List<Stopwatch> muestrasLatencia = new List(60);
  int punteroMuestrasLatencia = 0;
  Timer medidorLapsoPing;

  Duration lapsoMedicionPing = new Duration(seconds: 1);

  Duration get tiempoSinComunicacion =>
      new DateTime.now().difference(ultimaComunicacion);
  Duration get tiempoConectado =>
      new DateTime.now().difference(establecimientoConexion);
}

class Associate {}

abstract class Exportable<T> {
  T exportado;
  T aExportable();
}

abstract class EnviadorMensajesTerminal {
  bool tieneConexion;
  var canal;
  enviarMensaje(Mensaje msj);
}

///Tiene que ser si o si un exportable el T, eh
abstract class InterfazEnvioMensaje<T> {
  var identity;
  List<T> associates = [];
  Identidad identidad;
  var servidor;

  var comandos;

  /// Handles the sending of both the information and the destinatary supplied
  send(to, data) {
    int desde = this.identidad.id_sesion;
    var para;
    var medio;
    Mensaje msj;
    if (to is Associate) {
      //todo: manejar errores
      to = associates.singleWhere((T a) => (a as Exportable).exportado == to);
    }
    if (to is T || to is EnviadorMensajesTerminal) {
      //No deja meter T en el switch por no ser const
      para = to.identidad;
      medio = to;
    } else {
      switch (to.runtimeType) {
        case Identidad:
          para = to;
          medio = search(to);
          break;

        case int:
          //must be the session_id
          Identidad id_busqueda = new Identidad("");
          id_busqueda.id_sesion = to;
          medio = search(id_busqueda);
          para = medio.identidad;
          break;

        case DestinatariosMensaje:
          if (to == DestinatariosMensaje.TODOS)
            return sendAll(data);
          else if (to == DestinatariosMensaje.SERVIDOR) {
            para = DestinatariosMensaje.SERVIDOR;
            medio = this.servidor;
          }
          break;

        default:
          throw new Exception("Tipo de to (${to.runtimeType}) no manejado");
      }
    }

    if (data is Command) {
      //Todo: Seguir aca...
      Comando cmd;
      cmd = this.comandos.singleWhere((Comando c) => c.nombre == data.name);
      cmd.indice = (this.comandos as List).indexOf(cmd);
      cmd.arguments = data.arguments;
      data = new Mensaje.desdeDatos(desde, para, cmd);
    }

    msj = (data is Mensaje) ? data : new Mensaje.desdeDatos(desde, para, data);

    medio ??= search((data as Mensaje).id_receptor);
    if (medio == null) {
      throw new Exception("Hubo un lindo error por acá :/");
    } else {
      if(medio.tieneConexion == false)
        medio = this.servidor;
      medio.enviarMensaje(msj);
    }
  }

  sendAll(data) {
    //No se si deberia mandar un mensaje con DestinatariosMensaje.TODOS
    // invariante... Por lo pronto no se está mandando asi
    Mensaje mensaje = (data is Mensaje)
        ? data
        : new Mensaje.desdeDatos(
            this.identidad, DestinatariosMensaje.TODOS, data);
    print(mensaje.toCodificacion());
    if(this.servidor.tieneConexion)
      send(this.servidor, mensaje);
    associates
        .where((a) => a.tieneConexion)
        .forEach((a) => send(a, mensaje));
  }

  T search(id);
}
