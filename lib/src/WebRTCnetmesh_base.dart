// Copyright (c) 2016, Nico Rodsevich. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.
library WebRTCNetmesh.base;

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
    List ret = [this.tipo.index];
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

abstract class InterfazEnvioMensaje<T> {
  List<T> entities = [];

  /// Handles the sending of both the information and the destinatary supplied
  send(to, data) {
    //Hay algo q no me convence... Si me llaman de un sendAll?
    int desde = this.identity.id_sesion;
    Identidad para;
    T medio;
    Mensaje msj;
    if (to.runtimeType == T) {
      //No deja meter T en el switch por no ser const
      para = to.identidad_remota;
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
          para = medio.identidad_remota;
          break;

        default:
          throw new Exception("Tipo de to (${to.runtimeType}) no manejado");
      }
    }

    if (data is Mensaje && medio == null)
      medio = search((data as Mensaje).id_receptor);
    msj = new Mensaje.desdeDatos(desde, para, data);

    if (medio == null) {
      throw new Exception("Hubo un lindo error por acá :/");
    } else
      medio.enviarMensaje(msj);
  }

  send(to, Mensaje message) {
    if (to is DestinatariosMensaje) {
      if (to == DestinatariosMensaje.SERVIDOR)
        server.enviarMensaje(message);
      else if (to == DestinatariosMensaje.TODOS) sendAll(message);
      return;
    }
    if (to is Identidad) {
      Par entidad = _buscarPar(to);
      entidad.enviarMensaje(message);
    } else
      throw new Exception(
          "Must be delivered to Identidad or DestinatariosMensaje");
  }

  sendAll(Mensaje message) {
    message.id_receptor = DestinatariosMensaje.TODOS;
    server.enviarMensaje(message);
    pairs
        .where((Par par) => par.conectadoDirectamente)
        .forEach((Par par) => par.enviarMensaje(message));
  }

  sendAll(Mensaje msj) {
    //No se si deberia mandar un mensaje con DestinatariosMensaje.TODOS
    // invariante... Por lo pronto no se está mandando asi
    entities.forEach((c) {
      send(c, msj);
    });
  }

  T search(id);
}
