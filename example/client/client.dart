import 'dart:html';
import 'dart:convert';

import 'package:WebRTCnetmesh/WebRTCnetmesh_client.dart';

ButtonElement botonConectar;

WebRTCnetmesh webRTCnetmesh;
Identity identity;

List<Command> commands = [new ChatMessage()];

void main() {
  identity = new Identity("name");
  querySelector('#send-button').onClick.listen((_) => sendText());
  querySelector('#message-input')
      .onKeyPress
      .listen((KeyboardEvent k) => k.keyCode == 13 ? sendText() : null);
  querySelector("#registration__connect").onClick.listen(connect);
  querySelector("#registration__nickname").onInput.listen((e) {
    querySelector("#registration__connect").disabled =
        (e.target.value == "") ? true : false;
  });
}

sendText() {
  TextInputElement input = querySelector('#message-input');
  String message = input.value.trim();
  input.value = "";
  appendMessage(message, "message", identity.name);
  //TODO: mandar mensaje a todos
  CommandOrder chatCommand =
}

void connect(_) {
  if (identity == null)
    identity = new Identity(querySelector("#registration__nickname").value);
  else
    identity.name = querySelector("#registration__nickname").value;
  if (webRTCnetmesh == null) {
    webRTCnetmesh = new WebRTCnetmesh(identity, commands);
  }
}

void appendMessage(String message, [String type = "info", String user]) {
  DivElement d = new DivElement();
  d.classes..add("message-line")..add("message-line--$type");
  if (type == "message") d.attributes["data-user"] = user;
  Element chat = querySelector('#chat');
  d.text = message;
  int actualScroll = chat.scrollTop + chat.getBoundingClientRect().height;
  bool scroll = (actualScroll >= chat.scrollHeight) ? true : false;
  chat.append(d);
  //Make sure we 'autoscroll' the new messages
  if (scroll) chat.scrollTop = chat.scrollHeight;
}
