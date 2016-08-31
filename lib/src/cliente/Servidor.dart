import "dart:html";
import "dart:convert";
import "dart:async";
import "../Mensaje.dart";

/// Objeto que tendrá el cliente para facilitar las comunicaciones con el
/// servidor a través de websockets (utilizados también para establecer WebRTC)
class Servidor {
  /// Canal de comunicación con el servidor
  WebSocket canal;

  Stream<Event> onConexion;
  Stream<Mensaje> onMensaje;

  StreamController<Event> _onConexionController;
  StreamController<Mensaje> _onMensajeController;

  /// se puede proporcionar una URL particular para conectarse con el servidor
  /// por defecto la url que se usará será "ws://${window.location.host}"
  Servidor([String url]) {
    url ??= "ws://${window.location.host}";
    log("Creando websocket a: '$url'");
    canal = new WebSocket(url);
    canal.onOpen.listen(_manejadorEstablecimientoDeCanal);

    _onConexionController = new StreamController();
    onConexion = _onConexionController.stream;
    _onConexionController.addStream(canal.onOpen);

    _onMensajeController = new StreamController();
    onMensaje = _onMensajeController.stream;

    log("Esperando establecimiento del canal...");
    canal.onMessage.listen(_manejadorDatosDesdeCanal);
    canal.onError.listen(_manejadorErroresDeCanal);
    canal.onClose.listen(_manejadorCierreDeCanal);
  }

  void mandarMensaje(Mensaje msj) {
    canal.send(msj.toString());
  }

  void _manejadorEstablecimientoDeCanal(Event evt) {
    log("Websocket con servidor abierto.");
    _onConexionController.add(evt);
  }

  void _manejadorErroresDeCanal(ErrorEvent errorMessage) {
    log("Error: ${errorMessage.message}");
  }

  void _manejadorCierreDeCanal(CloseEvent closeEvent) {
    log("Websocket con servidor cerrado.");
  }

  void _manejadorDatosDesdeCanal(MessageEvent messageEvent) {
    log("Se recibió el texto: ${messageEvent.data}");
    Mensaje msj = new Mensaje.desdeCodificacion(messageEvent.data);

    switch (msj.tipo) {
      case MensajesAPI.COMANDO:

      case "offer":
        handleOffer(originClientId, messageContent);
        break;
      case "answer":
        handleAnswer(originClientId, messageContent);
        break;
      case "clientIds":
        handleCliendIds(messageContent);
        break;
      case "clientAdd":
        createSendingRtcPeerConnection(messageContent);
        break;
      case "clientRemove":
        handleClientRemove(messageContent);
        break;
      case "senderCandidate":
        handleSenderCandidate(originClientId, messageContent);
        break;
      case "receiverCandidate":
        handleReceiverCandidate(originClientId, messageContent);
        break;
    }
  }

  void handleCliendIds(List clientIds) {
    log("handleClientIds: clientIds='${clientIds}'");
    clientIds.forEach((id) {
      createSendingRtcPeerConnection(id);
    });
  }

  void createSendingRtcPeerConnection(id) {
    RtcPeerConnection sendingRtcPeerConnection = createRtcPeerConnection();
    ;
    sendingRtcPeerConnections[id] = sendingRtcPeerConnection;
    cachingUserMediaRetriever.get().then((MediaStream stream) {
      sendingRtcPeerConnection.addStream(stream);
      sendOffer(id, sendingRtcPeerConnection);
    });
  }

  void handleClientRemove(id) {
    RtcPeerConnection receivingRtcPeerConnection =
        receivingRtcPeerConnections[id];
    receivingRtcPeerConnections.remove(id);
    notifyRemoveStream(id);

    RtcPeerConnection sendingRtcPeerConnection = sendingRtcPeerConnections[id];
    sendingRtcPeerConnections.remove(id);
  }

  void sendOffer(originClientId, sendingRtcPeerConnection) {
    sendingRtcPeerConnection
        .createOffer({}).then((RtcSessionDescription description) {
      sendingRtcPeerConnection.setLocalDescription(description);
      sendMessage({
        "type": "offer",
        "targetClientId": originClientId,
        "content": {"sdp": description.sdp, "type": description.type}
      });
      sendingRtcPeerConnection.onIceCandidate
          .listen((RtcIceCandidateEvent event) {
        if (event.candidate != null)
          sendMessage({
          "type": "senderCandidate",
          "targetClientId": originClientId,
          "content": {
            "sdpMLineIndex": event.candidate.sdpMLineIndex,
            "candidate": event.candidate.candidate
          }
        });
      });
    });
  }

  void handleOffer(originClientId, offer) {
    var receivingRtcPeerConnection = createRtcPeerConnection();
    receivingRtcPeerConnections[originClientId] = receivingRtcPeerConnection;
    receivingRtcPeerConnection
        .setRemoteDescription(new RtcSessionDescription(offer));
    receivingRtcPeerConnection
        .createAnswer({}).then((RtcSessionDescription description) {
      receivingRtcPeerConnection.setLocalDescription(description);
      sendMessage({
        "type": "answer",
        "targetClientId": originClientId,
        "content": {"sdp": description.sdp, "type": description.type}
      });
    });
    receivingRtcPeerConnection.onIceCandidate
        .listen((RtcIceCandidateEvent event) {
      if (event.candidate != null)
        sendMessage({
        "type": "receiverCandidate",
        "targetClientId": originClientId,
        "content": {
          "sdpMLineIndex": event.candidate.sdpMLineIndex,
          "candidate": event.candidate.candidate
        }
      });
    });
    receivingRtcPeerConnection.onAddStream.listen((MediaStreamEvent event) {
      notifyAddStream(originClientId, event.stream);
    });
    receivingRtcPeerConnection.onIceConnectionStateChange.listen((Event event) {
      if (receivingRtcPeerConnection.iceConnectionState == "disconnected" &&
          receivingRtcPeerConnections.containsKey(originClientId))
        handleClientRemove(originClientId);
    });
  }

  void notifyAddStream(originClientId, MediaStream stream) {
    if (streamAddHandler != null) streamAddHandler(originClientId, stream);
  }

  void notifyRemoveStream(originClientId) {
    if (streamRemoveHandler != null) streamRemoveHandler(originClientId);
  }

  void handleAnswer(originClientId, answer) {
    log("Got answer from ${originClientId}");
    var sendingRtcPeerConnection = sendingRtcPeerConnections[originClientId];
    sendingRtcPeerConnection
        .setRemoteDescription(new RtcSessionDescription(answer));
  }

  void handleReceiverCandidate(originClientId, candidate) {
    var rtcIceCandidate = new RtcIceCandidate({
      "sdpMLineIndex": candidate["sdpMLineIndex"],
      "candidate": candidate["candidate"]
    });
    log("handleReceiverCandidate: originClientId=${originClientId}");
    var sendingRtcPeerConnection = sendingRtcPeerConnections[originClientId];
    sendingRtcPeerConnection.addIceCandidate(
        rtcIceCandidate, handleSuccess, handleError);
  }

  void handleSenderCandidate(originClientId, candidate) {
    var rtcIceCandidate = new RtcIceCandidate({
      "sdpMLineIndex": candidate["sdpMLineIndex"],
      "candidate": candidate["candidate"]
    });
    log("handleSenderCandidate: originClientId=${originClientId}");
    var receivingRtcPeerConnection =
        receivingRtcPeerConnections[originClientId];
    receivingRtcPeerConnection.addIceCandidate(
        rtcIceCandidate, handleSuccess, handleError);
  }

  void setStreamAddHandler(var handler) {
    streamAddHandler = handler;
  }

  void setStreamRemoveHandler(var handler) {
    streamRemoveHandler = handler;
  }

  void handleSuccess() {
    log("Success");
  }

  void log(message) {
    print(message);
  }
}
