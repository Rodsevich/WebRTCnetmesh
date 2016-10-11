// Copyright (c) 2016, Nico Rodsevich. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:WebRTCnetmesh/WebRTCnetmesh_server.dart';
import 'package:WebRTCnetmesh/src/Mensaje.dart';

main() {
  WebRTCnetmesh servidor = new WebRTCnetmesh();
  servidor.onMessage.listen((Mensaje msj) {
    print("Recibido un ${msj.runtimeType}");
  });
//  servidor.onNewConnection.listen(print);
  servidor.onCommand.listen((_) => print("Un comando! :O"));
}
