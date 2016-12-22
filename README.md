# WebRTCnetmesh

A library for interconnecting several browsers through WebRTC via websockets.

This library _is_ useful, but I'm not gonna document much of it 'til july or so (if and only if Gos wants that).
Any questions or interest on this, send an issue or a mail to nicorodsevich[at]gmail.com and I will hurry the plans up

## Features and bugs

Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: http://example.com/issues/replaceme

ToDos:
- Encaminamiento eficiente con bifurcacion de paquetes
- Facilidad registro desde BD en el lado del servidor:
  - _new Identidad()_ a secas, se carga con algún ID. Se envía solicitud. El servidor completa la ID
  - En el servidor:
    - WebRTCnetmesh.onOAuthRequest()
    - WebRTCnetmesh.requestBDSearch(id)
