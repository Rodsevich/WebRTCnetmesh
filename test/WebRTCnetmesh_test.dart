// Copyright (c) 2016, Nico Rodsevich. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

// import 'package:WebRTCnetmesh/WebRTCnetmesh_client.dart';
import 'package:test/test.dart';
import 'package:WebRTCnetmesh/src/Informacion.dart';
import 'package:WebRTCnetmesh/src/Identidad.dart';
import 'package:WebRTCnetmesh/src/Mensaje.dart';

void main() {
  group('grupo de tests de MensajesInformacion', () {
    // String sorp;
    // setUp(() {
    //   sorp = "pp";
    // });
    // test('ejemplo', () {
    //   expect(sorp == "pp", isTrue);
    // });

    Informacion nuevo_usuario = new InfoUsuario(InformacionAPI.NUEVO_USUARIO);
    Identidad sorp = new Identidad("sorp");
    MensajeInformacion msj = new Mensaje.

    test('MensajeInformacion', () {

      expect(sorp == "pp", isTrue);
    });
  });
}
