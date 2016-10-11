// Copyright (c) 2016, Nico Rodsevich. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:WebRTCnetmesh/src/Mensaje.dart';
import "package:w_transport/w_transport.dart";
import 'package:meta/meta.dart' show protected;

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

abstract class Asociado {
  @protected
  WSocket canal;

  void enviarMensaje(Mensaje msj) {
    canal.add(msj.toCodificacion());
  }

  @protected
  void manejadorMensajes(Mensaje msj);
}
