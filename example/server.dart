// Copyright (c) 2016, Nico Rodsevich. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:WebRTCnetmesh/WebRTCnetmesh_server.dart';
import 'package:WebRTCnetmesh/src/Mensaje.dart';

main() {
  WebRTCnetmesh server = new WebRTCnetmesh();
  server.onMessage.listen((Mensaje msj) {
    print("Received ${msj.runtimeType}");
  });
  server.onNewConnection.listen((Identidad id) => print("Conectado: ${id.nombre}"));
}
