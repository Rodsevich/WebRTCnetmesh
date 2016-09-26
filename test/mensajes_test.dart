@TestOn("vm")
// Copyright (c) 2016, Nico Rodsevich. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

// import 'package:WebRTCnetmesh/WebRTCnetmesh_client.dart';
import 'dart:math';
import 'package:test/test.dart';
import 'package:WebRTCnetmesh/src/Informacion.dart';
import 'package:WebRTCnetmesh/src/Identidad.dart';
import 'package:WebRTCnetmesh/src/Mensaje.dart';
import 'package:WebRTCnetmesh/src/Falta.dart';

void main() {
  String codificacion;
  Random aleatorio = new Random();
  int id_emisor = aleatorio.nextInt(99);
  int id_receptor = aleatorio.nextInt(99);

  Mensaje crearMensaje(dato) {
    return new Mensaje.desdeDatos(id_emisor, id_receptor, dato);
  }

  group('MensajesInteraccion', () {
    test('Codificacion', () {
      //skip
    });
    test('Decodificacion', () {
      //skip
    });
  }, skip: "no implementado todavia");

  group('MensajesFalta', () {
    group('Nombre no disponible', () {
      test('Codificacion', () {
        Identidad id = new Identidad("sorpi");
        Falta nombreNoDisponible = new FaltaNombreNoDisponible(id);
        Mensaje mensaje = crearMensaje(nombreNoDisponible);
        expect(mensaje, new isInstanceOf<MensajeFalta>());
        expect((mensaje as MensajeFalta).falta,
            new isInstanceOf<FaltaNombreNoDisponible>());
        expect(
            ((mensaje as MensajeFalta).falta as FaltaNombreNoDisponible)
                .identidad_no_disponible,
            new isInstanceOf<Identidad>());
        expect(
            ((mensaje as MensajeFalta).falta as FaltaNombreNoDisponible)
                .identidad_no_disponible
                .nombre,
            equals("sorpi"));

        codificacion = mensaje.toCodificacion();
      });
      test('Decodificacion', () {
        Mensaje msj = new Mensaje.desdeCodificacion(codificacion);
        expect(msj, new isInstanceOf<MensajeFalta>());

        Falta falta = (msj as MensajeFalta).falta;
        expect(falta, new isInstanceOf<FaltaNombreNoDisponible>());

        var id = (falta as FaltaNombreNoDisponible).identidad_no_disponible;
        expect(id, new isInstanceOf<Identidad>());
        expect(id.nombre, equals("sorpi"));
      });
    });
  });

  group('MensajesComando', () {
    test('Codificacion', () {
      //skip
    });
    test('Decodificacion', () {
      //skip
    });
  }, skip: true);

  group('MensajesInformacion', () {
    test('Codificacion', () {
      InfoUsuario info_nuevo_usuario =
          new InfoUsuario(InformacionAPI.NUEVO_USUARIO);
      Identidad identidad_nuevo_usuario = new Identidad("sorp");
      info_nuevo_usuario.usuario = identidad_nuevo_usuario;
      identidad_nuevo_usuario.id_sesion = 9;
      var msj = crearMensaje(info_nuevo_usuario);
      expect(msj, new isInstanceOf<MensajeInformacion>());
      codificacion = msj.toCodificacion();
    });
    test('Decodificacion', () {
      Mensaje mensaje = new Mensaje.desdeCodificacion(codificacion);
      expect(mensaje is MensajeInformacion, isTrue);

      Informacion informacion = (mensaje as MensajeInformacion).informacion;
      expect(informacion is InfoUsuario, isTrue);

      Identidad identidad = (informacion as InfoUsuario).usuario;
      expect(identidad.nombre, equals("sorp"));
      expect(identidad.id_sesion, equals(9));
    });
  });
}
