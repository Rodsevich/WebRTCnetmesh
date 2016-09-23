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

    InfoUsuario nuevo_usuario = new InfoUsuario(InformacionAPI.NUEVO_USUARIO);
    Identidad sorp = new Identidad("sorp");
    nuevo_usuario.usuario = sorp;
    sorp.id_sesion = 9;
    MensajeInformacion msj = new Mensaje.desdeDatos(3, 7, nuevo_usuario);
    String codificacion = msj.toCodificacion();
    print("codificado como... $codificacion");

    test('Decodificacion MensajeInformacion', () {
      Mensaje mensaje = new Mensaje.desdeCodificacion(codificacion);
      expect(mensaje is MensajeInformacion, isTrue);

      Informacion informacion = (mensaje as MensajeInformacion).informacion;
      expect(informacion is InfoUsuario, isTrue);

      Identidad identidad = (informacion as InfoUsuario).usuario;
      expect(identidad.nombre, equals("sorp"));
      expect(identidad, equals(sorp));
      expect(identidad.id_sesion, equals(9));
    }, testOn: "vm");
  });
}
