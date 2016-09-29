// Copyright (c) 2016, Nico Rodsevich. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import "Mensaje.dart";
import "Comando.dart";
import "Informacion.dart";

/// Usada para estandarizar el proceso de codificacion del objeto para su envio
/// eficiente por la red
abstract class Codificable<API> {
  API tipo;
  serializacionPropia();

  List paraSerializar() {
    List ret = [this.tipo.index];
    if (serializacionPropia() == null) return ret;
    var sPropia = serializacionPropia();
    if (sPropia is List) {
      sPropia.forEach((item) {
        ret.add(serializacionPropia());
      });
    } else
      ret.add(sPropia);
    return ret;
  }

  List toJson() => paraSerializar();
}
