# WebRTCnetmesh

A library for interconnecting several browsers through WebRTC via websockets. (someday...)

# USAR ESTA GENIALIDAD (como no estaba antes la ptm!!?!!?)
[MsgPack](https://github.com/DirectMyFile/msgpack.dart)

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
