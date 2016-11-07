import 'dart:html';
import 'dart:convert';

import 'package:WebRTCnetmesh/WebRTCnetmesh_client.dart';

ButtonElement botonConectar;

WebRTCnetmesh webRTCnetmesh;
Identity id;

void main() {

  querySelector('#enviar').onClick.listen((_) => enviarTexto());
  querySelector('#texto')
      .onKeyPress
      .listen((KeyboardEvent k) => k.keyCode == 13 ? enviarTexto() : null);
  botonConectar = querySelector("#conectar");
  botonConectar.onClick.listen(conectar);
}

enviarTexto() {
  TextInputElement input = querySelector('#texto');
  String texto = input.value.trim();

  input.value = "";
}

void conectar(_) {
  if(webRTCnetmesh = null){
    webRTCnetmesh = new WebRTCnetmesh(identity, commandImplementations)
  }
}

void outputMessage(String message, [String clase = "info"]) {
  Element e = new ParagraphElement();
  e.classes.add(clase);
  TextAreaElement pantalla = querySelector('#pantalla-chat');
  print(message);
  e.text = message;
  // e.appendHtml('<br/>');
  pantalla.append(e);

  //Make sure we 'autoscroll' the new messages
  pantalla.scrollTop = pantalla.scrollHeight;
}
