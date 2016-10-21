# WebRTCnetmesh

A library for interconnecting several browsers through WebRTC via websockets.

## Usage

A simple usage example:

    import 'package:WebRTCnetmesh/WebRTCnetmesh.dart';

    main() {
      var awesome = new Awesome();
    }

## Features and bugs

Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: http://example.com/issues/replaceme

ToDos:
- Encaminamiento eficiente con bifurcacion de paquetes
- Facilidad registro desde BD en el lado del servidor:
  - _new Identidad()_ a secas, se carga con algún ID. Se envía solicitud. El servidor completa la ID
  - En el servidor:
    - WebRTCnetmesh.onOAuthRequest()
    - WebRTCnetmesh.reuqestBDSearch(id)
