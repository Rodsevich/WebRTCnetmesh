@TestOn("vm")
// Copyright (c) 2016, Nico Rodsevich. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:WebRTCnetmesh/src/Identidad.dart';
import 'dart:convert';

void main() {
  Identidad id_parcial = new Identidad("nombre");
  id_parcial.id_sesion = 2;
  Identidad id_full = new Identidad("nombre");
  id_full.id_sesion = 2;
  id_full.id_feis = "IDFEIS";
  id_full.id_goog = "IDGOOG";
  id_full.id_github = "IDGithub";
  id_full.email = "pp@qq.com";
  id_full.es_servidor = true;

  String codificacionJSON = JSON.encode(id_full);
  String codificacionString = id_full.toString();
  test('JSON codifica a un String igual que ".toString()"',(){
    expect(codificacionJSON, new isInstanceOf<String>());
    expect(codificacionJSON, equals('"$codificacionString"'));
    expect(JSON.decode(codificacionJSON), equals(codificacionString));
  }, testOn: "vm");
  test('Identidad parcialmente llena recodifica bien', () {
    Identidad id = new Identidad.desdeCodificacion(codificacionString);
    expect(id.nombre, equals("nombre"));
    expect(id.id_sesion, equals(2));
  });
  test('Identidad completamente llena recodifica bien', () {
    Identidad id = new Identidad.desdeCodificacion(codificacionString);
    expect(id.nombre, equals("nombre"));
    expect(id.id_feis, equals("IDFEIS"));
    expect(id.id_goog, equals("IDGOOG"));
    expect(id.id_github, equals("IDGithub"));
    expect(id.email, equals("pp@qq.com"));
    expect(id.es_servidor, isTrue);
    expect(id.id_sesion, equals(2));
  }, testOn: "vm");
  group("CambioIdentidad",(){
    CambioIdentidad cambio = new CambioIdentidad('n', 'nombre', "nico");
    test("tiene buena funcionalidad",(){
      expect(cambio.codificacion, equals("nnico"));
      expect(cambio.valor_viejo, equals("nombre"));
      expect(cambio.toString(), equals("nnico,nombre"));
      cambio.implementarEn(id_parcial);
      expect(id_parcial.nombre, equals("nico"));
    });
    test("es bien disparada en broadcast por Identidad",() async {
      id_parcial.onCambios.listen(expectAsync((CambioIdentidad c) {
        expect(c, equals(cambio));
      }));
      id_parcial.onCambios.listen(expectAsync((CambioIdentidad c) {
        expect(c, equals(cambio));
      }));
      id_parcial.cambiosController.add(cambio);
    });
  });
}
