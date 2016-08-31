// Copyright (c) 2016, Nico Rodsevich. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:WebRTCnetmesh/WebRTCnetmesh_client.dart';
import 'package:test/test.dart';

void main() {
  group('grupo de tests de Identidad', () {
    Awesome awesome;

    setUp(() {
      awesome = new Awesome();
    });

    test('First Test', () {
      expect(awesome.isAwesome, isTrue);
    });
  });
}
