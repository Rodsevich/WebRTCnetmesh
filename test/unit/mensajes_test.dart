@TestOn("vm")
// Copyright (c) 2016, Nico Rodsevich. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

// import 'package:WebRTCnetmesh/WebRTCnetmesh_client.dart';
import 'dart:math';
import 'dart:convert';
import 'dart:developer';
import 'package:test/test.dart';
import 'package:WebRTCnetmesh/src/Informacion.dart';
import 'package:WebRTCnetmesh/src/Identidad.dart';
import 'package:WebRTCnetmesh/src/Mensaje.dart';
import 'package:WebRTCnetmesh/src/Falta.dart';

class MensajeBase extends Mensaje {
  MensajeBase(emisor, receptor) : super(emisor, receptor);

  @override
  serializacionPropia() {
    return null;
  }
}

void main() {
  String codificacion;
  Random aleatorio = new Random();
  int id_emisor = aleatorio.nextInt(99);
  int id_receptor = aleatorio.nextInt(99);

  Mensaje crearMensaje(dato) {
    return new Mensaje.desdeDatos(id_emisor, id_receptor, dato);
  }

  group('MensajeBase', () {
    test('Codificacion sin intermediarios', () {
      MensajeBase mb = new MensajeBase(id_emisor, id_receptor);
      codificacion = mb.toCodificacion();
      List partes = codificacion.split(',');
      expect(codificacion, startsWith("$id_emisor,$id_receptor"));
      if (JSON.decode(partes[2]) is List)
        fail("Incluye intermediarios vacios en la codificacion");
      expect(partes[2], equals("${MensajesAPI.INDEFINIDO.index}"));
    });
    test('Decodificacion sin intermediarios', () {
      expect(
          () => new Mensaje.desdeCodificacion(codificacion), throwsException);
      expect(codificacion,
          equals("$id_emisor,$id_receptor,${MensajesAPI.INDEFINIDO.index}"));
    });
    test('Codificacion con intermediarios', () {
      MensajeBase mb = new MensajeBase(id_emisor, id_receptor);
      mb.ids_intermediarios = [1, 2, 3];
      codificacion = mb.toCodificacion();
      List partes = JSON.decode("[$codificacion]");
      expect(codificacion, startsWith("$id_emisor,$id_receptor"));
      List inters = partes[2];
      expect(inters, new isInstanceOf<List>());
      expect(inters, equals([1, 2, 3]));
      expect(partes[3], equals(MensajesAPI.INDEFINIDO.index));
    });
    test('Decodificacion con intermediarios', () {
      expect(
          () => new Mensaje.desdeCodificacion(codificacion), throwsException);
      expect(
          codificacion,
          equals(
              "$id_emisor,$id_receptor,[1,2,3],${MensajesAPI.INDEFINIDO.index}"));
    });
  });

  group('MensajesFalta', () {
    group('FaltaNombreNoDisponible', () {
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
        // debugger();
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

  group('MensajesInteraccion', () {
    test('Codificacion', () {
      //skip
    });
    test('Decodificacion', () {
      //skip
    });
  }, skip: "no implementado todavia");

  group('MensajesComando', () {
    test('Codificacion', () {
      //skip
    });
    test('Decodificacion', () {
      //skip
    });
  }, skip: true);
}
